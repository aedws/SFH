import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {mkdir} from 'node:fs/promises';
const {chromium}=createRequire(import.meta.url)('playwright');
const origin=process.argv[2]||'http://127.0.0.1:8767';assert.ok(['localhost','127.0.0.1'].includes(new URL(origin).hostname));
const browser=await chromium.launch({headless:true}),errors=[];await mkdir('outputs/growth',{recursive:true});
try{for(const width of [320,390,768,1440]){
  const page=await browser.newPage({viewport:{width,height:1000},reducedMotion:'reduce'});page.on('pageerror',e=>errors.push(String(e)));
  let role='planner';
  await page.route('**/api/auth/session',r=>r.fulfill({json:{authenticated:true,role,username:role,csrf:'test'}}));
  await page.route('**/api/auth/balance*',r=>r.fulfill({json:{records:[],record:null}}));
  await page.goto(origin+'/access/planner/');
  const weapon=page.locator('[data-sfh-growth-lab][data-kind=weapon][data-ready=true]');await weapon.waitFor();
  await weapon.getByLabel('성장 지표',{exact:true}).selectOption('hit');
  const original=await weapon.locator('.dps-total').getAttribute('d');
  await weapon.getByText('선택한 대상의 단계별 목표값 수정',{exact:true}).click();
  await weapon.getByLabel('3단계 목표값',{exact:true}).fill('100');assert.notEqual(await weapon.locator('.dps-total').getAttribute('d'),original);
  await weapon.getByLabel('3단계 목표값',{exact:true}).fill('');assert.equal(await weapon.locator('svg').count(),0,'invalid trial clears stale curve');
  await weapon.getByLabel('성장 대상 하나 선택',{exact:true}).selectOption('combat_dagger');
  assert.match(await weapon.innerText(),/성장 효과가 없어 평탄/);assert.equal(await weapon.locator('svg').count(),1);
  await weapon.getByLabel('성장 대상 하나 선택',{exact:true}).selectOption('assault_rifle');
  assert.equal(await weapon.locator('.dps-total').getAttribute('d'),original,'switching identity resets trial');
  await weapon.getByText('선택한 대상의 단계별 목표값 수정',{exact:true}).click();
  await weapon.screenshot({path:`outputs/growth/planner-${width}.png`});
  for(const kind of ['character','armor']){
    const root=page.locator(`[data-sfh-growth-lab][data-kind=${kind}]`);
    await root.locator('..').locator('summary').first().click();await root.locator('svg').waitFor();
    await root.getByText('성장 수치·증가율 표',{exact:true}).click();
    assert.equal(await root.locator('table tr').count(),kind==='character'?41:5);
    assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),`${kind} overflow ${width}`);
  }
  role='developer';await page.goto(origin+'/access/developer/');
  await page.locator('.sfh-workspace-launcher a[href$="#confirmed-balance"]').click();
  const dev=page.locator('[data-sfh-growth-lab][data-kind=weapon][data-ready=true]');await dev.waitFor();
  assert.equal(await page.locator('[data-sfh-growth-lab] input,[data-sfh-growth-lab] textarea').count(),0);
  assert.equal(await page.locator('[data-sfh-growth-lab] .balance-confirm').count(),0);
  await dev.getByLabel('성장 지표',{exact:true}).selectOption('hit');assert.equal(await dev.locator('.dps-total').getAttribute('d'),original);
  assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),`developer overflow ${width}`);
  await dev.screenshot({path:`outputs/growth/developer-${width}.png`});await page.close();
}assert.deepEqual(errors,[]);console.log('GROWTH_UI_OK 4 widths; single entity/reset/invalid/flat/stage counts/readonly/no horizontal overflow');}finally{await browser.close();}
