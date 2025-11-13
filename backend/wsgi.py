from app import app, init_db

# Ensure database and tables exist when the service boots
try:
    init_db()
except Exception:
    pass

# Expose the Flask app for Gunicorn
# gunicorn wsgi:app
