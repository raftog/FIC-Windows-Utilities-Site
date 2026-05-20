$ErrorActionPreference = "Stop"

# v25: ASCII-only script. This avoids Windows PowerShell parsing failures caused by UTF-8/Greek text.
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}

$Root = $PSScriptRoot
$WorkerDir = Join-Path $Root "worker"
$DeployScript = Join-Path $Root "Deploy_Cloudflare_Worker.ps1"

function Step([string]$Text) {
  Write-Host ""
  Write-Host "=== $Text ===" -ForegroundColor Cyan
}

function Find-Exe([string]$Name, [string[]]$Paths) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  foreach ($p in $Paths) {
    if ($p -and (Test-Path -LiteralPath $p)) {
      $folder = Split-Path -Parent $p
      if ($env:PATH -notlike "*$folder*") {
        $env:PATH = "$folder;$env:PATH"
      }
      return $p
    }
  }

  return $null
}

function Ensure-Node {
  Step "Checking Node.js and npm"

  $node = Find-Exe "node.exe" @(
    "$env:ProgramFiles\nodejs\node.exe",
    "$env:LOCALAPPDATA\Programs\nodejs\node.exe"
  )
  $npm = Find-Exe "npm.cmd" @(
    "$env:ProgramFiles\nodejs\npm.cmd",
    "$env:LOCALAPPDATA\Programs\nodejs\npm.cmd"
  )

  if ($node -and $npm) {
    Write-Host "Node.js OK: $node" -ForegroundColor Green
    Write-Host "npm OK: $npm" -ForegroundColor Green
    return
  }

  Write-Host "Node.js/npm not found. Installing Node.js LTS with winget..." -ForegroundColor Yellow

  $winget = Find-Exe "winget.exe" @("$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe")
  if (-not $winget) {
    throw "winget.exe was not found. Install Node.js LTS manually, then run this script again."
  }

  & $winget install --id OpenJS.NodeJS.LTS -e --source winget --scope machine --accept-package-agreements --accept-source-agreements
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Machine install failed or needs elevation. Trying user scope..." -ForegroundColor Yellow
    & $winget install --id OpenJS.NodeJS.LTS -e --source winget --scope user --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
      throw "Node.js installation failed."
    }
  }

  $nodeFolder = "$env:ProgramFiles\nodejs"
  if (Test-Path -LiteralPath $nodeFolder) {
    $env:PATH = "$nodeFolder;$env:PATH"
  }

  $node = Find-Exe "node.exe" @("$env:ProgramFiles\nodejs\node.exe", "$env:LOCALAPPDATA\Programs\nodejs\node.exe")
  $npm = Find-Exe "npm.cmd" @("$env:ProgramFiles\nodejs\npm.cmd", "$env:LOCALAPPDATA\Programs\nodejs\npm.cmd")

  if (-not ($node -and $npm)) {
    throw "Node.js appears installed but is not visible in this session. Open a new CMD window and run this again."
  }
}

function Run-Wrangler([string[]]$WranglerArgs, [switch]$Capture) {
  Push-Location $WorkerDir
  try {
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
      $oldNative = $PSNativeCommandUseErrorActionPreference
      $PSNativeCommandUseErrorActionPreference = $false
    } else {
      $oldNative = $null
    }

    try {
      $cmdArgs = @("--yes", "wrangler") + $WranglerArgs

      if ($Capture) {
        $out = & npx @cmdArgs 2>&1
        $code = $LASTEXITCODE
        return @{ Code = $code; Output = ($out -join "`n") }
      } else {
        & npx @cmdArgs
        $code = $LASTEXITCODE
        return @{ Code = $code; Output = "" }
      }
    } finally {
      $ErrorActionPreference = $oldEap
      if ($null -ne $oldNative) {
        $PSNativeCommandUseErrorActionPreference = $oldNative
      }
    }
  } finally {
    Pop-Location
  }
}

function Is-NotAuthenticated([string]$Text, [int]$Code) {
  if ($Code -ne 0) { return $true }
  if ($Text -match "not authenticated") { return $true }
  if ($Text -match "You are not authenticated") { return $true }
  if ($Text -match "Please run") { return $true }
  return $false
}

Ensure-Node

Step "Cloudflare browser login"
Write-Host "A browser window will open." -ForegroundColor Yellow
Write-Host "Log in to Cloudflare and click Allow / Authorize for Wrangler." -ForegroundColor Yellow
Write-Host "Do not use API token. Do not add a domain." -ForegroundColor Yellow

$login = Run-Wrangler -WranglerArgs @("login")
if ($login.Code -ne 0) {
  throw "Cloudflare browser login command failed. Run this script again and authorize Wrangler in the browser."
}

Step "Verifying Cloudflare login"
$who = Run-Wrangler -WranglerArgs @("whoami") -Capture
Write-Host $who.Output

if (Is-NotAuthenticated $who.Output $who.Code) {
  throw "Cloudflare login is still not active. Run this script again and finish the browser authorization."
}

Write-Host "Cloudflare login OK." -ForegroundColor Green

Step "Deploying Worker and updating GitHub Pages"
& powershell -NoProfile -ExecutionPolicy Bypass -File $DeployScript

if ($LASTEXITCODE -ne 0) {
  throw "Deploy script failed."
}

Step "Finished"
Write-Host "Open this URL after 1-3 minutes and press Ctrl+F5:" -ForegroundColor Green
Write-Host "https://raftog.github.io/FIC-Windows-Utilities-Site/#statistics" -ForegroundColor Green
