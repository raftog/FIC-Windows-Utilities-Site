@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - GitHub Pages
echo   V7 Git identity and repo-create fix
echo ==========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Deploy_GitHub_Pages.ps1"
pause
