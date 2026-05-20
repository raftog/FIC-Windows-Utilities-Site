@echo off
cd /d "%~dp0"
title F.I.C. Windows Utilities - Use existing KV + Deploy
echo ======================================================
echo   F.I.C. Windows Utilities - Cloudflare
echo   V27 use existing KV namespace and continue deploy
echo ======================================================
echo.
echo Cloudflare login is already OK.
echo This version will use existing DOWNLOAD_STATS KV if it already exists.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Deploy_Cloudflare_Worker.ps1"
pause
