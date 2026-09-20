import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
// Lightweight DOM simulation: validates behavior, not browser rendering.
const read=name=>fs.readFileSync(new URL('../src/'+name,import.meta.url),'utf8');
const source=read('BridgePortalUi.h');
const templates=Object.fromEntries([...source.matchAll(/inline constexpr char (k\w+)\[\] = R"UI\(([\s\S]*?)\)UI";/g)].map(m=>[m[1],m[2]]));
const translationHtml=read('BridgePortalTranslations.h').match(/R"I18N\(([\s\S]*?)\)I18N"/)[1];
const languageHtml=read('BridgePortalLanguage.h').match(/R"I18N\(([\s\S]*?)\)I18N"/)[1];
const scripts=html=>[...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(m=>m[1]);
const catalogueContext={window:{}};vm.runInNewContext(scripts(translationHtml)[0],catalogueContext);
const catalogue=catalogueContext.window.bridgeGerman;
const texts=[...source.matchAll(/<(?:span|label)[^>]*data-i18n(?:>| [^>]*>)([^<]+)<\/(?:span|label)>/g)].map(m=>m[1]).filter(t=>!t.startsWith('{{'));
const attributes=[...source.matchAll(/<(?:input|button|nav|select)[^>]*data-i18n-attr="[^"]+"[^>]*>/g)].flatMap(m=>[...m[0].matchAll(/(?:placeholder|title|aria-label)="([^"]+)"/g)].map(a=>a[1]));
for(const text of [...texts,...attributes])assert.ok(catalogue[text],`Missing translation: ${text}`);
for(const match of read('BridgePortal.cpp').matchAll(/ui::kMessageBody, "([^"]+)",\s*"([^"]+)"/g))for(const text of match.slice(1))assert.ok(catalogue[text],`Missing server error translation: ${text}`);
const pages={login:'kLoginBody','first-setup':'kFirstSetupBody',dashboard:'kDashboardBody',message:'kMessageBody',restart:'kRestartBody'};
function page(name){
  let html=templates.kDocumentStart+translationHtml+languageHtml+templates[pages[name]]+'<script>bridgeI18n.apply();</script></body></html>';
  const values={BRAND:templates.kBrand,CSRF:'test-token',CONFIGURED:'0',MAC:'',OUT_INSTANCE:'0',IN_INSTANCE:'1',MESSAGE_TITLE:'Check account details',MESSAGE_TEXT:'Use a 3–32 character username and a password of at least 12 characters.'};
  return html.replace(/\{\{(\w+)\}\}/g,(_,key)=>values[key]);
}
for(const name of ['login','first-setup','dashboard','message','restart']){
  const html=page(name);
  for(const match of html.matchAll(/<script>([\s\S]*?)<\/script>/g))new vm.Script(match[1]);
}
const html=page('dashboard');
const script=scripts(html).join('\n');
function element(){return {hidden:true,dataset:{},style:{},textContent:'',value:'',listeners:{},getAttribute(k){return this[k]},setAttribute(k,v){this[k]=v},addEventListener(k,v){this.listeners[k]=v},setCustomValidity(v){this.validation=v}}}
function start({storageBlocked=false,stored={},preferences={},mode='ok'}={}){
  const ids=Object.fromEntries([...html.matchAll(/\bid="([^"]+)"/g)].map(m=>[m[1],element()]));
  const names=['overview','setup','guide','monitor'];
  const nav=names.map(name=>Object.assign(element(),{dataset:{panelButton:name}}));
  const steps=Array.from({length:4},element);
  const form=ids['orion-form'];form.elements={in:element(),out:element()};form.elements.in.value='1';form.elements.out.value='0';const save=element();form.querySelector=()=>save;
  const staticNodes=[...texts,...Object.keys(catalogue)].map(text=>Object.assign(element(),{textContent:text}));
  const placeholder=Object.assign(element(),{placeholder:'32 hexadecimal characters',dataset:{i18nAttr:'placeholder'},value:'typed-secret-for-test'});
  const listeners={};
  const storage=values=>({getItem(key){if(storageBlocked)throw Error('blocked');return values[key]??null},setItem(key,val){if(storageBlocked)throw Error('blocked');values[key]=val}});
  const sessionStorage=storage(stored),localStorage=storage(preferences);
  const timers=new Map();let nextTimer=0,calls=0,pending;
  const data={outV:14.4,outI:5,inV:13.3,inI:6,outW:72,inW:79.8,state:3,error:0,offReason:0,rssi:-50,age:200,status:'Receiving',rx:9,tx:10,rejected:0,txFailed:0,events:[{seq:1,ms:100,type:'BLE',detail:'First'},{seq:2,ms:200,type:'BLE',detail:'Second'}]};
  const context=vm.createContext({
    document:{hidden:false,documentElement:{lang:'de'},getElementById(id){assert.ok(ids[id],id);return ids[id]},querySelector(sel){if(sel==='.app-shell')return {dataset:{configured:'0'}};const n=sel.match(/data-panel-button="(.*?)"/);if(n)return nav[names.indexOf(n[1])];throw Error(sel)},querySelectorAll(sel){if(sel==='[data-guide-step]')return steps;if(sel==='[data-i18n]')return staticNodes;if(sel==='[data-i18n-attr]')return [placeholder];if(sel==='[data-busy-key]')return [];return nav},addEventListener(){}},
    scrollTo(){},matchMedia(){return {matches:false}},addEventListener(name,fn){listeners[name]=fn},dispatchEvent(event){listeners[event.type]?.()},Event,
    sessionStorage,localStorage,
    setTimeout(fn,ms){timers.set(++nextTimer,{fn,ms});return nextTimer},clearTimeout(id){timers.delete(id)},AbortController,
    fetch:async(url,options)=>{calls++;if(mode==='pending')return new Promise((resolve,reject)=>{pending={resolve,reject};options.signal.addEventListener('abort',()=>reject(Error('aborted'))) });if(mode==='fail')throw Error('offline');return {status:mode==='expired'?401:200,ok:mode!=='expired',json:async()=>data}}
  });
  context.window=context;
  vm.runInContext(script,context);
  return {ids,nav,steps,form,save,timers,context,stored,preferences,staticNodes,placeholder,calls:()=>calls,setMode(v){mode=v},pending:()=>pending};
}
const flush=()=>new Promise(resolve=>setImmediate(resolve));
let app=start({storageBlocked:true});await flush();
assert.equal(app.ids['panel-guide'].hidden,false);assert.equal(app.ids['out-v'].textContent,'14,40');
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
// Language changes preserve input, active step, raw event values and polling state.
app=start();await flush();
assert.equal(app.context.bridgeI18n.language,'de');
assert.equal(app.context.document.documentElement.lang,'de');
assert.equal(app.placeholder.placeholder,catalogue['32 hexadecimal characters']);
app.nav[1].listeners.click();app.ids['step-next'].onclick();
const before=app.calls();app.context.bridgeI18n.setLanguage('en');
assert.equal(app.ids['out-v'].textContent,'14.40');
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
const reload=start({preferences:{bridgeLanguage:'en'}});await flush();
assert.equal(reload.ids['out-v'].textContent,'14.40');assert.equal(reload.context.document.documentElement.lang,'en');
assert.equal(start({preferences:{bridgeLanguage:'xx'}}).context.bridgeI18n.language,'de');
assert.equal(start({stored:{bridgeLanguage:'en'}}).context.bridgeI18n.language,'en');
assert.equal(start({stored:{bridgeLanguage:'de'},preferences:{bridgeLanguage:'en'}}).context.bridgeI18n.language,'de');
console.log('PASS: German/English catalogue coverage, default, persistence, storage fallback, in-place switching, attributes, translated diagnostics; syntax, restricted storage, navigation, guide resume, instance validation, event newlines, offline values, session expiry, timeout and non-overlapping polling');
