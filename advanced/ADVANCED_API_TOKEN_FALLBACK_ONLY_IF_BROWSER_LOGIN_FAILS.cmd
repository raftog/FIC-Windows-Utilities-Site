@echo off
cd /d "%~dp0"
echo ==========================================
echo   F.I.C. Windows Utilities - Cloudflare
echo   V23 API token fallback
echo ==========================================
echo.
echo Paste Cloudflare API token with Workers/KV permissions.
echo It will be stored only for this CMD session.
echo.
set /p CLOUDFLARE_API_TOKEN=Cloudflare API Token: 
if "%CLOUDFLARE_API_TOKEN%"=="" (
  echo No token entered.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Deploy_Cloudflare_Worker.ps1"
pause
