// Rendered role pages: navigation, disclosure, draft retention and keyboard contracts.
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {mkdir} from 'node:fs/promises';
const {chromium}=createRequire(import.meta.url)('playwright');
const origin=process.argv[2]||'http://127.0.0.1:8767';
assert.ok(['localhost','127.0.0.1'].includes(new URL(origin).hostname));
const browser=await chromium.launch({headless:true});
await mkdir('outputs/role-workspace',{recursive:true});
const errors=[];
try {
  for(const width of [320,390,768,1440]) for(const role of ['planner','developer']) {
    const height={320:568,390:844,768:1024,1440:900}[width];
    const page=await browser.newPage({viewport:{width,height},reducedMotion:'reduce'});
    page.on('pageerror',e=>errors.push(String(e)));
    await page.route('**/api/auth/session',r=>r.fulfill({json:{authenticated:true,role,username:role,csrf:'test'}}));
    await page.route('**/api/auth/balance*',r=>r.fulfill({json:{ok:true,records:[],cursor:null}}));
    await page.goto(`${origin}/access/${role}/`);
    await page.evaluate(()=>document.fonts.ready);
    const root=page.locator('[data-sfh-workspace]');
    const cards=root.locator('.sfh-workspace-launcher a');
    assert.equal(await cards.count(),7);
    const rect=await cards.last().boundingBox();
    if(role==='developer') assert.ok(rect.y+rect.height<height,`${role} ${width}: all primary actions in first screen`);
    else {
      const notice=page.locator('#decisions-needed');
      const noticeRect=await notice.boundingBox();
      assert.ok(noticeRect.y>=0 && noticeRect.y<height,`planner ${width}: decision notice first`);
      assert.ok(noticeRect.y<rect.y,`planner ${width}: decisions before tools`);
      assert.equal(await notice.locator('details[open]').count(),0);
      assert.equal(await notice.locator('details').count(),5);
      assert.match(await notice.innerText(),/개인 메시지/);
      for(const summary of await notice.locator('summary').all()) {
        await summary.focus(); await page.keyboard.press('Enter');
        assert.ok(await summary.evaluate(n=>n.parentElement.open));
        assert.ok((await summary.boundingBox()).height>=44);
        assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));
        await page.keyboard.press('Enter');
        assert.ok(await summary.evaluate(n=>!n.parentElement.open));
      }
      await page.evaluate(()=>window.scrollTo(0,0));
    }
    assert.equal(await root.locator(':scope > details[open]').count(),role==='planner'?1:0);
    const bounds=async()=>assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),`${role} ${width}: overflow`);
    await bounds();await page.screenshot({path:`outputs/role-workspace/${role}-${width}.png`});
    // Every in-page launch opens its destination without deleting other panels' state.
    const anchors=await cards.evaluateAll(nodes=>nodes.map(n=>new URL(n.href)).filter(u=>u.pathname===location.pathname&&u.hash).map(u=>u.hash));
    for(const hash of anchors) {
      await page.locator(`.sfh-workspace-launcher a[href$="${hash}"]`).focus();
      await page.keyboard.press('Enter');
      await page.waitForFunction(id=>{const n=document.getElementById(id);return n&&n.getBoundingClientRect().height>0;},hash.slice(1));
      await page.waitForFunction(id=>(document.activeElement.id||document.activeElement.parentElement.id)===id,hash.slice(1),{timeout:5000}).catch(async error=>{throw new Error(`${role} ${width} ${hash}: focus ${await page.evaluate(()=>document.activeElement.outerHTML.slice(0,300))}; ${error}`);});
      assert.ok(await page.locator(hash).isVisible());
      await bounds();
    }
    if(role==='planner') {
      assert.equal(await page.locator('#planning-queue [data-sfh-planner-filters] button').count(),4);
      assert.equal(await page.locator('#planning-queue [data-sfh-planner-request-grid]').count(),1);
      await page.locator('.sfh-workspace-launcher a[href$="#proposal-draft"]').click();
      const title=page.locator('#proposal-draft input[name=title]');await title.fill('접어도 유지되는 기획 초안');
      await page.locator('#proposal-draft > summary').click();
      await page.locator('.sfh-workspace-launcher a[href$="#balance-workbench"]').click();
      await page.locator('.sfh-workspace-launcher a[href$="#proposal-draft"]').click();
      assert.equal(await title.inputValue(),'접어도 유지되는 기획 초안');
      await page.goto(`${origin}/access/planner/#notion-authoring`);
      await page.locator('#notion-authoring').waitFor();
      assert.ok(await page.locator('#notion-authoring').isVisible());
      await page.locator('.sfh-workspace-launcher a[href$="#item-balance"]').click();
      await page.goBack();
      await page.locator('#notion-authoring').waitFor();
    } else {
      await page.goto(`${origin}/access/developer/?view=operations`);
      await page.locator('[data-sfh-owner-decision-console]').waitFor();
      assert.ok(await page.locator('#owner-decision-console').isVisible());
      await page.locator('.sfh-workspace-launcher a[href$="#code-module-map"]').click();
      assert.equal(new URL(page.url()).searchParams.get('view'),'operations','In-page tools retain selected console view');
      assert.equal(await page.locator('[data-sfh-owner-decision-console]').count(),1);
    }
    await page.close();
    console.log(`ROLE_WORKSPACE_OK ${role} ${width} first_screen links keyboard disclosure retention deep_link`);
  }
  assert.deepEqual(errors,[]);
} finally {await browser.close();}
