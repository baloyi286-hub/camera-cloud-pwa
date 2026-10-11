// Cloud-first browser camera. HTTPS or localhost required.
// Upload API must authorize the current user; cookies must be Secure + HttpOnly + SameSite.
(() => {
  let stream, recorder, sessionId, queue = Promise.resolve(), failed = null, seq = 0;
  const video = document.createElement('video');
  Object.assign(video, {autoplay: true, muted: true, playsInline: true});
  video.setAttribute('playsinline', '');
  video.style.cssText = 'width:100%;height:100%;object-fit:cover;background:#000';
  const mime = () => ['video/mp4', 'video/webm;codecs=vp8,opus', 'video/webm']
    .find(x => MediaRecorder.isTypeSupported(x)) || '';
  async function json(url, body) {
    const res = await fetch(url, {method:'POST', credentials:'include',
      headers:{'Content-Type':'application/json'}, body:JSON.stringify(body)});
    if (!res.ok) throw new Error('API error '+res.status);
    return res.json();
  }
  async function upload(ticket, blob) {
    const res = await fetch(ticket.url, {method:ticket.method || 'PUT',
      headers:ticket.headers || {'Content-Type':blob.type}, body:blob});
    if (!res.ok) throw new Error('Cloud upload failed '+res.status);
  }
  window.cameraCloud = {
    preview: () => video,
    async start(front) {
      if (recorder?.state === 'recording') throw new Error('Stop recording first');
      if (!navigator.mediaDevices?.getUserMedia) throw new Error('HTTPS required');
      stream?.getTracks().forEach(t => t.stop());
      stream = await navigator.mediaDevices.getUserMedia({
        video:{facingMode:{ideal:front ? 'user' : 'environment'}},audio:true});
      video.srcObject = stream;
      await video.play();
    },
    async photo(api) {
      if (!stream || !video.videoWidth) throw new Error('Open camera first');
      if (!api) throw new Error('Configure API_BASE_URL');
      const canvas = document.createElement('canvas');
      canvas.width=video.videoWidth; canvas.height=video.videoHeight;
      canvas.getContext('2d').drawImage(video,0,0);
      const blob = await new Promise((resolve,reject) => canvas.toBlob(
        b => b ? resolve(b) : reject(new Error('Capture failed')), 'image/jpeg', .92));
      const ticket = await json(api+'/api/photos/sign',{contentType:blob.type,size:blob.size});
      await upload(ticket,blob);
    },
    async record(api) {
      if (!stream) throw new Error('Open camera first');
      if (!api) throw new Error('Configure API_BASE_URL');
      if (!window.MediaRecorder) throw new Error('Recording unsupported');
      const type=mime();
      const started=await json(api+'/api/uploads/start',{contentType:type || 'video/webm'});
      sessionId=started.sessionId; seq=0; failed=null; queue=Promise.resolve();
      recorder=new MediaRecorder(stream,type ? {mimeType:type} : undefined);
      recorder.ondataavailable=e => {
        if (!e.data.size) return;
        const part=++seq;
        queue=queue.then(async()=>{
          const ticket=await json(api+'/api/uploads/'+encodeURIComponent(sessionId)+'/part',
            {sequence:part,contentType:e.data.type,size:e.data.size});
          await upload(ticket,e.data);
        }).catch(err=>{ failed=err; throw err; });
        // Avoid an unhandled rejection while allowing stop() to report failure.
        queue.catch(()=>{});
      };
      recorder.start(2000);
    },
    async stop() {
      if (!recorder || recorder.state !== 'recording') throw new Error('Not recording');
      await new Promise((resolve,reject)=>{
        recorder.addEventListener('stop',resolve,{once:true});
        recorder.addEventListener('error',e=>reject(e.error),{once:true});
        recorder.stop();
      });
      await queue;
      if (failed) throw failed;
      // A server-side finalizer must combine container fragments into a playable video.
      await json((window.cameraCloudApiBase || '')+'/unused',{}).catch(()=>{});
      return true;
    },
    close() { if (recorder?.state === 'recording') recorder.stop();
      stream?.getTracks().forEach(t=>t.stop()); video.srcObject=null; }
  };
})();
