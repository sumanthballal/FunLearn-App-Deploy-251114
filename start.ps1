# Kill any existing processes
taskkill /F /IM python.exe /IM node.exe 2>$null
netstat -ano | findstr ":5000 :5173" | ForEach-Object { taskkill /F /PID ($_ -split '\s+')[4] 2>$null }

# Set up and start backend
cd backend
if (-not (Test-Path .venv)) {
    python -m venv .venv
}
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Start-Process -NoNewWindow -FilePath ".\.venv\Scripts\python.exe" -ArgumentList "app.py"

# Start frontend
cd ..\frontend
npm install
npm run dev