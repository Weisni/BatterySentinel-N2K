#pragma once

namespace bs::ui {

// Reuses the single live response; this controller never opens a polling request.
inline constexpr char kInsightsController[] = R"INSIGHTS(<script>
window.bridgeInsights=(()=>{
  let latest=null,form=null,dirty=false,loaded=false,saving=false,clock=null,bootId=null;
  const tr=(key,values)=>bridgeI18n.t(key,values),byId=id=>document.getElementById(id);
  const number=(value,digits=2)=>typeof value==='number'&&Number.isFinite(value)?value.toLocaleString(bridgeI18n.language==='de'?'de-DE':'en-US',{minimumFractionDigits:digits,maximumFractionDigits:digits,useGrouping:false}):'—';
  const text=(id,value)=>{const node=byId(id);if(node)node.textContent=value};
  const rules=['input_low','input_high','output_low','output_high'];
  const alertNames=['Input voltage low','Output voltage low','Input voltage high','Output voltage high','Orion data missing','Charger reports an error'];
  const qualities={synchronized:'Network time',holdover:'Estimated time',estimated:'Backdated time',backdated:'Backdated time',uptime:'Device uptime',unknown:'Device uptime',acquiring:'Acquiring network time',quarantined:'Time source needs review'};
  function eventTime(event){
    let utc=event.utcMs,quality=event.timeQuality;
    const time=clock;
    if(utc==null&&['synchronized','holdover'].includes(time?.quality)&&typeof time.anchorUtcMs==='number'&&typeof time.anchorMonotonicMs==='number'&&typeof event.ms==='number'){
      utc=time.anchorUtcMs+(event.ms-time.anchorMonotonicMs);quality='backdated';
    }
    if(typeof utc==='number'&&Number.isFinite(utc)){
      const date=new Date(utc);
      if(!Number.isNaN(date.getTime()))return date.toLocaleString(bridgeI18n.language==='de'?'de-DE':'en-GB',{timeZone:'UTC',hour12:false})+' UTC · '+tr(qualities[quality]||'Network time');
    }
    return tr('Uptime {seconds} s',{seconds:number((event.ms||0)/1000,0)});
  }
  function chart(id,history){
    const svg=byId(id);svg.replaceChildren();
    const valid=history.filter(p=>typeof p.v==='number'&&Number.isFinite(p.v)&&typeof p.ms==='number');
    if(!valid.length)return;
    const min=Math.min(...valid.map(p=>p.v)),max=Math.max(...valid.map(p=>p.v)),start=history[0].ms,end=history[history.length-1].ms;
    const range=Math.max(.1,max-min),x=ms=>12+(ms-start)/Math.max(1,end-start)*476,y=v=>100-(v-min)/range*76;
    const make=(name,attrs)=>{const node=document.createElementNS('http://www.w3.org/2000/svg',name);for(const [key,value]of Object.entries(attrs))node.setAttribute(key,value);svg.appendChild(node);return node};
    make('line',{x1:12,x2:488,y1:100,y2:100,stroke:'#294457'});
    let points=[];const flush=()=>{if(points.length>1)make('polyline',{points:points.join(' '),fill:'none',stroke:'#68e3d1','stroke-width':2.5,'vector-effect':'non-scaling-stroke'});else if(points.length) {const [cx,cy]=points[0].split(',');make('circle',{cx,cy,r:3,fill:'#68e3d1'})}points=[]};
    for(const point of history){if(typeof point.v!=='number'||!Number.isFinite(point.v)){flush();continue}points.push(x(point.ms)+','+y(point.v))}flush();
    svg.setAttribute('aria-label',tr('Voltage history from {min} to {max} V',{min:number(min),max:number(max)}));
  }
  function renderInsights(){
    const insight=latest?.insights;
    text('insights-status',!latest?tr('Connection interrupted'):!insight?tr('Waiting for observations'):tr('Observations since this start'));
    for(const side of ['input','output']){
      const channel=insight?.[side];
      text('insights-'+side+'-min',number(channel?.minV)+' V');text('insights-'+side+'-max',number(channel?.maxV)+' V');
      text('insights-'+side+'-ah',number(channel?.ah)+' Ah');text('insights-'+side+'-wh',number(channel?.wh)+' Wh');
      const trend=channel?.trendVPerMin;
      text('insights-'+side+'-trend',(typeof trend==='number'?tr('Voltage trend: {rate} V/min over {minutes} min',{rate:number(trend,3),minutes:number(channel.trendSpanMs/60000,1)}):tr('Not enough observations for a voltage trend'))+(channel&&!channel.fresh?' · '+tr('Waiting for fresh data'):''));
      text('insights-'+side+'-coverage',tr('{coverage}% voltage coverage · {minutes} min of energy observations',{coverage:number(channel?.coveragePct,0),minutes:number(channel?.transferCoveredMs/60000,1)}));
      text('insights-'+side+'-low-label',tr('Observed time below {voltage} V',{voltage:number(latest?.notifications?.config?.[side]?.lowV)}));
      text('insights-'+side+'-low-time',number(channel?.belowLowMs/60000,1)+' min');
      chart('insights-'+side+'-chart',channel?.history||[]);
    }
    const time=latest?.time;
    text('insights-time',time?.utcMs!=null?eventTime({utcMs:time.utcMs,timeQuality:time.quality}):tr('Calendar time unavailable; observations use device uptime.'));
  }
  function configValues(config){
    const values={enabled:config.enabled,nmea_enabled:config.nmeaEnabled,repeat_minutes:config.repeatMinutes,data_loss_enabled:config.dataLossEnabled,data_loss_delay_s:config.dataLossDelayS,charger_error_enabled:config.chargerErrorEnabled};
    for(const side of ['input','output']){const bank=config[side];Object.assign(values,{[side+'_delay_s']:bank.delayS,[side+'_clear_s']:bank.clearS});for(const kind of ['low','high'])Object.assign(values,{[side+'_'+kind+'_enabled']:bank[kind+'Enabled'],[side+'_'+kind+'_v']:bank[kind+'V'],[side+'_'+kind+'_clear_v']:bank[kind+'ClearV']})}
    return values;
  }
  function loadConfig(config){
    if(!form||dirty||saving||!config)return;
    for(const [name,value]of Object.entries(configValues(config))){const input=form.elements.namedItem(name);if(input.type==='checkbox')input.checked=Boolean(value);else input.value=String(value)}
    for(const input of form.querySelectorAll('input'))input.disabled=false;
    loaded=true;validate();
  }
  function validate(){
    if(!form)return false;
    let valid=true;
    for(const key of rules){
      const trigger=form.elements.namedItem(key+'_v'),clear=form.elements.namedItem(key+'_clear_v');
      const good=key.endsWith('low')?Number(clear.value)>Number(trigger.value):Number(clear.value)<Number(trigger.value);
      const message=good?'':tr(key.endsWith('low')?'The clear voltage must be above the low threshold.':'The clear voltage must be below the high threshold.');
      clear.setCustomValidity(message);clear.setAttribute('aria-invalid',String(!good));valid=valid&&good;
    }
    for(const side of ['input','output']){
      const low=form.elements.namedItem(side+'_low_clear_v'),high=form.elements.namedItem(side+'_high_clear_v');
      if(Number(low.value)>=Number(high.value)){high.setCustomValidity(tr('The low clear voltage must be below the high clear voltage.'));high.setAttribute('aria-invalid','true');valid=false}
    }
    for(const input of form.querySelectorAll('input[type=number]'))valid=input.validity.valid&&valid;
    byId('notifications-save').disabled=!loaded||saving||!valid||Boolean(window.bridgeOtaBusy||window.bridgeAccountSaving);
    text('notifications-form-status',tr(!loaded?'Waiting for saved settings…':saving?'Saving notifications…':!valid?'Check the voltage thresholds and time values.':dirty?'Unsaved changes':latest?.notifications?.storageValid===false?'Review and save the notification settings.':'Settings are up to date'));
    return valid;
  }
  function renderAlerts(){
    const container=byId('notification-alerts');container.replaceChildren();
    const notifications=latest?.notifications,alerts=(notifications?.alerts||[]).filter(alert=>alert.active);
    const banner=byId('notification-banner'),pending=alerts.filter(alert=>!alert.acknowledged).length;
    banner.hidden=Boolean(notifications&&alerts.length===0);
    banner.className='notice notification-banner'+(notifications&&pending===0?' blue':'');
    text('notification-banner-text',!notifications?tr('Notification status unavailable. Reconnect to check warnings.'):tr('Active warnings: {count} · unacknowledged: {pending}',{count:alerts.length,pending}));
    text('notifications-state',tr(!notifications?'Unavailable':notifications.config?.enabled?'Notifications enabled':'Notifications disabled'));
    const delivery=notifications?.delivery;
    text('nmea-alert-status',tr(notifications?.nmeaStatus==='unavailable'?'Garmin notifications are unavailable in this firmware. Local notifications remain available.':'Garmin delivery needs a test on your chartplotter. Acknowledgement in this portal.')+(delivery?.backlog?' '+tr('Some Garmin notifications are waiting. Check active warnings in this portal.'): '')+(delivery?.withdrawalsUnconfirmed?' '+tr('Withdrawal of earlier Garmin warnings is unconfirmed. Check the chartplotter; an old warning may remain.'):''));
    if(!alerts.length){const p=document.createElement('p');p.textContent=tr(!latest?'Connection interrupted':'No active notifications');container.appendChild(p);return}
    for(const alert of alerts){
      const card=document.createElement('article');card.className='notification-alert';
      const heading=document.createElement('h3');heading.textContent=tr(alertNames[alert.id]||'Notification');
      if(alert.id<4){const side=[0,2].includes(alert.id)?'input':'output';heading.textContent+=' · '+byId(side+'-alias-label').textContent}
      const details=document.createElement('p');details.textContent=eventTime({ms:alert.activatedAtMs,utcMs:alert.utcMs,timeQuality:alert.timeQuality})+' · '+tr(alert.acknowledged?'Acknowledged':'Needs attention')+(alert.known?'':' · '+tr('Waiting for fresh data'));
      card.append(heading,details);
      if(alert.known&&typeof alert.value==='number'){const reading=document.createElement('p');reading.textContent=alert.id<4?number(alert.value)+' V':alert.id===5?tr('Charger error (code)')+': '+number(alert.value,0):'';if(reading.textContent)card.appendChild(reading)}
      if(!alert.acknowledged){const ack=document.createElement('form');ack.method='post';ack.action='/notifications/ack';
        for(const [name,value]of [['csrf',form.elements.namedItem('csrf').value],['id',String(alert.id)],['generation',String(alert.generation)]]){const input=document.createElement('input');input.type='hidden';input.name=name;input.value=value;ack.appendChild(input)}
        const button=document.createElement('button');button.type='submit';button.className='button';button.textContent=tr('Acknowledge');button.disabled=Boolean(saving||window.bridgeAccountSaving||window.bridgeOtaBusy);ack.appendChild(button);ack.addEventListener('submit',event=>submit(event,ack,button));card.appendChild(ack);
      }
      container.appendChild(card);
    }
  }
  async function submit(event,target,button){
    event.preventDefault();
    if(saving||window.bridgeAccountSaving||window.bridgeOtaBusy||window.bridgeFirmwareLoading||window.bridgeFirmwarePicking)return;
    if(target===form&&(!validate()||!form.reportValidity()))return;
    // The firmware accepts decimal notation, without exponent syntax.
    if(target===form)for(const input of form.querySelectorAll('input[type=number]'))input.value=String(Number(input.value));
    saving=true;window.bridgeAccountSaving=true;bridgeI18n.busy(button,'Saving notifications…');
    window.dispatchEvent(new Event('bridge-account-saving'));
    await window.bridgePauseLive();
    target.submit();
  }
  function init(){
    form=byId('notifications-form');if(!form)return;
    for(const input of form.querySelectorAll('input'))if(input.type!=='hidden')input.disabled=true;
    form.addEventListener('input',()=>{dirty=true;validate()});form.addEventListener('change',()=>{dirty=true;validate()});
    form.addEventListener('submit',event=>submit(event,form,byId('notifications-save')));
    window.addEventListener('bridge-language-change',()=>{validate();renderInsights();renderAlerts()});
    window.addEventListener('bridge-account-saving',validate);
    window.addEventListener('pageshow',event=>{
      if(!event.persisted||!saving)return;
      saving=false;window.bridgeAccountSaving=false;
      const button=byId('notifications-save');delete button.dataset.busyKey;button.textContent=tr('Save notifications');
      bridgeI18n.apply();window.bridgeResumeLive(500);
    });
    validate();renderInsights();renderAlerts();
  }
  function update(data){
    latest=data;
    if(data?.bootId!=null&&data.bootId!==bootId){clock=null;bootId=data.bootId}
    if(data?.time){if(clock&&data.time.monotonicMs<clock.monotonicMs)clock=null;if(['synchronized','holdover'].includes(data.time.quality))clock=data.time;else if(data.time.quality==='quarantined')clock=null}
    loadConfig(data?.notifications?.config);renderInsights();renderAlerts();
  }
  return {init,update,eventTime};
})();
</script>)INSIGHTS";

} // namespace bs::ui
