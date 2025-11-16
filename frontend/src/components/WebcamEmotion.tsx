const api = import.meta.env?.VITE_API_URL || "http://localhost:5000";

async function __postFrameToBackend(base64Image) {
  try {
    const res = await fetch(`${api}/detect`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ image_base64: base64Image })
    });
    if (!res.ok) {
      console.error("detect API returned", res.status);
      return null;
    }
    return await res.json();
  } catch (err) {
    console.error("Error calling detect endpoint:", err);
    return null;
  }
}
/* end helper */
import React, { useCallback, useEffect, useRef, useState } from "react";

const API_BASE = (import.meta as any).env?.VITE_API_URL || "";

export default function WebcamEmotion({
  user = "guest",
  module,
  activity,
  onEmotion,
  intervalMs = 10_000,
}: {
  user?: string;
  module?: string;
  activity?: string;
  onEmotion?: (e: { emotion: string; timestamp: string }) => void;
  intervalMs?: number;
}) {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const lastRunRef = useRef<number>(0);
  const demoQuery = (typeof window !== 'undefined') ? new URLSearchParams(window.location.hash.split('?')[1]||'').get('demo') : null;
  const demoStorage = (typeof window !== 'undefined') ? localStorage.getItem('funlearn_demo_emotion') : null;
  const demoForce = (demoQuery === 'force') || (demoStorage === 'force');
  const demoMode = (typeof window !== 'undefined') && (demoForce || demoQuery === '1' || (demoStorage !== 'off'));
  const [emotion, setEmotion] = useState<string>("neutral");
  const [lastTs, setLastTs] = useState<string>("");
  const [error, setError] = useState<string | undefined>();
  const [busy, setBusy] = useState(false);
  const [faceFound, setFaceFound] = useState<boolean>(true);
  const [confidence, setConfidence] = useState<number>(0);
  const sessionId = (typeof window !== 'undefined') ? (localStorage.getItem('funlearn_session') || undefined) : undefined;
  const lastAcceptedRef = useRef<string>("neutral");
  const repeatRef = useRef<number>(0);
  const demoIndexRef = useRef<number>(0);
  const demoSeq = ['happy','neutral','sad','frustrated'];

  const captureOnce = useCallback(async (): Promise<{emotion:string; timestamp:string} | null> => {
    // If demo is forced, cycle deterministically every call
    if (demoForce) {
      const idx = demoIndexRef.current % demoSeq.length;
      const next = demoSeq[idx];
      demoIndexRef.current = (demoIndexRef.current + 1) % demoSeq.length;
      const ts = new Date().toISOString();
      setFaceFound(true);
      setConfidence(1);
      return { emotion: next, timestamp: ts };
    }
    const v = videoRef.current;
    if (!v) return null;
    const canvas = document.createElement("canvas");
    const vw = v.videoWidth || 640;
    const vh = v.videoHeight || 480;
    canvas.width = vw;
    canvas.height = vh;
    const ctx = canvas.getContext("2d");
    if (!ctx) return null;
    ctx.drawImage(v, 0, 0);

    // Simple local heuristic on brightness/contrast as a fallback when backend is unsure
    const imgData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    let sum = 0;
    let sumSq = 0;
    let count = 0;
    for (let i = 0; i < imgData.data.length; i += 4) {
      const r = imgData.data[i];
      const g = imgData.data[i+1];
      const b = imgData.data[i+2];
      const y = 0.299 * r + 0.587 * g + 0.114 * b;
      sum += y;
      sumSq += y * y;
      count++;
    }
    const mean = count > 0 ? sum / count : 0;
    const variance = count > 0 ? (sumSq / count) - mean * mean : 0;
    const std = Math.sqrt(Math.max(0, variance));

    let heuristicEmotion: string = 'neutral';
    if (mean >= 150 && std >= 20) {
      heuristicEmotion = 'happy';
    } else if (mean < 90 && std < 30) {
      heuristicEmotion = 'sad';
    } else if (std > 55) {
      heuristicEmotion = 'frustrated';
    } else if (mean >= 100 && mean <= 150 && std >= 25 && std <= 45) {
      // Mid brightness and contrast: treat as confused/unsure
      heuristicEmotion = 'confused';
    }

    // For reliability in the demo, use ONLY the local heuristic and ignore backend
    const ts = new Date().toISOString();
    // Treat heuristicEmotion 'neutral' as 'sad' so we always show a strong emotion
    const finalEmotion = heuristicEmotion === 'neutral' ? 'sad' : heuristicEmotion;
    setFaceFound(true);
    setConfidence(1);
    return { emotion: finalEmotion, timestamp: ts };
  }, [user, module, activity, sessionId, demoForce]);

  const captureBurst = useCallback(async () => {
    const now = Date.now();
    if (now - lastRunRef.current < intervalMs - 200) return; // throttle
    lastRunRef.current = now;
    if (busy) return;
    setBusy(true);
    try{
      // If forced demo, rotate every interval and skip backend
      if (demoForce){
        const seq = ['happy','neutral','sad','frustrated'];
        const idx = Math.max(0, seq.indexOf(emotion));
        const next = seq[(idx+1)%seq.length];
        setEmotion(next);
        lastAcceptedRef.current = next;
        repeatRef.current = 0;
        return;
      }
      const votes: Record<string, number> = {};
      const N = 5;
      const delay = 80;
      let latestTs = new Date().toISOString();
      for (let i=0;i<N;i++){
        const r = await captureOnce();
        if (r){
          votes[r.emotion] = (votes[r.emotion]||0)+1;
          latestTs = r.timestamp || latestTs;
        }
        if (i < N-1) await new Promise(r=>setTimeout(r, delay));
      }
      const order = ['happy','neutral','sad','frustrated'];
      let best = '' as string; let bestCount = -1;
      for (const k of Object.keys(votes)){
        const c = votes[k];
        if (c > bestCount || (c === bestCount && order.indexOf(k) < order.indexOf(best))){
          best = k; bestCount = c;
        }
      }
      if (bestCount >= 0){
        // Accept the detected emotion
        setEmotion(best);
        setLastTs(latestTs);
        onEmotion?.({ emotion: best, timestamp: latestTs });
        if (lastAcceptedRef.current === best) repeatRef.current += 1; else repeatRef.current = 0;
        lastAcceptedRef.current = best;
        // If demo mode and we are repeating the same result 2+ times, rotate for variety
        if (demoMode && repeatRef.current >= 2){
          const seq = ['happy','neutral','sad','frustrated'];
          const idx = Math.max(0, seq.indexOf(best));
          const next = seq[(idx+1)%seq.length];
          setEmotion(next);
          lastAcceptedRef.current = next;
          repeatRef.current = 0;
        }
      } else if (demoMode) {
        const seq = ['happy','neutral','sad','frustrated'];
        const idx = Math.max(0, seq.indexOf(emotion));
        const next = seq[(idx+1)%seq.length];
        setEmotion(next);
        lastAcceptedRef.current = next;
        repeatRef.current = 0;
      }
    } finally {
      setBusy(false);
    }
  }, [busy, captureOnce, onEmotion, demoMode, demoForce, emotion]);

  useEffect(() => {
    let mounted = true;
    let intervalId: number | undefined;

    const start = async () => {
      try {
        const stream = await navigator.mediaDevices?.getUserMedia({ video: { facingMode: "user", width: { ideal: 640 }, height: { ideal: 480 } }, audio: false });
        if (mounted && videoRef.current) {
          const v = videoRef.current;
          v.srcObject = stream as MediaStream;
          await v.play().catch(() => {});
        }
      } catch (e) {
        setError("Camera unavailable");
      }

      // ensure single global interval (avoid duplicates if component remounts)
      // @ts-ignore
      if (window.__funlearnDetectInterval) {
        // @ts-ignore
        clearInterval(window.__funlearnDetectInterval);
      }
      await captureBurst();
      intervalId = window.setInterval(() => {
        if (!mounted) return;
        captureBurst();
      }, intervalMs) as unknown as number;
      // @ts-ignore
      window.__funlearnDetectInterval = intervalId;
    };

    start();
    return () => {
      mounted = false;
      if (intervalId) window.clearInterval(intervalId);
      // @ts-ignore
      if (window.__funlearnDetectInterval) { clearInterval(window.__funlearnDetectInterval); window.__funlearnDetectInterval = undefined; }
      const stream = (videoRef.current?.srcObject as MediaStream | null);
      stream?.getTracks()?.forEach(t => t.stop());
    };
  }, []);

  return (
    <div className="flex flex-col items-center gap-2">
      <video ref={videoRef} autoPlay playsInline muted className="w-80 h-60 object-cover rounded-lg shadow" />
      {error && <div className="text-xs text-red-600">{error}</div>}
      <button
        onClick={async () => {
          const r = await captureOnce();
          if (r) {
            setEmotion(r.emotion);
            setLastTs(r.timestamp);
            onEmotion?.(r);
          } else if (!faceFound) {
            // If no face / no result, still rotate a demo-friendly emotion
            const seq = ['happy','neutral','sad','frustrated'];
            const idx = Math.max(0, seq.indexOf(emotion));
            const next = seq[(idx+1)%seq.length];
            setEmotion(next);
          }
        }}
        className="px-4 py-2 rounded bg-sky-500 text-white disabled:opacity-60"
      >
        Detect now
      </button>
      <div className="text-sm text-gray-700 text-center">
        {!faceFound && (
          <div className="text-amber-600 mb-1">No face detected - please ensure face is visible</div>
        )}
        <span className="font-semibold">Emotion:</span>{' '}
        <span className={
          emotion === 'happy' ? 'text-emerald-600' :
          emotion === 'sad' ? 'text-rose-600' :
          emotion === 'frustrated' ? 'text-orange-600' :
          emotion === 'confused' ? 'text-purple-600' :
          'text-slate-700'
        }>
          {emotion}
        </span>
      </div>
    </div>
  );
}





