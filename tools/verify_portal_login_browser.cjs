// Native browser navigation against the synthetic preview. This does not
// reproduce ESP32 TLS memory limits, RF behavior or on-device password hashing.
const assert = require('node:assert/strict');
const { once } = require('node:events');
const bounded = promise => {
  let timer;
  return Promise.race([promise, new Promise((_, reject) => { timer = setTimeout(() => reject(Error('Browser test gate timed out')), 8000); })]).finally(() => clearTimeout(timer));
};
const { chromium } = require(process.env.MANUAL_PLAYWRIGHT || 'C:/Users/marce/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');

(async () => {
  const { createPreviewServer } = await import('./preview_portal.mjs');
  const server = createPreviewServer();
  server.listen(0, '127.0.0.1'); await once(server, 'listening');
  const origin = `http://127.0.0.1:${server.address().port}`;
  const browser = await chromium.launch({ headless: true, channel: 'msedge' });
  try {
    for (const language of ['de', 'en']) {
      const page = await browser.newPage();
      page.setDefaultTimeout(8000);page.setDefaultNavigationTimeout(8000);
      const failures = [], logins = [];
      page.on('pageerror', error => failures.push(error.message));
      page.on('request', request => {
        if (request.method() === 'POST' && new URL(request.url()).pathname === '/login') logins.push(request);
      });
      await page.goto(origin + '/__preview/login');
      await page.locator('#language-select').selectOption(language);
      await page.locator('[name=user]').fill('demo');
      await page.locator('[name=password]').fill('demo-passwort');
      const submitEvents = []; let reportComplete;
      const reported = new Promise(resolve => { reportComplete = resolve; });
      await page.exposeFunction('reportLoginSubmit', state => {
        submitEvents.push(state); if (submitEvents.length === 2) reportComplete();
      });
      await page.evaluate(() => {
        let duplicateInjected = false;
        document.addEventListener('submit', event => {
          window.reportLoginSubmit({ prevented: event.defaultPrevented, disabled: document.getElementById('login-submit').disabled });
          if (!event.defaultPrevented && !duplicateInjected) {
            duplicateInjected = true;
            // Inject a duplicate event while the real native login is starting.
            // requestSubmit itself suppresses synchronous reentrant calls.
            event.target.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
          }
        });
      });
      let releaseResponse;
      const responseGate = new Promise(resolve => { releaseResponse = resolve; });
      await page.route(origin + '/login', async route => {
        if (route.request().method() === 'POST') await bounded(responseGate);
        await route.continue();
      });
      const submitted = page.waitForRequest(request => request.method() === 'POST' && request.url() === origin + '/login');
      await page.locator('#login-submit').click({ noWaitAfter: true }); await submitted; await bounded(reported);
      assert.deepEqual(submitEvents, [{ prevented: false, disabled: true }, { prevented: true, disabled: true }]);
      assert.equal(logins.length, 1);
      releaseResponse();
      await page.waitForURL(origin + '/'); await page.waitForLoadState('domcontentloaded');
      assert.equal(logins.length, 1, 'Successful redirect does not replay credentials');
      await page.reload();
      assert.equal(logins.length, 1, 'Reload after POST/303 uses GET');
      await page.goBack({ waitUntil: 'domcontentloaded' });
      assert.equal(await page.locator('#login-submit').isEnabled(), true);
      assert.equal(await page.locator('#login-submit').textContent(), language === 'de' ? ' Anmelden' : ' Sign in');
      // Force the persisted-page event as well: whether a real Back uses BFCache
      // depends on the browser's current no-store caching policy.
      const restored = await page.evaluate(() => {
        const form = document.querySelector('form'), button = document.getElementById('login-submit');
        form.dispatchEvent(new Event('submit', { cancelable: true }));
        window.dispatchEvent(new PageTransitionEvent('pageshow', { persisted: true }));
        return { disabled: button.disabled, pending: form.dataset.submitting, busy: button.dataset.busyKey };
      });
      assert.deepEqual(restored, { disabled: false, pending: undefined, busy: undefined });
      assert.equal(logins.length, 1, 'Page restoration sends no login request');
      await page.goto(origin + '/login');
      assert.equal(page.url(), origin + '/', 'Canonical GET /login redirects to the portal');
      assert.deepEqual(failures, []);
      await page.close();
    }
    // A dropped POST commits Edge's error document. No code retries it. Explicit
    // browser Reload may resubmit the native POST; that choice belongs to the
    // browser. Explicitly reopening /login uses GET and never resubmits it.
    const page = await browser.newPage();page.setDefaultTimeout(8000);page.setDefaultNavigationTimeout(8000); let posts = 0;
    await page.route(origin + '/login', async route => {
      if (route.request().method() === 'POST') { posts++;if(posts===1)await route.abort('connectionfailed');else await route.continue(); }
      else await route.continue();
    });
    await page.goto(origin + '/__preview/login');
    await page.locator('[name=user]').fill('demo'); await page.locator('[name=password]').fill('demo-passwort');
    const failure = page.waitForEvent('requestfailed', request => request.method() === 'POST');
    await page.locator('#login-submit').click({noWaitAfter:true}); await failure;
    await page.waitForURL('chrome-error://chromewebdata/');
    assert.equal(posts, 1, 'The UI does not automatically retry after failure');
    await page.reload({ waitUntil: 'domcontentloaded' });
    assert.equal(page.url(), origin + '/');
    assert.equal(posts, 2, 'Explicit Edge Reload resubmits the failed native POST once');
    posts = 0;
    await page.goto(origin + '/__preview/login');
    await page.locator('[name=user]').fill('demo'); await page.locator('[name=password]').fill('demo-passwort');
    const secondFailure = page.waitForEvent('requestfailed', request => request.method() === 'POST');
    await page.locator('#login-submit').click({ noWaitAfter: true }); await secondFailure;
    await page.waitForURL('chrome-error://chromewebdata/');
    assert.equal(posts, 1, 'The UI does not retry a failed native login automatically');
    await page.goto(origin + '/login');
    assert.equal(page.url(), origin + '/');assert.equal(posts, 1, 'Explicit GET /login recovery does not replay credentials');
    await page.close();
    console.log('PASS: native login POST/303/GET, slow response duplicate guard, reload without POST replay, Back and persisted pageshow reset, canonical GET /login, browser-controlled failed-POST reload and explicit GET recovery in English/German Edge preview. ESP32 TLS/RF behavior remains a physical test.');
  } finally {
    await browser.close(); server.closeAllConnections(); await new Promise(resolve => server.close(resolve));
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
