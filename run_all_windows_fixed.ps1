# run_all_windows_fixed.ps1
# Place at project root (same folder as backend/ and frontend/).
# Run in PowerShell (Admin recommended):
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# .\run_all_windows_fixed.ps1

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
try {
    $py = Get-Command python -ErrorAction Stop
    Write-Ok "Python found: $($py.Path)"
} catch {
    Write-Err "Python not found in PATH. Install Python 3.8+ and re-run."
    exit 1
}

try {
    $node = Get-Command node -ErrorAction Stop
    $npm = Get-Command npm -ErrorAction Stop
    Write-Ok "Node found: $($node.Path) ; npm: $($npm.Path)"
} catch {
    Write-Err "Node.js and npm must be installed and in PATH. Install from https://nodejs.org/ and re-open PowerShell."
    exit 1
}

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

    $venvPython = Join-Path $venvDir "Scripts\python.exe"
    if (-not (Test-Path $venvPython)) {
        Write-Warn "venv python not found at $venvPython — falling back to system python"
        $venvPython = "python"
    } else {
        Write-Ok "Using venv python: $venvPython"
    }

    if (Test-Path "requirements.txt") {
        Write-Host "Upgrading pip and installing requirements (this may take a while)..."
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

# ---------- Start backend in new cmd window ----------
Write-Host "`n== Starting backend server (new terminal) =="
# Build argument to run in cmd.exe; set WorkingDirectory so no need for cd && chaining.
# Use cmd.exe /k so window remains open for live logs.
$backendCmd = "`"$venvPython`" app.py > `"$backendLog`" 2>&1"
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $backendCmd -WorkingDirectory $backendDir
Write-Ok "Started backend in a new terminal. Logs will be written to: $backendLog"

# ---------- Wait for backend health ----------
Write-Host "`n== Waiting for backend health endpoint =="
$maxRetries = 15
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
    Write-Host "`nOpen the backend terminal window (it was started separately) and inspect errors."
    exit 1
}

# ---------- Start frontend in new cmd window ----------
Write-Host "`n== Starting frontend (new terminal) =="
# We run npm install then npm run dev in the new terminal; allow cmd to handle chaining with &&.
# Build single argument string to pass to cmd.exe; ensure quoting is correct.
$frontendCmd = "npm install && npm run dev > `"$frontendLog`" 2>&1"
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $frontendCmd -WorkingDirectory $frontendDir
Write-Ok "Started frontend in a new terminal. Logs will be written to: $frontendLog"

# ---------- Wait for frontend to respond ----------
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
    Write-Host "`nOpen the frontend terminal window (it was started separately) to inspect Vite/npm output."
    exit 1
}

Write-Host "`nAll done!"
Write-Ok "Backend: $healthUrl"
Write-Ok "Frontend: $frontendUrl"
Write-Host "Open the frontend URL in your browser and allow webcam access when prompted."
