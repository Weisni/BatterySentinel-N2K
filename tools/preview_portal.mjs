import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Serve the actual firmware HTML with a local, synthetic backend. No packages,
// hardware, firmware build, device credentials or generated HTML are required.
const root = fileURLToPath(new URL('../', import.meta.url));
const scenarios = new Set(['live', 'orion-errors', 'nmea-errors', 'stale', 'offline', 'expired', 'firmware-invalid', 'firmware-offline', 'firmware-unavailable', 'boot-held', 'low-voltage', 'network-time']);
const pages = { '/': 'kDashboardBody', '/__preview/login': 'kLoginBody', '/recover': 'kRecoveryBody', '/first-setup': 'kFirstSetupBody', '/message': 'kMessageBody', '/restart': 'kRestartBody' };
const escape = value => String(value).replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]);

function normalizeAlias(value) {
  if (value === null) return null;
  // Match the firmware's UTF-8/codepoint validation without broad Unicode
  // whitespace trimming or case folding that could merge distinct names.
  const normalized = value.replace(/^[\x09-\x0d ]+|[\x09-\x0d ]+$/g, '');
  const length = [...normalized].length;
  return length >= 1 && length <= 32 && !/[\x00-\x1f\x7f-\x9f\u2028\u2029]/.test(normalized) ? normalized : null;
}

const aliasIdentity = value => value.replace(/[A-ZÄÖÜẞ]/g, char => char.toLowerCase());

function toolbar(scenario) {
  const choices = { live: 'Normalbetrieb', 'orion-errors': 'Orion-Fehler', 'nmea-errors': 'NMEA-Fehler', stale: 'Orion-Daten veraltet', offline: 'API nicht erreichbar', expired: 'Sitzung abgelaufen', 'firmware-invalid': 'OTA: Datei abgelehnt', 'firmware-offline': 'OTA: Verbindung unterbrochen', 'firmware-unavailable': 'OTA: USB erforderlich', 'boot-held': 'BOOT gedrückt (Simulation)', 'low-voltage': 'Spannungswarnung (Simulation)', 'network-time': 'Netzwerkzeit (Simulation)' };
  return `<aside id="preview-tools" aria-label="Debug-Vorschau" style="position:relative;z-index:3;padding:14px 20px;background:#25301c;border-bottom:2px solid #b4dc76;color:#f1f7e7;font:14px/1.6 system-ui;display:flex;gap:12px;align-items:center;flex-wrap:wrap">
<strong>DEBUG · Simulierte Daten</strong>
<label for="preview-scenario">Szenario <select id="preview-scenario" style="font:inherit;padding:6px;background:#11202b;color:white">${Object.entries(choices).map(([value, label]) => `<option value="${value}"${value === scenario ? ' selected' : ''}>${label}</option>`).join('')}</select></label>
<nav style="display:flex;gap:12px;flex-wrap:wrap"><a href="/">Dashboard</a><a href="/__preview/login">Anmeldung</a><a href="/recover">Passwort vergessen</a><a href="/first-setup">Ersteinrichtung</a><a href="/message">Fehlerseite</a></nav>
<small style="flex-basis:100%;color:#dbeacb">Lokale Vorschau ohne Geräte. Formulare nur mit Testdaten ausfüllen: Benutzer demo, Passwort demo-passwort, Readout-Schlüssel 32 Nullen. Einstellungen bleiben nur bis zum Beenden im Arbeitsspeicher. OTA-Uploads werden nur simuliert; Dateien werden weder gespeichert noch installiert.</small>
<span id="preview-error" role="alert"></span></aside>
<script>document.getElementById('preview-scenario').addEventListener('change',async function(){try{const response=await fetch('/__preview/scenario',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({scenario:this.value})});if(!response.ok)throw Error();location.reload()}catch(_){document.getElementById('preview-error').textContent='Vorschau-Server nicht erreichbar.'}});</script>`;
}

