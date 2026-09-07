// Local rendered-wiki regression. Serve .wiki-site on loopback; no auth bypass is deployed.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { mkdir } from 'node:fs/promises';
const { chromium } = createRequire(import.meta.url)('playwright');
const origin = process.argv[2] || 'http://127.0.0.1:8767';
assert.ok(['127.0.0.1', 'localhost'].includes(new URL(origin).hostname), 'Local build only');
const browser = await chromium.launch({ headless: true });
const widths = [320, 390, 768, 1440];
const errors = [];
await mkdir('outputs/developer-workspace', { recursive: true });
try {
  for (const width of widths) {
    const page = await browser.newPage({ viewport: { width, height: 900 }, reducedMotion: 'reduce' });
    page.on('pageerror', error => errors.push(String(error)));
    let mapRequests = 0;
    page.on('request', request => { if (request.url().endsWith('/assets/code-module-map.json')) mapRequests++; });
    await page.goto(`${origin}/access/developer/`);
    const consoleUI = page.locator('[data-sfh-owner-decision-console]');
    await consoleUI.waitFor();
    await page.evaluate(() => document.fonts.ready);
    assert.equal(await consoleUI.getByRole('tab', { selected: true }).innerText(), '작업 개요');
    assert.equal(await page.locator('.sfh-developer-fold[open]').count(), 0);
    assert.equal(mapRequests, 0, 'Closed code map must not fetch');
    const titleMargin = await consoleUI.locator('h2').evaluate(node => parseFloat(getComputedStyle(node).marginTop));
    assert.ok(titleMargin < 16, 'Article heading CSS must not inflate the workbench header');
    const checkBounds = async () => {
      const sizes = await page.evaluate(() => ({ width: innerWidth, content: document.documentElement.scrollWidth }));
      assert.ok(sizes.content <= sizes.width + 1, `Overflow at ${width}: ${JSON.stringify(sizes)}`);
    };
    await checkBounds();
    await page.screenshot({ path: `outputs/developer-workspace/overview-${width}.png`, fullPage: true });
    const tabs = consoleUI.getByRole('tab');
    await tabs.first().focus();
    await page.keyboard.press('ArrowRight');
    assert.equal(await consoleUI.getByRole('tab', { selected: true }).innerText(), '판단 대기열');
    await consoleUI.getByRole('combobox', { name: '판단 상태 필터' }).selectOption('blocked');
    await consoleUI.getByRole('tab', { name: '판단 대기열', exact: true }).focus();
    await page.keyboard.press('End');
    assert.equal(await consoleUI.getByRole('tab', { selected: true }).innerText(), '행동·관측');
    await checkBounds();
    await consoleUI.getByRole('tab', { name: '판단 대기열', exact: true }).click();
    assert.equal(await consoleUI.getByRole('combobox', { name: '판단 상태 필터' }).inputValue(), 'blocked');
    await consoleUI.getByRole('tab', { name: '객체 탐색', exact: true }).click();
    const cards = consoleUI.locator('[data-object-id]');
    assert.equal(await cards.count(), 6);
    const search = consoleUI.getByRole('searchbox');
    await search.fill('N26');
    await consoleUI.getByRole('combobox', { name: '객체 유형 필터' }).selectOption('work_item');
    await cards.first().click();
    if (width <= 768) assert.equal(await page.evaluate(() => document.activeElement.className), 'sfh-owner-console__detail');
    assert.equal(await search.inputValue(), 'n26');
    const selected = new URL(page.url()).searchParams.get('decision');
    await consoleUI.getByRole('tab', { name: '관계·계보', exact: true }).click();
    assert.equal(await consoleUI.getByRole('combobox').inputValue(), selected);
    await checkBounds();
    await consoleUI.getByRole('tab', { name: '객체 탐색', exact: true }).click();
    assert.equal(await search.inputValue(), 'n26');
    assert.equal(await consoleUI.getByRole('combobox').inputValue(), 'work_item');
    await checkBounds();
    await page.screenshot({ path: `outputs/developer-workspace/inspector-${width}.png`, fullPage: true });
    await search.fill('no_such_sfh_object_xyz');
    assert.equal(await cards.count(), 0);
    assert.equal(await consoleUI.locator('.sfh-owner-console__detail').count(), 0, 'No stale inspector on empty search');
    await search.fill('');
    await consoleUI.getByRole('combobox').selectOption('all');
    const expected = await page.evaluate(async () => (await (await fetch('../../assets/project-ontology.json')).json()).objects.length);
    const seen = new Set();
    for (;;) {
      for (const id of await cards.evaluateAll(nodes => nodes.map(node => node.dataset.objectId))) seen.add(id);
      const next = consoleUI.getByRole('button', { name: '다음 →', exact: true });
      if (await next.isDisabled()) break;
      await next.click();
    }
    assert.equal(seen.size, expected, 'Every registered object is reachable, not only the first 120');
    const mapLoaded = page.waitForResponse(response => response.url().endsWith('/assets/code-module-map.json'));
    await page.locator('[data-sfh-lazy-code] > summary').click();
    await page.waitForFunction(() => !!document.querySelector('[data-sfh-code-module-map-host] > *'));
    await mapLoaded;
    assert.equal(mapRequests, 1);
    await checkBounds();
    await page.close();
    console.log(`DEVELOPER_WORKSPACE_OK width=${width} objects=${expected} tabs keyboard filters pagination lazy_map`);
  }
  const deep = await browser.newPage();
  await deep.goto(`${origin}/access/developer/?view=objects&decision=work:n26-08`);
  await deep.locator('.sfh-owner-console__detail').waitFor();
  assert.equal(await deep.locator('[data-object-id="work:n26-08"][aria-pressed=true]').count(), 1);
  assert.equal(await deep.locator('[role=tab][aria-selected=true]').innerText(), '객체 탐색');
  await deep.reload();
  await deep.locator('.sfh-owner-console__detail').waitFor();
  assert.equal(await deep.locator('[data-sfh-owner-decision-console]').count(), 1);
  await deep.close();
  for (const width of widths) {
    const page = await browser.newPage({ viewport: { width, height: 900 }, reducedMotion: 'reduce' });
    for (const path of ['features/', 'features/combat/', 'features/loot/', 'features/growth/', 'architecture/']) {
      await page.goto(`${origin}/${path}`);
      await page.locator('[data-sfh-stage-count]').waitFor();
      assert.ok(await page.locator('.sfh-article-children a').count() > 0);
      assert.equal(await page.locator('.sfh-implementation-guide details[open]').count(), 0);
      await page.locator('.sfh-implementation-guide summary').click();
      assert.ok(await page.locator('.sfh-stage-remaining li').count() > 0);
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1), `${path} overflow at ${width}`);
      await page.locator('.sfh-implementation-guide summary').click();
      if (path === 'features/') await page.screenshot({ path: `outputs/developer-workspace/article-home-${width}.png`, fullPage: true });
    }
    await page.close();
  }
  for (const role of ['planner', 'developer']) {
    const page = await browser.newPage();
    await page.route('**/api/auth/session', route => route.fulfill({ json: { authenticated: true, role, username: role, must_change: false } }));
    await page.goto(`${origin}/access/login/?return=%2Ffeatures%2F`);
    await page.waitForURL(`${origin}/features/`);
    const otherRole = role === 'planner' ? 'developer' : 'planner';
    await page.goto(`${origin}/access/login/?return=${encodeURIComponent('/access/' + otherRole + '/')}`);
    await page.waitForURL(`${origin}/access/${role}/`);
    await page.goto(`${origin}/access/login/?return=${encodeURIComponent('/\\example.com/')}`);
    await page.waitForURL(`${origin}/access/${role}/`);
    await page.goto(`${origin}/access/login/?return=${encodeURIComponent('/access/login/')}`);
    await page.waitForURL(`${origin}/access/${role}/`);
    await page.close();
  }
  console.log('ARTICLE_FLOW_OK 4 widths x 5 topic pages; authenticated return to root for both roles');
  assert.deepEqual(errors, []);
} finally { await browser.close(); }
