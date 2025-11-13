Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
cd "C:\Users\balla\Desktop\Funlearn"
# Activate venv
. .\.venv\Scripts\Activate.ps1
# Start Flask app (use python -c to avoid relying on environment FLASK_APP)
python -c "import importlib; m = importlib.import_module('backend.app'); getattr(m,'app').run(host='127.0.0.1', port=5001, debug=True)"