function renderPage(name, state, title = 'Check Orion settings', message = 'Enter a valid MAC, a 32-digit Instant Readout key, and two different NMEA instances.') {
  const source = fs.readFileSync(path.join(root, 'src/BridgePortalUi.h'), 'utf8');
  const templates = Object.fromEntries([...source.matchAll(/inline constexpr char (k\w+)\[\] = R"UI\(([\s\S]*?)\)UI";/g)].map(match => [match[1], match[2]]));
  const extras = ['BridgePortalTranslations.h', 'BridgePortalLanguage.h', 'BridgePortalForm.h', 'BridgePortalOta.h', 'BridgePortalInsights.h'].map(file => {
    const match = fs.readFileSync(path.join(root, 'src', file), 'utf8').match(/R"(I18N|FORM|OTA|INSIGHTS)\(([\s\S]*?)\)\1"/);
    if (!match) throw new Error(`Missing UI asset: ${file}`);
    return match[2];
  }).join('');
  if (!templates[name]) throw new Error(`Missing UI page: ${name}`);
  const values = { BRAND: templates.kBrand, CSRF: 'preview-token', RECOVERY_CSRF: 'preview-recovery-token', CONFIGURED: state.configured ? '1' : '0', MAC: escape(state.mac), OUT_INSTANCE: state.output, IN_INSTANCE: state.input, OUT_ALIAS: escape(state.outputAlias), IN_ALIAS: escape(state.inputAlias), MESSAGE_TITLE: escape(title), MESSAGE_TEXT: escape(message) };
  const body = templates[name].replace(/\{\{(\w+)\}\}/g, (_, key) => {
    if (!(key in values)) throw new Error(`Unknown template field: ${key}`);
    return values[key];
  });
  return templates.kDocumentStart + toolbar(state.scenario) + extras + body + '<script>bridgeI18n.apply();</script></body></html>';
}

