(() => {
  'use strict';

  // V0.1 browser harness. The UI/state orchestration is intentionally independent from
  // hardware. BatteryCore will be compiled to WebAssembly in the next milestone so the
  // browser and firmware share the exact SOC/alarm implementation.
  const $ = (id) => document.getElementById(id);
  const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
  const nowIso = () => new Date(sim.utcMs).toISOString().replace('T', ' ').replace('Z', 'Z');

  const profiles = {
    flooded: { label: 'Flooded Lead Acid', eta: 0.90, fullV: 14.40, ov: 15.10, selfDischargeMonth: 3.0, ocv: true },
    agm:     { label: 'AGM', eta: 0.93, fullV: 14.40, ov: 15.00, selfDischargeMonth: 2.0, ocv: true },
    gel:     { label: 'GEL', eta: 0.92, fullV: 14.10, ov: 14.60, selfDischargeMonth: 2.0, ocv: true },
    efb:     { label: 'EFB', eta: 0.91, fullV: 14.40, ov: 15.10, selfDischargeMonth: 3.0, ocv: true },
    lifepo4: { label: 'LiFePO4', eta: 0.99, fullV: 14.20, ov: 14.60, selfDischargeMonth: 1.0, ocv: false },
    unknown: { label: 'Unknown', eta: 1.00, fullV: 14.40, ov: 15.00, selfDischargeMonth: 0.0, ocv: false },
  };

  const sim = {
    voltage: 12.60,
    current: 0,
    capacity: 80,
    chemistry: 'flooded',
    ignition: true,
    sensor: true,
    nmea: true,
    externalCharger: false,
    soc: 90,
    socInitialized: true,
    consumedAh: 8,
    confidence: 'ESTIMATED',
    alarms: new Set(),
    offTimeSec: 0,
    utcMs: Date.now(),
    lastTick: performance.now(),
    nextFastPgn: 0,
    nextDcPgn: 0,
    wifiRemaining: 300,
    wifiActive: true,
    history: [],
    alertAcked: false,
    restSeconds: 0,
    fullSeconds: 0,
    timers: { lowV: 0, overV: 0, overI: 0 },
  };

  function log(msg) {
    const el = $('eventLog');
    el.textContent += `[${nowIso()}] ${msg}\n`;
    el.scrollTop = el.scrollHeight;
  }

  function bus(direction, pgn, text) {
    const el = $('busConsole');
    el.textContent += `${nowIso()}  ${direction.padEnd(2)} PGN ${String(pgn).padEnd(6)} ${text}\n`;
    const lines = el.textContent.split('\n');
    if (lines.length > 180) el.textContent = lines.slice(lines.length - 180).join('\n');
    el.scrollTop = el.scrollHeight;
  }

  function ocvSoc(v) {
    const curve = [
      [11.90, 0], [12.00, 20], [12.15, 40], [12.30, 60],
      [12.45, 75], [12.60, 90], [12.75, 100]
    ];
    if (v <= curve[0][0]) return 0;
    if (v >= curve[curve.length - 1][0]) return 100;
    for (let i = 1; i < curve.length; i++) {
      if (v <= curve[i][0]) {
        const [v0, s0] = curve[i - 1];
        const [v1, s1] = curve[i];
        return s0 + ((v - v0) / (v1 - v0)) * (s1 - s0);
      }
    }
    return 50;
  }

  function evaluateAlarms(dt) {
    const p = profiles[sim.chemistry];
    const a = new Set();
    if (!sim.sensor && sim.ignition) a.add('SENSOR_FAULT');

    if (sim.sensor && sim.ignition) {
      const highLoad = sim.current <= -50;
      const lowLimit = highLoad ? 9.50 : 11.60;
      const lowDelay = highLoad ? 0.75 : 10.0;
      sim.timers.lowV = sim.voltage < lowLimit ? sim.timers.lowV + dt : 0;
      sim.timers.overV = sim.voltage > p.ov ? sim.timers.overV + dt : 0;
      sim.timers.overI = Math.abs(sim.current) > 350 ? sim.timers.overI + dt : 0;
      if (sim.timers.lowV >= lowDelay) a.add('LOW_VOLTAGE');
      if (sim.timers.overV >= 2.0) a.add('OVER_VOLTAGE');
      if (sim.timers.overI >= 0.75) a.add('OVER_CURRENT');
    } else {
      sim.timers.lowV = sim.timers.overV = sim.timers.overI = 0;
    }

    if (sim.socInitialized && sim.soc <= 20) a.add('LOW_SOC');
    if (sim.socInitialized && sim.soc <= 10) a.add('CRITICAL_SOC');

    const prev = [...sim.alarms].sort().join(',');
    const next = [...a].sort().join(',');
    if (prev !== next) {
      log(`Alarm state: ${next || 'NONE'}`);
      sim.alertAcked = false;
      if (sim.nmea && sim.ignition && next) bus('TX', 126983, `Alert: ${next}`);
    }
    sim.alarms = a;
  }

  function updateSoc(dt) {
    if (!sim.ignition || !sim.sensor || sim.chemistry === 'unknown' || sim.capacity <= 0) return;
    const p = profiles[sim.chemistry];

    if (sim.socInitialized) {
      let dAh = sim.current * dt / 3600;
      if (dAh > 0) dAh *= p.eta;
      sim.soc = clamp(sim.soc + dAh / sim.capacity * 100, 0, 100);
    }

    const restEligible = Math.abs(sim.current) <= 0.8 && sim.voltage >= 11.5 && sim.voltage <= 12.95;
    sim.restSeconds = restEligible ? sim.restSeconds + dt : 0;
    if (p.ocv && restEligible) {
      if (!sim.socInitialized && sim.restSeconds >= 10) {
        sim.soc = ocvSoc(sim.voltage);
        sim.socInitialized = true;
        sim.confidence = 'ESTIMATED';
        log(`SOC initialized from resting voltage: ${sim.soc.toFixed(1)} %`);
      } else if (sim.socInitialized && sim.restSeconds >= 300) {
        sim.soc = sim.soc * 0.8 + ocvSoc(sim.voltage) * 0.2;
        sim.restSeconds = 0;
        sim.confidence = 'ESTIMATED';
      }
    }

    const tailA = sim.capacity * 0.02;
    const full = sim.current >= 0 && sim.current <= tailA && sim.voltage >= p.fullV;
    sim.fullSeconds = full ? sim.fullSeconds + dt : 0;
    if (sim.fullSeconds >= 300) {
      sim.soc = 100;
      sim.socInitialized = true;
      sim.confidence = 'SYNCED';
      sim.fullSeconds = 0;
      log('Full-charge synchronization -> SOC 100 %');
    }
    sim.consumedAh = sim.capacity * (100 - sim.soc) / 100;
  }

  function publishNmea(t) {
    if (!sim.nmea || !sim.ignition || !sim.sensor) return;
    if (t >= sim.nextFastPgn) {
      sim.nextFastPgn = t + 1500;
      bus('TX', 127508, `Instance=0 V=${sim.voltage.toFixed(2)}V I=${sim.current.toFixed(1)}A`);
    }
    if (t >= sim.nextDcPgn && sim.socInitialized && sim.chemistry !== 'unknown') {
      sim.nextDcPgn = t + 5000;
      bus('TX', 127506, `Instance=0 SOC=${sim.soc.toFixed(1)}% Used=${sim.consumedAh.toFixed(2)}Ah`);
    }
  }

  function tick(t) {
    const realDt = clamp((t - sim.lastTick) / 1000, 0, 0.5);
    sim.lastTick = t;
    if (sim.ignition) {
      sim.utcMs += realDt * 1000;
      if (sim.wifiActive) {
        sim.wifiRemaining = Math.max(0, sim.wifiRemaining - realDt);
        if (sim.wifiRemaining === 0) {
          sim.wifiActive = false;
          log('Diagnostics Wi-Fi timeout -> radio OFF');
        }
      }
      updateSoc(realDt);
      evaluateAlarms(realDt);
      publishNmea(t);
    } else {
      sim.offTimeSec += realDt;
      sim.utcMs += realDt * 1000;
    }
    pushHistory();
    render();
    requestAnimationFrame(tick);
  }

  function pushHistory() {
    const stamp = Math.floor(sim.utcMs / 1000);
    const last = sim.history[sim.history.length - 1];
    if (last && last.t === stamp) return;
    sim.history.push({ t: stamp, v: sim.voltage, i: sim.current, soc: sim.socInitialized ? sim.soc : null });
    if (sim.history.length > 180) sim.history.shift();
  }

  function render() {
    $('voltageOut').textContent = `${sim.voltage.toFixed(2)} V`;
    $('currentOut').textContent = `${sim.current.toFixed(1)} A`;
    $('mVoltage').textContent = sim.sensor && sim.ignition ? `${sim.voltage.toFixed(2)} V` : '--';
    $('mCurrent').textContent = sim.sensor && sim.ignition ? `${sim.current.toFixed(1)} A` : '--';
    $('mSoc').textContent = sim.socInitialized && sim.chemistry !== 'unknown' ? `${sim.soc.toFixed(1)} %` : '-- %';
    $('mAh').textContent = sim.socInitialized && sim.chemistry !== 'unknown' ? `${sim.consumedAh.toFixed(2)} Ah` : '-- Ah';
    $('mConfidence').textContent = sim.chemistry === 'unknown' ? 'UNKNOWN' : sim.confidence;
    $('mOff').textContent = formatDuration(sim.offTimeSec);
    $('sIna').textContent = !sim.ignition ? 'OFF' : (sim.sensor ? 'OK' : 'MISSING');
    $('sNmea').textContent = sim.nmea && sim.ignition ? 'ONLINE' : 'OFFLINE';
    $('sWifi').textContent = sim.wifiActive && sim.ignition ? `ACTIVE (${formatClock(sim.wifiRemaining)})` : 'OFF';
    $('sLogger').textContent = sim.ignition ? 'ACTIVE' : 'STOPPED';
    $('sFram').textContent = sim.ignition ? 'CHECKPOINT OK' : 'LAST STATE SAVED';
    $('simState').textContent = sim.ignition ? 'RUNNING' : 'POWERED OFF';

    $('alarms').innerHTML = sim.alarms.size
      ? [...sim.alarms].map(a => `<span>${a}${sim.alertAcked ? ' · ACK' : ''}</span>`).join('')
      : '<span class="ok">NONE</span>';
    drawChart();
  }

  function formatClock(sec) {
    const s = Math.max(0, Math.ceil(sec));
    return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
  }
  function formatDuration(sec) {
    if (sec >= 86400) return `${(sec / 86400).toFixed(2)} d`;
    if (sec >= 3600) return `${(sec / 3600).toFixed(1)} h`;
    return `${Math.round(sec)} s`;
  }

  function drawChart() {
    const c = $('chart');
    const ctx = c.getContext('2d');
    const w = c.width, h = c.height;
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = '#0d1117'; ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = '#21262d'; ctx.lineWidth = 1;
    for (let y = 30; y < h; y += 40) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke(); }
    const data = sim.history;
    if (data.length < 2) return;
    const x = (idx) => idx / (data.length - 1) * w;
    const plot = (fn, min, max, color) => {
      ctx.strokeStyle = color; ctx.lineWidth = 2; ctx.beginPath();
      let started = false;
      data.forEach((d, idx) => {
        const val = fn(d); if (val == null) return;
        const yy = h - clamp((val - min) / (max - min), 0, 1) * h;
        if (!started) { ctx.moveTo(x(idx), yy); started = true; } else ctx.lineTo(x(idx), yy);
      });
      ctx.stroke();
    };
    plot(d => d.v, 8, 16, '#58a6ff');
    plot(d => d.i, -400, 100, '#f0883e');
    plot(d => d.soc, 0, 100, '#3fb950');
    ctx.fillStyle = '#8b949e'; ctx.font = '12px system-ui';
    ctx.fillText('V', 10, 18); ctx.fillStyle = '#58a6ff'; ctx.fillRect(27, 9, 16, 3);
    ctx.fillStyle = '#8b949e'; ctx.fillText('I', 55, 18); ctx.fillStyle = '#f0883e'; ctx.fillRect(68, 9, 16, 3);
    ctx.fillStyle = '#8b949e'; ctx.fillText('SOC', 96, 18); ctx.fillStyle = '#3fb950'; ctx.fillRect(126, 9, 16, 3);
  }

  function setToggle(id, prop, onText, offText) {
    const el = $(id);
    el.addEventListener('click', () => {
      sim[prop] = !sim[prop];
      el.classList.toggle('on', sim[prop]);
      el.textContent = sim[prop] ? onText : offText;
      if (prop === 'ignition') {
        if (sim.ignition) boot('manual ignition ON');
        else shutdown('manual ignition OFF');
      }
      log(`${prop} -> ${sim[prop] ? onText : offText}`);
    });
  }

  function shutdown(reason) {
    if (!sim.ignition) return;
    sim.ignition = false;
    sim.wifiActive = false;
    sim.confidence = sim.socInitialized ? 'ESTIMATED' : 'UNKNOWN';
    log(`Power loss: ${reason}; simulated FRAM checkpoint saved`);
  }

  function boot(reason) {
    sim.ignition = true;
    sim.wifiActive = true;
    sim.wifiRemaining = 300;
    sim.nextFastPgn = 0; sim.nextDcPgn = 0;
    sim.restSeconds = sim.fullSeconds = 0;
    log(`Boot: ${reason}; diagnostics AP opened for 5 minutes`);
  }

  function jumpOff(days, externalCharge = false) {
    if (sim.ignition) shutdown('scenario');
    const seconds = days * 86400;
    sim.offTimeSec += seconds;
    sim.utcMs += seconds * 1000;
    const p = profiles[sim.chemistry];
    if (sim.socInitialized && !externalCharge) {
      const loss = p.selfDischargeMonth / 30 * days;
      sim.soc = clamp(sim.soc - loss, 0, 100);
      sim.confidence = 'ESTIMATED';
      log(`Off-time jump ${days} d: self-discharge estimate -${loss.toFixed(2)} %`);
    }
    if (externalCharge) {
      sim.soc = 100;
      sim.socInitialized = true;
      sim.confidence = 'WAITING_FOR_REST';
      sim.voltage = 12.80;
      log(`External charger simulated during ${days} d OFF; exact Ah unknown`);
    }
    boot(`restart after ${days} d OFF`);
  }

  const scenario = {
    rest() { sim.sensor = true; sim.voltage = 12.60; sim.current = 0; log('Scenario: resting battery'); syncControls(); },
    starter() {
      sim.sensor = true; sim.voltage = 10.35; sim.current = -225; log('Scenario: Mercury starter pulse -225 A'); syncControls();
      setTimeout(() => { sim.voltage = 12.42; sim.current = -3; log('Starter released -> recovery'); syncControls(); }, 1800);
    },
    charge() {
      sim.sensor = true; sim.voltage = 14.40; sim.current = 12; log('Scenario: charging +12 A'); syncControls();
      setTimeout(() => { sim.current = 1.0; log('Charger entered tail-current phase'); syncControls(); }, 4500);
    },
    lowv() { sim.sensor = true; sim.voltage = 11.20; sim.current = -2; log('Scenario: sustained idle undervoltage'); syncControls(); },
    overv() { sim.sensor = true; sim.voltage = 15.35; sim.current = 1; log('Scenario: overvoltage'); syncControls(); },
    overcurrent() { sim.sensor = true; sim.voltage = 10.8; sim.current = -380; log('Scenario: system overcurrent -380 A'); syncControls(); },
    sensorfail() { sim.sensor = false; log('Scenario: INA238 disconnected'); syncControls(); },
    poweroff() { jumpOff(3, false); syncControls(); },
    externalcharge() { jumpOff(2, true); syncControls(); },
  };

  function syncControls() {
    $('voltage').value = sim.voltage; $('current').value = sim.current;
    $('sensor').classList.toggle('on', sim.sensor); $('sensor').textContent = sim.sensor ? 'CONNECTED' : 'DISCONNECTED';
    $('ignition').classList.toggle('on', sim.ignition); $('ignition').textContent = sim.ignition ? 'ON' : 'OFF';
  }

  $('voltage').addEventListener('input', (e) => sim.voltage = Number(e.target.value));
  $('current').addEventListener('input', (e) => sim.current = Number(e.target.value));
  $('capacity').addEventListener('change', (e) => { sim.capacity = Math.max(1, Number(e.target.value)); log(`Capacity -> ${sim.capacity} Ah`); });
  $('chemistry').addEventListener('change', (e) => {
    sim.chemistry = e.target.value;
    if (sim.chemistry === 'unknown') { sim.socInitialized = false; sim.confidence = 'UNKNOWN'; }
    log(`Battery chemistry -> ${profiles[sim.chemistry].label}`);
  });
  setToggle('ignition', 'ignition', 'ON', 'OFF');
  setToggle('sensor', 'sensor', 'CONNECTED', 'DISCONNECTED');
  setToggle('nmea', 'nmea', 'ONLINE', 'OFFLINE');
  setToggle('externalCharger', 'externalCharger', 'ON', 'OFF');

  document.querySelectorAll('[data-scenario]').forEach(btn => btn.addEventListener('click', () => scenario[btn.dataset.scenario]()));
  $('clearBus').addEventListener('click', () => $('busConsole').textContent = '');
  $('injectTime').addEventListener('click', () => bus('RX', 129029, `GNSS UTC ${nowIso()} valid=1`));
  $('ackAlert').addEventListener('click', () => {
    sim.alertAcked = sim.alarms.size > 0;
    bus('RX', 126984, sim.alertAcked ? 'Alert acknowledgement' : 'ACK ignored: no active alert');
  });

  log('BatterySentinel Lab V0.1 initialized');
  bus('RX', 129029, `GNSS UTC ${nowIso()} valid=1`);
  requestAnimationFrame(tick);
})();
