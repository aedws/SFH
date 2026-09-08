import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {readFile,mkdir,writeFile} from 'node:fs/promises';
import {balanceApi} from '../cloudflare/wiki-auth/balance-api.js';
const {chromium}=createRequire(import.meta.url)('playwright');
const origin=process.argv[2]||'http://127.0.0.1:8767';assert.ok(['localhost','127.0.0.1'].includes(new URL(origin).hostname));
const catalog=JSON.parse(await readFile('docs/assets/dps-catalog.json','utf8'));
const browser=await chromium.launch({headless:true}),errors=[];await mkdir('outputs/weapon-distance',{recursive:true});
try{
 for(const width of [320,390,768,1440]){
  let role='planner';const records=new Map();
  const env={ASSETS:{fetch:async()=>Response.json(catalog)},WIKI_AUTH:{get:async k=>records.has(k)?{json:async()=>JSON.parse(records.get(k))}:null,
    put:async(k,body)=>{records.set(k,body);return {etag:'test'};},list:async()=>({objects:[],truncated:false})}};
  const page=await browser.newPage({viewport:{width,height:1000}});page.on('pageerror',e=>errors.push(String(e)));
  await page.route('**/api/auth/session',r=>r.fulfill({json:{authenticated:true,role,username:role,csrf:'test'}}));
  await page.route('**/api/auth/balance*',async r=>{const q=r.request();const request=new Request(q.url(),{method:q.method(),headers:{...q.headers(),origin},...(q.method()==='POST'?{body:q.postData()}: {})});
    const response=await balanceApi(request,env,{session:{role,csrf:'test'},user:{must_change:false}},r=>r.json());await r.fulfill({status:response.status,contentType:'application/json',body:await response.text()});});
  await page.goto(origin+'/access/planner/');await page.getByText('무기 거리별 DPS · 곡선 수정·확정',{exact:true}).click();
  const lab=page.locator('[data-sfh-distance-lab][data-ready=true]');await lab.waitFor();
  const field=lab.getByLabel('거리:피해 배율 제어점',{exact:true});const initial=await lab.locator('.dps-total').getAttribute('d');
  await field.fill('0:1;1:0.2');assert.notEqual(await lab.locator('.dps-total').getAttribute('d'),initial);
  await field.fill('0:1;0:1;1:0.5');assert.equal(await lab.locator('svg').count(),0);
  await field.fill('0:1;1:0.2');
  await lab.locator('.dps-loadout > summary').click();await lab.getByText(/^무기 · 모듈/).click();
  await lab.getByLabel('무기 모듈 1',{exact:true}).selectOption('ballistic_core');
  assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),`planner overflow ${width}`);
  await lab.locator('.dps-loadout > summary').click();
  await lab.locator('.balance-confirm > summary').click();
  await lab.getByLabel('안건 제목',{exact:true}).fill('거리 감쇠 시험');await lab.getByLabel('기획 사유와 목표',{exact:true}).fill('원거리 피해를 검토');
  await lab.getByLabel('근거 Notion 링크',{exact:true}).fill('https://example.notion.site/distance');await lab.locator('.balance-confirm input[type=checkbox]').check();
  await lab.getByRole('button',{name:'기획 확정본 저장',exact:true}).click();await lab.getByRole('status').filter({hasText:'저장 완료'}).waitFor();
  assert.equal(records.size,1);const saved=JSON.parse([...records.values()][0]);assert.equal(saved.submission.input.distanceCurve,'0:1;1:0.2');
  assert.deepEqual(saved.graph,SFHBalance.calculate('distance',catalog,saved.submission.input));
  await field.fill('0:1;1:0.9');const exported=await lab.locator('[data-distance-export] a').evaluate(async a=>(await fetch(a.href)).json());assert.deepEqual(exported,saved,'export remains saved snapshot');
  await writeFile('outputs/weapon-distance/confirmation.json',JSON.stringify(saved));
  await lab.screenshot({path:`outputs/weapon-distance/planner-${width}.png`});
  role='developer';await page.goto(origin+'/access/developer/');await page.locator('.sfh-workspace-launcher a[href$="#confirmed-balance"]').click();
  const current=page.locator('[data-sfh-distance-lab][data-source=implemented][data-ready=true]');await current.waitFor();
  assert.equal(await current.locator('input,textarea,.balance-confirm').count(),0);assert.match(await current.innerText(),/0:1;0.6:1;1:0.7/);
  await current.getByLabel('거리 곡선 무기',{exact:true}).selectOption('pulse_rifle');assert.match(await current.innerText(),/0:1;0.5:1.25;1:0.6/);
  assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),`developer overflow ${width}`);
  await current.screenshot({path:`outputs/weapon-distance/developer-${width}.png`});await page.close();
 }
 assert.deepEqual(errors,[]);console.log('WEAPON_DISTANCE_UI_OK 4 widths / curves / modules / invalid / confirmation / immutable export / current-only developer');
}finally{await browser.close();}
