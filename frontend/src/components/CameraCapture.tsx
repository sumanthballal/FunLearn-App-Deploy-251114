import React, { useRef, useEffect, useState } from "react";

export default function CameraCapture({ onDetect } : { onDetect?: (s:string)=>void }) {
  const videoRef = useRef<HTMLVideoElement|null>(null);
  const [loading,setLoading] = useState(false);
  const [error, setError] = useState<string|undefined>();

  useEffect(()=>{
    let mounted = true;
    const start = async ()=>{
      try{
        const stream = await navigator.mediaDevices?.getUserMedia({ video: { facingMode: "user" }, audio: false });
        if (mounted && videoRef.current) {
          const v = videoRef.current;
          v.srcObject = stream as MediaStream;
          await v.play().catch(()=>{/* autoplay may be blocked; button will trigger */});
        }
      } catch(e){ setError("Camera unavailable"); }
    };
    start();
    return ()=>{ mounted = false; };
  },[]);

  const capture = async () => {
    const v = videoRef.current;
    if (!v) { alert("No camera available"); return; }
    const canvas = document.createElement("canvas");
    canvas.width = v.videoWidth || 320; canvas.height = v.videoHeight || 240;
    const ctx = canvas.getContext("2d"); if (!ctx) { alert("Canvas error"); return; }

    const frames = 5; // burst size
    const delayMs = 60; // ~300ms total
    const votes: Record<string, number> = {};
    setLoading(true);
    try {
      for (let i=0;i<frames;i++){
        ctx.drawImage(v,0,0);
        const b64 = canvas.toDataURL("image/jpeg");
        const res = await fetch("/api/infer", { method:"POST", headers:{"Content-Type":"application/json"}, body: JSON.stringify({ image: b64 }) });
        if (res.ok){
          const j = await res.json();
          const e = (j.emotion || 'neutral') as string;
          votes[e] = (votes[e] || 0) + 1;
        }
        if (i < frames-1) await new Promise(r=>setTimeout(r, delayMs));
      }
      // Majority/plurality with tie-break preference: happy > neutral > sad > frustrated
      const order = ['happy','neutral','sad','frustrated'];
      let best = 'neutral'; let bestCount = -1;
      for (const key of Object.keys(votes)){
        const c = votes[key];
        if (c > bestCount || (c === bestCount && order.indexOf(key) < order.indexOf(best))){
          best = key; bestCount = c;
        }
      }
      setLoading(false);
      onDetect?.(best);
    } catch {
      setLoading(false);
      onDetect?.('neutral');
    }
  };

  return (
    <div className="flex flex-col items-center gap-2">
      <video ref={videoRef} autoPlay playsInline muted className="w-80 h-60 object-cover rounded-lg shadow" />
      {error && <div className="text-xs text-red-600">{error}</div>}
      <button onClick={capture} disabled={loading} className="mt-2 px-4 py-2 rounded bg-sky-500 text-white">
        {loading ? "Detecting..." : "Detect Emotion"}
      </button>
    </div>
  );
}
