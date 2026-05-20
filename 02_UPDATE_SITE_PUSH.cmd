@echo off
cd /d "%~dp0"
where git >nul 2>nul
if errorlevel 1 (
  echo ERROR: git.exe was not found in PATH.
  pause
  exit /b 1
)
git status >nul 2>nul
if errorlevel 1 (
  echo ERROR: This folder is not a git repository yet. Run 01_DEPLOY_TO_GITHUB_PAGES.cmd first.
  pause
  exit /b 1
)
git add .
git commit -m "Update FIC Windows Utilities site"
git push origin main
pause