function liveData(state, after) {
  const elapsed = Date.now() - state.started;
  const seconds = Math.floor(elapsed / 1000);
  const stale = state.scenario === 'stale';
  const orionSeconds = stale ? Math.floor((state.changed - state.started) / 1000) : seconds;
  const received = state.configured;
  const fresh = received && !stale;
  const orionError = received && state.scenario === 'orion-errors';
  const nmeaError = received && state.scenario === 'nmea-errors';
  const outV = state.scenario === 'low-voltage' ? 11.8 : Number((13.77 + Math.sin(seconds / 8) * 0.1).toFixed(2));
  const outI = Number((5.1 + Math.sin(seconds / 6) * 0.3).toFixed(1));
  const inV = 14.21, inI = 5.5;
  const value = number => fresh ? number : null;
  const sid = seconds % 253;
  const record = (pgn, instance, fields, age = 150) => ({ pgn, instance, age: received ? age : null, accepted: received ? !nmeaError : null, fields: received ? fields : Object.fromEntries(Object.keys(fields).map(key => [key, null])) });
  const metadata = dcType => ({ sid, dcType, soc: null, soh: null, timeRemaining: null, rippleVoltage: null, capacity: null });
  // These fixtures follow the firmware's schema and resolutions; they are not
  // a decoder, bus emulator, throughput benchmark or proof of wire delivery.
  const nmea = [
    record(127508, state.output, { sid, voltage: value(outV), current: value(outI), temperature: null }),
    record(127508, state.input, { sid: (sid + 1) % 253, voltage: value(inV), current: value(inI), temperature: null }),
    record(127507, state.output, { batteryInstance: state.output, chargeState: 1, chargerMode: 0, enabled: 1, equalizationPending: null, equalizationTimeRemaining: null }, stale ? 12000 + Date.now() - state.changed : 150),
    record(127506, state.output, metadata(0), elapsed % 5000),
    record(127506, state.input, metadata(2), elapsed % 5000),
  ];
  const rejected = orionError ? 4 : 0, dropped = orionError ? 2 : 0;
  const knownTime = state.scenario === 'network-time';
  const channel = (voltage, current) => ({
    minV: received ? voltage - .15 : null, maxV: received ? voltage + .12 : null,
    trendVPerMin: received ? -.012 : null, trendSpanMs: 120000,
    ah: received ? .84 : 0, wh: received ? 11.4 : 0, coveredMs: received ? 690000 : 0,
    transferCoveredMs: received ? 675000 : 0, belowLowMs: voltage < 12 ? 30000 : 0,
    coveragePct: received ? 94 : 0, fresh,
    history: received ? Array.from({length:48}, (_, i) => ({ms:i*15000, v:i===20||i===21?null:Number((voltage + .12*Math.sin(i/7)).toFixed(2))})) : [],
  });
  const active = state.scenario === 'low-voltage' && state.notificationConfig.enabled && state.notificationConfig.output.lowEnabled;
  const time = {quality:knownTime?'synchronized':'unknown',utcMs:knownTime?Date.now():null,anchorUtcMs:knownTime?state.started:null,anchorMonotonicMs:knownTime?0:null,monotonicMs:elapsed,sourceName:knownTime?'preview-clock':null,sourceAddress:knownTime?42:null,sourcePgn:knownTime?129029:null,ageMs:knownTime?150:null,rejected:0};
  return {
    outV: value(outV), outI: value(outI), inV: value(inV), inI: value(inI), outW: value(Number((outV * outI).toFixed(3))), inW: value(Number((inV * inI).toFixed(3))),
    state: value(3), error: value(0), offReason: value(0), rssi: value(-53), received, fresh,
    age: received ? stale ? 12000 + Date.now() - state.changed : 220 : null,
    counter: received ? orionSeconds % 65536 : null,
    status: !received ? 'Unconfigured' : stale ? 'Stale' : orionError ? 'Encryption key mismatch' : 'Receiving',
    rx: received ? 145 + orionSeconds : 0, duplicates: received ? 11 + Math.floor(orionSeconds / 3) : 0,
    rejected, dropped, orionStartupFailed: 0, orionErrors: rejected + dropped,
    tx: received ? 398 + seconds * (nmeaError ? 0 : 3) : 0, txFailed: nmeaError ? 7 : 0, nmeaErrors: nmeaError ? 7 : 0,
    nmea, time, bootId:1, insights:{sinceMs:0,nowMs:elapsed,maxGapMs:5000,input:channel(inV,inI),output:channel(outV,outI)},
    notifications:{config:state.notificationConfig,nmeaStatus:'unavailable',alerts:[{id:1,kind:'outputLow',enabled:state.notificationConfig.output.lowEnabled,active,acknowledged:state.acknowledgedGeneration===state.alertGeneration,known:fresh,pending:false,generation:state.alertGeneration,value:outV,activatedAtMs:0,changedAtMs:0}]},
    events: state.events.filter(event => event.seq > after).map(event=>({...event,utcMs:knownTime?state.started+event.ms:null,timeQuality:time.quality})),
  };
}

