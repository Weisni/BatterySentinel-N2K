#pragma once

// Browser-local language preference; no network request or flash write required.
namespace bs::ui {

inline constexpr char kLanguageController[] = R"I18N(<script>
window.bridgeI18n=(()=>{
  const key='bridgeLanguage';
  let language='de';
  // The current tab may have a newer choice if persistent writes were denied.
  for(const name of ['sessionStorage','localStorage']){
    try{const saved=window[name].getItem(key);if(saved==='de'||saved==='en'){language=saved;break}}catch(_){}
  }
  const originalText=new WeakMap(),originalAttributes=new WeakMap();
  function t(english,values={}){
    const text=language==='de'?(window.bridgeGerman[english]||english):english;
    return String(text).replace(/\{(\w+)\}/g,(match,name)=>Object.prototype.hasOwnProperty.call(values,name)?String(values[name]):match);
  }
  function apply(){
    document.documentElement.lang=language;
    document.getElementById('language-select').value=language;
    document.querySelectorAll('[data-i18n]').forEach(node=>{
      if(!originalText.has(node))originalText.set(node,node.textContent);
      node.textContent=t(originalText.get(node));
    });
    document.querySelectorAll('[data-i18n-attr]').forEach(node=>{
      if(!originalAttributes.has(node)){
        const attributes={};
        for(const name of node.dataset.i18nAttr.split(' '))attributes[name]=node.getAttribute(name);
        originalAttributes.set(node,attributes);
      }
      for(const [name,value] of Object.entries(originalAttributes.get(node)))node.setAttribute(name,t(value));
    });
    document.querySelectorAll('[data-busy-key]').forEach(node=>node.textContent=t(node.dataset.busyKey));
    window.dispatchEvent(new Event('bridge-language-change'));
  }
  function setLanguage(value){
    language=value==='en'?'en':'de';
    for(const name of ['localStorage','sessionStorage']){
      try{window[name].setItem(key,language)}catch(_){}
    }
    apply();
  }
  function busy(button,english){button.disabled=true;button.dataset.busyKey=english;button.textContent=t(english)}
  function eventText(english){
    const auth=/^Password verification (\d+) ms$/.exec(english);
    if(auth)return t('Password verification {ms} ms',{ms:auth[1]});
    const orion=/^Orion state (\d+), output (-?[\d.]+) V (-?[\d.]+) A$/.exec(english);
    if(orion)return t('Orion state {state}, output {voltage} V {current} A',{state:orion[1],voltage:orion[2],current:orion[3]});
    const nmea=/^PGN (.+); sent (\d+), failed (\d+)(; values unavailable)?$/.exec(english);
    if(nmea)return t('PGN {pgn}; sent {sent}, failed {failed}',{pgn:nmea[1],sent:nmea[2],failed:nmea[3]})+(nmea[4]?t('; values unavailable'):'');
    return t(english);
  }
  document.getElementById('language-select').addEventListener('change',event=>setLanguage(event.target.value));
  return {t,apply,setLanguage,busy,eventText,get language(){return language}};
})();
</script>)I18N";

} // namespace bs::ui
