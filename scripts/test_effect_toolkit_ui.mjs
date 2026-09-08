import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {mkdir} from 'node:fs/promises';
const {chromium}=createRequire(import.meta.url)('playwright');
const origin=process.argv[2]||'http://127.0.0.1:8767';
assert.ok(['localhost','127.0.0.1'].includes(new URL(origin).hostname));
const browser=await chromium.launch({headless:true});const errors=[];
await mkdir('outputs/effect-toolkit',{recursive:true});
try{
 for(const width of [320,390,768,1440])for(const role of ['planner','developer']){
  const page=await browser.newPage({viewport:{width,height:900},reducedMotion:'reduce'});
  page.on('pageerror',e=>errors.push(String(e)));
  await page.route('**/api/auth/session',r=>r.fulfill({json:{authenticated:true,role,username:role,csrf:'test'}}));
  await page.route('**/api/auth/balance*',r=>r.fulfill({json:{ok:true,records:[],cursor:null}}));
  await page.goto(`${origin}/access/${role}/`);
  const root=page.locator('[data-sfh-effect-toolkit]');
  await page.waitForFunction(()=>document.querySelector('[data-sfh-effect-toolkit]')?.dataset.ready==='true');
  await root.evaluate(n=>{for(let p=n.parentElement;p;p=p.parentElement)if(p.tagName==='DETAILS')p.open=true;});
  await root.scrollIntoViewIfNeeded();
  for(const kind of ['skill','weapon','character','module']){
   await root.getByLabel('대상 종류',{exact:true}).selectOption(kind);
   assert.ok((await root.locator('.dps-note').textContent()).includes('현재'));
   if(role==='planner'){
    await root.getByLabel('기획 의도',{exact:true}).fill('기존 효과를 명확히 지정');
    await root.getByLabel('플레이 수락 조건',{exact:true}).fill('대상에 적용하고 종료·해제 시 원복');
    await root.getByRole('button',{name:'명세 검증·노션 작성문 생성',exact:true}).click();
    assert.ok((await root.getByLabel('노션에 붙여 넣기',{exact:true}).inputValue()).includes('자동 적용되지 않습니다'));
    await root.getByLabel('요청값',{exact:true}).fill('');
    assert.ok(!(await root.getByLabel('노션에 붙여 넣기',{exact:true}).isVisible()),'old draft invalidated');
    await root.getByRole('button',{name:'명세 검증·노션 작성문 생성',exact:true}).click();
    assert.match(await root.getByRole('alert').textContent(),/빈값/);
   }else assert.equal(await root.locator('input,textarea,button').count(),0,'developer is read only');
  }
  assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),`${role} ${width} overflow`);
  await page.screenshot({path:`outputs/effect-toolkit/${role}-${width}.png`});await page.close();
  console.log(`EFFECT_TOOLKIT_UI_OK ${role} ${width}`);
 }
 assert.deepEqual(errors,[]);
}finally{await browser.close();}
