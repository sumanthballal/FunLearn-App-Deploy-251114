# fix_and_launch_all.ps1
# All-in-one fixer + launcher for FunLearn (frontend + backend)
# EDIT $ProjectRoot if your FunLearn repo path differs.

$ProjectRoot = "C:\Users\balla\Desktop\Funlearn"
$BackendDir = Join-Path $ProjectRoot "backend"
$FrontendDir = Join-Path $ProjectRoot "frontend"
$NodePort = 5173
$BackendHost = "127.0.0.1"
$BackendPort = 5000

function Log($msg){ Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Ok($msg){ Write-Host "[ OK ] $msg" -ForegroundColor Green }
function Err($msg){ Write-Host "[ERR ] $msg" -ForegroundColor Red }

# Validate folders
if (-not (Test-Path $ProjectRoot)) { Err "Project root not found: $ProjectRoot"; exit 1 }
if (-not (Test-Path $BackendDir)) { Err "Backend folder not found: $BackendDir"; exit 1 }
if (-not (Test-Path $FrontendDir)) { Err "Frontend folder not found: $FrontendDir"; exit 1 }

# 1) Write robust frontend source files (UTF-8) - safe, defensive, no fragile JSX
Set-Location $FrontendDir
Log "Writing frontend files (will overwrite)."

# helper to write literal here strings
function Write-File($path, $content){
  $content | Out-File -FilePath $path -Encoding UTF8 -Force
  Ok "Wrote $path"
}

# folders
$src = Join-Path $FrontendDir "src"
$pages = Join-Path $src "pages"
$components = Join-Path $src "components"
$lib = Join-Path $src "lib"
if (-not (Test-Path $src)) { New-Item -ItemType Directory -Path $src | Out-Null }
if (-not (Test-Path $pages)) { New-Item -ItemType Directory -Path $pages | Out-Null }
if (-not (Test-Path $components)) { New-Item -ItemType Directory -Path $components | Out-Null }
if (-not (Test-Path $lib)) { New-Item -ItemType Directory -Path $lib | Out-Null }

# index.css
Write-File (Join-Path $src "index.css") @'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root { --bg: #E6F4FF; --primary:#00AEEF; }
body { margin:0; font-family: "Nunito", sans-serif; background: var(--bg); }
.container { max-width:1100px; margin:0 auto; padding:24px; }
'@

# main.tsx
Write-File (Join-Path $src "main.tsx") @'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
'@

# App.tsx
Write-File (Join-Path $src "App.tsx") @'
import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Home from "./pages/Home";
import Learn from "./pages/Learn";
import LessonShell from "./pages/LessonShell";
import ActivityDetail from "./pages/ActivityDetail";

export default function App(){
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home/>} />
        <Route path="/learn" element={<Learn/>} />
        <Route path="/lesson/:module" element={<LessonShell/>} />
        <Route path="/activity/:id" element={<ActivityDetail/>} />
      </Routes>
    </Router>
  );
}
'@

# Home.tsx - anchor fallback so navigation cannot fail
Write-File (Join-Path $pages "Home.tsx") @'
import React from "react";

export default function Home(){
  return (
    <div className="h-screen flex flex-col items-center justify-center bg-gradient-to-b from-sky-100 to-sky-200">
  <h1 className="text-5xl font-extrabold text-sky-700 mb-4">🎉 FunLearn</h1>
  <p className="text-gray-700 mb-6">Emotion-aware learning for kids — safe, fun, and adaptive</p>
  <a href="/learn" className="bg-sky-500 text-white px-6 py-3 rounded-2xl shadow-lg">Start Learning 🚀</a>
    </div>
  );
}
'@

# Learn.tsx safe
Write-File (Join-Path $pages "Learn.tsx") @'
import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

