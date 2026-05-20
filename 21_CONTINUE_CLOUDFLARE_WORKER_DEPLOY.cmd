@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - Cloudflare
echo   V21 continue Worker deploy after Node install
echo ==========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Deploy_Cloudflare_Worker.ps1"
pause
