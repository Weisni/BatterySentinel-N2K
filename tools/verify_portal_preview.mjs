import assert from 'node:assert/strict';
import { once } from 'node:events';
import { createPreviewServer } from './preview_portal.mjs';

// Exercise the local preview over HTTP, including the real embedded UI templates.
// Dummy credentials must never be echoed into pages, events or API responses.
const dummyKey = '0123456789abcdeffedcba9876543210';
const dummyPassword = 'preview-only-dummy-password-97531';
const server = createPreviewServer();
assert.equal(server.listening, false, 'Importing or constructing the preview must not bind a port');
server.listen(0, '127.0.0.1');
await once(server, 'listening');
const origin = `http://127.0.0.1:${server.address().port}`;

async function request(path, { method = 'GET', form } = {}) {
  const response = await fetch(origin + path, {
    method,
    redirect: 'manual',
    ...(form ? { body: new URLSearchParams(form) } : {})
  });
  const text = await response.text();
  for (const secret of [dummyKey, dummyPassword]) {
    assert.ok(!text.includes(secret), `${method} ${path} must not echo submitted secrets`);
  }
  return { response, text };
}

async function page(path, marker) {
  const result = await request(path);
  assert.equal(result.response.status, 200, path);
  assert.match(result.response.headers.get('content-type'), /^text\/html\b/, path);
  assert.match(result.text, /<!doctype html>/i, path);
  assert.ok(result.text.includes(marker), `${path} must render its actual portal template`);
  assert.ok(result.text.includes('/__preview/scenario'), `${path} must include the preview controls`);
  assert.ok(result.text.includes('bridgeGerman'), `${path} must include the translation catalogue`);
  assert.ok(result.text.includes('bridgeI18n'), `${path} must include language switching`);
  assert.doesNotMatch(result.text, /\{\{[A-Z_]+\}\}/, `${path} must resolve template placeholders`);
  return result.text;
}

async function live(after) {
  const path = '/api/live' + (after === undefined ? '' : `?after=${after}`);
  const { response, text } = await request(path);
  assert.equal(response.status, 200, path);
  assert.match(response.headers.get('content-type'), /^application\/json\b/);
  return JSON.parse(text);
}

async function scenario(name) {
  const { response } = await request('/__preview/scenario', { method: 'POST', form: { scenario: name } });
  assert.ok([200, 303].includes(response.status), `Select scenario ${name}`);
}

