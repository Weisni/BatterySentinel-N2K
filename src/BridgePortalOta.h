#pragma once

// Local-file OTA controller. Device-side verification remains authoritative.
namespace bs::ui {

inline constexpr char kOtaController[] = R"OTA(<script>
window.bridgeOta=(()=>{
  function init(){
    const card=document.getElementById('firmware-card');
    if(!card)return;
    const el=id=>document.getElementById('firmware-'+id),tr=bridgeI18n.t;
    const file=el('file'),install=el('install'),cancel=el('cancel'),retry=el('retry');
    const errors={
      auth:'Sign in again before updating the firmware.',
      csrf:'Your session changed. Reopen the portal before updating.',
      busy:'The device is busy. Wait, then reopen the portal.',
      content_type:'Choose an application firmware .bin file.',
      size:'The firmware file is empty or too large for this device.',
      partition:'OTA is unavailable with the current flash layout. A USB installation is required.',
      image:'The file is not a valid application firmware image.',
      target:'This firmware was built for a different product or processor.',
      checksum:'The firmware checksum is invalid. Download the file again.',
      hash:'The firmware SHA-256 check failed. Download the file again.',
      receive:'The upload was incomplete. The current firmware remains selected.',
      write:'The device could not write the firmware. The current firmware remains selected.',
      finalize:'The device rejected the completed firmware. The current firmware remains selected.',
      activate:'The new firmware could not be selected for startup.'
    };
    let info=null,state='loading',statusKey='Reading firmware information…',statusValues={};
    let xhr=null,percentage=0,selected=null,blocked=[],pickerOpen=false,pickerReturn=0,loadingInfo=false;
    const active=()=>state==='uploading'||state==='validating';
    const locked=()=>active()||state==='success'||state==='uncertain';
    const mebibytes=bytes=>(bytes/1048576).toLocaleString(bridgeI18n.language==='de'?'de-DE':'en-US',{minimumFractionDigits:2,maximumFractionDigits:2});
    function render(){
      el('status').textContent=tr(statusKey,statusValues);
      el('status').dataset.severity=state==='error'?'error':state==='success'?'ok':state==='uncertain'?'warn':'neutral';
      el('version').textContent=info?info.version:'—';
      el('target').textContent=info?info.target:'—';
      el('limit').textContent=info?tr('{size} MiB maximum',{size:mebibytes(info.maxSize)}):'—';
      el('selected').textContent=selected?tr('{name} · {size} MiB',{name:selected.name,size:mebibytes(selected.size)}):tr('No firmware file selected.');
      el('progress-wrap').hidden=!active()&&state!=='success';
      el('progress').value=percentage;
      el('percent').textContent=tr('{percent}% transferred',{percent:percentage});
      file.disabled=window.bridgeAccountSaving||locked()||!info||!info.available;
      install.disabled=window.bridgeAccountSaving||locked()||!info||!info.available||!selected;
      cancel.hidden=!active();cancel.disabled=state!=='uploading';
      retry.hidden=!!info||locked();retry.disabled=window.bridgeAccountSaving||state==='loading';
      el('reopen').hidden=!['success','uncertain'].includes(state)&&!(state==='error'&&!info);
      // Form validators can rerender on a language change; keep their controls locked.
      if(locked())for(const [control] of blocked)control.disabled=true;
    }
    function status(key,values={}){statusKey=key;statusValues=values;render()}
    function lock(){
      window.bridgeOtaBusy=true;
      blocked=[...document.querySelectorAll('button,input,select,textarea')]
        .filter(control=>!card.contains(control)&&control.id!=='language-select')
        .map(control=>[control,control.disabled]);
      for(const [control] of blocked)control.disabled=true;
    }
    function unlock(){
      window.bridgeOtaBusy=false;
      for(const [control,disabled] of blocked)control.disabled=disabled;
      blocked=[];
      window.bridgeResumeLive();
    }
    function uncertain(key){xhr=null;state='uncertain';status(key)}
    function rejected(code){
      xhr=null;state='error';
      if(code==='auth'||code==='csrf'||code==='partition')info=null;
      status(errors[code]);unlock();
    }
    async function loadInfo(){
      if(window.bridgeAccountSaving||locked()||loadingInfo)return;
      loadingInfo=true;window.bridgeFirmwareLoading=true;
      state='loading';status('Reading firmware information…');
      const controller=new AbortController();let timeout=0;
      try{
        // This small device has one HTTPS connection slot. Drain live polling
        // before metadata, including retries after a failed information request.
        await window.bridgePauseLive();
        timeout=setTimeout(()=>controller.abort(),12000);
        const response=await fetch('/api/firmware',{cache:'no-store',signal:controller.signal});
        if(response.status===401){state='error';status(errors.auth);return}
        if(!response.ok)throw Error('metadata');
        const data=await response.json();
        if(!['orion-dongle','orion-r4','orion-debug-oled'].includes(data.target)||typeof data.version!=='string'||
           !Number.isSafeInteger(data.maxSize)||data.maxSize<0||typeof data.available!=='boolean')throw Error('metadata');
        info=data;state=data.available?'idle':'error';
        status(data.available?'Select the firmware file saved on your phone.':errors.partition);
      }catch(_){state='error';status('Firmware information could not be read. Check the Wi-Fi connection and try again.')}finally{
        clearTimeout(timeout);loadingInfo=false;window.bridgeFirmwareLoading=false;render();
        if(!locked())window.bridgeResumeLive();
      }
    }
    function finishPicker(){
      clearTimeout(pickerReturn);pickerReturn=0;
      if(!pickerOpen)return;
      pickerOpen=false;window.bridgeFirmwarePicking=false;
      // Let the returned page paint before starting another device request.
      if(!locked())window.bridgeResumeLive(500);
    }
    function returningFromPicker(){
      if(!pickerOpen||document.hidden)return;
      // Older browsers do not emit cancel when the picker closes unchanged.
      clearTimeout(pickerReturn);pickerReturn=setTimeout(finishPicker,500);
    }
    file.addEventListener('click',()=>{
      if(window.bridgeAccountSaving||file.disabled||locked())return;
      pickerOpen=true;window.bridgeFirmwarePicking=true;
      // Do not await the network here: opening a native picker needs the click.
      window.bridgePauseLive();
    });
    file.addEventListener('cancel',finishPicker);
    window.addEventListener('focus',returningFromPicker);
    document.addEventListener('visibilitychange',returningFromPicker);
    file.addEventListener('change',()=>{
      try{
        if(locked())return;
        selected=null;state='idle';
        const candidate=file.files&&file.files[0];
        if(!candidate){status('No firmware file selected.');return}
        if(!/\.bin$/i.test(candidate.name)){state='error';status(errors.content_type);return}
        if(!info||!info.available||candidate.size<=0||candidate.size>info.maxSize){state='error';status(errors.size);return}
        selected=candidate;status('Ready to upload. The device checks the complete firmware before activating it.');
      }finally{finishPicker()}
    });
    install.addEventListener('click',async()=>{
      if(window.bridgeAccountSaving||locked()||!info||!info.available||!selected)return;
      const token=document.querySelector('input[name="csrf"]');
      if(!token||!token.value){state='error';info=null;status(errors.csrf);return}
      state='uploading';percentage=0;lock();status('Preparing upload…');
      await window.bridgePauseLive();
      if(!active())return;
      const request=xhr=new XMLHttpRequest();
      request.open('POST','/api/firmware');request.timeout=180000;
      request.setRequestHeader('Content-Type','application/octet-stream');
      request.setRequestHeader('X-CSRF-Token',token.value);
      request.upload.onprogress=event=>{
        if(!active()||!event.lengthComputable)return;
        percentage=Math.min(100,Math.floor(event.loaded/event.total*100));
        status('Uploading firmware. Keep this page open and the device powered.');
      };
      request.upload.onload=()=>{if(!active())return;percentage=100;state='validating';status('Upload complete. The device is validating and installing the firmware…')};
      request.onload=()=>{
        if(!active())return;
        let data;
        try{data=JSON.parse(request.responseText)}catch(_){uncertain('The update result is unknown. Reconnect and reopen the portal to check the installed version before trying again.');return}
        if(data&&request.status===200&&data.ok===true&&data.rebooting===true){
          xhr=null;state='success';percentage=100;
          status('Firmware verified and installed. The device is restarting. Reconnect to its Wi-Fi and reopen the portal.');
        }else if(data&&request.status>=400&&data.ok===false&&data.error==='activate')uncertain('The update result is unknown. Reconnect and reopen the portal to check the installed version before trying again.');
        else if(data&&request.status>=400&&data.ok===false&&Object.prototype.hasOwnProperty.call(errors,data.error))rejected(data.error);
        else uncertain('The update result is unknown. Reconnect and reopen the portal to check the installed version before trying again.');
      };
      request.onerror=request.ontimeout=()=>{if(active())uncertain('The connection was interrupted. The update result is unknown. Reconnect and check the installed version before trying again.')};
      request.onabort=()=>{if(active())uncertain('Upload canceled. Reopen the portal and check the installed version before trying again.')};
      try{request.send(selected)}catch(_){uncertain('The connection was interrupted. The update result is unknown. Reconnect and check the installed version before trying again.')}
    });
    cancel.addEventListener('click',()=>{
      if(state!=='uploading')return;
      if(xhr)xhr.abort();else uncertain('Upload canceled. Reopen the portal and check the installed version before trying again.');
    });
    retry.addEventListener('click',loadInfo);
    document.addEventListener('submit',event=>{if(locked()){event.preventDefault();event.stopImmediatePropagation()}},true);
    document.addEventListener('click',event=>{
      if(!locked())return;
      const control=event.target.closest('a,button,input,select,textarea');
      if(control&&!card.contains(control)&&control.id!=='language-select'){event.preventDefault();event.stopImmediatePropagation()}
    },true);
    window.addEventListener('beforeunload',event=>{if(active()){event.preventDefault();event.returnValue=''}});
    window.addEventListener('bridge-language-change',render);
    window.addEventListener('bridge-account-saving',render);
    loadInfo();
  }
  return {init};
})();
</script>)OTA";

} // namespace bs::ui
