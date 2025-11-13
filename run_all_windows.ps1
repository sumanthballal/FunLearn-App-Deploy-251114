# run_all_windows.ps1
# Single-script launcher for FunLearn (Windows). Place in project root (same folder as backend/ and frontend/).
# Usage (PowerShell admin recommended):
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# .\run_all_windows.ps1

$ErrorActionPreference = "Stop"

# ---------- Configuration ----------
$Root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$backendDir = Join-Path $Root "backend"
$frontendDir = Join-Path $Root "frontend"
$venvDir = Join-Path $backendDir ".venv"
$backendLog = Join-Path $backendDir "backend_run.log"
$frontendLog = Join-Path $frontendDir "frontend_run.log"
$backendPort = 5000
$healthUrl = "http://localhost:$backendPort/health"
$frontendUrl = "http://localhost:5173"

# ---------- Helpers ----------
function Write-Ok($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

function TailLog($path, $lines = 60){
    if (Test-Path $path) {
        Write-Host "---- last $lines lines of $path ----"
        Get-Content $path -Tail $lines | ForEach-Object { Write-Host $_ }
        Write-Host "---- end log ----"
    } else {
        Write-Warn "Log file not found: $path"
    }
}

# ---------- Preflight checks ----------
Write-Host "== Preflight checks =="
# Python
try {
    $py = Get-Command python -ErrorAction Stop
    Write-Ok "Python found: $($py.Path)"
} catch {
    Write-Err "Python not found in PATH. Install Python 3.8+ and re-run."
    exit 1
}

# Node & npm
try {
    $node = Get-Command node -ErrorAction Stop
    $npm = Get-Command npm -ErrorAction Stop
    Write-Ok "Node found: $($node.Path) ; npm: $($npm.Path)"
} catch {
    Write-Err "Node.js and npm must be installed and in PATH. Install from https://nodejs.org/ and re-open PowerShell."
    exit 1
}

# Ensure backend/frontend folders exist
if (-not (Test-Path $backendDir)) { Write-Err "backend folder not found at $backendDir"; exit 1 }
if (-not (Test-Path $frontendDir)) { Write-Err "frontend folder not found at $frontendDir"; exit 1 }

# ---------- Backend venv & requirements ----------
Write-Host "`n== Backend venv & requirements =="

Push-Location $backendDir
try {
    if (-not (Test-Path $venvDir)) {
        Write-Host "Creating virtualenv..."
        python -m venv .venv
        Write-Ok "Virtualenv created at $venvDir"
    } else {
        Write-Ok "Virtualenv already exists at $venvDir"
    }

    # venv python path
    $venvPython = Join-Path $venvDir "Scripts\python.exe"
    if (-not (Test-Path $venvPython)) {
        Write-Warn "vnev python not found at $venvPython — falling back to system python"
        $venvPython = "python"
    } else {
        Write-Ok "Using venv python: $venvPython"
    }

    if (Test-Path "requirements.txt") {
        Write-Host "Upgrading pip & installing requirements (this may take a while)..."
        & $venvPython -m pip install --upgrade pip setuptools wheel | Out-Null
        & $venvPython -m pip install -r requirements.txt 2>&1 | Tee-Object -FilePath $backendLog
        Write-Ok "Backend requirements installed (log: $backendLog)"
    } else {
        Write-Warn "requirements.txt not found in backend; skipping install."
    }
} catch {
    Write-Err "Error preparing backend: $_"
    Pop-Location
    exit 1
}
Pop-Location

# ---------- Start backend in a new terminal window ----------
Write-Host "`n== Starting backend server (new terminal) =="
# Build command to run in cmd.exe. Using cmd.exe /k so window stays open for logs.
$backendPythonEsc = $venvPython -replace '\\','\\'  # escape backslashes in path string
$backendCmd = "`"$backendPythonEsc`" app.py > `"$backendLog`" 2>&1"
$fullBackendCmd = "cd /d `"$backendDir`" && $backendCmd"
# Start a new cmd.exe window that runs the backend; /k keeps it open so you can see live output if needed.
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $fullBackendCmd
Write-Ok "Started backend in a new terminal. Logs will be written to: $backendLog"

# ---------- Wait for backend health ----------
Write-Host "`n== Waiting for backend health endpoint =="
$maxRetries = 12
$attempt = 0
$healthy = $false
while ($attempt -lt $maxRetries) {
    Start-Sleep -Seconds 3
    $attempt++
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -TimeoutSec 3 -ErrorAction Stop
        if ($r.StatusCode -eq 200) {
            Write-Ok "Backend healthy (attempt $attempt)."
            $healthy = $true
            break
        }
    } catch {
        Write-Warn "Attempt ${attempt}: backend not responding yet at $healthUrl"
    }
}

if (-not $healthy) {
    Write-Err "Backend did not respond at $healthUrl after $($maxRetries*3) seconds."
    TailLog $backendLog 200
    Write-Host "`nCommon fixes:"
    Write-Host " - Open the backend terminal window started earlier and inspect errors."
    Write-Host " - If you see ModuleNotFoundError: activate venv and pip install missing package."
    Write-Host " - If DeepFace fails on model download: network/firewall may block downloads."
    exit 1
}

# ---------- Start frontend in new terminal (npm install & npm run dev) ----------
Write-Host "`n== Starting frontend (new terminal) =="
# Build frontend command: cd to frontend && npm install (silent) && npm run dev (logs to file)
# We want to run npm install first (it may be skipped if node_modules exists)
$frontendCmd = "cd /d `"$frontendDir`" && npm install && npm run dev > `"$frontendLog`" 2>&1"
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $frontendCmd
Write-Ok "Started frontend in a new terminal. Logs will be written to: $frontendLog"

# ---------- Wait for frontend server to reply ----------
Write-Host "`n== Waiting for frontend dev server =="
$maxFRetries = 20
$fattempt = 0
$fhealthy = $false
while ($fattempt -lt $maxFRetries) {
    Start-Sleep -Seconds 3
    $fattempt++
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri $frontendUrl -TimeoutSec 3 -ErrorAction Stop
        if ($r.StatusCode -eq 200) {
            Write-Ok "Frontend dev server responding at $frontendUrl (attempt $fattempt)."
            $fhealthy = $true
            break
        }
    } catch {
        Write-Warn "Attempt ${fattempt}: frontend not responding yet at $frontendUrl"
    }
}

if (-not $fhealthy) {
    Write-Err "Frontend did not respond at $frontendUrl after $($maxFRetries*3) seconds."
    TailLog $frontendLog 200
    Write-Host "`nOpen the frontend terminal window started earlier to inspect Vite/npm output."
    Write-Host "Common issues: missing packages (run npm install manually), port in use, or vite errors."
    exit 1
}

# ---------- Success ----------
Write-Host "`nAll done!"
Write-Ok "Backend: $healthUrl"
Write-Ok "Frontend: $frontendUrl"
Write-Host "Please open the frontend URL in your browser and allow webcam access when prompted."
