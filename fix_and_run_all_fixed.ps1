# fix_and_run_all_fixed.ps1
# Safe single-shot fixer & starter for FunLearn (Windows PowerShell)
# Place this file in C:\Users\balla\Desktop\Funlearn and run from that folder.
# This script will:
#  - create frontend/.env with VITE_API_URL
#  - create vite.config.js (if missing) with /api proxy
#  - append /health and /detect endpoints to backend/app.py if missing (safe fallback)
#  - create backend/emotion_model.py placeholder if missing
#  - prepend a safe helper to any Webcam/Emotion frontend files found
#  - create start_backend.bat and start_frontend.bat, and open them in new cmd windows
#  - list files that still contain the literal "detect_emotion" for manual inspection

$ErrorActionPreference = "Stop"

# Project root - running directory
$Root = (Get-Location).ProviderPath
Write-Host "Running fixer in: $Root"

$backendDir = Join-Path $Root "backend"
$frontendDir = Join-Path $Root "frontend"

if (-not (Test-Path $backendDir) -or -not (Test-Path $frontendDir)) {
    Write-Host "[ERROR] backend or frontend folders not found. Make sure you're running this from the FunLearn project root."
    exit 1
}

function Backup-File($path) {
    if (Test-Path $path) {
        $stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
        $bak = "$path.bak_$stamp"
        Copy-Item -Path $path -Destination $bak -Force
        Write-Host "[BACKUP] $path -> $bak"
    }
}

# 1) Create frontend/.env with VITE_API_URL
$envPath = Join-Path $frontendDir ".env"
if (-not (Test-Path $envPath)) {
    $text = @'
VITE_API_URL=http://localhost:5000
'@
    $text | Set-Content -Path $envPath -Encoding UTF8
    Write-Host "[CREATED] $envPath"
} else {
    Backup-File $envPath
    $envRaw = Get-Content $envPath -Raw
    if ($envRaw -match 'VITE_API_URL=') {
        $envRaw2 = [regex]::Replace($envRaw, 'VITE_API_URL=.*', 'VITE_API_URL=http://localhost:5000')
        $envRaw2 | Set-Content -Path $envPath -Encoding UTF8
        Write-Host "[UPDATED] $envPath (VITE_API_URL set)"
    } else {
        Add-Content -Path $envPath -Value "`nVITE_API_URL=http://localhost:5000"
        Write-Host "[APPENDED] VITE_API_URL to $envPath"
    }
}

# 2) Ensure vite.config.js exists with simple /api proxy (if missing)
$vitePath = Join-Path $frontendDir "vite.config.js"
if (-not (Test-Path $vitePath)) {
    $viteText = @'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      "/api": {
        target: "http://localhost:5000",
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, "")
      }
    }
  }
});
'@
    $viteText | Set-Content -Path $vitePath -Encoding UTF8
    Write-Host "[CREATED] $vitePath (with /api -> backend proxy)"
} else {
    Write-Host "[OK] $vitePath already exists; skipping creation."
}

# 3) Append /health and /detect in backend/app.py if missing
$appPy = Join-Path $backendDir "app.py"
if (-not (Test-Path $appPy)) {
    Write-Host "[ERROR] backend/app.py not found. Please ensure your backend has app.py. Exiting."
    exit 1
}

Backup-File $appPy
$appText = Get-Content $appPy -Raw

# Add flask_cors import and CORS(app) if missing
if ($appText -notmatch 'from\s+flask_cors\s+import\s+CORS') {
    $appText = $appText -replace '(^\s*from\s+flask\s+import\s+Flask)', "`$1`r`nfrom flask_cors import CORS"
    Write-Host "[PATCH] Inserted flask_cors import (if needed)"
}

if ($appText -match 'app\s*=\s*Flask') {
    if ($appText -notmatch 'CORS\s*\(\s*app\s*\)') {
        $appText = [regex]::Replace($appText, '(app\s*=\s*Flask\([^\)]*\)\s*)', "`$1`r`nCORS(app)`r`n", [System.Text.RegularExpressions.RegexOptions]::Singleline)
        Write-Host "[PATCH] Inserted CORS(app) after Flask app creation"
    } else {
        Write-Host "[OK] CORS(app) already present"
    }
}

# Ensure /health
if ($appText -notmatch "def\s+health\s*\(") {
    $healthSnippet = @'
@app.route("/health", methods=["GET"])
def health():
    return {"status":"ok"}
'@
    $appText += "`r`n" + $healthSnippet
    Write-Host "[ADDED] /health endpoint to app.py"
} else {
    Write-Host "[OK] /health endpoint exists"
}

# Ensure /detect (safe fallback) - append if not present
if ($appText -notmatch "@app.route\(\s*['""]\/detect['""]") {
    $detectSnippet = @'
import base64, io, time
from flask import request, jsonify

@app.route("/detect", methods=["POST"])
def detect():
    try:
        data = request.get_json(force=True)
        img_b64 = data.get("image_base64") if data else None
        if not img_b64:
            return jsonify({"emotion":"neutral","confidence":0.0,"face_found":False,"timestamp":int(time.time())})
        # If emotion_model.analyze_base64 exists, use it. Otherwise return neutral fallback.
        try:
            from emotion_model import analyze_base64
            res = analyze_base64(img_b64)
            return jsonify(res)
        except Exception:
            return jsonify({"emotion":"neutral","confidence":0.0,"face_found":False,"timestamp":int(time.time())})
    except Exception as exc:
        return jsonify({"error":str(exc)}), 500
'@
    $appText += "`r`n" + $detectSnippet
    Write-Host "[ADDED] /detect endpoint (fallback) to app.py"
} else {
    Write-Host "[OK] /detect route exists in app.py"
}

