@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - Changelog
echo   V15 own professional approach
echo ==========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
