<#
PowerShell script to diagnose and run FunLearn backend + frontend on Windows.
Place at the root of your project where backend/ and frontend/ folders live.
Run in an elevated PowerShell session:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\diagnose_and_run.ps1
#>

# --- Configuration ---
$backendDir = Join-Path $PSScriptRoot "backend"
$frontendDir = Join-Path $PSScriptRoot "frontend"
$venvDir = Join-Path $backendDir ".venv"
$backendLog = Join-Path $backendDir "backend_run.log"
$backendPort = 5000
$healthUrl = "http://localhost:$backendPort/health"
$frontendDevUrl = "http://localhost:5173"

# --- Helper functions ---
function Write-Ok($msg){ Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg){ Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red }

# 1) Check tools
Write-Host "== Checking required tools =="

# Python
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) {
    Write-Err "Python not found in PATH. Install Python 3.8+ and re-run."
    exit 1
} else { Write-Ok "Python found: $($py.Path)" }

# pip
$pip = Get-Command pip -ErrorAction SilentlyContinue
if (-not $pip) {
    Write-Warn "pip not found as command. Using python -m pip instead."
} else { Write-Ok "pip found: $($pip.Path)" }

# node & npm
$node = Get-Command node -ErrorAction SilentlyContinue
$npm = Get-Command npm -ErrorAction SilentlyContinue
if (-not $node -or -not $npm) {
    Write-Err "Node.js and npm are required for the frontend. Please install from https://nodejs.org/ and re-run."
    exit 1
} else { Write-Ok "Node: $($node.Path)  npm: $($npm.Path)" }

# 2) Setup backend venv & install requirements
Write-Host "`n== Preparing backend (virtualenv & requirements) =="
if (-not (Test-Path $backendDir)) {
    Write-Err "backend directory not found at: $backendDir"
    exit 1
}

Push-Location $backendDir
try {
    if (-not (Test-Path $venvDir)) {
        Write-Host "Creating virtualenv..."
        python -m venv .venv 2>&1 | Out-Null
        Write-Ok "Virtualenv created at $venvDir"
    } else {
        Write-Ok "Virtualenv already exists"
    }

    # Activate & install
    $activate = Join-Path $venvDir "Scripts\Activate.ps1"
    if (-not (Test-Path $activate)) {
        Write-Warn "Activate script not found at $activate. Virtualenv may have failed to create."
    } else {
        Write-Host "Activating virtualenv..."
        . $activate
    }

    # Install requirements
    if (Test-Path "requirements.txt") {
        Write-Host "Installing backend requirements (this may take a few minutes)..."
        python -m pip install --upgrade pip setuptools wheel
        python -m pip install -r requirements.txt 2>&1 | Tee-Object -FilePath $backendLog -Append
        Write-Ok "Backend packages installed (check $backendLog for details)."
    } else {
        Write-Warn "requirements.txt not found in backend folder."
    }
} catch {
    Write-Err "Error during virtualenv setup: $_"
    Pop-Location
    exit 1
}
Pop-Location

# 3) Start backend in background and capture logs
Write-Host "`n== Starting backend server (in background) =="
# Ensure previous log is truncated
if (Test-Path $backendLog) { Remove-Item $backendLog -Force }

Push-Location $backendDir
# Activate venv for the background process
$activateCmd = "`${env:VIRTUAL_ENV_ACTIVATE} = `$null; & `"$venvDir\Scripts\Activate.ps1`" ; python app.py"
# Use Start-Process to run in separate window and redirect output to log
# But since Start-Process can't easily source the PS script before running the python in same session,
# we will run python directly from venv python executable.
$pyExe = Join-Path $venvDir "Scripts\python.exe"
if (-not (Test-Path $pyExe)) {
    Write-Warn "venv python not found, falling back to system python"
    $pyExe = "python"
}
# Start python app.py, capture output to log
$startInfo = @{
    FilePath = $pyExe
    ArgumentList = @("app.py")
    RedirectStandardOutput = $true
    RedirectStandardError = $true
    WorkingDirectory = $backendDir
    NoNewWindow = $false
}
# Start process and capture Output asynchronously to file
$proc = Start-Process @startInfo -PassThru
Write-Host "Backend process started (PID $($proc.Id)). Waiting for server to respond on $healthUrl..."
Pop-Location

# Helper to tail the backend log if it exists
function Tail-BackendLog([int]$lines=60){
    Write-Host "`n---- backend log (last $lines lines) ----"
    $log = Join-Path $backendDir "backend_run.log"
    if (Test-Path $log) {
        Get-Content $log -Tail $lines
    } else {
        Write-Host "[no centralized log file present; check the window where backend started or check process output]"
    }
    Write-Host "---- end log ----`n"
}

