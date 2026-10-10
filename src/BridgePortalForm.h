#pragma once

namespace bs::ui {

inline constexpr char kFormController[] = R"FORM(<script>
window.bridgeForm={init(form,tr){
  const byId=id=>document.getElementById(id);
  const inputs={mac:byId('orion-mac'),key:byId('orion-key'),input:form.elements.in,output:form.elements.out};
  const feedback={mac:byId('mac-feedback'),key:byId('key-feedback'),input:byId('input-feedback'),output:byId('output-feedback')};
  const save=byId('orion-save'),touched={},blurred={};
  const macIdentity=value=>value.replace(/[:\s-]/g,'').toUpperCase();
  const storedMac=macIdentity(inputs.mac.value),keyPresent=inputs.key.dataset.keyPresent==='1';
  // A stored key is represented only by a presence flag and a placeholder.
  // Its value remains empty, including when the form is submitted unchanged.
  const keepStoredKey=()=>keyPresent&&!inputs.key.value&&macIdentity(inputs.mac.value)===storedMac;
  let saving=false;
  for(const name of Object.keys(inputs)){touched[name]=Boolean(inputs[name].value);blurred[name]=false}

  function formatMac(){
    const input=inputs.mac,original=input.value;
    // Keep invalid characters and overlong pastes intact for visible feedback.
    if(!/^[0-9a-fA-F:\s-]*$/.test(original))return;
    const digits=original.replace(/[:\s-]/g,'').toUpperCase();
    if(digits.length>12)return;
    const position=caret=>{
      const count=original.slice(0,caret).replace(/[:\s-]/g,'').length;
      return Math.min(formatted.length,count+Math.floor(Math.max(0,count-1)/2));
    };
    const start=input.selectionStart??original.length,end=input.selectionEnd??start;
    const formatted=(digits.match(/.{1,2}/g)||[]).join(':');
    input.value=formatted;
    input.setSelectionRange(position(start),position(end));
  }

  function result(name){
    const value=inputs[name].value;
    if(name==='mac'){
      if(!value)return {message:'Enter the Orion Bluetooth MAC address.',empty:true};
      if(!/^[0-9a-fA-F:\s-]*$/.test(value))return {message:'Use only hexadecimal characters (0–9 and A–F).'};
      const count=value.replace(/[:\s-]/g,'').length;
      if(count>12)return {message:'The MAC address must contain exactly 12 hexadecimal characters.'};
      if(count<12)return {message:'MAC incomplete: {count} of 12 hexadecimal characters.',values:{count},partial:true};
      if(!/^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$/.test(value))return {message:'The MAC address must contain exactly 12 hexadecimal characters.'};
      return {valid:true,message:'MAC address complete.'};
    }
    if(name==='key'){
      if(keepStoredKey())return {valid:true,message:'Key present'};
      if(!value&&keyPresent)return {message:'Enter the readout key for the new Orion.'};
      if(!value)return {message:'Enter the 32-character Instant Readout key.',empty:true};
      if(!/^[0-9a-fA-F]+$/.test(value))return {message:'Use only hexadecimal characters (0–9 and A–F).'};
      if(value.length>32)return {message:'The readout key must contain exactly 32 hexadecimal characters.'};
      if(value.length<32)return {message:'Key incomplete: {count} of 32 hexadecimal characters.',values:{count:value.length},partial:true};
      return {valid:true,message:'Readout key complete.'};
    }
    if(!/^\d{1,3}$/.test(value)||Number(value)>252)return {message:'Enter an integer from 0 to 252.',empty:!value};
    const other=inputs[name==='input'?'output':'input'].value;
    if(/^\d{1,3}$/.test(other)&&Number(value)===Number(other))return {message:'Choose a different instance for input and output.'};
    return {valid:true,message:'Instance valid.'};
  }

  function refresh(){
    const stored=keepStoredKey();
    inputs.key.required=!stored;
    inputs.key.dataset.keyStored=stored?'1':'0';
    inputs.key.placeholder=stored?'****************':tr('32 hexadecimal characters');
    let valid=true;
    for(const name of Object.keys(inputs)){
      const input=inputs[name],note=feedback[name],state=result(name);
      const hidden=Boolean(state.empty&&!touched[name]);
      const appearance=hidden?'neutral':state.valid?'ok':state.partial&&!blurred[name]?'warn':'error';
      const message=tr(state.message,state.values);
      input.setCustomValidity(state.valid?'':message);
      input.setAttribute('aria-invalid',String(!state.valid&&!hidden));
      input.dataset.validity=note.dataset.validity=appearance;
      note.textContent=hidden?'':message;
      note.hidden=hidden;
      valid=Boolean(state.valid)&&valid;
    }
    save.disabled=saving||window.bridgeOtaBusy||window.bridgeAccountSaving||!valid;
    return valid;
  }

  for(const [name,input] of Object.entries(inputs)){
    input.addEventListener('input',()=>{
      touched[name]=true;blurred[name]=false;
      if(name==='mac')formatMac();
      refresh();
    });
    input.addEventListener('blur',()=>{touched[name]=blurred[name]=true;refresh()});
    input.addEventListener('invalid',()=>{touched[name]=blurred[name]=true;refresh()});
  }
  inputs.mac.addEventListener('keydown',event=>{
    const input=inputs.mac,start=input.selectionStart,end=input.selectionEnd;
    if(start!==end||!/^[0-9a-fA-F:]*$/.test(input.value))return;
    let remove=-1;
    if(event.key==='Backspace'&&start>0&&input.value[start-1]===':')remove=start-2;
    if(event.key==='Delete'&&input.value[start]===':')remove=start+1;
    if(remove<0||remove>=input.value.length)return;
    event.preventDefault();
    input.value=input.value.slice(0,remove)+input.value.slice(remove+1);
    input.setSelectionRange(remove,remove);
    touched.mac=true;blurred.mac=false;
    formatMac();refresh();
  });
  form.addEventListener('submit',event=>{
    for(const name of Object.keys(inputs))touched[name]=blurred[name]=true;
    if(!refresh()){
      event.preventDefault();
      Object.values(inputs).find(input=>input.getAttribute('aria-invalid')==='true')?.focus();
      return;
    }
    saving=true;
    bridgeI18n.busy(save,'Saving settings…');
  });
  formatMac();refresh();
  return {refreshLanguage:refresh};
},initAliases(form,tr){
  const byId=id=>document.getElementById(id);
  const inputs={input:byId('input-alias'),output:byId('output-alias')};
  const feedback={input:byId('input-alias-feedback'),output:byId('output-alias-feedback')};
  const save=byId('aliases-save');
  let saving=false;
  // Match the firmware's trim and case-fold rules without changing user text.
  const trim=value=>value.replace(/^[\u0009-\u000D\u0020]+|[\u0009-\u000D\u0020]+$/g,'');
  const fold=value=>value.replace(/[A-ZÄÖÜẞ]/g,character=>character.toLowerCase());
  function result(name){
    const value=trim(inputs[name].value);
    if(/[\u0000-\u001F\u007F-\u009F\u2028\u2029]/.test(value))return {message:'Aliases must not contain control characters.'};
    const length=Array.from(value).length;
    if(length<1||length>32)return {message:'Enter an alias with 1 to 32 characters.'};
    const other=trim(inputs[name==='input'?'output':'input'].value);
    if(fold(value)===fold(other))return {message:'Choose different aliases for input and output.'};
    return {valid:true,message:'Alias valid.'};
  }
  function refresh(){
    let valid=true;
    for(const name of Object.keys(inputs)){
      const input=inputs[name],note=feedback[name],state=result(name);
      const message=tr(state.message);
      input.setCustomValidity(state.valid?'':message);
      input.setAttribute('aria-invalid',String(!state.valid));
      input.dataset.validity=note.dataset.validity=state.valid?'ok':'error';
      note.textContent=message;note.hidden=false;
      valid=Boolean(state.valid)&&valid;
    }
    save.disabled=saving||window.bridgeOtaBusy||window.bridgeAccountSaving||!valid;
    return valid;
  }
  for(const input of Object.values(inputs)){
    input.addEventListener('input',refresh);
    input.addEventListener('blur',refresh);
    input.addEventListener('invalid',refresh);
  }
  form.addEventListener('submit',event=>{
    if(!refresh()){
      event.preventDefault();
      Object.values(inputs).find(input=>input.getAttribute('aria-invalid')==='true')?.focus();
      return;
    }
    for(const input of Object.values(inputs))input.value=trim(input.value);
    saving=true;
    bridgeI18n.busy(save,'Saving aliases…');
  });
  refresh();
  return {refreshLanguage:refresh};
},initPassword(form,tr){
  const byId=id=>document.getElementById(id);
  const inputs={current:byId('current-password'),next:byId('new-password'),confirm:byId('confirm-password')};
  const feedback={current:byId('current-password-feedback'),next:byId('new-password-feedback'),confirm:byId('confirm-password-feedback')};
  const save=byId('password-save'),status=byId('password-status'),touched={};
  const bytes=value=>new TextEncoder().encode(value).length;
  let saving=false,statusKey='';
  function result(name){
    const value=inputs[name].value;
    if(name==='current')return value?{valid:true}:{message:'Enter your current administrator password.'};
    if(name==='next')return bytes(value)>=12&&bytes(value)<=128?{valid:true}:{message:'Use 12–128 bytes for the new password.'};
    return value&&value===inputs.next.value?{valid:true}:{message:'Enter the same new password in both fields.'};
  }
  function refresh(){
    let valid=true;
    for(const [name,input] of Object.entries(inputs)){
      const state=result(name),note=feedback[name],show=Boolean(touched[name]&&!state.valid);
      input.setCustomValidity(state.valid?'':tr(state.message));
      input.setAttribute('aria-invalid',String(show));
      input.dataset.validity=note.dataset.validity=show?'error':'neutral';
      note.hidden=!show;note.textContent=show?tr(state.message):'';
      valid=Boolean(state.valid)&&valid;
    }
    save.disabled=saving||window.bridgeOtaBusy||window.bridgeAccountSaving||!valid;
    status.hidden=!statusKey;status.textContent=statusKey?tr(statusKey):'';
    return valid;
  }
  for(const [name,input] of Object.entries(inputs)){
    input.addEventListener('input',()=>{touched[name]=true;statusKey='';refresh()});
    input.addEventListener('blur',()=>{touched[name]=true;refresh()});
    input.addEventListener('invalid',()=>{touched[name]=true;refresh()});
  }
  form.addEventListener('submit',async event=>{
    event.preventDefault();
    if(saving||window.bridgeAccountSaving)return;
    if(window.bridgeOtaBusy||window.bridgeFirmwareLoading||window.bridgeFirmwarePicking){
      statusKey='Wait for the firmware operation to finish, then try again.';refresh();return;
    }
    for(const name of Object.keys(inputs))touched[name]=true;
    if(!refresh()){
      Object.values(inputs).find(input=>input.getAttribute('aria-invalid')==='true')?.focus();return;
    }
    saving=true;window.bridgeAccountSaving=true;
    for(const input of Object.values(inputs))input.readOnly=true;
    statusKey='Changing the password can take a few seconds. Keep this page open.';
    refresh();bridgeI18n.busy(save,'Changing password…');
    window.dispatchEvent(new Event('bridge-account-saving'));
    // Free the single HTTPS connection before submitting credentials. Native
    // submission keeps passwords out of JavaScript requests and response logs.
    await window.bridgePauseLive();
    form.submit();
  });
  document.addEventListener('submit',event=>{
    if(window.bridgeAccountSaving){event.preventDefault();event.stopImmediatePropagation()}
  },true);
  document.addEventListener('click',event=>{
    if(!window.bridgeAccountSaving)return;
    const control=event.target.closest('a,button,input,select,textarea');
    if(control&&control.id!=='language-select'){event.preventDefault();event.stopImmediatePropagation()}
  },true);
  refresh();
  return {refreshLanguage:refresh};
}};
</script>)FORM";

} // namespace bs::ui
