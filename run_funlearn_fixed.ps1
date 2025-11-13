# run_funlearn_fixed.ps1
# Single-run launcher for FunLearn on Windows (fixed PSScriptRoot usage)

$ErrorActionPreference = "Stop"

# ----- CONFIG -----
# prefer PSScriptRoot (works when script file is executed); fallback to current directory
if ($PSScriptRoot -and ($PSScriptRoot -ne "")) {
    $Root = $PSScriptRoot
} else {
    $Root = (Get-Location).ProviderPath
}

$backendDir = Join-Path $Root "backend"
$frontendDir = Join-Path $Root "frontend"
$venvDir = Join-Path $backendDir ".venv"
$backendLog = Join-Path $backendDir "backend_run.log"
$frontendLog = Join-Path $frontendDir "frontend_run.log"
$backendPort = 5000
$healthUrl = "http://localhost:$backendPort/health"
$frontendUrl = "http://localhost:5173"

# ----- HELPERS -----
function Write-Ok($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

function TailLog($path, $lines = 60){
    if (Test-Path $path) {
        Write-Host "---- last $lines lines of $path ----"
        Get-Content $path -Tail $lines | ForEach-Object { Write-Host $_ }
        Write-Host "---- end log ----"
    } else {
        Write-Warn ("Log file not found: {0}" -f $path)
    }
}

# ----- PRECHECKS -----
Write-Host "== Checking required tools =="
try { Get-Command python -ErrorAction Stop | Out-Null; Write-Ok "Python found" } catch { Write-Err "Python not found in PATH"; exit 1 }
try { Get-Command node -ErrorAction Stop | Out-Null; Get-Command npm -ErrorAction Stop | Out-Null; Write-Ok "Node & npm found" } catch { Write-Err "Node/npm not found"; exit 1 }

if (-not (Test-Path $backendDir)) { Write-Err ("Backend folder not found: {0}" -f $backendDir); exit 1 }
if (-not (Test-Path $frontendDir)) { Write-Err ("Frontend folder not found: {0}" -f $frontendDir); exit 1 }

# ----- BACKEND VENV & INSTALL -----
Write-Host "`n== Setting up backend environment =="
Push-Location $backendDir
if (-not (Test-Path $venvDir)) {
    Write-Host "Creating virtualenv..."
    python -m venv .venv
    Write-Ok ("Virtualenv created at {0}" -f $venvDir)
} else { Write-Ok "Virtualenv already exists" }

$venvPython = Join-Path $venvDir "Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
    Write-Warn "Using system python (venv python not found)"
    $venvPython = "python"
}

if (Test-Path "requirements.txt") {
    Write-Host ("Installing backend requirements (logging to {0})..." -f $backendLog)
    & $venvPython -m pip install --upgrade pip setuptools wheel | Out-Null
    & $venvPython -m pip install -r requirements.txt 2>&1 | Tee-Object -FilePath $backendLog
    Write-Ok "Backend dependencies installed"
} else {
    Write-Warn "requirements.txt missing in backend"
}
Pop-Location

# ----- CREATE BAT LAUNCHERS -----
$backendBat = Join-Path $backendDir "start_backend.bat"
$frontendBat = Join-Path $frontendDir "start_frontend.bat"

@"
@echo off
title FunLearn Backend
echo Starting backend...
cd /d "%~dp0"
if exist .venv\Scripts\python.exe (
    .venv\Scripts\python.exe app.py > backend_run.log 2>&1
) else (
    python app.py > backend_run.log 2>&1
)
pause
"@ | Set-Content -Path $backendBat -Encoding ASCII

@"
@echo off
title FunLearn Frontend
echo Installing dependencies...
cd /d "%~dp0"
npm install
echo Starting Vite server...
npm run dev > frontend_run.log 2>&1
pause
"@ | Set-Content -Path $frontendBat -Encoding ASCII

Write-Ok "Launchers created: start_backend.bat and start_frontend.bat"

# ----- START BACKEND -----
Write-Host "`n== Launching backend =="
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $backendBat -WorkingDirectory $backendDir
Write-Ok ("Backend running in new CMD window (log: {0})" -f $backendLog)

# Wait for backend health
Write-Host "`n== Waiting for backend to respond =="
$max = 20; $ok = $false
for ($i=1; $i -le $max; $i++) {
    Start-Sleep -Seconds 3
    try {
        $r = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($r.StatusCode -eq 200) {
            Write-Ok ("Backend healthy (attempt {0})" -f $i)
            $ok = $true
            break
        }
    } catch {
        Write-Warn ("Attempt {0}: backend not yet ready..." -f $i)
    }
}
if (-not $ok) {
    Write-Err ("Backend not responding after {0} attempts" -f $max)
    TailLog $backendLog 100
    exit 1
}

# ----- START FRONTEND -----
Write-Host "`n== Launching frontend =="
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $frontendBat -WorkingDirectory $frontendDir
Write-Ok ("Frontend running in new CMD window (log: {0})" -f $frontendLog)

# Wait for frontend
Write-Host "`n== Waiting for frontend server =="
$maxF = 30; $fok = $false
for ($j=1; $j -le $maxF; $j++) {
    Start-Sleep -Seconds 3
    try {
        $r = Invoke-WebRequest -Uri $frontendUrl -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($r.StatusCode -eq 200) {
            Write-Ok ("Frontend healthy (attempt {0})" -f $j)
            $fok = $true
            break
        }
    } catch {
        Write-Warn ("Attempt {0}: frontend not yet ready..." -f $j)
    }
}
if (-not $fok) {
    Write-Err ("Frontend not responding after {0} attempts" -f $maxF)
    TailLog $frontendLog 100
    exit 1
}

# ----- SUCCESS -----
Write-Host "`n==============================================="
Write-Ok ("Backend ready at {0}" -f $healthUrl)
Write-Ok ("Frontend ready at {0}" -f $frontendUrl)
Write-Host "Open the frontend URL in your browser and allow webcam access when prompted."
Write-Host "==============================================="
