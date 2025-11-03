@echo off
REM ARCode Backend - Windows Setup Script
echo Setting up ARCode Backend on Windows...

REM Check Python
python --version
if errorlevel 1 (
    echo ERROR: Python not found! Please install Python 3.9+ from https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Create virtual environment
echo Creating virtual environment...
python -m venv venv
if errorlevel 1 (
    echo ERROR: Failed to create virtual environment
    pause
    exit /b 1
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip

REM Install dependencies
echo Installing dependencies...
if exist requirements.txt (
    pip install -r requirements.txt
) else (
    echo WARNING: requirements.txt not found, installing core dependencies...
    pip install Flask Flask-CORS psycopg2-binary redis requests python-dotenv Flask-Limiter PyJWT
)

REM Create .env file if it doesn't exist
if not exist .env (
    echo Creating .env file...
    if exist .env.example (
        copy .env.example .env
        echo .env file created from .env.example
        echo Please edit .env with your configuration
    ) else (
        echo Creating basic .env file...
        (
            echo FLASK_SECRET_KEY=dev-secret-key-change-in-production
            echo FLASK_DEBUG=True
            echo PORT=8080
            echo DB_HOST=localhost
            echo DB_PORT=5432
            echo DB_NAME=arcode_db
            echo DB_USER=postgres
            echo DB_PASSWORD=postgres
            echo REDIS_HOST=localhost
            echo REDIS_PORT=6379
        ) > .env
        echo .env file created with default values
    )
)

echo.
echo Setup complete!
echo.
echo To start the server:
echo   1. Run: start.bat
echo   2. Or manually: python api\app.py
echo.
pause


