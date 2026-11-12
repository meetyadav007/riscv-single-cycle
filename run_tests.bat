@echo off
rem Double-click to run every testbench.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_tests.ps1"
echo.
pause
