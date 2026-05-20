@echo off
echo ======================================================
echo   F.I.C. Windows Utilities - Test Worker Download Count
echo ======================================================
echo.
echo This will open the LatencyCheck download through the Worker.
echo The counter should increase after this.
echo.
start "" "https://fic-windows-utilities-counters.gvraftogiannis.workers.dev/download/latencycheck"
timeout /t 5 /nobreak >nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'https://fic-windows-utilities-counters.gvraftogiannis.workers.dev/api/stats' -TimeoutSec 20; Write-Host 'WORKER OK:' $r.StatusCode; Write-Host $r.Content } catch { Write-Host 'WORKER CHECK FAILED:' $_.Exception.Message; exit 2 }"
pause
