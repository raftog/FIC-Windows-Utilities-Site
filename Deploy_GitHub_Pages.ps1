$ErrorActionPreference = "Stop"

$Owner = "raftog"
$Repo  = "FIC-Windows-Utilities-Site"
$Full  = "$Owner/$Repo"
$Branch = "main"

# Local repository identity only. It does not change global Windows/Git settings.
$LocalGitName  = "G.V. Raftogiannis FIC"
$LocalGitEmail = "gvraftogiannis@gmail.com"

function Step($t) {
  Write-Host ""
  Write-Host "=== $t ===" -ForegroundColor Cyan
}

function Find-Executable($name, [string[]]$extraPaths) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  foreach ($p in $extraPaths) {
    if ($p -and (Test-Path -LiteralPath $p)) { return $p }
  }

  return $null
}

function Add-ToolFolderToPath($exePath) {
  if (-not $exePath) { return }
  $folder = Split-Path -Parent $exePath
  if ($env:PATH -notlike "*$folder*") {
    $env:PATH = "$folder;$env:PATH"
  }
}

function Ensure-Git {
  Step "Checking Git"
  $gitPaths = @(
    "$env:ProgramFiles\Git\cmd\git.exe",
    "$env:ProgramFiles\Git\bin\git.exe",
    "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
    "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
  )

  $git = Find-Executable "git.exe" $gitPaths
  if ($git) {
    Add-ToolFolderToPath $git
    Write-Host "git.exe OK: $git" -ForegroundColor Green
    return
  }

  Write-Host "git.exe was not found. Trying automatic Git installation with winget..." -ForegroundColor Yellow

  $winget = Find-Executable "winget.exe" @(
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
  )

  if (-not $winget) {
    throw "git.exe was not found and winget.exe is not available. Install Git for Windows manually, then run this script again."
  }

  & $winget install --id Git.Git -e --source winget --scope machine --accept-package-agreements --accept-source-agreements
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Machine-scope Git install failed or needs elevation. Trying user-scope install..." -ForegroundColor Yellow
    & $winget install --id Git.Git -e --source winget --scope user --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
      throw "Git installation failed. Install Git for Windows manually, then run this script again."
    }
  }

  Start-Sleep -Seconds 3
  $git = Find-Executable "git.exe" $gitPaths
  if (-not $git) {
    throw "Git appears installed but git.exe was not found in this session. Close this CMD window, open a new one, and run 01_DEPLOY_TO_GITHUB_PAGES.cmd again."
  }

  Add-ToolFolderToPath $git
  Write-Host "git.exe OK after install: $git" -ForegroundColor Green
}

function Ensure-GH {
  Step "Checking GitHub CLI"
  $ghPaths = @(
    "$env:ProgramFiles\GitHub CLI\gh.exe",
    "${env:ProgramFiles(x86)}\GitHub CLI\gh.exe",
    "$env:LOCALAPPDATA\Programs\GitHub CLI\gh.exe"
  )

  $gh = Find-Executable "gh.exe" $ghPaths
  if ($gh) {
    Add-ToolFolderToPath $gh
    Write-Host "gh.exe OK: $gh" -ForegroundColor Green
    return
  }

  Write-Host "gh.exe was not found. Trying automatic GitHub CLI installation with winget..." -ForegroundColor Yellow

  $winget = Find-Executable "winget.exe" @(
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
  )

  if (-not $winget) {
    throw "gh.exe was not found and winget.exe is not available. Install GitHub CLI manually, then run this script again."
  }

  & $winget install --id GitHub.cli -e --source winget --scope machine --accept-package-agreements --accept-source-agreements
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Machine-scope GitHub CLI install failed or needs elevation. Trying user-scope install..." -ForegroundColor Yellow
    & $winget install --id GitHub.cli -e --source winget --scope user --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
      throw "GitHub CLI installation failed. Install GitHub CLI manually, then run this script again."
    }
  }

  Start-Sleep -Seconds 3
  $gh = Find-Executable "gh.exe" $ghPaths
  if (-not $gh) {
    throw "GitHub CLI appears installed but gh.exe was not found in this session. Close this CMD window, open a new one, and run 01_DEPLOY_TO_GITHUB_PAGES.cmd again."
  }

  Add-ToolFolderToPath $gh
  Write-Host "gh.exe OK after install: $gh" -ForegroundColor Green
}

