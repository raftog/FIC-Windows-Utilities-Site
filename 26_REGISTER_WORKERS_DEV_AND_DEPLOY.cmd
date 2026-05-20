@echo off
cd /d "%~dp0"
title F.I.C. Windows Utilities - Register workers.dev + Deploy
echo ======================================================
echo   F.I.C. Windows Utilities - workers.dev setup
echo   V26 register workers.dev and continue deploy
echo ======================================================
echo.
echo Cloudflare already logged in and KV is ready.
echo This will open the workers.dev setup if Cloudflare asks for it.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Deploy_Cloudflare_Worker.ps1"
pause
