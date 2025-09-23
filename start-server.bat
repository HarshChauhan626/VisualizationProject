@echo off
echo Starting local web server for System Design Visualizer...
echo.
echo Checking for Python...
python --version >nul 2>&1
if %errorlevel% == 0 (
    echo Python found! Starting server on port 8080...
    echo.
    echo Open your browser and go to: http://localhost:8080
    echo Press Ctrl+C to stop the server
    echo.
    cd /d "%~dp0"
    python -m http.server 8080
) else (
    echo Python not found. Checking for Node.js...
    node --version >nul 2>&1
    if %errorlevel% == 0 (
        echo Node.js found! Starting server on port 8080...
        echo.
        echo Open your browser and go to: http://localhost:8080
        echo Press Ctrl+C to stop the server
        echo.
        cd /d "%~dp0"
        npx http-server -p 8080
    ) else (
        echo.
        echo ERROR: Neither Python nor Node.js found!
        echo Please install one of the following:
        echo.
        echo 1. Python: https://www.python.org/downloads/
        echo 2. Node.js: https://nodejs.org/
        echo.
        echo Or use VS Code with Live Server extension
        echo.
        pause
    )
)