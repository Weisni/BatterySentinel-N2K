import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import { once } from 'node:events';
import { createPreviewServer } from './preview_portal.mjs';

const read = name => fs.readFileSync(new URL('../src/' + name, import.meta.url), 'utf8');
const source = read('BridgePortalOta.h');
const script = source.match(/<script>([\s\S]*?)<\/script>/)[1];
const translations = { window: {} };
vm.runInNewContext(read('BridgePortalTranslations.h').match(/<script>([\s\S]*?)<\/script>/)[1], translations);
const catalogue = translations.window.bridgeGerman;
for (const match of script.matchAll(/(?:status\(|uncertain\(|tr\(|[a-z_]+:)'([^']+)'/g)) {
  if (match[1].includes(' ') || match[1].includes('…')) assert.ok(catalogue[match[1]], 'Missing OTA translation: ' + match[1]);
}
const markup = read('BridgePortalUi.h');
assert.match(markup, /type="file" accept="\.bin,application\/octet-stream"/);
assert.match(markup, /id="firmware-status"[^>]*role="status"/);
assert.doesNotMatch(script, /innerHTML|location\.reload|setInterval/);

const flush = () => new Promise(resolve => setImmediate(resolve));
function start({ metadata = { target: 'orion-dongle', version: '1.2.3', maxSize: 2000000, available: true }, status = 200, fail = false, token = 'csrf-token', pause, metadataPause, sendThrows = false } = {}) {
  const ids = {};
  for (const match of markup.matchAll(/\bid="(firmware-[^"]+)"/g)) ids[match[1]] = element(match[1]);
  const outside = element('orion-save'), alreadyDisabled = element('disabled-save'), language = element('language-select');
  alreadyDisabled.disabled = true;
  const card = ids['firmware-card'];
  card.contains = node => node.id.startsWith('firmware-');
  const documentEvents = {}, windowEvents = {}, timers = new Map(), requests = [];
  let nextTimer = 0, fetches = 0, pauses = 0, resumes = 0, lang = 'en';
  const resumeDelays = [];
  class Request {
    constructor() { this.upload = {}; this.headers = {}; requests.push(this); }
    open(method, url) { Object.assign(this, { method, url }); }
    setRequestHeader(name, value) { this.headers[name] = value; }
    send(body) { if (sendThrows) throw Error('network'); this.body = body; }
    abort() { this.aborted = true; this.onabort(); }
    respond(status, body) { this.status = status; this.responseText = typeof body === 'string' ? body : JSON.stringify(body); this.onload(); }
  }
  const context = vm.createContext({
    bridgeI18n: { get language() { return lang; }, t(text, values = {}) { return (lang === 'de' ? catalogue[text] || text : text).replace(/\{(\w+)\}/g, (_, key) => values[key]); } },
    document: {
      hidden: false,
      getElementById: id => ids[id],
      querySelector: () => token === null ? null : { value: token },
      querySelectorAll: () => [...Object.values(ids), outside, alreadyDisabled, language],
      addEventListener: (name, fn) => { documentEvents[name] = fn; },
    },
    addEventListener: (name, fn) => { windowEvents[name] = fn; },
    bridgePauseLive() { pauses++; return (context.bridgeFirmwareLoading ? metadataPause : pause) || Promise.resolve(); },
    bridgeResumeLive(delay = 0) { resumes++; resumeDelays.push(delay); },
    setTimeout(fn, ms) { timers.set(++nextTimer, { fn, ms }); return nextTimer; }, clearTimeout(id) { timers.delete(id); },
    AbortController, XMLHttpRequest: Request,
    FileReader: class { constructor() { throw Error('File selection must not read firmware bytes'); } },
    fetch: async () => { fetches++; if (fail) throw Error('network'); return { status, ok: status === 200, json: async () => metadata }; },
  });
  context.window = context;
  vm.runInContext(script, context); context.bridgeOta.init();
  const el = name => ids['firmware-' + name];
  return { context, el, outside, alreadyDisabled, language, documentEvents, windowEvents, requests, timers,
    fetches: () => fetches, pauses: () => pauses, resumes: () => resumes, resumeDelays,
    openPicker() { el('file').listeners.click(); },
    select(file = { name: 'firmware.bin', size: 1200000 }) { el('file').files = file ? [file] : []; el('file').listeners.change(); return file; },
    install() { return el('install').listeners.click(); },
    setLanguage(value) { lang = value; windowEvents['bridge-language-change'](); },
  };
}
function element(id) {
  return { id, disabled: false, hidden: false, dataset: {}, listeners: {}, value: '', textContent: '', addEventListener(name, fn) { this.listeners[name] = fn; } };
}
function event(target) {
  return { target: { closest: () => target }, prevented: false, stopped: false, preventDefault() { this.prevented = true; }, stopImmediatePropagation() { this.stopped = true; } };
}

// Metadata must wait for a previous live request to settle and reject duplicate
// reads while waiting, so startup/retry never uses two device HTTPS connections.
let releaseMetadata;
let app = start({ metadataPause: new Promise(resolve => { releaseMetadata = resolve; }) });
assert.equal(app.context.bridgeFirmwareLoading, true);
assert.equal(app.fetches(), 0);
await app.el('retry').listeners.click();
assert.equal(app.pauses(), 1, 'Do not enqueue duplicate metadata reads');
releaseMetadata(); await flush();
assert.equal(app.fetches(), 1);
assert.equal(app.context.bridgeFirmwareLoading, false);
assert.equal(app.resumes(), 1);
assert.equal(app.el('version').textContent, '1.2.3');

// The separate OLED jig must be able to select and submit an update. Device-side
// exact target verification remains authoritative after this metadata check.
app = start({ metadata: { target: 'orion-debug-oled', version: '1.2.0-debug.1', maxSize: 0x1e0000, available: true } });
await flush();
assert.equal(app.el('target').textContent, 'orion-debug-oled');
assert.equal(app.el('file').disabled, false);
const debugFile = app.select({ name: 'orion-debug-oled.bin', size: 1900000 });
assert.equal(app.el('install').disabled, false);
await app.install();
assert.equal(app.requests.length, 1);
assert.equal(app.requests[0].body, debugFile);
app.requests[0].respond(400, { ok: false, error: 'target' });
assert.equal(app.context.bridgeOtaBusy, false);
assert.match(app.el('status').textContent, /different product or processor/);
assert.equal(app.requests.length, 1, 'A wrong-target response must not retry');

// Saving credentials owns the HTTPS slot until the browser leaves this page.
// Already selected firmware, metadata retries and native pickers stay inactive.
app = start(); await flush(); app.select();
app.context.bridgeAccountSaving = true;
app.windowEvents['bridge-account-saving']();
assert.equal(app.el('file').disabled, true);
assert.equal(app.el('install').disabled, true);
assert.equal(app.el('retry').disabled, true);
app.setLanguage('de');
assert.equal(app.el('install').disabled, true, 'Language changes retain the account lock');
const accountPauses = app.pauses(), accountFetches = app.fetches();
app.openPicker(); await app.install(); await app.el('retry').listeners.click();
assert.equal(app.pauses(), accountPauses);
assert.equal(app.fetches(), accountFetches);
assert.equal(app.requests.length, 0, 'Password submission cannot overlap OTA');

// Opening the OS file picker drains live polling without awaiting the device.
// Returning renders name/size locally; firmware bytes and upload wait for Install.
app = start(); await flush();
app.openPicker();
assert.equal(app.pauses(), 2);
assert.equal(app.context.bridgeFirmwarePicking, true);
const localFile = { name: 'local.bin', size: 1768128,
  arrayBuffer() { throw Error('Unexpected file read'); },
  stream() { throw Error('Unexpected file stream'); },
};
app.select(localFile);
assert.equal(app.el('install').disabled, false);
assert.match(app.el('selected').textContent, /^local\.bin/);
assert.equal(app.fetches(), 1, 'Selecting a file must not wait for another metadata request');
assert.equal(app.requests.length, 0, 'Selecting a file must not upload it');
assert.equal(app.context.bridgeFirmwarePicking, false);
assert.deepEqual(app.resumeDelays, [0, 500], 'Let the page render before another HTTPS request');
app.openPicker(); app.el('file').listeners.cancel();
assert.equal(app.context.bridgeFirmwarePicking, false);
assert.match(app.el('selected').textContent, /^local\.bin/, 'Cancel preserves the existing selection');
assert.deepEqual(app.resumeDelays, [0, 500, 500]);
app.openPicker(); app.context.document.hidden = true;
app.documentEvents.visibilitychange(); assert.equal(app.timers.size, 0);
app.context.document.hidden = false; app.documentEvents.visibilitychange();
[...app.timers.values()].find(timer => timer.ms === 500).fn();
assert.equal(app.context.bridgeFirmwarePicking, false, 'Visibility return handles pickers without cancel events');
app.openPicker(); app.windowEvents.focus();
[...app.timers.values()].find(timer => timer.ms === 500).fn();
assert.equal(app.context.bridgeFirmwarePicking, false, 'Window focus handles desktop picker cancellation');
app.openPicker(); app.windowEvents.focus(); app.select(localFile);
assert.equal(app.timers.size, 0, 'Change clears the fallback timer');
await app.install();
const resumesBeforeUploadReturn = app.resumes();
app.windowEvents.focus(); app.el('file').listeners.cancel();
assert.equal(app.resumes(), resumesBeforeUploadReturn, 'Picker completion must not resume live polling during an upload');

app = start(); await flush();
assert.equal(app.el('version').textContent, '1.2.3');
assert.equal(app.el('target').textContent, 'orion-dongle');
assert.equal(app.el('install').disabled, true);
for (const candidate of [null, { name: 'firmware.zip', size: 100 }, { name: 'firmware.bin', size: 0 }, { name: 'firmware.bin', size: 2000001 }]) {
  app.select(candidate); assert.equal(app.el('install').disabled, true); await app.install(); assert.equal(app.requests.length, 0);
}
const file = app.select({ name: '<unsafe>.BIN', size: 2000000 });
assert.equal(app.el('install').disabled, false);
assert.ok(app.el('selected').textContent.startsWith('<unsafe>.BIN'));
await app.install();
const request = app.requests[0];
assert.equal(request.body, file, 'Upload the original File without re-encoding it');
assert.equal(request.method, 'POST'); assert.equal(request.url, '/api/firmware');
assert.equal(request.headers['Content-Type'], 'application/octet-stream');
assert.equal(request.headers['X-CSRF-Token'], 'csrf-token'); assert.equal(request.timeout, 180000);
assert.equal(app.pauses(), 2); assert.equal(app.context.bridgeOtaBusy, true);
assert.equal(app.outside.disabled, true); assert.equal(app.language.disabled, false);
await app.install(); assert.equal(app.requests.length, 1, 'No double upload');
for (const type of ['submit', 'click']) {
  const e = event(app.outside); app.documentEvents[type](e); assert.equal(e.prevented, true); assert.equal(e.stopped, true);
}
const languageEvent = event(app.language); app.documentEvents.click(languageEvent); assert.equal(languageEvent.prevented, false);
const leave = event(); app.windowEvents.beforeunload(leave); assert.equal(leave.prevented, true);
request.upload.onprogress({ lengthComputable: true, loaded: 800000, total: 2000000 });
assert.equal(app.el('progress').value, 40);
app.setLanguage('de'); assert.equal(app.el('percent').textContent, '40% übertragen'); assert.equal(app.outside.disabled, true);
assert.equal(app.el('limit').textContent, 'Maximal 1,91 MiB');
request.upload.onload(); assert.equal(app.el('cancel').disabled, true);
app.el('cancel').listeners.click(); assert.equal(request.aborted, undefined, 'Cannot abort while activating');
request.respond(200, { ok: true, rebooting: true });
assert.equal(app.el('progress').value, 100); assert.equal(app.el('reopen').hidden, false);
assert.equal(app.el('install').disabled, true); assert.equal(app.context.bridgeOtaBusy, true); assert.equal(app.resumes(), 1);
assert.match(app.el('status').textContent, /startet neu/);
const success = app.el('status').textContent; request.onerror(); assert.equal(app.el('status').textContent, success);

for (const code of ['auth', 'csrf', 'busy', 'content_type', 'size', 'partition', 'image', 'target', 'checksum', 'hash', 'receive', 'write', 'finalize']) {
  app = start(); await flush(); app.select(); await app.install();
  app.requests[0].respond(400, { ok: false, error: code });
  assert.equal(app.context.bridgeOtaBusy, false, code); assert.equal(app.resumes(), 2, code);
  assert.equal(app.outside.disabled, false, code); assert.equal(app.alreadyDisabled.disabled, true, code);
  assert.equal(app.el('status').dataset.severity, 'error', code);
  assert.equal(app.el('install').disabled, ['auth', 'csrf', 'partition'].includes(code), code);
  assert.equal(app.requests.length, 1, 'No automatic retry for ' + code);
}
for (const outcome of ['network', 'timeout', 'abort', 'activate', 'null', 'malformed', 'unknown', 'unexpected-success', 'send']) {
  app = start({ sendThrows: outcome === 'send' }); await flush(); app.select(); await app.install();
  const request = app.requests[0];
  if (outcome === 'network') request.onerror();
  if (outcome === 'timeout') request.ontimeout();
  if (outcome === 'abort') app.el('cancel').listeners.click();
  if (outcome === 'activate') request.respond(500, { ok: false, error: 'activate' });
  if (outcome === 'null') request.respond(200, 'null');
  if (outcome === 'malformed') request.respond(200, '<html>Sign in</html>');
  if (outcome === 'unknown') request.respond(500, { ok: false, error: 'new-error' });
  if (outcome === 'unexpected-success') request.respond(200, { ok: true });
  assert.equal(app.context.bridgeOtaBusy, true, outcome); assert.equal(app.resumes(), 1, outcome);
  assert.equal(app.el('install').disabled, true, outcome); assert.equal(app.el('reopen').hidden, false, outcome);
  assert.equal(app.el('status').dataset.severity, 'warn', outcome); assert.equal(app.requests.length, 1);
  const leave = event(); app.windowEvents.beforeunload(leave); assert.equal(leave.prevented, false, outcome);
  assert.match(app.el('status').textContent, /version/, outcome);
}
let release;
app = start({ pause: new Promise(resolve => { release = resolve; }) }); await flush(); app.select();
const starting = app.install(); assert.equal(app.requests.length, 0);
app.el('cancel').listeners.click(); release(); await starting;
assert.equal(app.requests.length, 0, 'Cancellation while waiting for live polling must not send a file');
for (const options of [{ status: 401 }, { status: 503 }, { fail: true }, { metadata: { target: 'other', version: '1', maxSize: 123, available: true } }, { metadata: { target: 'orion-r4', version: '1', maxSize: 0, available: false } }, { token: null }]) {
  app = start(options); await flush(); app.select(); await app.install();
  assert.equal(app.requests.length, 0); assert.equal(app.el('install').disabled, true);
}

// Real HTTP preview contract: synthetic success, validation feedback and a lost
// response can be reviewed without a connected product or persistent upload.
const server = createPreviewServer(); server.listen(0, '127.0.0.1'); await once(server, 'listening');
const base = 'http://127.0.0.1:' + server.address().port;
const upload = (body, headers = {}) => fetch(base + '/api/firmware', { method: 'POST', headers: { 'Content-Type': 'application/octet-stream', 'X-CSRF-Token': 'preview-token', ...headers }, body });
const scenario = value => fetch(base + '/__preview/scenario', { method: 'POST', body: new URLSearchParams({ scenario: value }) });
try {
  const metadata = await (await fetch(base + '/api/firmware')).json();
  assert.equal(metadata.available, true); assert.equal(metadata.maxSize, 0x1e0000);
  assert.equal((await (await upload(new Uint8Array([0xe9]), { 'X-CSRF-Token': 'wrong' })).json()).error, 'csrf');
  assert.equal((await (await upload(new Uint8Array([0xe9]), { 'Content-Type': 'text/plain' })).json()).error, 'content_type');
  assert.equal((await (await upload(new Uint8Array())).json()).error, 'size');
  assert.equal((await (await upload(new Uint8Array([1, 2, 3]))).json()).error, 'image');
  const ok = await upload(new Uint8Array([0xe9, 0, 0])); assert.equal(ok.status, 200); assert.equal((await ok.json()).rebooting, true);
  assert.equal((await (await fetch(base + '/api/firmware')).json()).version, 'preview-updated');
  await scenario('firmware-invalid'); assert.equal((await (await upload(new Uint8Array([0xe9]))).json()).error, 'checksum');
  await scenario('firmware-unavailable'); assert.equal((await (await fetch(base + '/api/firmware')).json()).available, false);
  assert.equal((await (await upload(new Uint8Array([0xe9]))).json()).error, 'partition');
  await scenario('expired'); assert.equal((await upload(new Uint8Array([0xe9]))).status, 401);
  await scenario('firmware-offline'); await assert.rejects(upload(new Uint8Array([0xe9])));
} finally { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); }
console.log('PASS: OTA local-file selection without file reads or extra requests, native-picker pause/cancel/return, metadata and size guards, authenticated raw upload, progress, language, mutation locks, cancel, polling coordination, every rejection, uncertain result and no automatic retries; synthetic preview OTA contract');
