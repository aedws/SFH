import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {mkdir} from 'node:fs/promises';
const {chromium}=createRequire(import.meta.url)('playwright');
const origin=process.argv[2]||'http://127.0.0.1:8767';
assert.ok(['localhost','127.0.0.1'].includes(new URL(origin).hostname));
const browser=await chromium.launch({headless:true});await mkdir('outputs/map-workbench',{recursive:true});
const errors=[];
try{
 for(const width of [320,390,768,1440])for(const role of ['planner','developer']){
  const page=await browser.newPage({viewport:{width,height:900},reducedMotion:'reduce'});
  page.on('pageerror',e=>errors.push(String(e)));
  let posts=0;page.on('request',r=>{if(r.method()==='POST')posts++;});
  await page.route('**/api/auth/session',r=>r.fulfill({json:{authenticated:true,role,username:role,csrf:'test'}}));
  await page.route('**/api/auth/balance*',r=>r.fulfill({json:{ok:true,records:[],cursor:null}}));
  await page.goto(`${origin}/access/${role}/#map-workbench`);
  const host=page.locator('[data-sfh-map-workbench]');await host.locator('svg').waitFor();
  assert.equal(await host.locator('.building').count(),21);
  const fixed=()=>host.locator('.required').evaluateAll(ns=>ns.map(n=>n.outerHTML.replace(/ selected/g,'')));
  const before=await fixed();await host.getByRole('button',{name:'다른 시드',exact:true}).click();assert.deepEqual(await fixed(),before);
  await host.getByLabel('지역',{exact:true}).selectOption('research_complex');
  await host.getByLabel('규모',{exact:true}).selectOption('large');assert.equal(await host.locator('.building').count(),52);
  const room=host.getByLabel('공간 선택 (지도 클릭과 동일)');
  const value=await room.locator('option').filter({hasText:'◆ · 의료 구역'}).getAttribute('value');await room.selectOption(value);
  await host.getByLabel('필수 위치',{exact:true}).selectOption('east');
  assert.match(await room.locator('option:checked').textContent(),/의료 구역/,'moving a required piece must retain that piece selection');
  assert.match(await host.getByRole('status').first().textContent(),/시험 변경/);
  await host.getByText('아이디어 정리 · Notion에 전달',{exact:true}).click();
  await host.getByLabel('목적 → 기대 경험 → 확인 기준').fill('동쪽 의료 구역을 두 번째 출격에서 기억할 수 있는가');
  await host.getByLabel('근거 Notion 주소 (선택)').fill('https://example.com');
  await host.getByRole('button',{name:'제안 초안 만들기'}).click();assert.match(await host.getByRole('status').last().textContent(),/HTTPS Notion/);
  await host.getByLabel('근거 Notion 주소 (선택)').fill('https://sample.notion.site/map');
  await host.getByRole('button',{name:'제안 초안 만들기'}).click();
  assert.match(await host.getByLabel('Notion에 붙일 제안 초안').inputValue(),/승인·게임 적용 아님/);
  assert.match(await host.getByLabel('Notion에 붙일 제안 초안').inputValue(),/east/);
  assert.equal(posts,0,'trial drafts never submit or mutate game');
  assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),`${role} ${width} overflow`);
  for(const b of await host.locator('button').all())assert.ok((await b.boundingBox()).height>=44);
  for(const b of await host.locator('.sfh-map-controls button').all()){
   const bounds=await b.boundingBox();assert.ok(bounds.width>=80&&bounds.height<=80,'control text must not collapse into a vertical column');
  }
  await host.getByRole('button',{name:'다른 시드',exact:true}).click();assert.equal(await host.getByLabel('Notion에 붙일 제안 초안').inputValue(),'');
  await host.getByRole('button',{name:'현행 피스로 복원'}).click();assert.match(await host.getByRole('status').first().textContent(),/현행 CSV/);
  await host.getByLabel('시드',{exact:true}).fill('-1');await host.getByLabel('시드',{exact:true}).press('Tab');assert.equal(await host.locator('svg').count(),0);
  await host.getByLabel('시드',{exact:true}).fill('90808');await host.getByLabel('시드',{exact:true}).press('Tab');await host.locator('svg').waitFor();
  await host.screenshot({path:`outputs/map-workbench/${role}-${width}.png`});
  await page.close();console.log(`MAP_UI_OK ${role} ${width} preview trial draft keyboard no_write bounded`);
 }
 assert.deepEqual(errors,[]);
}finally{await browser.close();}
