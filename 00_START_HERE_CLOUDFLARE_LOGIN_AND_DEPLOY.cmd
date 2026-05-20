@echo off
cd /d "%~dp0"
title F.I.C. Windows Utilities - Cloudflare One Click Login + Deploy
echo ======================================================
echo   F.I.C. Windows Utilities - START HERE
echo   Cloudflare browser login + Worker deploy
echo   V27 existing KV aware
echo ======================================================
echo.
echo Simple path. Do NOT use API token here.
echo A browser window will open. Login to Cloudflare and press Allow/Authorize.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start_Cloudflare_Login_Deploy.ps1"
pause
