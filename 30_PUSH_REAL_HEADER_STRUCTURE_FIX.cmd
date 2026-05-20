@echo off
cd /d "%~dp0"
title F.I.C. Windows Utilities - V30 Real Header Structure Fix
echo ======================================================
echo   F.I.C. Windows Utilities - V30
echo   Real blue header structure + Worker config
echo ======================================================
echo.
echo This version fixes the real problem:
echo HTML did not have the .site-header wrapper that the CSS expected.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
