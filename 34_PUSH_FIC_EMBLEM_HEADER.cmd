@echo off
cd /d "%~dp0"
title F.I.C. Windows Utilities - V34 FIC Emblem Header
echo ======================================================
echo   F.I.C. Windows Utilities - V34
echo   F.I.C. emblem in top header
echo ======================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
