@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - Download Fix
echo   V10 direct GitHub release links
echo ==========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
