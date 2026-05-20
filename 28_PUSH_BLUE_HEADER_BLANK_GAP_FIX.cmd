@echo off
cd /d "%~dp0"
title F.I.C. Windows Utilities - Blue Header Blank Gap Fix
echo ======================================================
echo   F.I.C. Windows Utilities - Blue Header Gap Fix
echo   V28 leave blank gap below blue frame
echo ======================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
