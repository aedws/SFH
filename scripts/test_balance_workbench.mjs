import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {balanceApi} from '../cloudflare/wiki-auth/balance-api.js';
import worker from '../cloudflare/wiki-auth/_worker.js';
const catalog=JSON.parse(await readFile('docs/assets/balance-catalog.json','utf8'));
const dps=JSON.parse(await readFile('docs/assets/dps-catalog.json','utf8'));
const E=globalThis.SFHBalance;
for(const dataset of catalog.datasets)for(const [column,values]of Object.entries(dataset.columns)){
  const input={dataset:dataset.id,column,values:structuredClone(values)};
  const graph=E.calculate('table',catalog,input);assert.equal(graph.points.length,values.length);
  input.values[0].value+=1;assert.equal(E.calculate('table',catalog,input).points[0].value,values[0].value+1);
  input.values[0].value=NaN;assert.throws(()=>E.calculate('table',catalog,input));
}
assert.throws(()=>E.calculate('__proto__',catalog,{}));
const facility={minimum:12,maximum:18,risk:.25,capacity:36};
assert.equal(E.calculate('facility',catalog,facility).points.at(-1).value,23);
assert.equal(E.calculate('facility',catalog,{...facility,capacity:11}).points.at(-1).value,0);
assert.throws(()=>E.calculate('facility',catalog,{...facility,minimum:50}));
const recovery={cost:100,minimum:2.5,maximum:5,success:.5};
assert.equal(E.calculate('recovery',catalog,recovery).points.at(-1).value,250);
assert.equal(E.calculate('recovery',catalog,{...recovery,success:0}).points.at(-1).value,0);
assert.throws(()=>E.calculate('recovery',catalog,{...recovery,success:2}));
const input=globalThis.SFHDps.defaults(dps,'assault_rifle','magnetic_field');
assert.ok(E.calculate('combat',dps,input).points.at(-1).value>0);
assert.ok(E.calculate('combat',dps,{...input,moving:true}).points.at(-1).value>0);
assert.throws(()=>E.calculate('combat',dps,{...input,moving:'true'}),/체크박스/);
assert.throws(()=>E.calculate('combat',dps,{...input,horizon:120,skillDuration:120,skillTick:10,skillCooldown:.05,resourceLimits:false}),/예산/);

class Store{
  values=new Map();
  async get(k){const value=this.values.get(k);return value?{json:async()=>JSON.parse(value.body)}:null;}
  async put(k,body,options){if(options.onlyIf&&this.values.has(k))return null;this.values.set(k,{body,options});return {etag:'test'};}
  async list({prefix,limit,cursor}){const start=Number(cursor||0),rows=[...this.values].filter(([k])=>k.startsWith(prefix)).sort(([a],[b])=>a.localeCompare(b));return {objects:rows.slice(start,start+limit).map(([key,v])=>({key,customMetadata:v.options.customMetadata})),truncated:start+limit<rows.length,cursor:String(start+limit)};}
}
const store=new Store(),origin='https://sfh-dev-wiki.pages.dev';
const env={WIKI_AUTH:store,AUTH_PEPPER:'test',ASSETS:{fetch:async req=>Response.json(new URL(req.url).pathname.includes('dps-')?dps:catalog)}};
const current={session:{role:'planner',csrf:'csrf'},user:{must_change:false}};
const body={id:`${Date.now()}-${crypto.randomUUID()}`,model:'recovery',model_version:E.version,input:recovery,source:await E.fingerprint(catalog.sources),title:'회수 검토',reason:'초보 생환율 가정 비교',notion:'https://example.notion.site/test'};
const req=(data=body,headers={},method='POST')=>new Request(origin+'/api/auth/balance',{method,headers:{origin,'content-type':'application/json','x-csrf-token':'csrf',...headers},...(method==='POST'?{body:JSON.stringify(data)}:{})});
const call=(request,state=current)=>balanceApi(request,env,state,r=>r.json());
assert.equal((await worker.fetch(req(),env)).status,401,'real router rejects anonymous');
assert.equal((await call(req(),null)).status,401);
assert.equal((await call(req(),{...current,session:{...current.session,role:'developer'}})).status,403);
assert.equal((await call(req(),{...current,user:{must_change:true}})).status,403);
assert.equal((await call(req(body,{origin:'https://evil.example'}))).status,403);
assert.equal((await call(req(body,{'x-csrf-token':'no'}))).status,403);
assert.equal((await call(req({...body,notion:'https://notion.site.evil.example/a'}))).status,400);
assert.equal((await call(req({...body,source:'stale'}))).status,409);
assert.equal((await call(req({...body,model_version:0}))).status,409);
assert.equal((await call(req({...body,input:{...recovery,success:20}}))).status,400);
assert.equal(store.values.size,0,'rejected attempts do not write');
let response=await call(req());assert.equal(response.status,201);const saved=await response.json();
assert.equal(saved.graph.points.at(-1).value,250);assert.equal(saved.owner_status,'pending');assert.equal(saved.game_status,'not_applied');
assert.equal((await call(req())).status,200,'retry returns immutable snapshot');
assert.equal((await call(req({...body,title:'overwrite'}))).status,409);
assert.equal(store.values.size,1);
assert.equal((await call(req({}, {},'DELETE'))).status,405);
const get=new Request(`${origin}/api/auth/balance?id=${body.id}`);
const developerView=await (await call(get,{...current,session:{role:'developer'}})).json();
assert.deepEqual(developerView.graph,saved.graph);assert.equal(developerView.submission,undefined,'developer API omits editable submission payload');
for(let i=0;i<22;i++)await call(req({...body,id:`${Date.now()}-${crypto.randomUUID()}`}));
const page=await (await call(new Request(origin+'/api/auth/balance'))).json();assert.equal(page.records.length,20);assert.ok(page.cursor);
const next=await (await call(new Request(origin+'/api/auth/balance?cursor='+page.cursor))).json();assert.equal(next.records.length,3);
assert.ok([...store.values.keys()].every(k=>k.startsWith('balance/confirmed/')));
assert.equal((await (await call(new Request(origin+'/api/auth/balance?latest=combat'))).json()).record,null);
const combatBody={...body,id:`${Date.now()-10000}-${crypto.randomUUID()}`,model:'combat',input,source:await E.fingerprint(dps.sources)};
input.loadout.weapon.modules.push({id:'ballistic_core',slot:0,level:3,quality:1});
const combatSaved=await call(req(combatBody));assert.equal(combatSaved.status,201);
const latest=await (await call(new Request(origin+'/api/auth/balance?latest=combat'),{...current,session:{role:'developer'}})).json();
assert.equal(latest.record.id,combatBody.id,'find combat behind more than one page of other models');
assert.equal(latest.record.graph.series.length,dps.skills.length+2);
assert.equal(latest.record.source,combatBody.source);
assert.equal(latest.record.submission,undefined);
assert.equal((await call(new Request(origin+'/api/auth/balance?latest=combat'),null)).status,401);
console.log(`BALANCE_WORKBENCH_OK datasets=${catalog.datasets.length} numeric columns, immutable confirmation, roles/CSRF/stale/retry/pagination`);
