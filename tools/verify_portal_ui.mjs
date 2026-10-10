import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
// Lightweight DOM simulation: validates behavior, not browser rendering.
const read=name=>fs.readFileSync(new URL('../src/'+name,import.meta.url),'utf8');
const source=read('BridgePortalUi.h');
const templates=Object.fromEntries([...source.matchAll(/inline constexpr char (k\w+)\[\] = R"UI\(([\s\S]*?)\)UI";/g)].map(m=>[m[1],m[2]]));
const translationHtml=read('BridgePortalTranslations.h').match(/R"I18N\(([\s\S]*?)\)I18N"/)[1];
const languageHtml=read('BridgePortalLanguage.h').match(/R"I18N\(([\s\S]*?)\)I18N"/)[1];
const formSource=read('BridgePortalForm.h');
const formHtml=formSource.match(/R"FORM\(([\s\S]*?)\)FORM"/)[1];
const otaHtml=read('BridgePortalOta.h').match(/R"OTA\(([\s\S]*?)\)OTA"/)[1];
const insightsHtml=read('BridgePortalInsights.h').match(/R"INSIGHTS\(([\s\S]*?)\)INSIGHTS"/)[1];
const scripts=html=>[...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(m=>m[1]);
const catalogueContext={window:{}};vm.runInNewContext(scripts(translationHtml)[0],catalogueContext);
const catalogue=catalogueContext.window.bridgeGerman;
const texts=[...source.matchAll(/<(?:span|label)[^>]*data-i18n(?:>| [^>]*>)([^<]+)<\/(?:span|label)>/g)].map(m=>m[1]).filter(t=>!t.startsWith('{{'));
const attributes=[...source.matchAll(/<(?:input|button|nav|select)[^>]*data-i18n-attr="[^"]+"[^>]*>/g)].flatMap(m=>[...m[0].matchAll(/(?:placeholder|title|aria-label)="([^"]+)"/g)].map(a=>a[1]));
for(const text of [...texts,...attributes])assert.ok(catalogue[text],`Missing translation: ${text}`);
for(const match of formSource.matchAll(/message:'([^']+)'/g))assert.ok(catalogue[match[1]],`Missing form feedback translation: ${match[1]}`);
for(const match of insightsHtml.matchAll(/tr\('([^']+)'/g))assert.ok(catalogue[match[1]],`Missing insights feedback translation: ${match[1]}`);
for(const match of read('BridgePortal.cpp').matchAll(/ui::kMessageBody, "([^"]+)",\s*"([^"]+)"/g))for(const text of match.slice(1))assert.ok(catalogue[text],`Missing server error translation: ${text}`);
const pages={login:'kLoginBody',recovery:'kRecoveryBody',account:'kAccountMessageBody','first-setup':'kFirstSetupBody',dashboard:'kDashboardBody',message:'kMessageBody',restart:'kRestartBody'};
function page(name){
  let html=templates.kDocumentStart+translationHtml+languageHtml+formHtml+otaHtml+insightsHtml+templates[pages[name]]+'<script>bridgeI18n.apply();</script></body></html>';
  const values={BRAND:templates.kBrand,CSRF:'test-token',RECOVERY_CSRF:'test-recovery-token',CONFIGURED:'0',MAC:'',OUT_INSTANCE:'0',IN_INSTANCE:'1',IN_ALIAS:'Startbatterie',OUT_ALIAS:'Bugbatterie',MESSAGE_TITLE:'Check account details',MESSAGE_TEXT:'Use a 3–32 character username and a password of at least 12 characters.'};
  html=html.replace(/\{\{(\w+)\}\}/g,(_,key)=>{assert.ok(Object.hasOwn(values,key),`Missing preview template value: ${key}`);assert.equal(typeof values[key],'string',`Undefined preview template value: ${key}`);return values[key]});
  assert.doesNotMatch(html,/\{\{\w+\}\}/,`Unresolved template placeholder in ${name}`);
  return html;
}
for(const name of Object.keys(pages)){
  const html=page(name);
  for(const match of html.matchAll(/<script>([\s\S]*?)<\/script>/g))new vm.Script(match[1]);
}
// A slow native login may still receive another submit event. Back/forward
// restoration must re-enable the form without replaying a credential request.
{
  const form={dataset:{},listeners:{},addEventListener(name,fn){this.listeners[name]=fn}};
  const button={dataset:{},disabled:false,innerHTML:'<span data-i18n>Sign in</span>'};
  const events={};let busyCalls=0,languageApplications=0;
  const context={document:{querySelector:()=>form,getElementById:()=>button},window:{addEventListener(name,fn){events[name]=fn}},bridgeI18n:{busy(node,key){busyCalls++;node.disabled=true;node.dataset.busyKey=key;node.innerHTML=key},apply(){languageApplications++}}};
  vm.runInNewContext(scripts(templates.kLoginBody)[0],context);
  const submit=()=>{let prevented=false;form.listeners.submit({preventDefault(){prevented=true}});return prevented};
  assert.equal(submit(),false);assert.equal(button.disabled,true);assert.equal(form.dataset.submitting,'1');
  assert.equal(submit(),true);assert.equal(busyCalls,1,'Duplicate login must not start another submission');
  events.pageshow({persisted:true});
  assert.equal(button.disabled,false);assert.equal(button.dataset.busyKey,undefined);assert.equal(form.dataset.submitting,undefined);
  assert.equal(button.innerHTML,'<span data-i18n>Sign in</span>');assert.equal(languageApplications,1);
  assert.equal(busyCalls,1,'Restoring a page must not replay the login');
  assert.equal(submit(),false,'User can deliberately sign in after going back');
}
const html=page('dashboard');
// The isolated OTA controller is exercised in verify_portal_ota.mjs. Keep this
// harness focused on live polling, settings and language behavior.
// Insights uses real SVG/forms and has a dedicated browser regression suite.
const script=scripts(html).filter(code=>!code.includes('window.bridgeOta=')&&!code.includes('window.bridgeInsights=')).join('\n');
function element(tagName='div'){
  let text='',value='',className='';
  return {tagName:String(tagName).toUpperCase(),hidden:true,dataset:{},style:{},children:[],listeners:{},selectionStart:0,selectionEnd:0,
    get className(){return className},set className(value){className=String(value)},
    classList:{add(...tokens){className=[...new Set([...className.split(/\s+/).filter(Boolean),...tokens])].join(' ')},contains(token){return className.split(/\s+/).includes(token)}},
    get textContent(){return text+this.children.map(child=>child.textContent).join('')},set textContent(v){text=String(v);this.children=[]},
    get value(){return value},set value(v){value=String(v);this.selectionStart=this.selectionEnd=value.length},
    appendChild(child){this.children.push(child);return child},replaceChildren(...children){text='';this.children=[...children]},
    setSelectionRange(start,end){this.selectionStart=Math.max(0,Math.min(value.length,start));this.selectionEnd=Math.max(this.selectionStart,Math.min(value.length,end))},
    getAttribute(k){return this[k]},setAttribute(k,v){this[k]=v},addEventListener(k,v){this.listeners[k]=v},setCustomValidity(v){this.validation=v},focus(){this.focused=true}};
}
const nmeaFixture=[
  {pgn:127508,instance:0,age:100,accepted:true,fields:{sid:7,voltage:14.4,current:5,temperature:null}},
  {pgn:127508,instance:1,age:101,accepted:false,fields:{sid:8,voltage:13.3,current:6,temperature:null}},
  {pgn:127507,instance:0,age:102,accepted:true,fields:{batteryInstance:0,chargeState:1,chargerMode:0,enabled:1,equalizationPending:null,equalizationTimeRemaining:null}},
  {pgn:127506,instance:0,age:3000,accepted:true,fields:{sid:9,dcType:0,soc:null,soh:null,timeRemaining:null,rippleVoltage:null,capacity:null}},
  {pgn:127506,instance:1,age:null,accepted:null,fields:{sid:null,dcType:null,soc:null,soh:null,timeRemaining:null,rippleVoltage:null,capacity:null}}
];
function start({storageBlocked=false,stored={},preferences={},mode='ok',live={},configured=false,formValues={},withOta=false,readyState='complete'}={}){
  const ids=Object.fromEntries([...html.matchAll(/\bid="([^"]+)"/g)].map(m=>[m[1],element()]));
  const names=['overview','setup','guide','monitor','insights','notifications'];
  const nav=names.map(name=>Object.assign(element(),{dataset:{panelButton:name}}));
  const steps=Array.from({length:4},element);
  const form=ids['orion-form'];form.elements={in:element(),out:element()};form.elements.in.value=formValues.in??'1';form.elements.out.value=formValues.out??'0';const save=ids['orion-save'];form.querySelector=()=>save;
  ids['orion-mac'].value=formValues.mac??(configured?'aa:bb:cc:dd:ee:ff':'');ids['orion-key'].value=formValues.key??'';
  ids['orion-key'].dataset.keyPresent=configured?'1':'0';
  const aliasForm=ids['aliases-form'],aliasSave=ids['aliases-save'];
  ids['input-alias'].value=formValues.inputAlias??'Startbatterie';ids['output-alias'].value=formValues.outputAlias??'Bugbatterie';
  ids['input-alias-label'].textContent=ids['input-alias'].value;ids['output-alias-label'].textContent=ids['output-alias'].value;
  aliasForm.elements={input_alias:ids['input-alias'],output_alias:ids['output-alias']};
  const staticNodes=[...texts,...Object.keys(catalogue)].map(text=>Object.assign(element(),{textContent:text}));
  const placeholder=Object.assign(element(),{placeholder:'32 hexadecimal characters',dataset:{i18nAttr:'placeholder'},value:'typed-secret-for-test'});
  const listeners={},documentListeners={};
  const storage=values=>({getItem(key){if(storageBlocked)throw Error('blocked');return values[key]??null},setItem(key,val){if(storageBlocked)throw Error('blocked');values[key]=val}});
  const sessionStorage=storage(stored),localStorage=storage(preferences);
  const timers=new Map(),requestUrls=[];let nextTimer=0,calls=0,pending,metadataPending;
  const data={outV:14.4,outI:5,inV:13.3,inI:6,outW:72,inW:79.8,state:3,error:0,offReason:4,rssi:-50,age:200,received:true,fresh:true,counter:65535,status:'Receiving',rx:9,tx:10,rejected:2,dropped:3,duplicates:6,orionStartupFailed:1,orionErrors:6,nmeaErrors:7,txFailed:7,nmea:structuredClone(nmeaFixture),events:[{seq:1,ms:100,type:'BLE',detail:'First'},{seq:2,ms:200,type:'BLE',detail:'Second'}],...live};
  const context=vm.createContext({
    document:{hidden:false,readyState,documentElement:{lang:'de'},createElement:element,getElementById(id){assert.ok(ids[id],id);return ids[id]},querySelector(sel){if(sel==='.app-shell')return {dataset:{configured:configured?'1':'0'}};const n=sel.match(/data-panel-button="(.*?)"/);if(n)return nav[names.indexOf(n[1])];throw Error(sel)},querySelectorAll(sel){if(sel==='[data-guide-step]')return steps;if(sel==='[data-i18n]')return staticNodes;if(sel==='[data-i18n-attr]')return [placeholder];if(sel==='[data-busy-key]')return [save,aliasSave].filter(node=>node.dataset.busyKey);return nav},addEventListener(name,fn){const previous=documentListeners[name];documentListeners[name]=event=>{previous?.(event);fn(event)}}},
    scrollTo(){},matchMedia(){return {matches:false}},addEventListener(name,fn){listeners[name]=fn},dispatchEvent(event){listeners[event.type]?.()},Event,
    sessionStorage,localStorage,
    bridgeOta:{init(){}},bridgeInsights:{init(){},update(){},eventTime(event){return String(event.ms)}},
    setTimeout(fn,ms){timers.set(++nextTimer,{fn,ms});return nextTimer},clearTimeout(id){timers.delete(id)},AbortController,TextEncoder,
    fetch:async(url,options)=>{calls++;requestUrls.push(url);if(withOta&&url==='/api/firmware')return new Promise((resolve,reject)=>{metadataPending={resolve,reject};options.signal.addEventListener('abort',()=>reject(Error('aborted')))});if(mode==='pending')return new Promise((resolve,reject)=>{pending={resolve,reject};options.signal.addEventListener('abort',()=>reject(Error('aborted'))) });if(mode==='fail')throw Error('offline');return {status:mode==='expired'?401:200,ok:mode!=='expired',json:async()=>data}}
  });
  context.window=context;
  vm.runInContext(withOta?scripts(html).filter(code=>!code.includes('window.bridgeInsights=')).join('\n'):script,context);
  return {ids,nav,steps,form,save,aliasForm,aliasSave,timers,context,stored,preferences,staticNodes,placeholder,data,documentListeners,requestUrls,calls:()=>calls,setMode(v){mode=v},pending:()=>pending,metadataPending:()=>metadataPending};
}
const flush=()=>new Promise(resolve=>setImmediate(resolve));
// Full-controller startup: finish the HTML stream before opening another TLS
// connection, then finish metadata (including its body) before live polling.
let app=start({withOta:true,readyState:'loading'});await flush();
assert.equal(app.calls(),0, 'No API requests while HTML is still streaming');
app.context.document.readyState='interactive';app.documentListeners.DOMContentLoaded();await flush();
assert.deepEqual(app.requestUrls,['/api/firmware']);
assert.equal(app.context.bridgeFirmwareLoading,true);
await app.ids.refresh.onclick();app.documentListeners.visibilitychange();await flush();
assert.deepEqual(app.requestUrls,['/api/firmware'], 'Refresh/visibility cannot overlap pending metadata');
let finishMetadataBody;
app.metadataPending().resolve({status:200,ok:true,json:()=>new Promise(resolve=>{finishMetadataBody=resolve})});await flush();
assert.equal(app.calls(),1, 'Read the metadata body completely before live polling');
finishMetadataBody({target:'orion-dongle',version:'1.2.3',maxSize:2000000,available:true});await flush();
assert.deepEqual(app.requestUrls,['/api/firmware','/api/live?after=0']);
assert.equal(app.context.bridgeFirmwareLoading,false);assert.equal(app.ids['firmware-version'].textContent,'1.2.3');
// Failed firmware metadata must not leave ordinary live data paused indefinitely.
app=start({withOta:true});await flush();app.metadataPending().reject(Error('offline'));await flush();
assert.deepEqual(app.requestUrls,['/api/firmware','/api/live?after=0']);
assert.equal(app.context.bridgeFirmwareLoading,false);assert.equal(app.ids['out-v'].textContent,'14,400');

app=start({storageBlocked:true});await flush();
assert.equal(app.ids['panel-guide'].hidden,false);assert.equal(app.ids['out-v'].textContent,'14,400');
assert.equal(app.ids.events.textContent,'100  BLE  First\n200  BLE  Second\n');
app.nav[1].listeners.click();assert.equal(app.ids['panel-setup'].hidden,false);
for(let i=0;i<3;i++)app.ids['step-next'].onclick();assert.equal(app.ids['step-label'].textContent,'Schritt 4 von 4');
app.ids['step-next'].onclick();assert.equal(app.ids['panel-overview'].hidden,false);
app.form.elements.in.value='00';app.form.elements.in.listeners.input();assert.ok(app.form.elements.in.validation);
app.form.elements.in.value='2';app.form.elements.in.listeners.input();assert.equal(app.form.elements.in.validation,'');
app.setMode('fail');await app.ids.refresh.onclick();assert.equal(app.ids['out-v'].textContent,'—');assert.equal(app.ids.connection.textContent,'Verbindung unterbrochen');
app=start({stored:{bridgePanel:'guide',bridgeGuideStep:'3'}});await flush();assert.equal(app.ids['step-label'].textContent,'Schritt 4 von 4');
app=start({mode:'expired'});await flush();assert.equal(app.ids['session-notice'].hidden,false);assert.equal(app.timers.size,0);await app.ids.refresh.onclick();assert.equal(app.calls(),1);
app=start({mode:'pending'});await app.ids.refresh.onclick();assert.equal(app.calls(),1);
[...app.timers.values()].find(t=>t.ms===12000).fn();await flush();assert.equal(app.ids.connection.textContent,'Verbindung unterbrochen');assert.ok([...app.timers.values()].some(t=>t.ms===3000));
// OTA drains an active live request, stops timers and navigation, and resumes
// only when a rejected update has safely released the OTA lock.
app=start({mode:'pending'});
const activePanel=app.ids['panel-guide'].hidden;
app.context.bridgeOtaBusy=true;
await app.context.bridgePauseLive();await flush();
assert.equal(app.calls(),1);assert.equal(app.timers.size,0);
await app.ids.refresh.onclick();assert.equal(app.calls(),1);
app.nav[1].listeners.click();assert.equal(app.ids['panel-guide'].hidden,activePanel);
app.setMode('ok');app.context.bridgeOtaBusy=false;app.context.bridgeResumeLive();await flush();
assert.equal(app.calls(),2);assert.ok([...app.timers.values()].some(t=>t.ms===3000));
// Native pickers may keep the document visible. An explicit pause must persist
// after the in-flight request settles, preserving the last displayed readings.
app=start();await flush();
app.setMode('pending');const pickerPending=app.ids.refresh.onclick();
app.context.bridgeFirmwarePicking=true;await app.context.bridgePauseLive();await pickerPending;
assert.equal(app.ids['out-v'].textContent,'14,400');assert.equal(app.timers.size,0);
await app.ids.refresh.onclick();assert.equal(app.calls(),2);
app.documentListeners.visibilitychange();assert.equal(app.timers.size,0, 'Visibility cannot override the picker pause');
app.context.bridgeFirmwarePicking=false;app.setMode('ok');app.context.bridgeResumeLive(500);
assert.equal(app.calls(),2, 'Returning from picker must not immediately start HTTPS');
assert.ok([...app.timers.values()].some(t=>t.ms===500));
[...app.timers.values()].find(t=>t.ms===500).fn();await flush();assert.equal(app.calls(),3);
// Hiding a page aborts its live request and stops polling until a delayed return.
app.setMode('pending');const hiddenPending=app.ids.refresh.onclick();
app.context.document.hidden=true;app.documentListeners.visibilitychange();await hiddenPending;
assert.equal(app.timers.size,0);assert.equal(app.ids['out-v'].textContent,'14,400');
app.context.document.hidden=false;app.context.bridgeOtaBusy=true;app.documentListeners.visibilitychange();
assert.equal(app.timers.size,0, 'Returning during OTA must not resume live traffic');
app.context.bridgeOtaBusy=false;app.setMode('ok');app.documentListeners.visibilitychange();
assert.ok([...app.timers.values()].some(t=>t.ms===500));
// Language changes preserve input, active step, raw event values and polling state.
app=start();await flush();
assert.equal(app.context.bridgeI18n.language,'de');
assert.equal(app.context.document.documentElement.lang,'de');
assert.equal(app.placeholder.placeholder,catalogue['32 hexadecimal characters']);
app.nav[1].listeners.click();app.ids['step-next'].onclick();
const before=app.calls();app.context.bridgeI18n.setLanguage('en');
assert.equal(app.ids['out-v'].textContent,'14.400');
assert.equal(app.ids['panel-setup'].hidden,false);
assert.equal(app.ids['step-label'].textContent,'Step 2 of 4');
assert.equal(app.placeholder.value,'typed-secret-for-test');
assert.equal(app.placeholder.placeholder,'32 hexadecimal characters');
assert.equal(app.preferences.bridgeLanguage,'en');assert.equal(app.calls(),before);
assert.ok(app.staticNodes.some(n=>n.textContent==='Create administrator'));
app.context.bridgeI18n.setLanguage('de');
assert.ok(app.staticNodes.some(n=>n.textContent===catalogue['Create administrator']));
assert.equal(app.context.bridgeI18n.eventText('Password verification 9567 ms'),'Passwortprüfung 9567 ms');
assert.equal(app.context.bridgeI18n.eventText('PGN 127508 x2, 127507; sent 3, failed 0; values unavailable'),'PGN 127508 x2, 127507; gesendet 3, fehlgeschlagen 0; Werte nicht verfügbar');
assert.equal(app.context.bridgeI18n.eventText('PGN 127508 x2; accepted 2, failed 0; values unavailable'),'PGN 127508 x2; akzeptiert 2, fehlgeschlagen 0; Werte nicht verfügbar');
assert.equal(app.context.bridgeI18n.eventText('Orion state 3, output NA V 35.200 A'),'Orion-Status 3, Ausgang Nicht verfügbar V 35,200 A');
const reload=start({preferences:{bridgeLanguage:'en'}});await flush();
assert.equal(reload.ids['out-v'].textContent,'14.400');assert.equal(reload.context.document.documentElement.lang,'en');
assert.equal(start({preferences:{bridgeLanguage:'xx'}}).context.bridgeI18n.language,'de');
assert.equal(start({stored:{bridgeLanguage:'en'}}).context.bridgeI18n.language,'en');
assert.equal(start({stored:{bridgeLanguage:'de'},preferences:{bridgeLanguage:'en'}}).context.bridgeI18n.language,'de');
// Every Orion value and each individual error source remains visible in Monitor.
app=start();await flush();
const expectedOrion={
  'out-v':'14,400','out-i':'5,000','in-v':'13,300','in-i':'6,000',
  'monitor-out-v':'14,400','monitor-out-i':'5,000','monitor-in-v':'13,300','monitor-in-i':'6,000',
  'out-w':'72,000','in-w':'79,800','overview-out-w':'72,000','overview-in-w':'79,800','charger-state':'3','charger-error':'0',
  'off-reason':'4 (0x00000004)','frame-counter':'65535',rssi:'-50','ble-age':'200',
  'rx-count':'9','tx-count':'10','monitor-rx':'9','monitor-tx':'10',
  'orion-errors':'6','nmea-errors':'7',rejected:'2',dropped:'3',duplicates:'6','startup-failed':'1'
};
for(const [id,expected] of Object.entries(expectedOrion))assert.equal(app.ids[id].textContent,expected,id);
assert.equal(app.ids.freshness.textContent,catalogue.Fresh);
assert.equal(app.ids['monitor-orion-status'].textContent,catalogue['Charger switched off']);
function cards(app){return app.ids['nmea-parameters'].children.map(card=>({
  title:card.children[0].textContent,status:card.children[1].textContent,
  fields:Object.fromEntries(card.children[2].children[0].children.map(row=>[row.children[0].textContent,row.children[1].textContent]))
}))}
const germanCards=cards(app);
assert.equal(germanCards.length,5);
assert.equal(germanCards[0].fields[catalogue.Voltage],'14,400 V');
assert.equal(germanCards[0].fields[catalogue.Temperature],catalogue.Unavailable);
assert.equal(germanCards[1].status,catalogue['Last submission failed']+' · '+catalogue.Age+' 101 ms');
app.context.bridgeI18n.setLanguage('en');
assert.deepEqual(cards(app),[
  {title:'PGN 127508 · Instance 0',status:'Last submission accepted · Age 100 ms',fields:{'Sequence ID':'7',Voltage:'14.400 V',Current:'5.000 A',Temperature:'Unavailable'}},
  {title:'PGN 127508 · Instance 1',status:'Last submission failed · Age 101 ms',fields:{'Sequence ID':'8',Voltage:'13.300 V',Current:'6.000 A',Temperature:'Unavailable'}},
  {title:'PGN 127507 · Instance 0',status:'Last submission accepted · Age 102 ms',fields:{'Battery instance':'0','Charge state (code)':'1','Charger mode (code)':'0','Enabled (code)':'1','Equalization pending (code)':'Unavailable','Equalization time remaining':'Unavailable'}},
  {title:'PGN 127506 · Instance 0',status:'Last submission accepted · Age 3000 ms',fields:{'Sequence ID':'9','DC type (code)':'0','State of charge':'Unavailable','State of health':'Unavailable','Time remaining':'Unavailable','Ripple voltage':'Unavailable',Capacity:'Unavailable'}},
  {title:'PGN 127506 · Instance 1',status:'Not submitted yet',fields:{'Sequence ID':'Unavailable','DC type (code)':'Unavailable','State of charge':'Unavailable','State of health':'Unavailable','Time remaining':'Unavailable','Ripple voltage':'Unavailable',Capacity:'Unavailable'}}
]);
app.context.bridgeI18n.setLanguage('de');assert.deepEqual(cards(app),germanCards);
// Browser disconnection clears both counter groups and retained submission cards.
app.setMode('fail');await app.ids.refresh.onclick();
for(const id of [...Object.keys(expectedOrion),'freshness'])assert.equal(app.ids[id].textContent,'—',id);
for(const id of ['orion-status','monitor-orion-status','nmea-status']){assert.equal(app.ids[id].textContent,catalogue.Unavailable,id);assert.equal(app.ids[id].dataset.severity,'neutral',id)}
assert.equal(app.ids['nmea-parameters'].children.length,1);
assert.equal(app.ids['nmea-parameters'].textContent,catalogue['No NMEA submission data available.']);
// Stale Orion values arrive as null, while the last NMEA submission remains visible.
const missingOrion={outV:null,outI:null,inV:null,inI:null,outW:null,inW:null,state:null,error:null,offReason:null,rssi:null};
app=start({live:{...missingOrion,fresh:false,status:'Stale',age:12001}});await flush();
for(const id of ['out-v','out-i','in-v','in-i','monitor-out-v','monitor-out-i','monitor-in-v','monitor-in-i','out-w','in-w','overview-out-w','overview-in-w','charger-state','charger-error','off-reason','rssi'])assert.equal(app.ids[id].textContent,'—',id);
assert.equal(app.ids.freshness.textContent,catalogue.Stale);
assert.equal(app.ids['ble-age'].textContent,'12001');assert.equal(app.ids['frame-counter'].textContent,'65535');
assert.equal(cards(app)[0].fields[catalogue.Voltage],'14,400 V');
app=start({live:{...missingOrion,received:false,fresh:false,age:null,counter:null,rx:0,tx:0,orionErrors:0,nmeaErrors:0,nmea:[]}});await flush();
assert.equal(app.ids.freshness.textContent,catalogue['Waiting for data']);
for(const id of ['ble-age','frame-counter'])assert.equal(app.ids[id].textContent,'—',id);
for(const id of ['monitor-rx','monitor-tx','orion-errors','nmea-errors'])assert.equal(app.ids[id].textContent,'0',id);
// Future available NMEA fields use the same locale and three-decimal convention.
const available=structuredClone(nmeaFixture);
available[0].fields={sid:0,voltage:-1.23,current:0,temperature:273.15};
available[2].fields.equalizationTimeRemaining=60;
Object.assign(available[3].fields,{soc:75,soh:98,timeRemaining:3600,rippleVoltage:0.123,capacity:180000});
app=start({preferences:{bridgeLanguage:'en'},live:{nmea:available}});await flush();
assert.deepEqual(cards(app)[0].fields,{'Sequence ID':'0',Voltage:'-1.230 V',Current:'0.000 A',Temperature:'273.150 K'});
assert.equal(cards(app)[2].fields['Equalization time remaining'],'60.000 s');
assert.deepEqual(cards(app)[3].fields,{'Sequence ID':'9','DC type (code)':'0','State of charge':'75.000 %','State of health':'98.000 %','Time remaining':'3600.000 s','Ripple voltage':'0.123 V',Capacity:'180000.000 C'});
// MAC entry accepts typing and pasted common formats without losing information.
const mac=app.ids['orion-mac'];
assert.ok(mac,'MAC input must have a stable accessible control');
function inputMac(value,start=value.length,end=start){mac.value=value;mac.setSelectionRange(start,end);mac.listeners.input()}
inputMac('');
for(const digit of 'aabb01cd23ef'){
  const position=mac.selectionStart;
  inputMac(mac.value.slice(0,position)+digit+mac.value.slice(mac.selectionEnd),position+1);
}
assert.equal(mac.value,'AA:BB:01:CD:23:EF');assert.equal(mac.selectionStart,17);
for(const pasted of ['aabb01cd23ef','aa:bb:01:cd:23:ef','aa-bb-01-cd-23-ef',' aa bb 01 cd 23 ef\r\n']){
  inputMac(pasted);assert.equal(mac.value,'AA:BB:01:CD:23:EF',pasted);assert.equal(mac.selectionStart,17);
}
inputMac('12ab34',4);assert.equal(mac.value,'12:AB:34');assert.equal(mac.selectionStart,5);
function press(key,start,end=start){mac.setSelectionRange(start,end);let prevented=false;mac.listeners.keydown({key,preventDefault(){prevented=true}});return prevented}
inputMac('AA:BB:CC');assert.equal(press('Backspace',3),true);assert.equal(mac.value,'AB:BC:C');assert.equal(mac.selectionStart,1);
inputMac('AA:BB:CC');assert.equal(press('Delete',2),true);assert.equal(mac.value,'AA:BC:C');assert.equal(mac.selectionStart,2);
inputMac('AA:BB:CC');assert.equal(press('Backspace',0),false);assert.equal(mac.value,'AA:BB:CC');
assert.equal(press('Backspace',0,3),false);assert.equal(mac.value,'AA:BB:CC');
inputMac('aabb01cd23eff');assert.equal(mac.value,'aabb01cd23eff');
inputMac('aa:bb:01:cd:23:eg');assert.equal(mac.value,'aa:bb:01:cd:23:eg');
inputMac('aa.bb.01.cd.23.ef');assert.equal(mac.value,'aa.bb.01.cd.23.ef');
inputMac('');assert.equal(mac.value,'');assert.equal(mac.selectionStart,0);
// Missing/partial/invalid credentials must be visible immediately and block saving.
app=start();await flush();
const formMac=app.ids['orion-mac'],key=app.ids['orion-key'];
const macNote=app.ids['mac-feedback'],keyNote=app.ids['key-feedback'];
assert.equal(app.save.disabled,true);
assert.equal(keyNote.hidden,true);assert.equal(key.dataset.validity,'neutral');
assert.equal(key.getAttribute('aria-invalid'),'false');assert.ok(key.validation);
assert.equal(macNote.hidden,true);assert.ok(formMac.validation);
const keyTag=html.match(/<input\b[^>]*\bid="orion-key"[^>]*>/)[0];
assert.doesNotMatch(keyTag,/\bmaxlength=/,'Overlong pasted keys must remain visible for validation');
function inputField(input,value,start=value.length,end=start){input.value=value;input.setSelectionRange(start,end);input.listeners.input()}
function submit(){let prevented=false;app.form.listeners.submit({preventDefault(){prevented=true}});return prevented}
key.listeners.blur();assert.equal(keyNote.hidden,false);assert.equal(key.dataset.validity,'error');
assert.equal(keyNote.textContent,catalogue['Enter the 32-character Instant Readout key.']);
inputField(formMac,'AB:CD:EFghijklmnop');
assert.equal(formMac.value,'AB:CD:EFghijklmnop');assert.equal(formMac.dataset.validity,'error');
assert.equal(formMac.getAttribute('aria-invalid'),'true');assert.equal(macNote.hidden,false);
assert.equal(macNote.textContent,catalogue['Use only hexadecimal characters (0–9 and A–F).']);
assert.equal(app.save.disabled,true);assert.equal(submit(),true);assert.equal(formMac.focused,true);
inputField(formMac,'AABB01');assert.equal(formMac.value,'AA:BB:01');
assert.equal(formMac.dataset.validity,'warn');assert.ok(formMac.validation);assert.ok(macNote.textContent.includes('6'));
formMac.listeners.blur();assert.equal(formMac.dataset.validity,'error');
inputField(formMac,'AABB01CD23EFF');assert.equal(formMac.value,'AABB01CD23EFF');assert.equal(formMac.dataset.validity,'error');
inputField(formMac,'AABB01CD23EF');assert.equal(formMac.value,'AA:BB:01:CD:23:EF');
assert.equal(formMac.validation,'');assert.equal(formMac.dataset.validity,'ok');assert.equal(app.save.disabled,true);
inputField(formMac,'aabb01',2,4);assert.equal(formMac.selectionStart,2);assert.equal(formMac.selectionEnd,5);
inputField(formMac,'AABB01CD23EF');
inputField(key,'0123456789abcdef');assert.equal(key.dataset.validity,'warn');assert.ok(keyNote.textContent.includes('16'));
assert.equal(key.getAttribute('aria-invalid'),'true');assert.equal(app.save.disabled,true);assert.ok(key.validation);
const partialKey=key.value,partialCaret=key.selectionStart;
app.context.bridgeI18n.setLanguage('en');
assert.equal(keyNote.textContent,'Key incomplete: 16 of 32 hexadecimal characters.');
assert.equal(key.value,partialKey);assert.equal(key.selectionStart,partialCaret);assert.equal(app.save.disabled,true);
key.listeners.blur();assert.equal(key.dataset.validity,'error');
for(const invalid of ['gggggggggggggggggggggggggggggggg','0'.repeat(33),'0123456789abcdef 0123456789abcdef',' '+ '0'.repeat(32)+' ']){
  inputField(key,invalid);assert.equal(key.value,invalid);assert.equal(key.dataset.validity,'error',invalid);
  assert.equal(app.save.disabled,true);assert.equal(submit(),true);
}
inputField(key,'0123456789aBcDeF0123456789AbCdEf');
assert.equal(key.validation,'');assert.equal(key.dataset.validity,'ok');assert.equal(keyNote.textContent,'Readout key complete.');
assert.equal(key.getAttribute('aria-invalid'),'false');assert.equal(app.save.disabled,false);
assert.ok(!keyNote.textContent.includes(key.value));
for(const invalid of ['','-1','253','1.5','1e2','NaN']){
  inputField(app.form.elements.out,invalid);
  assert.ok(app.form.elements.out.validation,invalid);assert.equal(app.save.disabled,true,invalid);
}
inputField(app.form.elements.out,'252');assert.equal(app.form.elements.out.validation,'');assert.equal(app.save.disabled,false);
inputField(app.form.elements.in,'252');
for(const name of ['in','out'])assert.ok(app.form.elements[name].validation,'Both equal instances must show feedback');
assert.equal(app.ids['input-feedback'].hidden,false);assert.equal(app.ids['output-feedback'].hidden,false);assert.equal(app.save.disabled,true);
inputField(app.form.elements.in,'0');assert.equal(app.save.disabled,false);
app.context.bridgeI18n.setLanguage('de');
assert.equal(macNote.textContent,catalogue['MAC address complete.']);assert.equal(keyNote.textContent,catalogue['Readout key complete.']);
assert.equal(submit(),false);assert.equal(app.save.disabled,true);assert.equal(app.save.textContent,catalogue['Saving settings…']);
app.context.bridgeI18n.setLanguage('en');assert.equal(app.save.disabled,true);assert.equal(app.save.textContent,'Saving settings…');
// Returning users land on Overview and see settings instead of first setup calls.
app=start({configured:true});await flush();
assert.equal(app.ids['panel-overview'].hidden,false);assert.equal(app.ids['setup-cta'].hidden,true);
assert.equal(app.ids['setup-nav-label'].textContent,catalogue.Settings);
assert.equal(app.ids['setup-title'].textContent,catalogue['Orion settings.']);
assert.equal(app.ids['orion-mac'].value,'AA:BB:CC:DD:EE:FF');assert.equal(app.save.disabled,false);
const savedKey=app.ids['orion-key'],savedKeyNote=app.ids['key-feedback'];
assert.equal(savedKey.value,'','The stored key is never populated into the input');
assert.equal(savedKey.placeholder,'****************');assert.equal(savedKey.required,false);
assert.equal(savedKey.dataset.keyStored,'1');assert.equal(savedKey.dataset.validity,'ok');
assert.equal(savedKeyNote.dataset.validity,'ok');assert.equal(savedKeyNote.hidden,false);
assert.equal(savedKeyNote.textContent,'Schlüssel vorhanden');
assert.doesNotMatch(keyTag,/\bvalue=/,'The HTML must never contain a stored key or mask value');
assert.match(keyTag,/data-key-present="0"/,'Only the presence flag is rendered');
app.context.bridgeI18n.setLanguage('en');assert.equal(app.ids['setup-nav-label'].textContent,'Settings');
assert.equal(app.ids['setup-title'].textContent,'Orion settings.');assert.equal(app.ids['setup-cta'].hidden,true);
assert.equal(savedKeyNote.textContent,'Key present');assert.equal(savedKey.placeholder,'****************');
// Editing or clearing a replacement never treats mask characters as a secret.
inputField(savedKey,'****************');assert.equal(savedKey.dataset.validity,'error');assert.equal(app.save.disabled,true);
inputField(savedKey,'0123456789abcdef');assert.equal(savedKey.dataset.validity,'warn');assert.equal(app.save.disabled,true);
inputField(savedKey,'');assert.equal(savedKeyNote.textContent,'Key present');assert.equal(app.save.disabled,false);
inputField(app.ids['orion-mac'],'aa-bb-cc-dd-ee-00');
assert.equal(savedKey.required,true);assert.equal(savedKey.dataset.keyStored,'0');
assert.equal(savedKey.placeholder,'32 hexadecimal characters');assert.equal(app.save.disabled,true);
assert.equal(savedKeyNote.textContent,'Enter the readout key for the new Orion.');
inputField(savedKey,'0123456789abcdef0123456789abcdef');
assert.equal(app.save.disabled,false);assert.equal(savedKeyNote.textContent,'Readout key complete.');
inputField(savedKey,'');assert.equal(app.save.disabled,true);
inputField(app.ids['orion-mac'],'aa bb cc dd ee ff');
assert.equal(savedKeyNote.textContent,'Key present');assert.equal(savedKey.required,false);assert.equal(app.save.disabled,false);
app.context.bridgeI18n.setLanguage('de');assert.equal(savedKeyNote.textContent,'Schlüssel vorhanden');
let savedKeySubmitPrevented=false;
app.form.listeners.submit({preventDefault(){savedKeySubmitPrevented=true}});
assert.equal(savedKeySubmitPrevented,false);assert.equal(savedKey.value,'');
assert.equal(app.save.disabled,true,'Unchanged stored key may save settings and is sent as an empty value');
app=start();await flush();assert.equal(app.ids['setup-cta'].hidden,false);
assert.equal(app.ids['setup-nav-label'].textContent,catalogue.Setup);
assert.equal(app.ids['setup-title'].textContent,catalogue['Connect your Orion.']);
// Status colors describe current issues, missing information and previous failures.
const healthyRecords=nmeaFixture.map(record=>({...structuredClone(record),accepted:true,age:100}));
const healthy={offReason:0,orionErrors:0,rejected:0,dropped:0,orionStartupFailed:0,nmeaErrors:0,txFailed:0,nmea:healthyRecords};
async function health(changes={}){const result=start({live:{...healthy,...changes}});await flush();return result}
app=await health({duplicates:99999});
for(const id of ['orion-status','monitor-orion-status','nmea-status','connection'])assert.equal(app.ids[id].dataset.severity,'ok',id);
assert.equal(app.ids.connection.textContent,catalogue['Bridge ready']);
assert.equal(app.ids['overview-out-w'].textContent,'72,000');assert.equal(app.ids['overview-in-w'].textContent,'79,800');
for(const changes of [{outV:null},{error:255},{state:255},{offReason:4},{fresh:false,status:'Stale'},{orionErrors:1,rejected:1}]){
  app=await health(changes);assert.equal(app.ids['orion-status'].dataset.severity,'warn',JSON.stringify(changes));
  assert.notEqual(app.ids.connection.dataset.severity,'ok');
}
for(const changes of [{error:2},{status:'Encryption key mismatch'},{status:'BLE scan failed'}]){
  app=await health(changes);assert.equal(app.ids['orion-status'].dataset.severity,'error',JSON.stringify(changes));
  assert.equal(app.ids.connection.dataset.severity,'error');
}
function alteredRecord(index,changes){return healthyRecords.map((record,i)=>({...structuredClone(record),...(i===index?changes:{})}))}
app=await health({nmea:alteredRecord(0,{accepted:false})});assert.equal(app.ids['nmea-status'].dataset.severity,'error');
assert.equal(app.ids['nmea-parameters'].children[0].children[1].dataset.severity,'error');
for(const nmea of [[],alteredRecord(0,{accepted:null,age:null}),alteredRecord(0,{age:3501}),alteredRecord(3,{age:15001}),alteredRecord(0,{accepted:false,age:4000})]){
  app=await health({nmea});assert.equal(app.ids['nmea-status'].dataset.severity,'warn',JSON.stringify(nmea));
  assert.notEqual(app.ids.connection.dataset.severity,'ok');
}
app=await health({nmeaErrors:1,txFailed:1});assert.equal(app.ids['nmea-status'].dataset.severity,'warn');
assert.equal(app.ids['nmea-status'].textContent,catalogue['Submissions accepted; earlier errors recorded']);
app=await health({fresh:false,status:'Stale',nmeaErrors:1,txFailed:1,nmea:alteredRecord(2,{accepted:false})});
assert.equal(app.ids['nmea-status'].dataset.severity,'warn','A charger PGN that is not due must not imply a current NMEA failure');
assert.equal(app.ids['nmea-status'].textContent,catalogue['Submissions accepted; earlier errors recorded']);
app=await health({events:[
  {seq:1,ms:1,type:'BLE',detail:'Encryption key mismatch'},
  {seq:2,ms:2,type:'NMEA',detail:'PGN 127508 x2; accepted 1, failed 1'},
  {seq:3,ms:3,type:'BLE',detail:'Orion state 3, output NA V 35.200 A'},
  {seq:4,ms:4,type:'NMEA',detail:'PGN 127508 x2; accepted 2, failed 0; values unavailable'},
  {seq:5,ms:5,type:'BLE',detail:'Orion state 3, output 14.400 V 5.000 A'},
  {seq:6,ms:6,type:'NMEA',detail:'PGN 127508 x2; accepted 2, failed 0'}
]});
assert.deepEqual(app.ids.events.children.map(line=>line.dataset.severity),['error','error','warn','warn','ok','ok']);
// Alias editing is independent of credentials and follows the firmware's Unicode rules.
app=start();await flush();
const inputAlias=app.ids['input-alias'],outputAlias=app.ids['output-alias'];
assert.equal(inputAlias.value,'Startbatterie');assert.equal(outputAlias.value,'Bugbatterie');
assert.equal(app.ids['orion-key'].value,'');assert.equal(app.save.disabled,true);assert.equal(app.aliasSave.disabled,false);
const aliasMarkup=html.match(/<form\b[^>]*\bid="aliases-form"[^>]*>[\s\S]*?<\/form>/)[0];
assert.match(aliasMarkup,/action="\/aliases"/);assert.doesNotMatch(aliasMarkup,/name="(?:key|password|mac)"/);
for(const id of ['input-alias','output-alias']){
  const tag=html.match(new RegExp('<input\\b[^>]*\\bid="'+id+'"[^>]*>'))[0];
  assert.doesNotMatch(tag,/\bmaxlength="32"/,'A 32-codepoint alias may use more than 32 UTF-16 units');
}
for(const id of ['input-alias-label','output-alias-label']){
  const tag=html.match(new RegExp('<span\\b[^>]*\\bid="'+id+'"[^>]*>'))[0];
  assert.doesNotMatch(tag,/\bdata-i18n\b/,'Saved aliases must not be translated');
}
function submitAliases(){let prevented=false;app.aliasForm.listeners.submit({preventDefault(){prevented=true}});return prevented}
for(const pair of [['Startbatterie','  STARTBATTERIE\t'],['ÄÖÜ Batterie','äöü batterie'],['Groẞbatterie','großbatterie']]){
  inputField(inputAlias,pair[0]);inputField(outputAlias,pair[1]);
  assert.equal(app.aliasSave.disabled,true,pair.join(' / '));
  for(const input of [inputAlias,outputAlias]){assert.equal(input.dataset.validity,'error');assert.equal(input.getAttribute('aria-invalid'),'true');assert.ok(input.validation)}
  assert.equal(submitAliases(),true);
}
assert.equal(inputAlias.focused,true);
inputField(outputAlias,'Bugbatterie');
for(const invalid of ['', ' \t\r\n ', 'a'.repeat(33), '🚤'.repeat(33), 'Bat\u0000terie', 'Bat\u001Fterie', 'Bat\u007Fterie', 'Bat\u0085terie', 'Bat\u009Fterie', 'Bat\u2028terie', 'Bat\u2029terie']){
  inputField(inputAlias,invalid);assert.equal(inputAlias.value,invalid);assert.equal(inputAlias.dataset.validity,'error',JSON.stringify(invalid));
  assert.equal(app.aliasSave.disabled,true);assert.equal(submitAliases(),true);
}
for(const valid of ['A','🚤','a'.repeat(32),'🚤'.repeat(32),'Äußere Batterie ⚓']){
  inputField(inputAlias,valid);assert.equal(inputAlias.validation,'',valid);assert.equal(inputAlias.dataset.validity,'ok');assert.equal(app.aliasSave.disabled,false);
}
inputField(inputAlias,'É');inputField(outputAlias,'é');
assert.equal(app.aliasSave.disabled,false,'Only the agreed ASCII/German characters participate in case folding');
inputField(inputAlias,' Startbatterie\t');inputField(outputAlias,'STARTBATTERIE');
assert.equal(app.aliasSave.disabled,true);
app.context.bridgeI18n.setLanguage('en');
assert.equal(app.ids['input-alias-feedback'].textContent,'Choose different aliases for input and output.');
assert.equal(inputAlias.value,' Startbatterie\t');assert.equal(outputAlias.value,'STARTBATTERIE');
assert.equal(app.ids['input-alias-label'].textContent,'Startbatterie');assert.equal(app.ids['output-alias-label'].textContent,'Bugbatterie');
inputField(inputAlias,' \tÄußere Batterie 🚤\r\n');inputField(outputAlias,'\u00A0Bugbatterie\u00A0');
assert.equal(app.aliasSave.disabled,false);
assert.equal(submitAliases(),false);
assert.equal(inputAlias.value,'Äußere Batterie 🚤');assert.equal(outputAlias.value,'\u00A0Bugbatterie\u00A0','Unicode spaces must not be silently trimmed');
assert.equal(app.ids['orion-key'].value,'');assert.equal(app.aliasSave.disabled,true);assert.equal(app.aliasSave.textContent,'Saving aliases…');
app.context.bridgeI18n.setLanguage('de');assert.equal(app.aliasSave.disabled,true);assert.equal(app.aliasSave.textContent,catalogue['Saving aliases…']);
assert.equal(app.ids['input-alias-label'].textContent,'Startbatterie');assert.equal(app.ids['output-alias-label'].textContent,'Bugbatterie');
// Password changes use the server's UTF-8 byte range, retain literal spaces,
// drain the single HTTPS slot, and cannot overlap OTA or duplicate submissions.
app=start();await flush();
const passwordForm=app.ids['password-form'],passwordSave=app.ids['password-save'];
const currentPassword=app.ids['current-password'],nextPassword=app.ids['new-password'],confirmPassword=app.ids['confirm-password'];
const passwordMarkup=html.match(/<form\b[^>]*\bid="password-form"[^>]*>[\s\S]*?<\/form>/)[0];
assert.match(passwordMarkup,/action="\/password"/);assert.match(passwordMarkup,/name="csrf"/);
for(const name of ['current_password','new_password','confirm_password'])assert.match(passwordMarkup,new RegExp(`name="${name}"`));
assert.doesNotMatch(passwordMarkup,/\b(?:minlength|maxlength|value="[^\"]+")(?=[^>]*type="password")/);
let nativeSubmissions=0;passwordForm.submit=()=>nativeSubmissions++;
async function submitPassword(){let prevented=false;await passwordForm.listeners.submit({preventDefault(){prevented=true}});assert.equal(prevented,true)}
assert.equal(passwordSave.disabled,true);
await submitPassword();assert.equal(nativeSubmissions,0);assert.equal(currentPassword.focused,true);
inputField(currentPassword,'  existing password  ');
for(const invalid of ['', 'x'.repeat(11), 'x'.repeat(129), 'é'.repeat(65), '🚤'.repeat(33)]){
  inputField(nextPassword,invalid);inputField(confirmPassword,invalid);
  assert.equal(passwordSave.disabled,true,JSON.stringify(invalid));await submitPassword();assert.equal(nativeSubmissions,0);
}
for(const valid of ['x'.repeat(12), 'x'.repeat(128), 'é'.repeat(6), '🚤'.repeat(32), '  keep spaces  ']){
  inputField(nextPassword,valid);inputField(confirmPassword,valid);assert.equal(passwordSave.disabled,false,valid);
}
inputField(confirmPassword,'different password');assert.equal(passwordSave.disabled,true);await submitPassword();assert.equal(nativeSubmissions,0);
assert.equal(confirmPassword.getAttribute('aria-invalid'),'true');
app.context.bridgeI18n.setLanguage('en');assert.equal(app.ids['confirm-password-feedback'].textContent,'Enter the same new password in both fields.');
inputField(confirmPassword,nextPassword.value);
for(const busyFlag of ['bridgeOtaBusy','bridgeFirmwareLoading','bridgeFirmwarePicking']){
  app.context[busyFlag]=true;await submitPassword();assert.equal(nativeSubmissions,0,busyFlag);
  assert.equal(app.ids['password-status'].textContent,'Wait for the firmware operation to finish, then try again.');
  app.context[busyFlag]=false;
}
let releaseLive;app.context.bridgePauseLive=()=>new Promise(resolve=>{releaseLive=resolve});
const originalCurrent=currentPassword.value,originalNext=nextPassword.value;
const passwordPending=submitPassword();await flush();
assert.equal(nativeSubmissions,0,'Native password POST waits for live polling to drain');
assert.equal(app.context.bridgeAccountSaving,true);assert.equal(passwordSave.disabled,true);
assert.equal(currentPassword.readOnly,true);assert.equal(nextPassword.readOnly,true);
await submitPassword();assert.equal(nativeSubmissions,0,'Duplicate submission does not queue another POST');
const passwordCalls=app.calls();await app.ids.refresh.onclick();app.documentListeners.visibilitychange();assert.equal(app.calls(),passwordCalls);
app.context.bridgeI18n.setLanguage('de');assert.equal(passwordSave.disabled,true);assert.equal(app.save.disabled,true);assert.equal(app.aliasSave.disabled,true);
let otherFormBlocked=false;app.documentListeners.submit({preventDefault(){otherFormBlocked=true},stopImmediatePropagation(){}});assert.equal(otherFormBlocked,true);
releaseLive();await passwordPending;assert.equal(nativeSubmissions,1);
assert.equal(currentPassword.value,originalCurrent);assert.equal(nextPassword.value,originalNext);assert.equal(confirmPassword.value,originalNext);
assert.equal(app.ids['password-status'].textContent,catalogue['Changing the password can take a few seconds. Keep this page open.']);
assert.match(page('login'),/href="\/recover"/);
const recovery=page('recovery');assert.match(recovery,/method="post" action="\/recover"/);assert.match(recovery,/name="csrf" value="test-recovery-token"/);
assert.match(recovery,/type="checkbox" name="confirm_reset" value="yes" required/);
assert.match(recovery,/docs\/erstverbindung\.md/);assert.match(recovery,/BOOT/);
assert.match(page('account'),/href="\/"[^>]*><span data-i18n>Sign in<\/span>/);
console.log('PASS: German/English catalogue, persistence and switching; page syntax, storage fallback, navigation and guide; inline MAC/key/instance validation, save blocking, caret-safe formatting and secret preservation; independent Unicode aliases, duplicate detection and trimmed submission; password UTF-8 boundaries, confirmation, unchanged spaces, recovery/success pages and exclusive native submission; configured navigation and powers; Orion/NMEA status severity and event colors; all parameters, precision, unavailable and stale data, split counters, submission age/failures; offline clearing, session expiry, timeout and non-overlapping polling');
