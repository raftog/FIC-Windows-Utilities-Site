@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - Counters
echo   V13 counters UI and Worker backend
echo ==========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
