<#
  setup_funlearn.ps1
  - Saves/patches Vite + TS configs and essential component stubs (if missing)
  - Creates backend venv, installs Python deps
  - Installs frontend node deps and runs Vite
  - Starts backend and frontend in separate PowerShell windows and opens browser

  NOTE: Update $ProjectRoot if your FunLearn folder is elsewhere.
#>

# --------- Configuration ----------
$ProjectRoot = "C:\Users\balla\Desktop\FunLearn"
$BackendDir = Join-Path $ProjectRoot "backend"
$FrontendDir = Join-Path $ProjectRoot "frontend"
$SrcDir = Join-Path $FrontendDir "src"
$ComponentsDir = Join-Path $SrcDir "components"
$LibDir = Join-Path $SrcDir "lib"
$NodeDevPort = 5173
# ----------------------------------

function Write-Info($s){ Write-Host "[INFO] $s" -ForegroundColor Cyan }
function Write-OK($s){ Write-Host "[ OK ] $s" -ForegroundColor Green }
function Write-Warn($s){ Write-Host "[WARN] $s" -ForegroundColor Yellow }
function Write-Err($s){ Write-Host "[ERR ] $s" -ForegroundColor Red }

# sanity checks
if (-not (Test-Path $ProjectRoot)) {
    Write-Err "Project root not found: $ProjectRoot. Edit this script to point to your project."
    exit 1
}
if (-not (Test-Path $BackendDir)) {
    Write-Err "Backend folder not found: $BackendDir"
    exit 1
}
if (-not (Test-Path $FrontendDir)) {
    Write-Err "Frontend folder not found: $FrontendDir"
    exit 1
}

Write-Info "Using project root: $ProjectRoot"

# Check Python
$python = (Get-Command python -ErrorAction SilentlyContinue)
if (-not $python) {
    Write-Err "Python not found in PATH. Install Python 3.9-3.11 and add to PATH."
    exit 1
}
Write-OK "Python found: $($python.Path)"

# Check Node + npm
$node = (Get-Command node -ErrorAction SilentlyContinue)
$npm = (Get-Command npm -ErrorAction SilentlyContinue)
if (-not $node -or -not $npm) {
    Write-Err "Node and/or npm not found. Install Node (recommended 18.x LTS) and try again."
    exit 1
}
Write-OK "Node found: $($node.Path)"
Write-OK "npm found: $($npm.Path)"

# --------------------
# Ensure frontend config files (backup if present)
# --------------------
function Backup-File($path) {
    if (Test-Path $path) {
        $bak = "$path.bak_$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item $path $bak -Force
        Write-Warn "Backed up $path -> $bak"
    }
}

# vite.config.ts content
$viteConfigPath = Join-Path $FrontendDir "vite.config.ts"
$viteConfigContent = @"
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
    port: $NodeDevPort,
    proxy: {
      '/api': 'http://127.0.0.1:5000',
    },
  },
});
"@

# tsconfig.json
$tsconfigPath = Join-Path $FrontendDir "tsconfig.json"
$tsconfigContent = @"
{
  "compilerOptions": {
    "target": "ESNext",
    "useDefineForClassFields": true,
    "lib": ["DOM", "ESNext"],
    "jsx": "react-jsx",
    "module": "ESNext",
    "moduleResolution": "Node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src"]
}
"@

# create/overwrite configs with backup
Backup-File $viteConfigPath
Set-Content -Path $viteConfigPath -Value $viteConfigContent -Encoding UTF8
Write-OK "Wrote $viteConfigPath"

Backup-File $tsconfigPath
Set-Content -Path $tsconfigPath -Value $tsconfigContent -Encoding UTF8
Write-OK "Wrote $tsconfigPath"

# --------------------
# Ensure component & lib stubs exist (won't overwrite existing files)
# --------------------
if (-not (Test-Path $ComponentsDir)) { New-Item -ItemType Directory -Path $ComponentsDir | Out-Null; Write-OK "Created directory $ComponentsDir" }
if (-not (Test-Path $LibDir)) { New-Item -ItemType Directory -Path $LibDir | Out-Null; Write-OK "Created directory $LibDir" }

# HelpFAB
$helpFabPath = Join-Path $ComponentsDir "HelpFAB.tsx"
if (-not (Test-Path $helpFabPath)) {
    $content = @"
import React from 'react';

export default function HelpFAB() {
  return (
    <button title='Help' className='fixed bottom-6 right-6 p-4 rounded-full shadow-lg bg-white'>
      Help
    </button>
  );
}
"@
    Set-Content -Path $helpFabPath -Value $content -Encoding UTF8
    Write-OK "Created component stub: $helpFabPath"
} else { Write-Info "Found existing: $helpFabPath" }

# CameraCapture
$cameraPath = Join-Path $ComponentsDir "CameraCapture.tsx"
if (-not (Test-Path $cameraPath)) {
    $content = @"
import React from 'react';

export default function CameraCapture({ onCapture } : { onCapture?: (b64:string)=>void }) {
  return (
    <div>
      <p className='p-4'>CameraCapture stub - allow camera on real component.</p>
      <button onClick={() => onCapture && onCapture('data:image/png;base64,')} className='btn'>Capture</button>
    </div>
  );
}
"@
    Set-Content -Path $cameraPath -Value $content -Encoding UTF8
    Write-OK "Created component stub: $cameraPath"
} else { Write-Info "Found existing: $cameraPath" }

