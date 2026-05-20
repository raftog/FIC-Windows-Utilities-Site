@echo off
echo ======================================================
echo   F.I.C. Windows Utilities - Check site and Worker
echo ======================================================
echo.
echo === apps.forensiclabs.gr ===
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'https://apps.forensiclabs.gr/' -TimeoutSec 20; Write-Host 'SITE OK:' $r.StatusCode } catch { Write-Host 'SITE CHECK FAILED:' $_.Exception.Message }"
echo.
echo === Worker ===
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'https://fic-windows-utilities-counters.gvraftogiannis.workers.dev/api/stats' -TimeoutSec 20; Write-Host 'WORKER OK:' $r.StatusCode; Write-Host $r.Content } catch { Write-Host 'WORKER CHECK FAILED:' $_.Exception.Message }"
pause