export function createPreviewServer() {
  const bank = () => ({lowEnabled:true,highEnabled:false,lowV:12,lowClearV:12.3,highV:15,highClearV:14.7,delayS:10,clearS:30});
  const notificationConfig = {enabled:false,nmeaEnabled:false,dataLossEnabled:true,chargerErrorEnabled:true,dataLossDelayS:30,repeatMinutes:0,input:bank(),output:bank()};
  const state = { scenario: 'live', configured: true, firmwareVersion: 'preview-1.0', mac: 'aa:bb:cc:dd:ee:ff', output: 0, input: 1, inputAlias: 'Startbatterie', outputAlias: 'Bugbatterie', started: Date.now(), changed: Date.now(), sequence: 0, lastSample: -1, events: [], notificationConfig,alertGeneration:1,acknowledgedGeneration:0 };
  const event = (type, detail) => {
    state.events.push({ seq: ++state.sequence, ms: Date.now() - state.started, type, detail });
    state.events = state.events.slice(-64);
  };
  event('PREVIEW', 'Simulated Orion data; no hardware connected');
  return http.createServer(async (request, response) => {
    const url = new URL(request.url, 'http://127.0.0.1');
    const send = (status, data, type = 'text/html; charset=utf-8') => {
      response.writeHead(status, { 'Content-Type': type, 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
      response.end(data);
    };
    const page = (name, status = 200, title, message) => send(status, renderPage(name, state, title, message));
    const redirect = location => { response.writeHead(303, { Location: location, 'Cache-Control': 'no-store' }); response.end(); };
    try {
      if (request.method === 'GET') {
        // Match firmware canonical navigation; the debug route forces a login page.
        if (url.pathname === '/login') return redirect('/');
        if (url.pathname in pages) return page(pages[url.pathname]);
        if (url.pathname === '/favicon.ico') return send(204, '', 'image/x-icon');
        if (url.pathname === '/api/firmware') {
          if (state.scenario === 'expired') return send(401, JSON.stringify({ ok: false, error: 'auth' }), 'application/json');
          if (state.scenario === 'offline') return send(503, '{}', 'application/json');
          return send(200, JSON.stringify({ target: 'orion-dongle', version: state.firmwareVersion, maxSize: 1966080, available: state.scenario !== 'firmware-unavailable' }), 'application/json');
        }
        if (url.pathname === '/api/live' || url.pathname === '/api/events') {
          if (state.scenario === 'offline') return send(503, 'Preview offline scenario', 'text/plain');
          if (state.scenario === 'expired') return send(401, 'Login required', 'text/plain');
          const sample = Math.floor((Date.now() - state.started) / 3000);
          if (sample !== state.lastSample && state.configured) {
            state.lastSample = sample;
            const sampleData = liveData(state, Infinity);
            event('BLE', state.scenario === 'stale' ? 'Orion data stale' : state.scenario === 'orion-errors' ? 'Encryption key mismatch' : `Orion state 3, output ${sampleData.outV.toFixed(3)} V ${sampleData.outI.toFixed(3)} A`);
            event('NMEA', state.scenario === 'nmea-errors' ? 'PGN 127508 x2, 127507; accepted 0, failed 3' : state.scenario === 'stale' ? 'PGN 127508 x2; accepted 2, failed 0; values unavailable' : 'PGN 127508 x2, 127507; accepted 3, failed 0');
          }
          const after = Math.max(0, Number(url.searchParams.get('after')) || 0);
          const data = liveData(state, after);
          return send(200, JSON.stringify(url.pathname === '/api/events' ? { events: data.events, time: data.time, bootId: data.bootId } : data), 'application/json');
        }
        return send(404, 'Preview route not found', 'text/plain');
      }
      if (request.method !== 'POST') return send(405, 'Method not allowed', 'text/plain');
      if (url.pathname === '/api/firmware') {
        const fail = (status, error) => send(status, JSON.stringify({ ok: false, error }), 'application/json');
        if (state.scenario === 'expired') return fail(401, 'auth');
        if (request.headers['x-csrf-token'] !== 'preview-token') return fail(403, 'csrf');
        if (request.headers['content-type'] !== 'application/octet-stream') return fail(415, 'content_type');
        if (state.scenario === 'firmware-unavailable') return fail(400, 'partition');
        let size = 0, magic;
        for await (const chunk of request) {
          if (magic === undefined && chunk.length) magic = chunk[0];
          size += chunk.length;
          if (size > 1966080) return fail(413, 'size');
        }
        if (!size) return fail(400, 'size');
        if (state.scenario === 'firmware-offline') { response.destroy(); return; }
        if (state.scenario === 'firmware-invalid') return fail(400, 'checksum');
        if (magic !== 0xe9) return fail(400, 'image');
        // Deliberately synthetic: never store, flash or claim to validate an image.
        await new Promise(resolve => setTimeout(resolve, 750));
        state.firmwareVersion = 'preview-updated';
        event('PREVIEW', 'Simulated firmware update; no image installed');
        return send(200, JSON.stringify({ ok: true, rebooting: true }), 'application/json');
      }
      let body = '';
      for await (const chunk of request) {
        body += chunk;
        if (body.length > 4096) return send(413, 'Form too large', 'text/plain');
      }
      const form = new URLSearchParams(body);
      if (url.pathname === '/__preview/scenario') {
        if (!scenarios.has(form.get('scenario'))) return send(400, 'Unknown scenario', 'text/plain');
        state.scenario = form.get('scenario');
        if(state.scenario==='low-voltage'){state.notificationConfig.enabled=true;state.alertGeneration++}
        state.changed = Date.now();
        state.lastSample = -1;
        event('PREVIEW', `Scenario: ${state.scenario}`);
        return send(200, '{}', 'application/json');
      }
      if (url.pathname === '/login' || url.pathname === '/setup') {
        // This demonstrates the navigation only. Never retain credentials.
        state.scenario = 'live';
        return redirect('/');
      }
      if (url.pathname === '/logout') return redirect('/login');
      if (url.pathname === '/notifications' || url.pathname === '/notifications/ack') {
        if(state.scenario==='expired')return send(401,'Login required','text/plain');
        if(form.get('csrf')!=='preview-token')return page('kMessageBody',403,'Session expired','Reload the portal and try your change again.');
        if(url.pathname.endsWith('/ack')){
          if(form.get('id')!=='1'||Number(form.get('generation'))!==state.alertGeneration)return send(409,'Notification changed; reload.','text/plain');
          state.acknowledgedGeneration=state.alertGeneration;event('ALERT','Notification acknowledged');return redirect('/#notifications');
        }
        const flag=name=>form.get(name)==='1',read=(name,min,max)=>{const raw=form.get(name);const v=Number(raw);const voltage=name.endsWith('_v');if(raw===null||!(voltage?/^\d{1,2}(?:\.\d{1,2})?$/:/^\d+$/).test(raw)||!Number.isFinite(v)||v<min||v>max)throw Error('Invalid notification value');return v};
        try{
          const config={enabled:flag('enabled'),nmeaEnabled:flag('nmea_enabled'),dataLossEnabled:flag('data_loss_enabled'),chargerErrorEnabled:flag('charger_error_enabled'),dataLossDelayS:read('data_loss_delay_s',10,3600),repeatMinutes:read('repeat_minutes',0,1440)};
          for(const side of ['input','output']){
            const b={lowEnabled:flag(side+'_low_enabled'),highEnabled:flag(side+'_high_enabled'),lowV:read(side+'_low_v',4,65),lowClearV:read(side+'_low_clear_v',4,65),highV:read(side+'_high_v',4,65),highClearV:read(side+'_high_clear_v',4,65),delayS:read(side+'_delay_s',1,600),clearS:read(side+'_clear_s',1,600)};
            if(b.lowClearV<=b.lowV||b.highClearV>=b.highV||b.lowClearV>=b.highClearV)throw Error('Invalid hysteresis');config[side]=b;
          }
          state.notificationConfig=config;event('CONFIG','Notification settings saved');return redirect('/#notifications');
        }catch(_){return send(400,'Invalid notification settings','text/plain')}
      }
      if (url.pathname === '/password') {
        // Exercise validation/navigation with the public preview dummy password.
        // Submitted credentials are never persisted, echoed or logged.
        if (state.scenario === 'expired') return redirect('/login');
        if (form.get('csrf') !== 'preview-token') return page('kMessageBody', 403, 'Session expired', 'Reload the portal and try your change again.');
        const next = form.get('new_password') || '';
        if (Buffer.byteLength(next, 'utf8') < 12 || Buffer.byteLength(next, 'utf8') > 128 || next !== form.get('confirm_password'))
          return page('kMessageBody', 400, 'Check the new password', 'Use 12–128 UTF-8 bytes for the new password and enter it identically in both fields.');
        if (form.get('current_password') !== 'demo-passwort') return page('kMessageBody', 403, 'Current password incorrect', 'Enter your current administrator password and try again.');
        state.scenario = 'expired';
        event('AUTH', 'Administrator password changed');
        return page('kAccountMessageBody', 200, 'Password changed', 'Sign in with your new password. All saved data and assignments are unchanged.');
      }
      if (url.pathname === '/recover') {
        if (form.get('csrf') !== 'preview-recovery-token' || form.get('confirm_reset') !== 'yes' || state.scenario !== 'boot-held')
          return page('kMessageBody', 403, 'Confirm password recovery', 'Open Forgot password again, confirm the reset, and hold BOOT while submitting.');
        state.scenario = 'expired';
        event('AUTH', 'Administrator password reset with BOOT');
        return page('kAccountMessageBody', 200, 'Password reset', 'Sign in with your existing username and the recovery password printed in the manual. Then change it in Settings.');
      }
      if (url.pathname === '/aliases') {
        // Authentication is synthetic in this preview; retain the firmware's
        // expired-session and CSRF outcomes without storing credentials.
        if (state.scenario === 'expired') return send(401, 'Login required', 'text/plain');
        if (form.get('csrf') !== 'preview-token') return page('kMessageBody', 403, 'Session expired', 'Reload the portal and try your change again.');
        const inputAlias = normalizeAlias(form.get('input_alias'));
        const outputAlias = normalizeAlias(form.get('output_alias'));
        if (inputAlias === null || outputAlias === null || aliasIdentity(inputAlias) === aliasIdentity(outputAlias))
          return page('kMessageBody', 400, 'Check channel names', 'Enter two different names with 1–32 characters and no control characters.');
        Object.assign(state, { inputAlias, outputAlias });
        event('CONFIG', 'Channel names saved');
        return redirect('/');
      }
      if (url.pathname === '/config') {
        const mac = (form.get('mac') || '').trim();
        const output = form.get('out') || '', input = form.get('in') || '';
        const key = form.get('key') || '';
        const keepKey = !key && state.configured && mac.toLowerCase() === state.mac.toLowerCase();
        if (!/^([\da-f]{2}:){5}[\da-f]{2}$/i.test(mac) || (!keepKey && !/^[\da-f]{32}$/i.test(key)) ||
            !/^\d{1,3}$/.test(output) || !/^\d{1,3}$/.test(input) || Number(output) > 252 || Number(input) > 252 || Number(output) === Number(input))
          return page('kMessageBody', 400);
        Object.assign(state, { configured: true, mac: mac.toLowerCase(), output: Number(output), input: Number(input) });
        event('CONFIG', 'Orion identity and key saved');
        return page('kRestartBody');
      }
      if (url.pathname === '/forget') {
        Object.assign(state, { configured: false, mac: '' });
        event('CONFIG', 'Orion identity and key erased');
        return page('kRestartBody');
      }
      return send(404, 'Preview route not found', 'text/plain');
    } catch (error) {
      // Don't log request bodies: users might paste a real key by mistake.
      console.error('Preview error:', error.message);
      if (!response.headersSent) send(500, 'Preview failed; see the terminal.', 'text/plain');
      else response.end();
    }
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const port = args.length === 0 ? 8765 : args.length === 2 && args[0] === '--port' ? Number(args[1]) : NaN;
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    console.error('Usage: node tools/preview_portal.mjs [--port 8765]');
    process.exitCode = 1;
  } else {
    const server = createPreviewServer();
    server.on('error', error => { console.error(error.code === 'EADDRINUSE' ? `Port ${port} is in use. Choose another with --port 8766.` : error.message); process.exitCode = 1; });
    server.listen(port, '127.0.0.1', () => console.log(`Orion portal debug preview: http://127.0.0.1:${port}/\nSynthetic data only. Stop with Ctrl+C. Reload after editing the UI source.`));
  }
}
