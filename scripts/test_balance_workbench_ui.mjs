import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {mkdir,readFile} from 'node:fs/promises';
import {balanceApi} from '../cloudflare/wiki-auth/balance-api.js';
const {chromium}=createRequire(import.meta.url)('playwright');
const origin=process.argv[2]||'http://127.0.0.1:8767';
assert.ok(['localhost','127.0.0.1'].includes(new URL(origin).hostname));
const catalog=JSON.parse(await readFile('docs/assets/balance-catalog.json','utf8'));
const dps=JSON.parse(await readFile('docs/assets/dps-catalog.json','utf8'));
const browser=await chromium.launch({headless:true});
await mkdir('outputs/balance-workbench',{recursive:true});
const errors=[];
try{
  for(const width of [320,390,768,1440]){
    let role='planner';const records=new Map();
    const bucket={get:async key=>records.has(key)?{json:async()=>JSON.parse(records.get(key).body)}:null,
      put:async(key,body,options)=>{if(records.has(key))return null;records.set(key,{body,options});return {etag:'test'};},
      list:async()=>({objects:[...records.values()].map(v=>({customMetadata:v.options.customMetadata})),truncated:false})};
    const env={WIKI_AUTH:bucket,ASSETS:{fetch:async req=>Response.json(new URL(req.url).pathname.includes('dps-')?dps:catalog)}};
    const page=await browser.newPage({viewport:{width,height:1000},reducedMotion:'reduce'});
    page.on('pageerror',e=>errors.push(String(e)));
    await page.route('**/api/auth/session',route=>route.fulfill({contentType:'application/json',body:JSON.stringify({authenticated:true,role,username:role,csrf:'test'})}));
    await page.route('**/api/auth/balance*',async route=>{
      const r=route.request();const req=new Request(r.url(),{method:r.method(),headers:{...r.headers(),origin},...(r.method()==='POST'?{body:r.postData()}: {})});
      const response=await balanceApi(req,env,{session:{role,csrf:'test'},user:{must_change:false}},r=>r.json());
      await route.fulfill({status:response.status,contentType:'application/json',body:await response.text()});
    });
    await page.goto(origin+'/access/planner/');
    await page.getByText('시설·회수·성장·강화·아이템 등 전체 수치 비교',{exact:true}).click();
    const lab=page.locator('[data-sfh-balance-workbench][data-ready=true]');await lab.waitFor();
    await lab.getByLabel('계산 대상',{exact:true}).selectOption('recovery');
    await lab.getByLabel('투입 크레딧 C',{exact:true}).fill('200');
    assert.match(await lab.getByRole('img').locator('title').textContent(),/투입 대비/);
    const path=await lab.locator('path.dps-total').getAttribute('d');
    await lab.getByLabel('생환율 가정 (0~1)',{exact:true}).fill('0');
    assert.notEqual(await lab.locator('path.dps-total').getAttribute('d'),path);
    await lab.getByLabel('생환율 가정 (0~1)',{exact:true}).fill('');
    assert.ok(await lab.getByRole('alert').isVisible());assert.ok(await lab.getByRole('img').isHidden());
    await lab.getByLabel('생환율 가정 (0~1)',{exact:true}).fill('.5');
    await lab.getByText('검토한 수치를 기획 확정으로 전달',{exact:true}).click();
    await lab.getByRole('button',{name:'기획 확정본 저장',exact:true}).click();
    assert.match(await lab.getByRole('status').innerText(),/저장되지 않음/);assert.equal(records.size,0);
    await lab.getByLabel('안건 제목',{exact:true}).fill('회수 예시 '+width);
    await lab.getByLabel('기획 사유와 목표',{exact:true}).fill('생환율 50%에서 기대 회수를 비교한다.');
    await lab.getByLabel('근거 Notion 링크',{exact:true}).fill('https://example.notion.site/test');
    await lab.getByRole('checkbox').check();await lab.getByRole('button',{name:'기획 확정본 저장',exact:true}).click();
    await lab.getByRole('status').filter({hasText:'저장 완료'}).waitFor();assert.equal(records.size,1);
    assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),`planner overflow ${width}`);
    await lab.screenshot({path:`outputs/balance-workbench/planner-${width}.png`});
    await lab.getByLabel('계산 대상',{exact:true}).selectOption('table');
    await lab.getByLabel('수치 목록',{exact:true}).selectOption('facility');
    await lab.getByLabel('변수 열',{exact:true}).selectOption('risk_bonus');
    const row=lab.locator('.balance-rows input').first();await row.fill('1.5');
    assert.match(await lab.getByRole('img').locator('title').textContent(),/risk_bonus/);
    await lab.getByLabel('계산 대상',{exact:true}).selectOption('facility');
    await lab.getByLabel('잔여 동시 수용량',{exact:true}).fill('0');
    assert.equal(await lab.getByRole('alert').isHidden(),true);
    // Existing DPS input now produces a confirmable model snapshot.
    await page.getByText('무기·스킬·적·AP 계산기',{exact:true}).click();
    const combat=page.locator('[data-sfh-dps-lab][data-confirm-mounted=true]');await combat.waitFor();
    assert.equal(await combat.locator('.balance-confirm').count(),1);
    role='developer';await page.goto(origin+'/access/developer/');
    const gallery=page.locator('[data-sfh-balance-gallery]');
    await gallery.getByText('회수 예시 '+width,{exact:false}).click();
    await gallery.getByRole('img').waitFor();
    assert.equal(await gallery.locator('input,textarea,select').count(),0,'developer has graphs, not trial inputs');
    assert.equal(await gallery.getByRole('button',{name:'기획 확정본 저장'}).count(),0);
    assert.match(await gallery.innerText(),/오너 승인 대기/);
    assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),`developer overflow ${width}`);
    await gallery.screenshot({path:`outputs/balance-workbench/developer-${width}.png`});
    await page.reload();await gallery.getByText('회수 예시 '+width,{exact:false}).click();await gallery.getByRole('img').waitFor();
    assert.equal(records.size,1,'graph reload does not mutate confirmations');
    await page.close();
  }
  assert.deepEqual(errors,[]);
  console.log('BALANCE_UI_E2E_OK 4 widths; trial/invalid/confirm/server recompute/read-only/reload');
}finally{await browser.close();}
