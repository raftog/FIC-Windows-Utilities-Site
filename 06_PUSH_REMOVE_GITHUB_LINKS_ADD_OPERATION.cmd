@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - Links Fix
echo   V12 remove GitHub links, add operation
echo ==========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