function Repo-Exists($fullName) {
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $out = & gh repo view $fullName 2>&1
  $code = $LASTEXITCODE
  $ErrorActionPreference = $oldPreference

  if ($code -eq 0) {
    return $true
  }

  Write-Host "Repository was not found or is not accessible yet. It will be created." -ForegroundColor Yellow
  return $false
}

Ensure-Git
Ensure-GH

Step "Checking GitHub login"
& gh auth status
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "GitHub CLI is not logged in." -ForegroundColor Yellow
  Write-Host "A browser login will open now. Choose GitHub.com and authorize the raftog account."
  & gh auth login -h github.com -w
  if ($LASTEXITCODE -ne 0) { throw "GitHub login failed." }
}

Step "Checking index.html"
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot "index.html"))) {
  throw "index.html is not in this folder."
}
Write-Host "index.html found." -ForegroundColor Green

Set-Location -LiteralPath $PSScriptRoot

Step "Initializing git"
if (-not (Test-Path ".git")) {
  git init
  if ($LASTEXITCODE -ne 0) { throw "git init failed." }
}

git branch -M $Branch

Step "Setting local Git identity"
git config user.name  "$LocalGitName"
git config user.email "$LocalGitEmail"
Write-Host "Local git user.name/user.email configured for this repository only." -ForegroundColor Green

Step "Creating commit"
git add .
git commit -m "Initial FIC Windows Utilities GitHub Pages site"
if ($LASTEXITCODE -ne 0) {
  Write-Host "No new commit was created. Checking whether a commit already exists..." -ForegroundColor Yellow
  git rev-parse --verify HEAD *> $null
  if ($LASTEXITCODE -ne 0) {
    throw "Commit failed and no existing commit was found."
  }
}

Step "Creating or connecting repository"
$exists = Repo-Exists $Full
if (-not $exists) {
  gh repo create $Full --public --source=. --remote=origin --push
  if ($LASTEXITCODE -ne 0) { throw "Repository creation or push failed." }
} else {
  Write-Host "Repository already exists: $Full"
  $remotes = git remote
  if ($remotes -notcontains "origin") {
    git remote add origin "https://github.com/$Full.git"
  } else {
    git remote set-url origin "https://github.com/$Full.git"
  }
  git push -u origin $Branch
  if ($LASTEXITCODE -ne 0) { throw "Push failed." }
}

Step "Enabling GitHub Pages"
$oldPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
gh api --method POST "repos/$Full/pages" -F "source[branch]=$Branch" -F "source[path]=/" 2>$null
$postCode = $LASTEXITCODE
$ErrorActionPreference = $oldPreference

if ($postCode -ne 0) {
  $ErrorActionPreference = "Continue"
  gh api --method PUT "repos/$Full/pages" -F "source[branch]=$Branch" -F "source[path]=/" 2>$null
  $putCode = $LASTEXITCODE
  $ErrorActionPreference = $oldPreference

  if ($putCode -ne 0) {
    Write-Host "Automatic Pages setup failed." -ForegroundColor Yellow
    Write-Host "Manual path: GitHub repository -> Settings -> Pages -> Deploy from branch -> main -> /root"
  } else {
    Write-Host "GitHub Pages source updated." -ForegroundColor Green
  }
} else {
  Write-Host "GitHub Pages enabled." -ForegroundColor Green
}

Step "Done"
Write-Host "Repository: https://github.com/$Full" -ForegroundColor Green
Write-Host "Site:       https://$Owner.github.io/$Repo/" -ForegroundColor Green
Write-Host "Stats:      https://$Owner.github.io/$Repo/#statistics" -ForegroundColor Green
Write-Host ""
Write-Host "If GitHub says Pages is building, wait 1-3 minutes and refresh the URL."