export default function Learn(){
  const nav = useNavigate();
  const [modules, setModules] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(()=> {
    let mounted = true;
    (async ()=>{
      try {
        const res = await fetch("/api/modules");
        if (!res.ok) throw new Error("bad modules");
        const data = await res.json();
        if (mounted && Array.isArray(data)) setModules(data);
      } catch {
        if (mounted) setModules(["Math","Science","Reading","Art"]);
      } finally { if (mounted) setLoading(false); }
    })();
    return ()=>{ mounted = false; };
  },[]);

  return (
    <div className="min-h-screen p-8">
      <div className="container">
        <h1 className="text-4xl font-bold text-sky-700 mb-6">Choose a module</h1>
  {loading ? <div>Loading modules…</div> : (
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
            {modules.map((m)=>(
              <button key={m} onClick={()=>nav(`/lesson/${encodeURIComponent(m.toLowerCase())}`)}
                className="bg-white/80 p-6 rounded-2xl shadow-md hover:bg-sky-100">{m}</button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
'@

# LessonShell.tsx safe
Write-File (Join-Path $pages "LessonShell.tsx") @'
import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import CameraCapture from "@/components/CameraCapture";
import RecommendPanel from "@/components/RecommendPanel";

export default function LessonShell(){
  const { module } = useParams();
  const navigate = useNavigate();
  const [emotion, setEmotion] = useState<string>("neutral");
  const [activities, setActivities] = useState<any[]>([]);
  const [showPanel, setShowPanel] = useState<boolean>(false);
  const modKey = (module ?? "").toString();

  useEffect(()=>{
    let mounted = true;
    (async ()=>{
      if (!modKey) { setActivities([]); return; }
      try {
        const res = await fetch(`/api/activities/${encodeURIComponent(modKey)}`);
        if (!res.ok) throw new Error("bad activities");
        const data = await res.json();
        if (mounted && Array.isArray(data)) setActivities(data);
      } catch {
        if (mounted) setActivities([]);
      }
    })();
    return ()=>{ mounted = false; };
  },[modKey]);

  const openActivity = (id:string)=> navigate(`/activity/${encodeURIComponent(id)}`);

  return (
    <div className="min-h-screen p-8 bg-sky-50">
      <div className="container flex gap-8">
        <div style={{flex:1}}>
          <h1 className="text-3xl font-bold text-sky-700 mb-4">📚 {module}</h1>
          <p className="mb-4">Detected emotion: <b>{emotion}</b></p>

          <div className="mb-6">
            <CameraCapture onDetect={(e)=>{ setEmotion(e); setShowPanel(true); }} />
          </div>

          <h2 className="text-xl font-semibold mb-2">Activities</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {activities.length===0 ? <div className="text-gray-600">No activities found.</div> :
              activities.map(a=>(
                <div key={a.id} className="bg-white p-4 rounded shadow flex justify-between items-center">
                  <div>
                    <div className="font-bold">{a.title}</div>
                    <div className="text-sm text-gray-600">{a.duration ?? ""}</div>
                  </div>
                  <div>
                    <button onClick={()=>openActivity(a.id)} className="px-3 py-1 rounded bg-sky-500 text-white">Open</button>
                  </div>
                </div>
              ))
            }
          </div>
        </div>

        <div style={{width:340}}>
          <button onClick={()=>setShowPanel(s=>!s)} className="mb-4 px-3 py-1 rounded bg-sky-500 text-white">Toggle Recommendations</button>
          <RecommendPanel emotion={emotion} open={showPanel} />
        </div>
      </div>
    </div>
  );
}
'@

# ActivityDetail.tsx
Write-File (Join-Path $pages "ActivityDetail.tsx") @'
import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";

export default function ActivityDetail(){
  const { id } = useParams();
  const [activity, setActivity] = useState<any>(null);
  const [msg, setMsg] = useState("");

  useEffect(()=> {
    let mounted=true;
    (async ()=> {
      if (!id) return;
      try {
        const res = await fetch(`/api/activity/${encodeURIComponent(id)}`);
        if (!res.ok) throw new Error("no activity");
        const data = await res.json();
        if (mounted) setActivity(data);
      } catch { if (mounted) setActivity(null); }
    })();
    return ()=>{ mounted=false; };
  },[id]);

  const markDone = async () => {
    try {
      const rec = { user:"local-user", module: activity?.module ?? "unknown", activity: id, timestamp: new Date().toISOString() };
      await fetch("/api/progress",{ method:"POST", headers:{"Content-Type":"application/json"}, body: JSON.stringify(rec) });
      setMsg("Saved!");
    } catch { setMsg("Save failed"); }
  };

  if (!activity) return <div className="p-8">Loading...</div>;
  return (
    <div className="min-h-screen p-8 bg-sky-50">
      <div className="container">
        <h1 className="text-3xl font-bold mb-4">{activity.title}</h1>
        <p className="text-gray-700 mb-4">{activity.description}</p>
        {activity.media?.type==="youtube" && <iframe title="media" width="640" height="360" src={activity.media.src}></iframe>}
        <button onClick={markDone} className="bg-sky-500 text-white px-4 py-2 rounded">Mark as Done</button>
        <div className="mt-2">{msg}</div>
      </div>
    </div>
  );
}
'@

# CameraCapture.tsx
Write-File (Join-Path $components "CameraCapture.tsx") @'
import React, { useRef, useEffect, useState } from "react";

export default function CameraCapture({ onDetect } : { onDetect?: (s:string)=>void }) {
  const videoRef = useRef<HTMLVideoElement|null>(null);
  const [loading,setLoading] = useState(false);

  useEffect(()=>{
    let mounted = true;
    navigator.mediaDevices?.getUserMedia({ video:true })
      .then(stream => { if (mounted && videoRef.current) videoRef.current.srcObject = stream; })
      .catch(()=>{ /* ignore */ });
    return ()=>{ mounted = false; };
  },[]);

  const capture = async () => {
    const v = videoRef.current;
    if (!v) { alert("No camera available"); return; }
    const canvas = document.createElement("canvas");
    canvas.width = v.videoWidth || 320; canvas.height = v.videoHeight || 240;
    const ctx = canvas.getContext("2d"); if (!ctx) { alert("Canvas error"); return; }
    ctx.drawImage(v,0,0);
    const b64 = canvas.toDataURL("image/jpeg");
    setLoading(true);
    try {
      const res = await fetch("/api/infer", { method:"POST", headers:{"Content-Type":"application/json"}, body: JSON.stringify({ image: b64 }) });
      if (!res.ok) throw new Error("infer failed");
      const j = await res.json();
      setLoading(false);
      onDetect?.(j.emotion ?? "neutral");
    } catch {
      setLoading(false);
      onDetect?.("neutral");
    }
  };

  return (
    <div className="flex flex-col items-center gap-2">
      <video ref={videoRef} autoPlay playsInline className="w-80 h-60 object-cover rounded-lg shadow" />
      <button onClick={capture} disabled={loading} className="mt-2 px-4 py-2 rounded bg-sky-500 text-white">
        {loading ? "Detecting..." : "Detect Emotion"}
      </button>
    </div>
  );
}
'@

# RecommendPanel.tsx
Write-File (Join-Path $components "RecommendPanel.tsx") @'
import React, { useEffect, useState } from "react";
import fallbackRecs from "@/lib/fallbacks";

export default function RecommendPanel({ emotion="neutral", open=true }:{emotion?:string, open?:boolean}) {
  const [items,setItems] = useState<any[]>([]);
  useEffect(()=>{
    let mounted=true;
    (async ()=>{
      try {
        const res = await fetch("/api/recommend", { method:"POST", headers:{"Content-Type":"application/json"}, body: JSON.stringify({ emotion }) });
        if (res.ok) {
          const j = await res.json();
          if (mounted && Array.isArray(j)) setItems(j);
          else if (mounted) setItems(fallbackRecs[emotion] || []);
        } else { if (mounted) setItems(fallbackRecs[emotion]||[]); }
      } catch { if (mounted) setItems(fallbackRecs[emotion]||[]); }
    })();
    return ()=>{ mounted=false; };
  },[emotion]);
  if (!open) return <div />;
  return (
    <div className="bg-white p-4 rounded-lg shadow">
      <h3 className="font-bold mb-2">Recommended</h3>
      <ul className="space-y-2">
        {items.map((it:any,i:number)=><li key={i} className="flex justify-between items-center"><div>{it.title}</div><div className="text-sm text-gray-500">{it.duration ?? ""}</div></li>)}
      </ul>
    </div>
  );
}
'@

# HelpFAB.tsx
Write-File (Join-Path $components "HelpFAB.tsx") @'
import React from "react";
export default function HelpFAB({onClick}:{onClick?:()=>void}) {
  return <button onClick={onClick} className="fixed bottom-6 right-6 p-3 rounded-full bg-white shadow-lg">Help</button>;
}
'@

# fallbacks.ts
Write-File (Join-Path $lib "fallbacks.ts") @'
const fallbackRecs = {
  happy:[{title:"Fun Math Game", duration:"5m"}],
  neutral:[{title:"Practice Quiz", duration:"8m"}],
  confused:[{title:"Step-by-Step Lesson", duration:"7m"}],
  frustrated:[{title:"Easy Puzzle", duration:"6m"}],
  sad:[{title:"Cheerful Art Project", duration:"10m"}]
};
export default fallbackRecs;
export { fallbackRecs };
'@

# vite.config.js
Write-File (Join-Path $FrontendDir "vite.config.js") @'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins:[react()],
  resolve:{ alias: { "@": path.resolve(__dirname,"src") } },
  server:{ port:5173, proxy: { "/api": "http://127.0.0.1:5000" } }
});
'@

# remove vite cache
if (Test-Path (Join-Path $FrontendDir "node_modules\.vite")) {
  try { Remove-Item -Recurse -Force (Join-Path $FrontendDir "node_modules\.vite") } catch {}
}

# 2) Ensure npm deps installed (frontend)
Set-Location $FrontendDir
try {
  Log "Running npm install (frontend)..."
  npm install --no-audit --no-fund | Out-Null
  Ok "npm install finished."
} catch {
  Err "npm install failed: $($_.Exception.Message)"; exit 1
}

# 3) Prepare backend: create venv and install requirements if needed
Set-Location $BackendDir
$venvPath = Join-Path $BackendDir ".venv"
if (-not (Test-Path $venvPath)) {
  try {
    Log "Creating Python venv..."
    python -m venv .venv
    Ok "Created venv"
  } catch {
    Err "Failed to create venv: $($_.Exception.Message)"; exit 1
  }
}

# create a temporary script to activate and pip install
$tempScript = Join-Path $env:TEMP "funlearn_backend_setup_$(Get-Random).ps1"
$ts = @"
`$ErrorActionPreference = 'Stop'
cd '$BackendDir'
. '.\.venv\Scripts\Activate.ps1'
pip install --upgrade pip
if (Test-Path 'requirements.txt') { pip install -r requirements.txt }
"@
Set-Content -Path $tempScript -Value $ts -Encoding UTF8
& powershell -NoProfile -ExecutionPolicy Bypass -File $tempScript
Remove-Item $tempScript -Force
Ok "Backend venv and pip install done (if requirements.txt existed)."

# 4) Start backend in new PowerShell window
$backendCmd = "cd `"$BackendDir`"; . .\.venv\Scripts\Activate.ps1; python app.py"
Log "Starting backend in new window..."
Start-Process -FilePath "powershell" -ArgumentList "-NoExit","-NoProfile","-Command",$backendCmd

# 5) Start frontend in new PowerShell window
$frontendCmd = "cd `"$FrontendDir`"; npm run dev"
Log "Starting frontend in new window..."
Start-Process -FilePath "powershell" -ArgumentList "-NoExit","-NoProfile","-Command",$frontendCmd

# 6) Wait for services to be healthy
function Wait-ForUrl($url, $timeoutSec, $label){
  $end = (Get-Date).AddSeconds($timeoutSec)
  while((Get-Date) -lt $end){
    try {
      $res = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3
      Ok "$label is up: $url"
      return $true
    } catch { Start-Sleep -Seconds 1 }
  }
  Err "$label did not respond within $timeoutSec seconds: $url"
  return $false
}

# wait frontend root and backend health
$frontendUrl = "http://localhost:$NodePort"
$backendHealth = "http://${BackendHost}:${BackendPort}/health"

Log "Waiting for backend health..."
if (-not (Wait-ForUrl $backendHealth 20 "Backend")) {
  Err "Backend not healthy; check backend PowerShell window for errors."
}

Log "Waiting for frontend..."
if (-not (Wait-ForUrl $frontendUrl 20 "Frontend")) {
  Err "Frontend not healthy; check frontend PowerShell window for errors."
}

# Finally open learn page
Start-Process "$frontendUrl/learn"
Ok "Opened $frontendUrl/learn in browser. If modules still don't show, open browser DevTools (F12) -> Console and paste errors here."

Write-Host "`nFinished. If you still experience problems, copy the FIRST red error block from the FRONTEND terminal (npm run dev) and the browser console errors and paste them here." -ForegroundColor Cyan

