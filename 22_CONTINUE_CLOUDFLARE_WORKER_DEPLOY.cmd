@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - Cloudflare
echo   V22 continue Worker deploy - argument fix
echo ==========================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Deploy_Cloudflare_Worker.ps1"
pause
