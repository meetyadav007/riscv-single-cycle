@echo off
rem Double-click to run the demo and open the waveform in GTKWave.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_demo.ps1" -Wave
echo.
pause
