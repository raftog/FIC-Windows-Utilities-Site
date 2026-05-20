@echo off
echo ======================================================
echo   F.I.C. Windows Utilities - Check apps.forensiclabs.gr
echo ======================================================
echo.
echo === DNS CNAME check ===
nslookup -type=CNAME apps.forensiclabs.gr
echo.
echo === HTTPS check ===
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'https://apps.forensiclabs.gr/' -TimeoutSec 20; Write-Host 'SITE OK:' $r.StatusCode } catch { Write-Host 'SITE CHECK FAILED:' $_.Exception.Message }"
echo.
echo === Worker check ===
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'https://fic-windows-utilities-counters.gvraftogiannis.workers.dev/api/stats' -TimeoutSec 20; Write-Host 'WORKER OK:' $r.StatusCode; Write-Host $r.Content } catch { Write-Host 'WORKER CHECK FAILED:' $_.Exception.Message }"
pause
