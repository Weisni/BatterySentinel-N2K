// Capture the real firmware UI with synthetic data for the German manual.
// Starts an isolated preview unless MANUAL_PREVIEW_URL names an existing one.
const { chromium } = require(process.env.MANUAL_PLAYWRIGHT || 'C:/Users/marce/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs = require('node:fs');
const { once } = require('node:events');
(async () => {
  fs.mkdirSync('docs/manual-assets', { recursive: true });
  let server, origin = process.env.MANUAL_PREVIEW_URL;
  if (!origin) {
    const { createPreviewServer } = await import('./preview_portal.mjs');
    server = createPreviewServer(); server.listen(0, '127.0.0.1'); await once(server, 'listening');
    origin = `http://127.0.0.1:${server.address().port}`;
  }
  const browser = await chromium.launch({ headless: true, channel: 'msedge' });
  try {
  const page = await browser.newPage({ viewport: { width: 1250, height: 1180 }, deviceScaleFactor: 1.5 });
  page.setDefaultTimeout(10000);
  // A continuous synthetic trace within the real five-minute history window.
  await page.route('**/api/live?*', async route => {
    const response = await route.fetch(); const data = await response.json();
    for (const side of ['input', 'output']) data.insights[side].history = data.insights[side].history.filter(p => p.v !== null).map((p,i) => ({ms:i*5000,v:p.v}));
    await route.fulfill({json:data});
  });
  await page.goto(origin + '/');
  await page.locator('#language-select').selectOption('de');
  await page.locator('#preview-tools').evaluate(el => el.remove());
  await page.locator('#panel-overview').waitFor({ state: 'visible' });
  await page.waitForFunction(() => document.getElementById('out-v').textContent !== '—');
  await page.screenshot({ path: 'docs/manual-assets/portal-overview.png', fullPage: true });
  await page.locator('#panel-overview .channel-grid').screenshot({ path: 'docs/manual-assets/portal-channels.png' });
  for (const name of ['setup', 'monitor']) {
    await page.locator(`[data-panel-button="${name}"]`).click();
    await page.locator(`#panel-${name}`).screenshot({ path: `docs/manual-assets/portal-${name}.png` });
    if (name === 'monitor') await page.locator('#panel-monitor .parameter-grid').first().screenshot({ path: 'docs/manual-assets/portal-counters.png' });
  }
  await page.locator('[data-panel-button="insights"]').click();
  await page.locator('#panel-insights .parameter-grid').screenshot({ path: 'docs/manual-assets/portal-insights.png' });
  await page.locator('[data-panel-button="notifications"]').click();
  await page.locator('#notifications-form .parameter-grid').screenshot({ path: 'docs/manual-assets/portal-notification-settings.png' });
  await fetch(origin + '/__preview/scenario', {method:'POST',body:new URLSearchParams({scenario:'low-voltage'})});
  await page.evaluate(() => document.getElementById('refresh').click());
  await page.locator('#notification-alerts button').waitFor();
  await page.locator('#notification-alerts').screenshot({ path: 'docs/manual-assets/portal-active-alert.png' });
  console.log('Captured overview, settings, monitor, insights and notifications with synthetic preview data.');
  } finally {
    await browser.close();
    if (server) {server.closeAllConnections(); await new Promise(resolve => server.close(resolve))}
  }
})().catch(e => { console.error(e); process.exitCode = 1; });