# Wait and poll /health (up to 45 seconds)
$maxAttempts = 9
$attempt = 0
$healthy = $false

while ($attempt -lt $maxAttempts) {
    Start-Sleep -Seconds 5
    $attempt++
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -TimeoutSec 3 -ErrorAction Stop
        if ($r.StatusCode -eq 200) {
            Write-Ok "Backend health endpoint responded (attempt $attempt)."
            $healthy = $true
            break
        }
    } catch {
        Write-Warn "Attempt ${attempt}: backend not responding yet."
    }
}

if (-not $healthy) {
    Write-Err "Backend did not become healthy on $healthUrl after $($attempt*5) seconds."
    # Show recent event logs with Get-Process output and netstat
    Write-Host "`n--- Diagnostic information ---"
    Try {
        Write-Host "Backend process info:"
        Get-Process -Id $proc.Id -ErrorAction Stop | Format-List -Property Id,ProcessName,StartTime | Out-String | Write-Host
    } Catch {
        Write-Warn "Backend process not found or has exited."
    }
    Write-Host "`nListening ports (netstat):"
    netstat -ano | Select-String ":$backendPort" | Write-Host
    Tail-BackendLog 100
    Write-Host "`nCommon causes and fixes:"
    Write-Host " - If you see ModuleNotFoundError: install missing package (pip install <package>)."
    Write-Host " - If DeepFace errors show model download failing: check network/firewall or download models on another machine and copy to user deepface cache (follow DeepFace docs)."
    Write-Host " - If 'address already in use': change port or stop conflicting service."
    Write-Host " - If python crashes on import: paste the traceback here."
    exit 1
}

# 4) Start or install frontend
Write-Host "`n== Frontend setup & start =="
Push-Location $frontendDir
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing frontend dependencies (npm install)..."
    npm install 2>&1 | Tee-Object -Variable npmout
    Write-Ok "npm install completed"
} else {
    Write-Ok "node_modules exists; skipping npm install"
}

# Start vite dev server in a new process
Write-Host "Starting frontend dev server (vite)..."
$npmProc = Start-Process -FilePath "npm" -ArgumentList "run","dev" -WorkingDirectory $frontendDir -PassThru
Write-Host "Frontend started (PID $($npmProc.Id)). Waiting for $frontendDevUrl to be reachable..."

# Poll frontend URL
$maxF = 12
$fattempt = 0
$fhealthy = $false
while ($fattempt -lt $maxF) {
    Start-Sleep -Seconds 3
    $fattempt++
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri $frontendDevUrl -TimeoutSec 3 -ErrorAction Stop
        if ($r.StatusCode -eq 200) {
            Write-Ok "Frontend dev server responded."
            $fhealthy = $true
            break
        }
    } catch {
        Write-Warn "Attempt ${fattempt}: frontend not responding yet."
    }
}

if ($fhealthy) {
    Write-Host "Opening frontend in default browser: $frontendDevUrl"
    Start-Process $frontendDevUrl
    Write-Ok "FunLearn should be accessible. Make sure to allow webcam access when the browser asks."
    Pop-Location
    exit 0
} else {
    Write-Warn "Frontend did not respond at $frontendDevUrl. Check the Vite window or the process logs."
    Pop-Location
    exit 1
}
