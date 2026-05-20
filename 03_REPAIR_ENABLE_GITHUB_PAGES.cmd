@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - Pages Repair
echo   V9 remote already has commits fix
echo ==========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
