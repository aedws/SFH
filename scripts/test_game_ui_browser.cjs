// Local export only. Playwright isolates saves; it never takes over the desktop.
const { chromium } = require('playwright');
const fs = require('node:fs');
const out = process.argv[3] || 'build/ui-review/captures';
const base = process.argv[2] || 'http://127.0.0.1:8768/';
(async () => {
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch({ headless: true });
  const errors = [], warnings = [], captures = [];
  try {
    for (const [width, height] of [[1280,720], [960,540]]) {
      const context = await browser.newContext({ viewport: { width, height } });
      const page = await context.newPage();
      page.on('pageerror', e => errors.push(e.message));
      page.on('console', msg => {
        console.log('WEB', msg.text());
        if (/SCRIPT ERROR|Parse Error|Invalid (call|access)|ERROR:/.test(msg.text())) errors.push(msg.text());
        if (/WebGL: INVALID_OPERATION|context lost/i.test(msg.text())) warnings.push(msg.text());
      });
      await page.goto(base);
      await page.waitForTimeout(8000);
      await page.screenshot({path: `${out}/${width}-boot.png`});
      let previous = '';
      for (let count = 0; count < 40; count++) {
        await page.waitForFunction(last => window.sfhReviewDone || (window.sfhReviewFrame && window.sfhReviewFrame !== last), previous, { timeout: 90000 });
        if (await page.evaluate(() => window.sfhReviewDone)) break;
        const name = await page.evaluate(() => window.sfhReviewFrame);
        await page.screenshot({ path: `${out}/${width}-${name}.png` });
        captures.push(`${width}-${name}`);
        console.log('CAPTURE', width, name);
        previous = name;
        await page.evaluate(() => { window.sfhReviewAdvance = true; });
      }
      if (!await page.evaluate(() => window.sfhReviewDone)) throw new Error('Incomplete review sequence');
      await context.close();
    }
    fs.writeFileSync(`${out}/report.json`, JSON.stringify({ captures, errors, warnings, mode: 'WebGL scripted visual fixtures, not human acceptance' }, null, 2));
    if (errors.length) throw new Error(errors.join('\n'));
    console.log(`GAME_UI_BROWSER_OK captures=${captures.length} warnings=${warnings.length}`);
  } catch (error) {
    fs.writeFileSync(`${out}/report.json`, JSON.stringify({ captures, errors: [...errors, String(error)], warnings, complete: false }, null, 2));
    throw error;
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
