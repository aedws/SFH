// Real DOM events and real confirmation API; loopback only, no production writes.
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {readFile,mkdir} from 'node:fs/promises';
import {balanceApi} from '../cloudflare/wiki-auth/balance-api.js';
const {chromium}=createRequire(import.meta.url)('playwright');
const origin=process.argv[2]||'http://127.0.0.1:8767';
assert.ok(['localhost','127.0.0.1'].includes(new URL(origin).hostname));
const dps=JSON.parse(await readFile('docs/assets/dps-catalog.json','utf8'));
const catalog=JSON.parse(await readFile('docs/assets/balance-catalog.json','utf8'));
const browser=await chromium.launch({headless:true}),errors=[];
await mkdir('outputs/dps-loadout',{recursive:true});
try{
 for(const width of [320,390,768,1440]){
  let role='planner',failure=false;const records=new Map();
  const env={WIKI_AUTH:{get:async k=>records.has(k)?{json:async()=>JSON.parse(records.get(k).body)}:null,
   put:async(k,body,options)=>{records.set(k,{body,options});return {etag:'test'};},
   list:async()=>({objects:[...records.values()].map(v=>({customMetadata:v.options.customMetadata})),truncated:false})},
   ASSETS:{fetch:async req=>Response.json(new URL(req.url).pathname.includes('dps-')?dps:catalog)}};
  const page=await browser.newPage({viewport:{width,height:1000},reducedMotion:'reduce'});
  page.on('pageerror',e=>errors.push(String(e)));
  await page.route('**/api/auth/session',r=>r.fulfill({json:{authenticated:true,role,username:role,csrf:'test'}}));
  await page.route('**/api/auth/balance*',async r=>{
   if(failure)return r.fulfill({status:503,json:{error:'test outage'}});
   const q=r.request(),request=new Request(q.url(),{method:q.method(),headers:{...q.headers(),origin},...(q.method()==='POST'?{body:q.postData()}: {})});
   const response=await balanceApi(request,env,{session:{role,csrf:'test'},user:{must_change:false}},r=>r.json());
   await r.fulfill({status:response.status,contentType:'application/json',body:await response.text()});
  });
  await page.goto(origin+'/access/planner/');
  await page.getByText('무기·스킬·적·AP 계산기',{exact:true}).click();
  const lab=page.locator('[data-sfh-dps-lab][data-confirm-mounted=true]');await lab.waitFor();
  await lab.locator('.dps-loadout > summary').click();
  await lab.getByText(/^무기 · 모듈/).click();
  const original=await lab.locator('.dps-kpis').innerText();
  await lab.getByLabel('무기 파츠 optic',{exact:true}).selectOption('rifle_scope');
  assert.equal(await lab.locator('.dps-kpis').innerText(),original,'non-DPS part must not invent damage');
  await lab.getByLabel('무기 모듈 1',{exact:true}).selectOption('ballistic_core');
  await lab.getByLabel('무기 모듈 1 강화',{exact:true}).selectOption('3');
  assert.notEqual(await lab.locator('.dps-kpis').innerText(),original,'real upgraded weapon module changes result');
  await lab.getByLabel('무기 모듈 2',{exact:true}).selectOption('ballistic_core');
  assert.ok(await lab.locator('[role=alert]').isVisible());
  assert.ok(await lab.locator('.dps-results').isHidden());
  await lab.getByLabel('무기 모듈 2',{exact:true}).selectOption('');
  const beforeCharacter=await lab.locator('.dps-kpis').innerText();
  await lab.getByLabel('캐릭터 원본',{exact:true}).selectOption(dps.loadout.characters.at(-1).character_id);
  assert.notEqual(await lab.locator('.dps-kpis').innerText(),beforeCharacter);
  assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),`attachments overflow ${width}`);
  await lab.locator('.dps-loadout').screenshot({path:`outputs/dps-loadout/attachments-${width}.png`});
  await lab.locator('.dps-extra-graphs > summary').click();
  assert.equal(await lab.locator('.dps-extra-graphs svg').count(),dps.skills.length+2);
  await lab.locator('.balance-confirm > summary').click();
  await lab.getByLabel('안건 제목',{exact:true}).fill('장착 조합 검토');
  await lab.getByLabel('기획 사유와 목표',{exact:true}).fill('탄도 코어 강화와 캐릭터 교체 성능을 확인합니다.');
  await lab.getByLabel('근거 Notion 링크',{exact:true}).fill('https://example.notion.site/loadout');
  await lab.locator('.balance-confirm input[type=checkbox]').check();
  await lab.getByRole('button',{name:'기획 확정본 저장',exact:true}).click();
  await lab.getByRole('status').filter({hasText:'저장 완료'}).waitFor();
  assert.equal(records.size,1);
  const saved=JSON.parse([...records.values()][0].body);
  assert.equal(saved.submission.input.loadout.weapon.modules[0].level,3);
  assert.equal(saved.graph.series.length,dps.skills.length+2);
  role='developer';await page.goto(origin+'/access/developer/');
  await page.locator('.sfh-workspace-launcher a[href$="#confirmed-balance"]').click();
  const panel=page.locator('.balance-combat-default');
  await page.locator('.balance-combat-default[data-source=confirmed][data-ready=true]').waitFor();
  assert.match(await panel.innerText(),/장착 조합 검토/);
  assert.equal(await panel.locator('input,textarea,select').count(),0);
  assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),`default graph overflow ${width}`);
  await panel.screenshot({path:`outputs/dps-loadout/developer-${width}.png`});
  // Stale confirmations survive unchanged; never silently become a current approval.
  for(const v of records.values()){const old=JSON.parse(v.body);old.submission.source='stale';v.body=JSON.stringify(old);}
  await panel.getByRole('button').click();
  await page.locator('.balance-combat-default[data-source=implemented]').waitFor();
  assert.match(await panel.innerText(),/재검토/);
  records.clear();await panel.getByRole('button').click();
  await panel.getByRole('status').filter({hasText:'확정본이 없습니다'}).waitFor();
  failure=true;await panel.getByRole('button').click();
  await panel.getByRole('status').filter({hasText:'조회 실패'}).waitFor();
  assert.ok(await panel.locator('svg').first().isVisible());assert.equal(records.size,0);
  await page.close();
 }
 assert.deepEqual(errors,[]);
 console.log('DPS_LOADOUT_UI_OK 4 widths; attachments/invalid/character/skill graphs/real confirmation/developer default/stale/absent/outage');
}finally{await browser.close();}
