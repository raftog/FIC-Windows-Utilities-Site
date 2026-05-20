@echo off
cd /d "%~dp0"
title F.I.C. Windows Utilities - V32 Official Name
echo ======================================================
echo   F.I.C. Windows Utilities - V32
echo   Official public name + Worker identity
echo ======================================================
echo.
echo Official name: F.I.C. Windows Utilities
echo Worker: fic-windows-utilities-counters
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
