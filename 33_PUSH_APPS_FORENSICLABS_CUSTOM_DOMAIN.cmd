@echo off
cd /d "%~dp0"
title F.I.C. Windows Utilities - V33 Custom Domain
echo ======================================================
echo   F.I.C. Windows Utilities - V33
echo   Custom domain: apps.forensiclabs.gr
echo ======================================================
echo.
echo This pushes the CNAME file and site identity for:
echo https://apps.forensiclabs.gr/
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