const decodeHtml = value => value.replace(/&(amp|lt|gt|quot|#39);/g, (_, entity) => ({ amp: '&', lt: '<', gt: '>', quot: '"', '#39': "'" })[entity]);
let expectedAliases = ['Startbatterie', 'Bugbatterie'];

async function checkAliases() {
  const html = await page('/', 'id="panel-monitor"');
  for (const [direction, expected] of [['input', expectedAliases[0]], ['output', expectedAliases[1]]]) {
    const input = [...html.matchAll(/<input\b[^>]*>/g)].find(match => match[0].includes(`name="${direction}_alias"`));
    assert.ok(input, `${direction} alias input must be present`);
    const value = input[0].match(/\bvalue="([^"]*)"/);
    assert.ok(value, `${direction} alias must have a value`);
    assert.equal(decodeHtml(value[1]), expected, `${direction} alias must survive refresh without double escaping`);
    const label = html.match(new RegExp(`<span\\b[^>]*id="${direction}-alias-label"[^>]*>([^<]*)<\\/span>`));
    assert.ok(label, `${direction} alias must be rendered as text in its channel heading`);
    assert.equal(decodeHtml(label[1]), expected, `${direction} channel label must match its saved alias`);
  }
  return html;
}

async function saveAliases(inputAlias, outputAlias, expected = [inputAlias, outputAlias]) {
  const { response, text } = await request('/aliases', { method: 'POST', form: { csrf: 'preview-token', input_alias: inputAlias, output_alias: outputAlias } });
  assert.equal(response.status, 303, 'Saving names does not require an Orion key');
  assert.equal(response.headers.get('location'), '/', 'Saving names must return directly to the dashboard');
  assert.doesNotMatch(text, /Configuration updated/, 'Alias-only changes must not restart the bridge');
  expectedAliases = expected;
  return checkAliases();
}

function assertLiveSchema(data) {
  for (const field of ['outV', 'outI', 'inV', 'inI', 'outW', 'inW', 'state', 'error', 'offReason', 'rssi', 'age', 'counter']) {
    assert.ok(data[field] === null || Number.isFinite(data[field]), `Telemetry field ${field}`);
  }
  for (const field of ['rx', 'tx', 'rejected', 'dropped', 'duplicates', 'orionStartupFailed', 'orionErrors', 'txFailed', 'nmeaErrors']) {
    assert.ok(Number.isInteger(data[field]) && data[field] >= 0, `Counter ${field}`);
  }
  assert.equal(typeof data.received, 'boolean');
  assert.equal(typeof data.fresh, 'boolean');
  assert.equal(typeof data.status, 'string');
  assert.equal(data.orionErrors, data.rejected + data.dropped + data.orionStartupFailed);
  assert.equal(data.nmeaErrors, data.txFailed);
  assert.equal(data.nmea.length, 5);
  const fields = {
    127508: ['sid', 'voltage', 'current', 'temperature'],
    127507: ['batteryInstance', 'chargeState', 'chargerMode', 'enabled', 'equalizationPending', 'equalizationTimeRemaining'],
    127506: ['sid', 'dcType', 'soc', 'soh', 'timeRemaining', 'rippleVoltage', 'capacity']
  };
  assert.deepEqual(data.nmea.map(record => record.pgn).sort(), [127506, 127506, 127507, 127508, 127508]);
  for (const record of data.nmea) {
    assert.ok(Number.isInteger(record.instance) && record.instance >= 0 && record.instance <= 252);
    assert.ok(record.age === null || (Number.isInteger(record.age) && record.age >= 0));
    assert.ok(record.accepted === null || typeof record.accepted === 'boolean');
    assert.deepEqual(Object.keys(record.fields).sort(), fields[record.pgn].toSorted());
    for (const value of Object.values(record.fields)) assert.ok(value === null || Number.isFinite(value));
  }
  assert.ok(Array.isArray(data.events));
  let previous = -1;
  for (const event of data.events) {
    assert.ok(Number.isInteger(event.seq) && event.seq > previous, 'Event sequences must increase');
    assert.ok(Number.isInteger(event.ms) && event.ms >= 0);
    assert.equal(typeof event.type, 'string');
    assert.equal(typeof event.detail, 'string');
    previous = event.seq;
  }
}

try {
  await page('/', 'id="panel-monitor"');
  await checkAliases();
  await page('/__preview/login', 'action="/login"');
  const loginRedirect = await request('/login');
  assert.equal(loginRedirect.response.status, 303);assert.equal(loginRedirect.response.headers.get('location'), '/');
  await page('/recover', 'action="/recover"');
  await page('/first-setup', 'action="/setup"');
  await page('/message', 'Return to portal');
  await page('/restart', 'Configuration updated');

  await scenario('live');
  const initial = await live();
  assertLiveSchema(initial);
  assert.equal(initial.received, true);
  assert.equal(initial.fresh, true);
  assert.ok(initial.events.length > 0, 'The preview must include sample device events');
  const cursor = initial.events.at(-1).seq;
  const subsequent = await live(cursor);
  assertLiveSchema(subsequent);
  assert.ok(subsequent.events.every(event => event.seq > cursor), 'Cursor polling must not repeat events');

  await scenario('orion-errors');
  const orionErrors = await live();
  assertLiveSchema(orionErrors);
  assert.ok(orionErrors.orionErrors > 0, 'Orion error scenario must exercise its counter');
  assert.equal(orionErrors.nmeaErrors, 0, 'Orion errors must not increase the NMEA counter');
  await scenario('nmea-errors');
  const nmeaErrors = await live();
  assertLiveSchema(nmeaErrors);
  assert.ok(nmeaErrors.nmeaErrors > 0, 'NMEA error scenario must exercise its counter');
  assert.equal(nmeaErrors.orionErrors, 0, 'NMEA errors must not increase the Orion counter');
  assert.ok(nmeaErrors.nmea.some(record => record.accepted === false), 'NMEA scenario must show a failed submission');

  await scenario('stale');
  const stale = await live();
  assertLiveSchema(stale);
  assert.equal(stale.received, true);
  assert.equal(stale.fresh, false);
  for (const key of ['outV', 'outI', 'inV', 'inI', 'outW', 'inW', 'state', 'error', 'offReason', 'rssi']) {
    assert.equal(stale[key], null, `Stale Orion ${key} must be unavailable`);
  }
  assert.ok(stale.age > 10000, 'Stale data must exceed the normal freshness interval');
  for (const [name, status] of [['offline', 503], ['expired', 401]]) {
    await scenario(name);
    assert.equal((await request('/api/live')).response.status, status, name);
    await page('/', 'id="panel-monitor"');
  }
  await scenario('live');
  assert.equal((await request('/api/live')).response.status, 200, 'A new scenario must recover the API');

  await saveAliases(' \tStarter\r\n', '\v\fBow thruster ', ['Starter', 'Bow thruster']);
  const injection = '\"><img src=x onerror=alert(1)>';
  const injectionPage = await saveAliases(injection, "Aft & 'reserve'");
  assert.ok(!injectionPage.includes(injection), 'Names must never produce executable HTML');
  assert.ok(injectionPage.includes('&quot;&gt;&lt;img src=x onerror=alert(1)&gt;'), 'HTML-like names must remain visible as escaped text');
  await saveAliases('🚤'.repeat(32), 'Büg-Batterie');
  await saveAliases('\u00a0Vorn\u00a0', 'Énergie'); // Only outer ASCII whitespace is trimmed.
  await saveAliases('É', 'é'); // Deliberately not part of the firmware's limited case folding.

  const invalidPairs = [
    {}, { input_alias: 'Only input' }, { output_alias: 'Only output' },
    { input_alias: '', output_alias: 'Other' }, { input_alias: ' \t\r\n', output_alias: 'Other' },
    { input_alias: 'X'.repeat(33), output_alias: 'Other' }, { input_alias: '🚤'.repeat(33), output_alias: 'Other' },
    { input_alias: 'Same', output_alias: 'Same' }, { input_alias: ' AFT ', output_alias: 'aft' },
    { input_alias: 'ÄÖÜẞ', output_alias: 'äöüß' },
    ...['\u0000', '\u001f', '\u007f', '\u0085', '\u009f', '\u2028', '\u2029', '\t', '\n'].map(control => ({ input_alias: `A${control}B`, output_alias: 'Other' }))
  ];
  for (const pair of invalidPairs) {
    assert.equal((await request('/aliases', { method: 'POST', form: { csrf: 'preview-token', ...pair } })).response.status, 400, 'Invalid/missing/duplicate names must be rejected');
    await checkAliases();
  }
  for (const csrf of [undefined, 'wrong-token']) {
    assert.equal((await request('/aliases', { method: 'POST', form: { ...(csrf ? { csrf } : {}), input_alias: 'Changed', output_alias: 'Elsewhere' } })).response.status, 403, 'Preview alias saving requires its CSRF token');
    await checkAliases();
  }
  await scenario('expired');
  assert.equal((await request('/aliases', { method: 'POST', form: { csrf: 'preview-token', input_alias: 'Changed', output_alias: 'Elsewhere' } })).response.status, 401);
  await scenario('live');
  await checkAliases();
  await saveAliases('Starter custom', 'Bow custom');

  const config = await request('/config', { method: 'POST', form: { mac: 'AA:BB:01:CD:23:EF', key: dummyKey, out: '0', in: '1' } });
  assert.equal(config.response.status, 200);
  assert.ok(config.text.includes('Configuration updated'), 'Saving preview configuration must render the restart template');
  const configured = await page('/', 'id="panel-monitor"');
  assert.match(configured, /data-configured="1"/);
  assert.match(configured, /id="orion-mac"[^>]*value="aa:bb:01:cd:23:ef"/i);
  const savedKeyTag = configured.match(/<input\b[^>]*id="orion-key"[^>]*>/)[0];
  assert.match(savedKeyTag, /data-key-present="1"/);
  assert.doesNotMatch(savedKeyTag, /\bvalue=/, 'Stored key and mask must never appear as an input value');
  for (const form of [
    { mac: 'AA:BB:01:CD:23:EF', key: '', out: '2', in: '3' },
    { mac: 'aa:bb:01:cd:23:ef', out: '0', in: '1' }
  ]) {
    assert.equal((await request('/config', { method: 'POST', form })).response.status, 200, 'Empty key retains the key for the same Orion');
  }
  for (const form of [
    { mac: 'AA:BB:01:CD:23:EF', key: '****************', out: '0', in: '1' },
    { mac: 'AA:BB:01:CD:23:00', key: '', out: '0', in: '1' }
  ]) {
    assert.equal((await request('/config', { method: 'POST', form })).response.status, 400, 'Masks and changing the Orion without its key must be rejected');
  }
  await checkAliases();
  assertLiveSchema(await live());

  for (const path of ['/login', '/setup']) {
    const { response } = await request(path, { method: 'POST', form: { user: 'preview-admin', password: dummyPassword } });
    assert.equal(response.status, 303, path);
    assert.equal(response.headers.get('location'), '/', path);
  }
  const validPassword = { csrf: 'preview-token', current_password: 'demo-passwort', new_password: dummyPassword, confirm_password: dummyPassword };
  for (const changed of [
    { new_password: 'short', confirm_password: 'short' },
    { new_password: '🚤'.repeat(33), confirm_password: '🚤'.repeat(33) },
    { confirm_password: 'does-not-match' }
  ]) assert.equal((await request('/password', { method: 'POST', form: { ...validPassword, ...changed } })).response.status, 400);
  for (const changed of [{ csrf: 'wrong-token' }, { current_password: 'wrong-password' }])
    assert.equal((await request('/password', { method: 'POST', form: { ...validPassword, ...changed } })).response.status, 403);
  await scenario('expired');
  const expiredChange = await request('/password', { method: 'POST', form: validPassword });
  assert.equal(expiredChange.response.status, 303);assert.equal(expiredChange.response.headers.get('location'), '/login');
  await scenario('live');
  const changedPassword = await request('/password', { method: 'POST', form: validPassword });
  assert.equal(changedPassword.response.status, 200);assert.match(changedPassword.text, /Password changed/);
  assert.match(changedPassword.text, /href="\/"[^>]*><span data-i18n>Sign in<\/span>/);
  assert.equal((await request('/api/live')).response.status, 401, 'Successful password changes expire the preview session');
  await scenario('live');await checkAliases();
  let preserved = await page('/', 'id="password-card"');
  assert.match(preserved, /id="orion-mac"[^>]*value="aa:bb:01:cd:23:ef"/i);
  assert.match(preserved, /id="orion-key"[^>]*data-key-present="1"/);
  const validRecovery = { csrf: 'preview-recovery-token', confirm_reset: 'yes' };
  assert.equal((await request('/recover', { method: 'POST', form: validRecovery })).response.status, 403, 'Recovery requires simulated physical BOOT');
  await scenario('boot-held');
  for (const form of [{ csrf: 'preview-recovery-token' }, { ...validRecovery, csrf: 'preview-token' }, { ...validRecovery, confirm_reset: 'no' }])
    assert.equal((await request('/recover', { method: 'POST', form })).response.status, 403, 'Recovery requires its token and explicit confirmation');
  const recoveryResult = await request('/recover', { method: 'POST', form: validRecovery });
  assert.equal(recoveryResult.response.status, 200);assert.match(recoveryResult.text, /Password reset/);
  assert.match(recoveryResult.text, /existing username and the recovery password printed in the manual/);
  assert.equal((await request('/api/live')).response.status, 401, 'Recovery expires existing preview sessions');
  await scenario('live');await checkAliases();
  preserved = await page('/', 'id="password-card"');
  assert.match(preserved, /id="orion-mac"[^>]*value="aa:bb:01:cd:23:ef"/i);
  assert.match(preserved, /id="orion-key"[^>]*data-key-present="1"/);
  const logout = await request('/logout', { method: 'POST' });
  assert.equal(logout.response.status, 303);
  assert.equal(logout.response.headers.get('location'), '/login');
  // Re-read pages and the event stream after dummy secrets have been submitted.
  for (const path of ['/', '/__preview/login', '/recover', '/first-setup', '/message', '/restart', '/api/live']) {
    assert.equal((await request(path)).response.status, 200, path);
  }

  const observed=await live();
  assert.equal(observed.notifications.config.enabled,false);assert.equal(observed.notifications.config.nmeaEnabled,false);
  assert.equal(observed.notifications.config.repeatMinutes,0);
  for(const side of ['input','output']){
    assert.ok(observed.insights[side].history.some(sample=>sample.v===null),'Preview exposes a visible observation gap');
    assert.ok(observed.insights[side].coveragePct<100);assert.ok(observed.insights[side].transferCoveredMs>0);
  }
  const notificationForm={csrf:'preview-token',repeat_minutes:'0',data_loss_delay_s:'30',data_loss_enabled:'1',charger_error_enabled:'1'};
  for(const side of ['input','output'])Object.assign(notificationForm,{[side+'_low_enabled']:'1',[side+'_low_v']:'12',[side+'_low_clear_v']:'12.3',[side+'_high_v']:'15',[side+'_high_clear_v']:'14.7',[side+'_delay_s']:'10',[side+'_clear_s']:'30'});
  assert.equal((await request('/notifications',{method:'POST',form:{...notificationForm,csrf:'wrong'}})).response.status,403);
  for(const change of [{input_low_v:'12e0'},{output_clear_s:'1.5'},{input_low_clear_v:'11.9'},{output_high_clear_v:'12'},{data_loss_delay_s:'1'},{input_delay_s:'601'}]){
    assert.equal((await request('/notifications',{method:'POST',form:{...notificationForm,...change}})).response.status,400);
    assert.deepEqual((await live()).notifications.config,observed.notifications.config,'Invalid changes do not partially alter settings');
  }
  const savedNotifications=await request('/notifications',{method:'POST',form:{...notificationForm,enabled:'1',input_low_v:'11.8'}});
  assert.equal(savedNotifications.response.status,303);assert.equal(savedNotifications.response.headers.get('location'),'/#notifications');
  assert.equal((await live()).notifications.config.input.lowV,11.8);
  await scenario('low-voltage');const incident=(await live()).notifications.alerts[0];
  assert.equal(incident.active,true);
  assert.equal((await request('/notifications/ack',{method:'POST',form:{csrf:'preview-token',id:'1',generation:String(incident.generation-1)}})).response.status,409);
  assert.equal((await request('/notifications/ack',{method:'POST',form:{csrf:'preview-token',id:'1',generation:String(incident.generation)}})).response.status,303);
  assert.equal((await live()).notifications.alerts[0].acknowledged,true);
  await scenario('network-time');assert.equal((await live()).time.quality,'synchronized');
  assert.ok((await live()).events.every(event=>typeof event.utcMs==='number'));
  await scenario('live');

  const forgotten = await request('/forget', { method: 'POST' });
  assert.ok([200, 303].includes(forgotten.response.status));
  const reset = await page('/', 'id="panel-monitor"');
  assert.match(reset, /data-configured="0"/);
  assert.match(reset, /id="orion-mac"[^>]*value=""/);
  assert.match(reset, /id="orion-key"[^>]*data-key-present="0"/);
  assert.equal((await request('/config', { method: 'POST', form: { mac: 'AA:BB:01:CD:23:EF', key: '', out: '0', in: '1' } })).response.status, 400, 'A forgotten key cannot be retained');
  await checkAliases();
  await saveAliases('Unconfigured input', 'Unconfigured output');

  for (const path of ['/not-a-preview-route', '/README.md', '/src/BridgePortalUi.h', '/.git/config', '/../README.md', '/%2e%2e/%2e%2e/Windows/win.ini']) {
    assert.equal((await request(path)).response.status, 404, `No arbitrary file access: ${path}`);
  }
  console.log('PASS: local preview templates and controls; complete live telemetry; independent error/stale/offline/expired scenarios; event cursor; simulated configuration/authentication/reset; password change and physical recovery validation, session expiry and data preservation; alias defaults/save/refresh/Unicode/escaping/validation/CSRF and preservation; insights/UTC schema, notification persistence/strict bounds/CSRF and incident acknowledgments; no secret echo or arbitrary file serving');
} finally {
  const closed = new Promise((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
  server.closeAllConnections();
  await closed;
}
