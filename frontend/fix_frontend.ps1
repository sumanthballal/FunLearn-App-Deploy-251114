# 1) go to frontend
cd "C:\Users\balla\Desktop\FunLearn\frontend"

# 2) show current vite config & tsconfig (for quick debug)
Write-Host "`n--- vite.config.ts (if exists) ---`n"
if (Test-Path .\vite.config.ts) { Get-Content .\vite.config.ts -Raw } else { Write-Host "vite.config.ts not found" }
Write-Host "`n--- tsconfig.json (if exists) ---`n"
if (Test-Path .\tsconfig.json) { Get-Content .\tsconfig.json -Raw } else { Write-Host "tsconfig.json not found" }

# 3) show components folder contents expected by alias
Write-Host "`n--- src/components contents ---`n"
if (Test-Path .\src\components) { Get-ChildItem .\src\components -File | Select-Object Name,FullName } else { Write-Host "components folder missing" }

# 4) If any component missing, create safe stubs (won't overwrite existing files)
# HelpFAB
if (-not (Test-Path .\src\components\HelpFAB.tsx)) {
  Write-Host "Creating HelpFAB.tsx"
  @'
import React from "react";
export default function HelpFAB() {
  return <button title="Help" className="fixed bottom-6 right-6 p-3 rounded-full bg-white">?</button>;
}
'@ | Out-File .\src\components\HelpFAB.tsx -Encoding UTF8
} else { Write-Host "HelpFAB.tsx already exists" }

# CameraCapture
if (-not (Test-Path .\src\components\CameraCapture.tsx)) {
  Write-Host "Creating CameraCapture.tsx"
  @'
import React, { useRef, useEffect } from "react";
export default function CameraCapture({ onCapture }:{onCapture?:(s:string)=>void}) {
  const videoRef = useRef<HTMLVideoElement|null>(null);
  useEffect(()=>{ navigator.mediaDevices?.getUserMedia({video:true}).then(s=>{ if(videoRef.current) videoRef.current.srcObject=s }).catch(()=>{}) },[]);
  const handle = ()=>{ const v=videoRef.current; if(!v) return; const c=document.createElement("canvas"); c.width=v.videoWidth; c.height=v.videoHeight; const ctx=c.getContext("2d"); ctx?.drawImage(v,0,0); onCapture?.(c.toDataURL("image/png")); };
  return (<div><video ref={videoRef} autoPlay playsInline className="rounded-lg" /><button onClick={handle} className="mt-2 px-3 py-1 bg-blue-600 text-white rounded">Capture</button></div>);
}
'@ | Out-File .\src\components\CameraCapture.tsx -Encoding UTF8
} else { Write-Host "CameraCapture.tsx already exists" }

# RecommendPanel
if (-not (Test-Path .\src\components\RecommendPanel.tsx)) {
  Write-Host "Creating RecommendPanel.tsx"
  @'
import React from "react";
export default function RecommendPanel({ items = [] }:{items?:any[]}) {
  return (<aside className="p-3 bg-white/80 rounded shadow"><h3 className="font-bold">Recommendations</h3><ul>{items.map((it,i)=>(<li key={i}>{it?.title ?? "Activity"}</li>))}</ul></aside>);
}
'@ | Out-File .\src\components\RecommendPanel.tsx -Encoding UTF8
} else { Write-Host "RecommendPanel.tsx already exists" }

# lib/fallbacks.ts
if (-not (Test-Path .\src\lib\fallbacks.ts)) {
  Write-Host "Creating lib/fallbacks.ts"
  @'
export const fallbackRecommendations = {
  happy:[{title:"Fun Math Game"}],
  neutral:[{title:"Practice Quiz"}],
  confused:[{title:"Step-by-Step Lesson"}],
  frustrated:[{title:"Easy Puzzle"}],
  sad:[{title:"Cheerful Art Project"}]
};
export default fallbackRecommendations;
'@ | Out-File .\src\lib\fallbacks.ts -Encoding UTF8
} else { Write-Host "src/lib/fallbacks.ts already exists" }

# 5) Ensure vite.config.ts has alias configuration (overwrite to exact correct content)
Write-Host "`nWriting/overwriting vite.config.ts to ensure alias '@' -> src`"
@"
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
  server: {
    port: 5173,
    proxy: { '/api': 'http://127.0.0.1:5000' },
  },
});
"@ | Out-File .\vite.config.ts -Encoding UTF8

# 6) Ensure tsconfig.json includes baseUrl + paths (overwrite to canonical)
Write-Host "Writing/overwriting tsconfig.json"
@"
{
  ""compilerOptions"": {
    ""target"": ""ESNext"",
    ""useDefineForClassFields"": true,
    ""lib"": [""DOM"",""ESNext""],
    ""jsx"": ""react-jsx"",
    ""module"": ""ESNext"",
    ""moduleResolution"": ""Node"",
    ""resolveJsonModule"": true,
    ""isolatedModules"": true,
    ""noEmit"": true,
    ""baseUrl"": ""."",
    ""paths"": { ""@/*"": [""src/*""] }
  },
  ""include"": [""src""]
}
"@ | Out-File .\tsconfig.json -Encoding UTF8

# 7) Remove Vite cache so it re-resolves fresh
if (Test-Path .\node_modules\.vite) {
  Write-Host "Removing Vite cache .vite"
  Remove-Item .\node_modules\.vite -Recurse -Force
}

# 8) Restart dev server - stop previous if running and start fresh
Write-Host "`nStopping existing dev server (if any) - you may need to press Ctrl+C in any running terminal"`
# (User should manually stop any running npm run dev terminals first)
# Start a new clean dev server
Write-Host "Starting Vite dev server..."
Start-Process -NoNewWindow -FilePath "cmd.exe" -ArgumentList "/c npm run dev" -WorkingDirectory (Get-Location).Path

Write-Host "`n--- DONE ---"
Write-Host "Open http://localhost:5173 in your browser. If you still see the same import error, paste the exact output here."
