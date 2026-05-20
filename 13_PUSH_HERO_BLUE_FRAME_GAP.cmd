@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - Hero Frame
echo   V19 blue frame and bottom gap
echo ==========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
