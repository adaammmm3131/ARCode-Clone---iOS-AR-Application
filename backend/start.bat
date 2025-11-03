@echo off
REM ARCode Backend - Windows Startup Script
echo Starting ARCode Backend...

REM Activate virtual environment if it exists
if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate.bat
)

REM Set environment variables
set FLASK_APP=api\app.py
set FLASK_DEBUG=True
set PORT=8080

REM Start Flask server
echo Starting Flask server on http://localhost:8080
python api\app.py

pause


