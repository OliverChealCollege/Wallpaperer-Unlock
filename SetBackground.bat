@echo off
if "%~1"=="" (
    echo Drag an image file onto this file to set it as your background.
    pause
    exit /b
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0@Resources\Browse.ps1" -Source "%~1"
