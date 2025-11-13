# run_funlearn.ps1
# 🧠 FunLearn full auto-fix + run script (Windows PowerShell)
# Usage:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\run_funlearn.ps1

$ErrorActionPreference = "Stop"
$Root = (Get-Location).ProviderPath
Write-Host "🚀 Running FunLearn auto-fixer in: $Root`n"

$backendDir  = Join-Path $Root "backend"
$frontendDir = Join-Path $Root "frontend"

if (-not (Test-Path $backendDir) -or -not (Test-Path $frontendDir)) {
    Write-Host "[❌] backend or frontend folder missing. Run from FunLearn root." -ForegroundColor Red
    exit 1
}

function Backup-File($f) {
    if (Test-Path $f) {
        $bak="$f.bak_$(Get-Date -f yyyyMMdd_HHmmss)"
        Copy-Item $f $bak -Force
        Write-Host "[💾] Backup: $f → $bak"
    }
}

# === FRONTEND ENV ===
$envPath = Join-Path $frontendDir ".env"
if (-not (Test-Path $envPath)) {
@'
VITE_API_URL=http://localhost:5000
'@ | Set-Content $envPath -Encoding UTF8
Write-Host "[✅] Created frontend/.env"
} else {
    Backup-File $envPath
    (Get-Content $envPath -Raw) -replace 'VITE_API_URL=.*','VITE_API_URL=http://localhost:5000' |
        Set-Content $envPath -Encoding UTF8
    Write-Host "[🔄] Updated VITE_API_URL in .env"
}

# === VITE CONFIG ===
$vite = Join-Path $frontendDir "vite.config.js"
if (-not (Test-Path $vite)) {
@'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
export default defineConfig({
  plugins:[react()],
  server:{
    port:5173,
    proxy:{
      "/api":{
        target:"http://localhost:5000",
        changeOrigin:true,
        rewrite:(p)=>p.replace(/^\/api/,"")
      }
    }
  }
});
'@ | Set-Content $vite -Encoding UTF8
Write-Host "[✅] Created vite.config.js with /api proxy"
}

# === BACKEND PATCH ===
$appPy = Join-Path $backendDir "app.py"
if (-not (Test-Path $appPy)) {
Write-Host "[❌] backend/app.py not found."; exit 1
}
Backup-File $appPy
$app = Get-Content $appPy -Raw
if ($app -notmatch 'from\s+flask_cors') {
$app = $app -replace 'from\s+flask\s+import\s+Flask','from flask import Flask`r`nfrom flask_cors import CORS'
}
if ($app -match 'app\s*=\s*Flask' -and $app -notmatch 'CORS\(app\)') {
$app = [regex]::Replace($app,'(app\s*=\s*Flask\(.*?\))',"$1`r`nCORS(app)",[System.Text.RegularExpressions.RegexOptions]::Singleline)
}
if ($app -notmatch 'def\s+health') {
$app += @'
@app.route("/health",methods=["GET"])
def health():
    return {"status":"ok"}
'@
}
if ($app -notmatch '@app.route\("/detect"') {
$app += @'
import base64, io, time
from flask import request, jsonify
@app.route("/detect",methods=["POST"])
def detect():
    try:
        data=request.get_json(force=True)
        b64=data.get("image_base64") if data else None
        if not b64:
            return jsonify({"emotion":"neutral","confidence":0.0,"face_found":False,"timestamp":int(time.time())})
        try:
            from emotion_model import analyze_base64
            return jsonify(analyze_base64(b64))
        except Exception:
            return jsonify({"emotion":"neutral","confidence":0.0,"face_found":False,"timestamp":int(time.time())})
    except Exception as e:
        return jsonify({"error":str(e)}),500
'@
}
Set-Content $appPy $app -Encoding UTF8
Write-Host "[✅] Patched backend/app.py (CORS + /health + /detect)"

# === EMOTION MODEL PLACEHOLDER ===
$em = Join-Path $backendDir "emotion_model.py"
if (-not (Test-Path $em)) {
@'
import base64, io, time
from PIL import Image
def analyze_base64(b64):
    try:
        data=b64.split(",",1)[-1]
        img=Image.open(io.BytesIO(base64.b64decode(data)))
        return {"emotion":"neutral","confidence":0.0,"face_found":False,"timestamp":int(time.time())}
    except:
        return {"emotion":"neutral","confidence":0.0,"face_found":False,"timestamp":int(time.time())}
'@ | Set-Content $em -Encoding UTF8
Write-Host "[✅] Created emotion_model.py placeholder"
}

# === FRONTEND HELPER INJECTION ===
$src = Join-Path $frontendDir "src"
$files = Get-ChildItem $src -Recurse -Include *Webcam*.tsx,*Emotion*.tsx,*WebcamEmotion*.tsx -ErrorAction SilentlyContinue |
          Where-Object { $_.FullName -notmatch "node_modules" }
$helper = @'
/* __FUNLEARN_EMOTION_HELPER__ */
const api = (import.meta.env.VITE_API_URL) || "http://localhost:5000";
async function __postFrameToBackend(base64Image){
 try{
  const res=await fetch(`${api}/detect`,{
   method:"POST",
   headers:{"Content-Type":"application/json"},
   body:JSON.stringify({image_base64:base64Image})
  });
  return res.ok?await res.json():null;
 }catch(e){console.error("detect error",e);return null;}
}
/* end helper */
'@
foreach($f in $files){
 try{
  $c=Get-Content $f.FullName -Raw
  if($c -notmatch '__FUNLEARN_EMOTION_HELPER__'){
   Backup-File $f.FullName
   ($helper + "`r`n" + $c) | Set-Content $f.FullName -Encoding UTF8
   Write-Host "[✨] Helper prepended to $($f.Name)"
  }
 }catch{}
}

# === START FILES ===
$backendBat = Join-Path $backendDir "start_backend.bat"
$frontendBat = Join-Path $frontendDir "start_frontend.bat"
@"
@echo off
title FunLearn Backend
cd /d "%~dp0"
if exist .venv\Scripts\activate.bat call .venv\Scripts\activate.bat
python app.py > backend_run.log 2>&1
"@ | Set-Content $backendBat -Encoding ASCII
@"
@echo off
title FunLearn Frontend
cd /d "%~dp0"
npm install
npm run dev > frontend_run.log 2>&1
"@ | Set-Content $frontendBat -Encoding ASCII
Write-Host "[✅] start_backend.bat and start_frontend.bat created"

# === LAUNCH ===
Start-Process -FilePath "cmd.exe" -ArgumentList "/k",$backendBat -WorkingDirectory $backendDir
Start-Sleep -s 3
Start-Process -FilePath "cmd.exe" -ArgumentList "/k",$frontendBat -WorkingDirectory $frontendDir
Start-Sleep -s 10
Start-Process "http://localhost:5173"
Write-Host "`n🎉 Everything started! Browser opened at http://localhost:5173"
Write-Host "Check backend health: curl http://localhost:5000/health"
Write-Host "Logs: backend/backend_run.log, frontend/frontend_run.log"
