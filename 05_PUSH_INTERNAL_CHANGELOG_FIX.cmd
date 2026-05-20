@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - Changelog Fix
echo   V11 internal changelog section
echo ==========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