Set-Content -Path $appPy -Value $appText -Encoding UTF8
Write-Host "[SAVED] backend/app.py"

# 4) Create emotion_model.py placeholder if missing
$emotionModel = Join-Path $backendDir "emotion_model.py"
if (-not (Test-Path $emotionModel)) {
    $emText = @'
# emotion_model.py - placeholder analyze_base64
import base64, io, time
from PIL import Image

def analyze_base64(b64str):
    try:
        # Accept either "data:image/png;base64,..." or raw base64
        if "," in b64str:
            _, data = b64str.split(",", 1)
        else:
            data = b64str
        imgdata = base64.b64decode(data)
        Image.open(io.BytesIO(imgdata))  # validate image
        return {"emotion":"neutral","confidence":0.0,"face_found":False,"timestamp":int(time.time())}
    except Exception:
        return {"emotion":"neutral","confidence":0.0,"face_found":False,"timestamp":int(time.time())}
'@
    $emText | Set-Content -Path $emotionModel -Encoding UTF8
    Write-Host "[CREATED] backend/emotion_model.py (placeholder). Replace with your model code later."
} else {
    Write-Host "[OK] backend/emotion_model.py already exists"
}

# 5) Prepend frontend helper to Webcam/Emotion files found (safe add)
$webcamFiles = Get-ChildItem -Path (Join-Path $frontendDir "src") -Recurse -Include *Webcam*.tsx,*Webcam*.jsx,*Emotion*.tsx,*WebcamEmotion*.tsx -ErrorAction SilentlyContinue
if ($webcamFiles.Count -eq 0) {
    Write-Host "[WARN] No webcam/emotion component candidates found under frontend/src; searching entire frontend folder..."
    $webcamFiles = Get-ChildItem -Path $frontendDir -Recurse -Include *.tsx,*.jsx -ErrorAction SilentlyContinue | Where-Object {
        (Get-Content $_.FullName -Raw) -match "detect_emotion|detect_emotion|webcam|getUserMedia"
    }
}

$helperMarker = "// __FUNLEARN_EMOTION_HELPER__"
$helperSnippet = @'
/* __FUNLEARN_EMOTION_HELPER__ */
const api = (typeof import !== "undefined" && import.meta && import.meta.env && import.meta.env.VITE_API_URL) ? import.meta.env.VITE_API_URL : "http://localhost:5000";

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
'@

foreach ($file in $webcamFiles) {
    try {
        $path = $file.FullName
        $content = Get-Content $path -Raw
        if ($content -match [regex]::Escape($helperMarker)) {
            Write-Host "[SKIP] helper already present in $path"
            continue
        }
        Backup-File $path
        $newContent = $helperSnippet + "`r`n" + $content
        Set-Content -Path $path -Value $newContent -Encoding UTF8
        Write-Host "[PATCHED] Prepend helper to $path"
    } catch {
        Write-Host "[ERROR] Could not modify $($file.FullName): $_"
    }
}

# 6) Create start .bat files (backend/front) and launch them in new cmd windows
$backendBat = Join-Path $backendDir "start_backend.bat"
$frontendBat = Join-Path $frontendDir "start_frontend.bat"

$backendBatContent = @'
@echo off
title FunLearn Backend
cd /d "%~dp0"
if exist .venv\Scripts\activate.bat (
  call .venv\Scripts\activate.bat
)
echo Starting backend (python app.py). Logs: backend_run.log
python app.py > backend_run.log 2>&1
pause
'@
$backendBatContent | Set-Content -Path $backendBat -Encoding ASCII

$frontendBatContent = @'
@echo off
title FunLearn Frontend
cd /d "%~dp0"
echo Installing dependencies if needed and starting Vite (logs -> frontend_run.log)
npm install
npm run dev > frontend_run.log 2>&1
pause
'@
$frontendBatContent | Set-Content -Path $frontendBat -Encoding ASCII

Write-Host "[CREATED] start_backend.bat and start_frontend.bat"

# Launch them
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $backendBat -WorkingDirectory $backendDir
Start-Sleep -Seconds 2
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $frontendBat -WorkingDirectory $frontendDir
Write-Host "[LAUNCHED] backend and frontend start scripts in new cmd windows."

# 7) Report files still containing literal detect_emotion for manual fixes
Write-Host "`nScanning frontend for remaining literal 'detect_emotion' occurrences..."
$occurs = Get-ChildItem -Path $frontendDir -Recurse -Include *.tsx,*.jsx,*.ts,*.js -ErrorAction SilentlyContinue | Where-Object {
    (Get-Content $_.FullName -Raw) -match "detect_emotion"
}
if ($occurs.Count -gt 0) {
    Write-Host "[NOTICE] Found files that contain 'detect_emotion' (you may need to change the fetch target to use the helper __postFrameToBackend or /api/detect):"
    $occurs | ForEach-Object { Write-Host " - $($_.FullName)" }
} else {
    Write-Host "[OK] No residual 'detect_emotion' literals found in frontend files."
}

# 8) Final checks & instructions
Write-Host "`n[FINAL] Verification:"
Write-Host " 1) Backend health: curl http://localhost:5000/health"
Write-Host " 2) Manual detect test: curl -X POST http://localhost:5000/detect -H ""Content-Type: application/json"" -d ""{\""image_base64\"":\""data:,\""}"""
Write-Host " 3) Open frontend: http://localhost:5173"
Write-Host "`nBackups of modified files were created next to originals with .bak_TIMESTAMP suffix."
Write-Host "If something fails, paste the last 80 lines of backend/backend_run.log and frontend/frontend_run.log and the list of files shown above."
