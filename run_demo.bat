@echo off
rem Double-click to run the demo and print the instruction trace.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_demo.ps1"
echo.
pause
