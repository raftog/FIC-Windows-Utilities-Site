@echo off
cd /d "%~dp0"
title F.I.C. Windows Utilities - V31 Worker Stats UI Fix
echo ======================================================
echo   F.I.C. Windows Utilities - V31
echo   Worker country stats UI fix + push
echo ======================================================
echo.
echo === Checking Worker endpoint ===
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'https://fic-windows-utilities-counters.gvraftogiannis.workers.dev/api/stats' -TimeoutSec 20; Write-Host 'WORKER OK:' $r.StatusCode; Write-Host $r.Content } catch { Write-Host 'WORKER CHECK FAILED:' $_.Exception.Message; exit 2 }"
echo.
echo === Pushing site to GitHub Pages ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_Enable_GitHub_Pages.ps1"
pause
