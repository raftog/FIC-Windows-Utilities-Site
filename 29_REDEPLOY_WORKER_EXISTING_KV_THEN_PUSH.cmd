@echo off
cd /d "%~dp0"
title F.I.C. Windows Utilities - V29 Redeploy Worker + Push
echo ======================================================
echo   F.I.C. Windows Utilities - V29
echo   Redeploy Worker, use existing KV, then push site
echo ======================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Deploy_Cloudflare_Worker.ps1"
pause