# RecommendPanel
$recommendPath = Join-Path $ComponentsDir "RecommendPanel.tsx"
if (-not (Test-Path $recommendPath)) {
    $content = @"
import React from 'react';

export default function RecommendPanel({ items } : { items?: any[] }) {
  return (
    <aside className='p-4'>
      <h3>Recommendations</h3>
      <ul>{(items||[]).map((it,idx)=><li key={idx}>{it?.title ?? 'Sample activity'}</li>)}</ul>
    </aside>
  );
}
"@
    Set-Content -Path $recommendPath -Value $content -Encoding UTF8
    Write-OK "Created component stub: $recommendPath"
} else { Write-Info "Found existing: $recommendPath" }

# lib/fallbacks.ts
$fallbacksPath = Join-Path $LibDir "fallbacks.ts"
if (-not (Test-Path $fallbacksPath)) {
    $content = @"
export const fallbackRecommendations = {
  happy: [{ id:'h1', title:'Fun math game' }, { id:'h2', title:'Reading comic' }],
  neutral: [{ id:'n1', title:'Practice quiz' }],
  confused: [{ id:'c1', title:'Step-by-step lesson' }],
  frustrated: [{ id:'f1', title:'Easy practice puzzle' }],
  sad: [{ id:'s1', title:'Cheerful art activity' }]
};

export default fallbackRecommendations;
"@
    Set-Content -Path $fallbacksPath -Value $content -Encoding UTF8
    Write-OK "Created lib stub: $fallbacksPath"
} else { Write-Info "Found existing: $fallbacksPath" }

# --------------------
# Backend: create and activate venv, install requirements
# --------------------
Push-Location $BackendDir
try {
    Write-Info "Preparing backend venv in $BackendDir"
    if (-not (Test-Path ".venv")) {
        python -m venv .venv
        Write-OK "Created venv"
    } else {
        Write-Info "Venv already exists"
    }

    # Activate and pip install - run in separate hidden process? We'll install now in this session
    $activate = Join-Path $BackendDir ".venv\Scripts\Activate.ps1"
    if (Test-Path $activate) {
        Write-Info "Activating venv and installing requirements..."
        # Use a temporary script to run activation + install (so we ensure activation in same process)
        $tmpScript = Join-Path $env:TEMP "funlearn_backend_setup_$(Get-Random).ps1"
        $ts = @"
`$ErrorActionPreference = 'Stop'
cd '$BackendDir'
. '.\.venv\Scripts\Activate.ps1'
pip install --upgrade pip
if (Test-Path 'requirements.txt') {
  pip install -r requirements.txt
} else {
  Write-Host 'No requirements.txt found - skipping pip install'
}
"@
        Set-Content -Path $tmpScript -Value $ts -Encoding UTF8
        # run the temporary script using powershell so venv is activated for those commands
        & powershell -NoProfile -ExecutionPolicy Bypass -File $tmpScript
        Remove-Item $tmpScript -Force
        Write-OK "Backend pip install finished."
    } else {
        Write-Warn "Activate script not found at $activate. Ensure venv exists and try manually."
    }
} catch {
    Write-Err "Error preparing backend: $($_.Exception.Message)"
    Pop-Location
    exit 1
}
Pop-Location

# --------------------
# Frontend: npm install
# --------------------
Push-Location $FrontendDir
try {
    Write-Info "Running npm install in $FrontendDir (this may take a minute)..."
    npm install --no-audit --no-fund
    Write-OK "npm install completed."
} catch {
    Write-Err "npm install failed: $($_.Exception.Message)"
    Pop-Location
    exit 1
}
Pop-Location

# --------------------
# Start backend in new PowerShell window
# --------------------
$backendStartCmd = "cd `"$BackendDir`"; if (Test-Path .venv\Scripts\Activate.ps1) { . .\.venv\Scripts\Activate.ps1 } ; python app.py"
Write-Info "Starting backend in a new PowerShell window..."
Start-Process -FilePath "powershell" -ArgumentList "-NoExit","-NoProfile","-Command",$backendStartCmd

# --------------------
# Start frontend (Vite) in new PowerShell window
# --------------------
$frontendStartCmd = "cd `"$FrontendDir`"; npm run dev"
Write-Info "Starting frontend (Vite) in a new PowerShell window..."
Start-Process -FilePath "powershell" -ArgumentList "-NoExit","-NoProfile","-Command",$frontendStartCmd

# --------------------
# Wait & open browser to frontend
# --------------------
Write-Info "Waiting for frontend to warm up..."
Start-Sleep -Seconds 4

# Try to open the site. If not ready, user can refresh.
$localUrl = "http://localhost:$NodeDevPort"
Write-Info "Opening $localUrl in default browser..."
Start-Process $localUrl

Write-OK "Setup script completed. Two PowerShell windows started: backend and frontend."
Write-Info "If any window shows errors, copy-paste the exact error here and I'll help fix it."
