$line = netstat -aon | Select-String ':5173' | Select-Object -First 1
if ($line) {
  $parts = -split $line
  $pid = $parts[-1]
  Write-Host "Found PID: $pid"
  try {
    Stop-Process -Id $pid -Force -ErrorAction Stop
    Write-Host "Killed PID $pid"
  } catch {
    Write-Host ('Failed to kill PID ' + $pid + ': ' + ($_ | Out-String))
  }
} else {
  Write-Host "No listener on port 5173"
}
