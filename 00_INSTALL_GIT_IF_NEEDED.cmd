@echo off
echo Installing Git for Windows with winget...
winget install --id Git.Git -e --source winget --scope machine --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
  echo Machine install failed. Trying user scope...
  winget install --id Git.Git -e --source winget --scope user --accept-package-agreements --accept-source-agreements
)
echo.
echo Close this window, open a new CMD if needed, then run 01_DEPLOY_TO_GITHUB_PAGES.cmd
pause
