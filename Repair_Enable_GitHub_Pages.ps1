$ErrorActionPreference = "Stop"

$Owner = "raftog"
$Repo  = "FIC-Windows-Utilities-Site"
$Full  = "$Owner/$Repo"
$Branch = "main"
$LocalGitName  = "G.V. Raftogiannis FIC"
$LocalGitEmail = "gvraftogiannis@gmail.com"

function Step($t) {
  Write-Host ""
  Write-Host "=== $t ===" -ForegroundColor Cyan
}

function Need($cmd, [string[]]$paths) {
  $c = Get-Command $cmd -ErrorAction SilentlyContinue
  if ($c) { return $c.Source }
  foreach ($p in $paths) {
    if ($p -and (Test-Path -LiteralPath $p)) {
      $folder = Split-Path -Parent $p
      if ($env:PATH -notlike "*$folder*") { $env:PATH = "$folder;$env:PATH" }
      return $p
    }
  }
  throw "$cmd not found."
}

function Push-Main-With-Reconcile {
  Step "Pushing main branch"

  git push -u origin $Branch
  if ($LASTEXITCODE -eq 0) {
    Write-Host "Push OK." -ForegroundColor Green
    return
  }

  Write-Host ""
  Write-Host "Normal push was rejected because the remote repository already contains commits." -ForegroundColor Yellow
  Write-Host "Reconciling remote main with local site files, without deleting local files..." -ForegroundColor Yellow

  git fetch origin $Branch
  if ($LASTEXITCODE -ne 0) {
    throw "git fetch origin main failed."
  }

  git merge --allow-unrelated-histories -X ours --no-edit "origin/$Branch"
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Automatic merge failed. Aborting merge and using safe force-with-lease for this new site repository..." -ForegroundColor Yellow
    git merge --abort 2>$null

    git push --force-with-lease -u origin $Branch
    if ($LASTEXITCODE -ne 0) {
      throw "Push failed even after reconcile / force-with-lease."
    }

    Write-Host "Push OK with force-with-lease." -ForegroundColor Green
    return
  }

  git push -u origin $Branch
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Push after merge failed. Trying force-with-lease for this new site repository..." -ForegroundColor Yellow
    git push --force-with-lease -u origin $Branch
    if ($LASTEXITCODE -ne 0) {
      throw "Push failed after merge and force-with-lease."
    }
  }

  Write-Host "Push OK after remote reconciliation." -ForegroundColor Green
}

Step "Checking tools"
Need "git.exe" @("$env:ProgramFiles\Git\cmd\git.exe", "$env:ProgramFiles\Git\bin\git.exe", "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe") | Out-Null
Need "gh.exe"  @("$env:ProgramFiles\GitHub CLI\gh.exe", "$env:LOCALAPPDATA\Programs\GitHub CLI\gh.exe") | Out-Null
Write-Host "Tools OK." -ForegroundColor Green

Step "Checking GitHub login"
gh auth status
if ($LASTEXITCODE -ne 0) {
  gh auth login -h github.com -w
  if ($LASTEXITCODE -ne 0) { throw "GitHub login failed." }
}

Step "Checking repository folder"
Set-Location -LiteralPath $PSScriptRoot
if (-not (Test-Path -LiteralPath "index.html")) {
  throw "index.html not found. Run this from the FIC-Windows-Utilities-Site folder."
}
Write-Host "index.html found." -ForegroundColor Green

Step "Ensuring git repository and commit"
if (-not (Test-Path ".git")) {
  git init
}
git branch -M $Branch
git config user.name  "$LocalGitName"
git config user.email "$LocalGitEmail"

$remotes = git remote
if ($remotes -contains "origin") {
  git remote set-url origin "https://github.com/$Full.git"
} else {
  git remote add origin "https://github.com/$Full.git"
}

git add .
git commit -m "Deploy FIC Windows Utilities site"
if ($LASTEXITCODE -ne 0) {
  Write-Host "No new commit was created; continuing with existing commit." -ForegroundColor Yellow
}

git rev-parse --verify HEAD *> $null
if ($LASTEXITCODE -ne 0) {
  throw "No local commit exists. Cannot push."
}

Step "Ensuring repository exists"
$repoOutput = gh repo view $Full 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Host "Repository does not exist yet. Creating it..." -ForegroundColor Yellow
  gh repo create $Full --public --source=. --remote=origin --push
  if ($LASTEXITCODE -ne 0) { throw "Repository creation failed." }
} else {
  Write-Host "Repository exists: $Full" -ForegroundColor Green
  Push-Main-With-Reconcile
}

Step "Enabling or repairing GitHub Pages"
$pagesOutput = gh api "repos/$Full/pages" 2>&1
if ($LASTEXITCODE -eq 0) {
  Write-Host "Pages already exists. Updating source to main / root..." -ForegroundColor Green
  $body = @{
    source = @{
      branch = $Branch
      path   = "/"
    }
  } | ConvertTo-Json -Depth 5
  $body | gh api --method PUT "repos/$Full/pages" --input -
  if ($LASTEXITCODE -ne 0) {
    Write-Host "PUT update failed. Existing Pages settings may already be correct." -ForegroundColor Yellow
  }
} else {
  Write-Host "Pages not enabled yet. Creating Pages site from main / root..." -ForegroundColor Yellow
  $body = @{
    source = @{
      branch = $Branch
      path   = "/"
    }
  } | ConvertTo-Json -Depth 5
  $body | gh api --method POST "repos/$Full/pages" --input -
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Automatic Pages creation failed." -ForegroundColor Yellow
    Write-Host "Manual path: GitHub repo -> Settings -> Pages -> Deploy from branch -> main -> /root"
  }
}

Step "Reading Pages status"
gh api "repos/$Full/pages" 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Pages status is not available yet. Check manually in Settings -> Pages." -ForegroundColor Yellow
}

Step "Open URLs"
$SiteUrl = "https://$Owner.github.io/$Repo/"
$StatsUrl = "https://$Owner.github.io/$Repo/#statistics"

Write-Host ""
Write-Host "Repository: https://github.com/$Full" -ForegroundColor Green
Write-Host "Site:       $SiteUrl" -ForegroundColor Green
Write-Host "Stats:      $StatsUrl" -ForegroundColor Green
Write-Host ""
Write-Host "If you still see 404, wait 2-5 minutes and refresh with Ctrl+F5."
Write-Host "If it still shows 404 after that, open GitHub -> repo -> Settings -> Pages and confirm: main / root."

Start-Process $SiteUrl
