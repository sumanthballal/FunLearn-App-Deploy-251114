# Function to ensure directory exists and is clean
function Ensure-CleanDirectory {
    param([string]$path, [string]$name)
    Write-Host "Checking $name setup..."
    if (-not (Test-Path $path)) {
        Write-Error "$name directory not found at: $path"
        exit 1
    }
}

# Kill any existing python and node processes that might be running our servers
Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*$PSScriptRoot*" } | Stop-Process -Force
Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*$PSScriptRoot*" } | Stop-Process -Force
Start-Sleep -Seconds 2

# Verify directories and dependencies
Ensure-CleanDirectory "$PSScriptRoot\backend" "Backend"
Ensure-CleanDirectory "$PSScriptRoot\frontend" "Frontend"

# Create timestamped log files
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backendLog = "backend_run_${timestamp}.log"
$frontendLog = "frontend_run_${timestamp}.log"

# Force a stable Vite dev server port so the user always knows which URL to open
$env:VITE_PORT = '5173'

# Verify vite is installed
if (-not (Test-Path "$PSScriptRoot\frontend\node_modules\.bin\vite.cmd")) {
    Write-Host "Vite not found. Reinstalling frontend dependencies..."
    Push-Location "$PSScriptRoot\frontend"
    npm ci
    Pop-Location
}

# Start backend server in a new window
$backendWindow = Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoExit","-Command","Set-Location '$PSScriptRoot\backend'; & '.\.venv\Scripts\Activate.ps1'; python app.py 2>&1 | Tee-Object -FilePath $backendLog" -PassThru -WindowStyle Normal

Write-Host "Started backend server (PID: $($backendWindow.Id))"
Start-Sleep -Seconds 2

# Start frontend dev server in a new window (pin port from $env:VITE_PORT)
$frontendCmd = @"
Set-Location '$PSScriptRoot\frontend'
`$env:PATH = '$PSScriptRoot\frontend\node_modules\.bin;' + `$env:PATH
Write-Host 'Starting Vite dev server on port:' `$env:VITE_PORT
# Pass the port explicitly to npm so Vite will bind to the chosen port
npm run dev -- --port `$env:VITE_PORT 2>&1 | Tee-Object -FilePath '$frontendLog'
"@
$frontendWindow = Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoExit","-Command",$frontendCmd -PassThru -WindowStyle Normal

Write-Host "Started frontend server (PID: $($frontendWindow.Id))"
Write-Host "`nServers running at:"
Write-Host "- Backend: http://localhost:5000"
Start-Sleep -Seconds 2
# attempt to read the actual frontend port from the latest frontend log
try {
    $latest = Get-ChildItem -Path "$PSScriptRoot\frontend" -Filter 'frontend_run_*.log' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        $content = Get-Content $latest.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match 'Local:\s+http://localhost:(\d+)/') { $port = $Matches[1] } else { $port = '5173' }
    } else { $port = '5173' }
} catch { $port = '5173' }
Write-Host "- Frontend: http://localhost:$port"
Write-Host "`nLog files:"
Write-Host "- Backend: $PSScriptRoot\backend\$backendLog"
Write-Host "- Frontend: $PSScriptRoot\frontend\$frontendLog"
Write-Host "`nPress Ctrl+C in the respective windows to stop the servers."