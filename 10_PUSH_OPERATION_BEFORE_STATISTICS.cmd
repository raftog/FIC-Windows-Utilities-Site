@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - Layout Fix
echo   V16 operation before statistics
echo ==========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
