#!/usr/bin/env pwsh

Write-Host "Starting local web server for System Design Visualizer..." -ForegroundColor Cyan
Write-Host ""

# Check for Python
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Python found! Starting server on port 8080..." -ForegroundColor Green
        Write-Host ""
        Write-Host "Open your browser and go to: " -NoNewline
        Write-Host "http://localhost:8080" -ForegroundColor Yellow
        Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
        Write-Host ""
        
        Set-Location -Path $PSScriptRoot
        python -m http.server 8080
        exit
    }
} catch {
    # Python not found, continue to check Node.js
}

# Check for Node.js
try {
    $nodeVersion = node --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Node.js found! Starting server on port 8080..." -ForegroundColor Green
        Write-Host ""
        Write-Host "Open your browser and go to: " -NoNewline
        Write-Host "http://localhost:8080" -ForegroundColor Yellow
        Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
        Write-Host ""
        
        Set-Location -Path $PSScriptRoot
        npx http-server -p 8080
        exit
    }
} catch {
    # Node.js not found
}

# Neither found
Write-Host ""
Write-Host "ERROR: Neither Python nor Node.js found!" -ForegroundColor Red
Write-Host "Please install one of the following:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Python: https://www.python.org/downloads/" -ForegroundColor White
Write-Host "2. Node.js: https://nodejs.org/" -ForegroundColor White
Write-Host ""
Write-Host "Or use VS Code with Live Server extension" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"