#!/bin/bash
cd "$(dirname "$0")"

# Kill any existing processes
pkill -f "python.*app.py" || true
pkill -f "node.*vite" || true

# Create timestamped log files
timestamp=$(date +%Y%m%d_%H%M%S)
backend_log="backend_run_${timestamp}.log"
frontend_log="frontend_run_${timestamp}.log"

# Start backend
echo "Starting backend server..."
cd backend
python3 -m venv .venv 2>/dev/null || true
source .venv/bin/activate
python app.py > "$backend_log" 2>&1 &
BACKEND_PID=$!

# Start frontend
echo "Starting frontend dev server..."
cd ../frontend
export PATH="$PWD/node_modules/.bin:$PATH"
npm run dev > "$frontend_log" 2>&1 &
FRONTEND_PID=$!

echo -e "\nServers running at:"
echo "- Backend: http://localhost:5000"
echo "- Frontend: http://localhost:5173"

echo -e "\nLog files:"
echo "- Backend: $PWD/../backend/$backend_log"
echo "- Frontend: $PWD/$frontend_log"

echo -e "\nTo stop the servers:"
echo "kill $BACKEND_PID $FRONTEND_PID"

# Wait for either process to exit
wait -n
kill $BACKEND_PID $FRONTEND_PID 2>/dev/null