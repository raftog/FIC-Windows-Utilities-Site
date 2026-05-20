@echo off
echo ======================================================
echo   F.I.C. Windows Utilities - Worker Status Check
echo ======================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'https://fic-windows-utilities-counters.gvraftogiannis.workers.dev/api/stats' -TimeoutSec 20; Write-Host 'WORKER OK:' $r.StatusCode; Write-Host $r.Content } catch { Write-Host 'WORKER CHECK FAILED:' $_.Exception.Message; exit 2 }"
pause
