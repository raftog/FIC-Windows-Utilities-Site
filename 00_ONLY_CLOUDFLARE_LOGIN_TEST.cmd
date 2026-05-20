@echo off
cd /d "%~dp0worker"
echo ==========================================
echo   Cloudflare Wrangler login test
echo ==========================================
npx --yes wrangler login
echo.
echo === whoami ===
npx --yes wrangler whoami
echo.
pause
