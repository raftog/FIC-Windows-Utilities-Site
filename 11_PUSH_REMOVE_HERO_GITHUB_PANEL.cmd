@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - Hero Fix
echo   V17 remove GitHub Releases panel
echo ==========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
