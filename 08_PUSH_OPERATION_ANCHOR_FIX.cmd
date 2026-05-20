@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - Anchor Fix
echo   V14 operation target sections
echo ==========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
