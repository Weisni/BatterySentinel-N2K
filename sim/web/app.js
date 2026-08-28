(() => {
  'use strict';

  const $ = (id) => document.getElementById(id);
  const ui = {
    voltage: $('voltage'), current: $('current'), ignition: $('ignition'), sensorOk: $('sensorOk'),
    chemistry: $('chemistry'), capacity: $('capacity'), speed: $('speed'),
    voltageOut: $('voltageOut'), currentOut: $('currentOut'),
    runPill: $('runPill'), ignPill: $('ignPill'), sensorPill: $('sensorPill'),
    mVoltage: $('mVoltage'), mCurrent: $('mCurrent'), mPower: $('mPower'), mSoc: $('mSoc'),
    mConsumed: $('mConsumed'), mRuntime: $('mRuntime'), mConfidence: $('mConfidence'), mUtc: $('mUtc'),
    alerts: $('alerts'), internalState: $('internalState'), busLog: $('busLog'), eventLog: $('eventLog'),
    chart: $('chart'), injectTime: $('injectTime'), ackAlert: $('ackAlert'), clearBus: $('clearBus'), clearTimeline: $('clearTimeline')
  };

  const chemistryProfiles = {
    flooded: { chargeEff: 0.90, fullV: 14.40, tailC: 0.02, lowIdle: 11.60, overV: 15.10, selfDischargeMonth: 3.0, ocv: true },
    agm:     { chargeEff: 0.93, fullV: 14.40, tailC: 0.02, lowIdle: 11.70, overV: 15.00, selfDischargeMonth: 2.0, ocv: true },
    gel:     { chargeEff: 0.92, fullV: 14.10, tailC: 0.02, lowIdle: 11.70, overV: 14.60, selfDischargeMonth: 2.0, ocv: true },
    efb:     { chargeEff: 0.91, fullV: 14.40, tailC: 0.02, lowIdle: 11.60, overV: 15.10, selfDischargeMonth: 3.0, ocv: true },
    lifepo4: { chargeEff: 0.99, fullV: 14.20, tailC: 0.05, lowIdle: 11.50, overV: 14.60, selfDischargeMonth: 1.0, ocv: false },
    unknown: { chargeEff: 1.00, fullV: 99.00, tailC: 0.00, lowIdle: 11.50, overV: 15.50, selfDischargeMonth: 0.0, ocv: false }
  };

  const state = {
    soc: 100,
    socInitialized: true,
    confidence: 'ESTIMATED',
    consumedAh: 0,
    utc: new Date(),
    lastPgnFast: 0,
    lastPgnDc: 0,
    simSeconds: 0,
    alerts: new Set(),
    acknowledged: new Set(),
    timers: { low: 0, high: 0, overCurrent: 0, rest: 0, full: 0 },
    timeline: [],
    scenarioTimer: null,
    lastAlertKey: '',
    nmeaSeq: 0
  };

  function profile() { return chemistryProfiles[ui.chemistry.value] || chemistryProfiles.unknown; }
  function capacityAh() { return Math.max(1, Number(ui.capacity.value) || 80); }
  function voltageV() { return Number(ui.voltage.value); }
  function currentA() { return Number(ui.current.value); }
  function sensorValid() { return ui.sensorOk.checked; }
  function powered() { return ui.ignition.checked; }

  function estimateLeadSoc(v) {
    const curve = [[11.90,0],[12.00,20],[12.15,40],[12.30,60],[12.45,75],[12.60,90],[12.75,100]];
    if (v <= curve[0][0]) return 0;
    if (v >= curve[curve.length - 1][0]) return 100;
    for (let i=1;i<curve.length;i++) {
      if (v <= curve[i][0]) {
        const [v0,s0] = curve[i-1], [v1,s1] = curve[i];
        const f = (v-v0)/(v1-v0);
        return s0 + f*(s1-s0);
      }
    }
    return 50;
  }

  function addEvent(text) {
    const div = document.createElement('div');
    div.className = 'event';
    div.innerHTML = `<b>${state.utc.toISOString().slice(11,19)}</b> ${escapeHtml(text)}`;
    ui.eventLog.prepend(div);
    while (ui.eventLog.children.length > 100) ui.eventLog.lastChild.remove();
  }

  function escapeHtml(text) {
    return String(text).replace(/[&<>'"]/g, (c) => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
  }

  function bus(direction, pgn, data) {
    const tr = document.createElement('tr');
    const dirClass = direction === 'TX' ? 'ok' : 'warn';
    tr.innerHTML = `<td>${state.utc.toISOString().slice(11,19)}</td><td><span class="pill ${dirClass}">${direction}</span></td><td>${pgn}</td><td>${escapeHtml(data)}</td>`;
    ui.busLog.prepend(tr);
    while (ui.busLog.children.length > 80) ui.busLog.lastChild.remove();
  }

  function publishFast() {
    const socText = state.socInitialized ? `${state.soc.toFixed(1)}%` : 'NA';
    bus('TX', '127508', `Battery=0 V=${voltageV().toFixed(2)}V I=${currentA().toFixed(1)}A SOC=${socText}`);
  }

  function publishDc() {
    const t = remainingSeconds();
    bus('TX', '127506', `Battery=0 SOC=${state.socInitialized ? state.soc.toFixed(1)+'%' : 'NA'} Consumed=${state.consumedAh.toFixed(2)}Ah TimeRemaining=${t > 0 ? Math.round(t/60)+'min' : 'NA'}`);
  }

  function remainingSeconds() {
    if (!state.socInitialized || currentA() >= -0.5) return -1;
    return (capacityAh() * state.soc / 100 / -currentA()) * 3600;
  }

  function setAlert(name, active) {
    const had = state.alerts.has(name);
    if (active) state.alerts.add(name); else { state.alerts.delete(name); state.acknowledged.delete(name); }
    if (had !== active) {
      addEvent(`${active ? 'ALARM SET' : 'ALARM CLEAR'}: ${name}`);
      if (active && powered()) bus('TX', '126983/126985', `Alert=${name} state=ACTIVE`);
    }
  }

  function updateModel(dt) {
    state.simSeconds += dt;
    state.utc = new Date(state.utc.getTime() + dt * 1000);

    const p = profile();
    const cap = capacityAh();
    const v = voltageV();
    const i = currentA();

    if (!powered()) return;

    if (!sensorValid()) {
      setAlert('SENSOR_FAULT', true);
      state.timers.low = state.timers.high = state.timers.overCurrent = 0;
      return;
    }
    setAlert('SENSOR_FAULT', false);

    if (ui.chemistry.value === 'unknown') {
      state.socInitialized = false;
      state.confidence = 'UNKNOWN';
    } else {
      let deltaAh = i * dt / 3600;
      if (deltaAh > 0) deltaAh *= p.chargeEff;
      if (state.socInitialized) state.soc = clamp(state.soc + deltaAh / cap * 100, 0, 100);

      const restEligible = Math.abs(i) <= 0.8 && v >= 11.5 && v <= 12.95 && p.ocv;
      state.timers.rest = restEligible ? state.timers.rest + dt : 0;
      if (!state.socInitialized && state.timers.rest >= 10) {
        state.soc = estimateLeadSoc(v); state.socInitialized = true; state.confidence = 'ESTIMATED';
      } else if (state.socInitialized && state.timers.rest >= 300) {
        const ocvSoc = estimateLeadSoc(v);
        state.soc = 0.8 * state.soc + 0.2 * ocvSoc;
        state.timers.rest = 0;
        if (state.confidence === 'UNKNOWN') state.confidence = 'ESTIMATED';
      }

      const tail = cap * p.tailC;
      const full = v >= p.fullV && i >= 0 && i <= tail;
      state.timers.full = full ? state.timers.full + dt : 0;
      if (state.timers.full >= 300) {
        state.soc = 100; state.socInitialized = true; state.confidence = 'SYNCED'; state.timers.full = 0;
        addEvent('SOC full-charge synchronization -> 100%');
      }
    }

    state.consumedAh = state.socInitialized ? cap * (100 - state.soc) / 100 : 0;

    const highLoad = -i >= 50;
    const lowThreshold = highLoad ? 9.5 : p.lowIdle;
    const lowDelay = highLoad ? 0.75 : 10.0;
    state.timers.low = v < lowThreshold ? state.timers.low + dt : 0;
    setAlert('LOW_VOLTAGE', state.timers.low >= lowDelay);

    state.timers.high = v > p.overV ? state.timers.high + dt : 0;
    setAlert('OVER_VOLTAGE', state.timers.high >= 2.0);

    state.timers.overCurrent = Math.abs(i) > 350 ? state.timers.overCurrent + dt : 0;
    setAlert('OVER_CURRENT', state.timers.overCurrent >= 0.75);
    setAlert('LOW_SOC', state.socInitialized && state.soc <= 20);
    setAlert('CRITICAL_SOC', state.socInitialized && state.soc <= 10);

    if (state.simSeconds - state.lastPgnFast >= 1.5) { state.lastPgnFast = state.simSeconds; publishFast(); }
    if (state.simSeconds - state.lastPgnDc >= 5.0 && state.socInitialized) { state.lastPgnDc = state.simSeconds; publishDc(); }
  }

  function clamp(x,a,b){ return Math.max(a,Math.min(b,x)); }

  function render() {
    const v = voltageV(), i = currentA();
    ui.voltageOut.value = `${v.toFixed(2)} V`;
    ui.currentOut.value = `${i.toFixed(1)} A`;
    ui.mVoltage.textContent = sensorValid() && powered() ? `${v.toFixed(2)} V` : '—';
    ui.mCurrent.textContent = sensorValid() && powered() ? `${i.toFixed(1)} A` : '—';
    ui.mPower.textContent = sensorValid() && powered() ? `${Math.round(v*i)} W` : '—';
    ui.mSoc.textContent = state.socInitialized ? `${state.soc.toFixed(1)} %` : 'UNKNOWN';
    ui.mConsumed.textContent = state.socInitialized ? `${state.consumedAh.toFixed(2)} Ah` : '—';
    const rem = remainingSeconds();
    ui.mRuntime.textContent = rem > 0 ? formatDuration(rem) : '—';
    ui.mConfidence.textContent = state.confidence;
    ui.mUtc.textContent = state.utc.toISOString().replace('T',' ').slice(0,19) + 'Z';

    ui.ignPill.textContent = powered() ? 'IGN ON' : 'IGN OFF';
    ui.ignPill.className = `pill ${powered() ? 'ok':'warn'}`;
    ui.sensorPill.textContent = sensorValid() ? 'INA238 OK' : 'INA238 FAULT';
    ui.sensorPill.className = `pill ${sensorValid() ? 'ok':'bad'}`;
    ui.runPill.textContent = powered() ? 'RUNNING' : 'POWERED OFF';
    ui.runPill.className = `pill ${powered() ? 'ok':'warn'}`;

    ui.alerts.innerHTML = '';
    if (state.alerts.size === 0) ui.alerts.innerHTML = '<span class="pill ok">NONE</span>';
    else for (const a of state.alerts) {
      const span = document.createElement('span');
      span.className = `pill ${state.acknowledged.has(a) ? 'warn':'bad'}`;
      span.textContent = a + (state.acknowledged.has(a) ? ' ACK' : '');
      ui.alerts.appendChild(span);
    }

    ui.internalState.textContent = JSON.stringify({
      chemistry: ui.chemistry.value,
      capacityAh: capacityAh(),
      socInitialized: state.socInitialized,
      confidence: state.confidence,
      timers: Object.fromEntries(Object.entries(state.timers).map(([k,v])=>[k,Number(v.toFixed(2))])),
      nmeaBatteryInstance: 0,
      sensorValid: sensorValid(),
      ignition: powered()
    }, null, 2);
  }

  function formatDuration(sec) {
    const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60);
    return h > 48 ? `${(h/24).toFixed(1)} d` : `${h} h ${m} min`;
  }

  function timelineSample() {
    state.timeline.push({v:voltageV(), i:currentA(), soc:state.socInitialized ? state.soc : NaN});
    if (state.timeline.length > 300) state.timeline.shift();
    drawChart();
  }

  function drawChart() {
    const c = ui.chart, ctx = c.getContext('2d');
    const w = c.width, h = c.height;
    ctx.clearRect(0,0,w,h);
    ctx.strokeStyle = '#253244'; ctx.lineWidth = 1;
    for(let y=0;y<=10;y++){ const py=y*h/10; ctx.beginPath();ctx.moveTo(0,py);ctx.lineTo(w,py);ctx.stroke(); }
    if(state.timeline.length < 2) return;
    const draw = (selector, transform, color) => {
      ctx.strokeStyle=color;ctx.lineWidth=2;ctx.beginPath();
      state.timeline.forEach((p,idx)=>{
        const val=selector(p); if(!Number.isFinite(val)) return;
        const x=idx/(state.timeline.length-1)*w; const y=h-clamp(transform(val),0,1)*h;
        if(idx===0)ctx.moveTo(x,y);else ctx.lineTo(x,y);
      }); ctx.stroke();
    };
    draw(p=>p.v,v=>(v-8)/8,'#6cb8ff');
    draw(p=>p.i,i=>(i+400)/500,'#ffa76c');
    draw(p=>p.soc,s=>s/100,'#86df9a');
  }

  function cancelScenario(){ if(state.scenarioTimer){ clearTimeout(state.scenarioTimer); state.scenarioTimer=null; } }
  function setInputs(v,i){ ui.voltage.value=String(v);ui.current.value=String(i);render(); }

  function runScenario(name) {
    cancelScenario();
    ui.ignition.checked = true; ui.sensorOk.checked = true;
    switch(name){
      case 'rest': setInputs(12.70,0); addEvent('Scenario: rested battery'); break;
      case 'crank':
        addEvent('Scenario: Mercury starter pulse 225 A'); setInputs(12.70,0);
        state.scenarioTimer=setTimeout(()=>{setInputs(10.25,-225); state.scenarioTimer=setTimeout(()=>{setInputs(12.35,-3);state.scenarioTimer=null;},3000);},500);
        break;
      case 'load': setInputs(12.25,-20); addEvent('Scenario: sustained 20 A discharge'); break;
      case 'charge': setInputs(14.40,20); addEvent('Scenario: charger 20 A'); break;
      case 'undervolt': setInputs(11.20,-2); addEvent('Scenario: idle undervoltage'); break;
      case 'overvolt': setInputs(15.40,2); addEvent('Scenario: overvoltage'); break;
      case 'sensorfail': ui.sensorOk.checked=false; addEvent('Scenario: INA238 disconnected'); break;
      case 'poweroff': simulatePowerOff(24); break;
    }
  }

  function simulatePowerOff(hours){
    cancelScenario();
    const wasSoc = state.soc;
    ui.ignition.checked=false;
    const p=profile();
    if(state.socInitialized && p.selfDischargeMonth>0){ state.soc=clamp(state.soc - p.selfDischargeMonth/30*(hours/24),0,100); }
    state.utc = new Date(state.utc.getTime()+hours*3600*1000);
    state.confidence = state.socInitialized ? 'ESTIMATED':'UNKNOWN';
    addEvent(`Power off ${hours} h; SOC ${wasSoc.toFixed(2)}% -> ${state.soc.toFixed(2)}% by configured self-discharge model`);
    state.scenarioTimer=setTimeout(()=>{ui.ignition.checked=true; setInputs(12.62,0); addEvent('Restart after simulated off-time'); state.scenarioTimer=null;},1200);
  }

  document.querySelectorAll('[data-scenario]').forEach(b=>b.addEventListener('click',()=>runScenario(b.dataset.scenario)));
  [ui.voltage,ui.current,ui.ignition,ui.sensorOk,ui.speed].forEach(el=>el.addEventListener('input',render));
  ui.capacity.addEventListener('change',()=>{state.socInitialized=ui.chemistry.value!=='unknown';state.confidence='ESTIMATED';addEvent(`Capacity changed to ${capacityAh()} Ah`);});
  ui.chemistry.addEventListener('change',()=>{
    state.socInitialized=ui.chemistry.value!=='unknown';
    state.confidence=state.socInitialized?'ESTIMATED':'UNKNOWN';
    addEvent(`Battery chemistry -> ${ui.chemistry.options[ui.chemistry.selectedIndex].text}`);render();
  });
  ui.injectTime.addEventListener('click',()=>{state.utc=new Date();bus('RX','129029',`GNSS UTC=${state.utc.toISOString()}`);state.confidence=state.socInitialized?'ESTIMATED':'UNKNOWN';render();});
  ui.ackAlert.addEventListener('click',()=>{
    if(state.alerts.size===0){bus('RX','126984','No active alert to acknowledge');return;}
    for(const a of state.alerts)state.acknowledged.add(a);
    bus('RX','126984',`ACK ${[...state.alerts].join(',')}`);addEvent('Garmin-style alert acknowledgement received');render();
  });
  ui.clearBus.addEventListener('click',()=>ui.busLog.innerHTML='');
  ui.clearTimeline.addEventListener('click',()=>{state.timeline=[];drawChart();});

  setInterval(()=>{
    const dt=0.1*Number(ui.speed.value||1);
    updateModel(dt);render();
  },100);
  setInterval(timelineSample,500);

  addEvent('BatterySentinel Lab started');
  bus('RX','60928','Virtual NMEA peer online / address claim environment ready');
  render();timelineSample();
})();
