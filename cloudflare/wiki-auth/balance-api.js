import '../../docs/javascripts/dps-engine.js';
import '../../docs/javascripts/balance-engine.js';

// Immutable records in the EXISTING private wiki bucket; no gameplay or credential writes.
const PREFIX='balance/confirmed/';
const idPattern=/^\d{13}-[a-f0-9-]{36}$/;
const keyFor=id=>`${PREFIX}${String(9999999999999-Number(id.slice(0,13))).padStart(13,'0')}-${id}.json`;
const response=(body,status=200)=>new Response(JSON.stringify(body),{status,headers:{'content-type':'application/json','cache-control':'no-store'}});
const graphView=record=>{const {submission,...view}=record;return view;};
export async function balanceApi(request,env,current,parseBody){
  if(!current)return response({error:'로그인이 필요합니다.'},401);
  if(current.user.must_change)return response({error:'먼저 비밀번호를 변경하세요.'},403);
  const url=new URL(request.url);
  if(request.method==='GET'){
    const id=url.searchParams.get('id');
    if(id){if(!idPattern.test(id))return response({error:'잘못된 ID'},400);const object=await env.WIKI_AUTH.get(keyFor(id));if(!object)return response({error:'안건 없음'},404);const record=await object.json();return response(current.session.role==='developer'?graphView(record):record);}
    const page=await env.WIKI_AUTH.list({prefix:PREFIX,limit:20,cursor:url.searchParams.get('cursor')||undefined,include:['customMetadata']});
    return response({records:page.objects.map(o=>o.customMetadata),cursor:page.truncated?page.cursor:null});
  }
  if(request.method!=='POST')return response({error:'읽기 또는 새 확정만 가능합니다.'},405);
  if(current.session.role!=='planner')return response({error:'개발자는 확정 그래프 읽기 전용입니다.'},403);
  if(request.headers.get('origin')!==url.origin||request.headers.get('x-csrf-token')!==current.session.csrf)return response({error:'요청 검증 실패'},403);
  const body=await parseBody(request);
  if(!idPattern.test(body.id||'')||!['combat','table','facility','recovery'].includes(body.model))return response({error:'지원하지 않는 안건'},400);
  if(typeof body.title!=='string'||!body.title.trim()||body.title.length>100||typeof body.reason!=='string'||!body.reason.trim()||body.reason.length>2000)return response({error:'제목과 기획 사유를 입력하세요.'},400);
  let source;
  try {source=new URL(body.notion);if(source.protocol!=='https:'||!['notion.site','notion.so'].some(d=>source.hostname===d||source.hostname.endsWith('.'+d)))throw Error();}
  catch{return response({error:'기획 근거 Notion HTTPS 링크가 필요합니다.'},400);}
  // Retry of the same submitted snapshot is idempotent, including after a deploy.
  const key=keyFor(body.id),existing=await env.WIKI_AUTH.get(key);
  if(existing){const saved=await existing.json();return JSON.stringify(saved.submission)===JSON.stringify(body)?response(saved):response({error:'같은 ID의 내용을 덮어쓸 수 없습니다.'},409);}
  const catalogPath=body.model==='combat'?'/assets/dps-catalog.json':'/assets/balance-catalog.json';
  const raw=await env.ASSETS.fetch(new Request(new URL(catalogPath,url)));
  if(!raw.ok)return response({error:'원본 카탈로그를 읽지 못했습니다.'},503);
  const catalog=await raw.json();
  const fingerprint=await globalThis.SFHBalance.fingerprint(catalog.sources);
  if(body.source!==fingerprint||body.model_version!==globalThis.SFHBalance.version)return response({error:'원본 또는 계산 모델이 갱신되었습니다. 다시 불러온 뒤 검토하세요.'},409);
  let graph;
  try{graph=globalThis.SFHBalance.calculate(body.model,catalog,body.input);}catch(e){return response({error:e.message},400);}
  const record={schema:1,id:body.id,title:body.title.trim(),reason:body.reason.trim(),notion:source.href,role:'planner',status:'planner_confirmed',owner_status:'pending',game_status:'not_applied',confirmed_at:new Date().toISOString(),model_version:globalThis.SFHBalance.version,submission:body,graph};
  const saved=await env.WIKI_AUTH.put(key,JSON.stringify(record),{onlyIf:{etagDoesNotMatch:'*'},httpMetadata:{contentType:'application/json'},customMetadata:{id:record.id,title:record.title,confirmed_at:record.confirmed_at,model:body.model}});
  if(!saved)return response({error:'다른 요청이 먼저 저장되었습니다. 같은 안건을 다시 확인하세요.'},409);
  return response(record,201);
}
