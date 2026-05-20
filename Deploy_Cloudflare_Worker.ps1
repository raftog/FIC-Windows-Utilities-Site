$ErrorActionPreference = "Stop"
# v21: npm/npx/wrangler can write harmless notices to stderr. Do not let that abort the script.
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) { $PSNativeCommandUseErrorActionPreference = $false }

$WorkerName = "fic-windows-utilities-counters"
$BindingName = "DOWNLOAD_STATS"
$WorkerDir = Join-Path $PSScriptRoot "worker"
$WranglerToml = Join-Path $WorkerDir "wrangler.toml"
$WorkerConfigJs = Join-Path $PSScriptRoot "assets\js\worker-config.js"
$RepairScript = Join-Path $PSScriptRoot "Repair_Enable_GitHub_Pages.ps1"

function Step($t) {
  Write-Host ""
  Write-Host "=== $t ===" -ForegroundColor Cyan
}

function Find-Exe($name, [string[]]$paths) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  foreach ($p in $paths) {
    if ($p -and (Test-Path -LiteralPath $p)) {
      $folder = Split-Path -Parent $p
      if ($env:PATH -notlike "*$folder*") { $env:PATH = "$folder;$env:PATH" }
      return $p
    }
  }
  return $null
}

function Ensure-Node {
  Step "Checking Node.js / npm"
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
    Write-Host "Machine-scope install failed or needs elevation. Trying user-scope..." -ForegroundColor Yellow
    & $winget install --id OpenJS.NodeJS.LTS -e --source winget --scope user --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
      throw "Node.js installation failed."
    }
  }

  $nodeFolder = "$env:ProgramFiles\nodejs"
  if (Test-Path $nodeFolder) { $env:PATH = "$nodeFolder;$env:PATH" }

  $node = Find-Exe "node.exe" @("$env:ProgramFiles\nodejs\node.exe", "$env:LOCALAPPDATA\Programs\nodejs\node.exe")
  $npm = Find-Exe "npm.cmd" @("$env:ProgramFiles\nodejs\npm.cmd", "$env:LOCALAPPDATA\Programs\nodejs\npm.cmd")
  if (-not ($node -and $npm)) {
    throw "Node.js appears installed but is not visible in this session. Open a new CMD and run this script again."
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
        if ($code -ne 0) {
          throw "Wrangler command failed: wrangler $($WranglerArgs -join ' ')"
        }
      }
    } finally {
      $ErrorActionPreference = $oldEap
      if ($null -ne $oldNative) { $PSNativeCommandUseErrorActionPreference = $oldNative }
    }
  } finally {
    Pop-Location
  }
}

function Ensure-CloudflareLogin {
  Step "Checking Cloudflare login"
  $who = Run-Wrangler -WranglerArgs @("whoami") -Capture
  if ($who.Code -ne 0) {
    Write-Host "Cloudflare login is required. Browser login will open. Ignore harmless npm notices." -ForegroundColor Yellow
    Run-Wrangler -WranglerArgs @("login")
  } else {
    Write-Host $who.Output
  }
}

function Get-KVNamespaceIdFromListOutput([string]$Text) {
  $id = $null

  # Wrangler usually returns JSON for kv namespace list.
  try {
    $jsonStart = $Text.IndexOf("[")
    if ($jsonStart -ge 0) {
      $jsonText = $Text.Substring($jsonStart)
      $items = $jsonText | ConvertFrom-Json
      foreach ($item in $items) {
        if ($item.title -eq $BindingName -or $item.title -eq "DOWNLOAD_STATS") {
          return $item.id
        }
      }
    }
  } catch {}

  # Fallback for table/plain output.
  $lines = $Text -split "`r?`n"
  foreach ($line in $lines) {
    if ($line -match "DOWNLOAD_STATS" -and $line -match "([a-f0-9]{32})") {
      return $Matches[1]
    }
  }

  return $null
}

function Set-KVNamespaceIdInToml([string]$Id) {
  if (-not $Id) {
    throw "Empty KV namespace id."
  }

  $toml = Get-Content -LiteralPath $WranglerToml -Raw -Encoding UTF8

  if ($toml -match "PUT_KV_NAMESPACE_ID_HERE") {
    $toml = $toml.Replace("PUT_KV_NAMESPACE_ID_HERE", $Id)
  } elseif ($toml -match 'id\s*=\s*"[a-f0-9]{32}"') {
    $toml = [regex]::Replace($toml, 'id\s*=\s*"[a-f0-9]{32}"', "id = `"$Id`"", 1)
  } else {
    $toml += "`n[[kv_namespaces]]`nbinding = `"DOWNLOAD_STATS`"`nid = `"$Id`"`n"
  }

  Set-Content -LiteralPath $WranglerToml -Value $toml -Encoding UTF8
  Write-Host "KV namespace configured in wrangler.toml: $Id" -ForegroundColor Green
}

function Find-ExistingKVNamespace {
  Step "Looking for existing KV namespace"
  $list = Run-Wrangler -WranglerArgs @("kv", "namespace", "list") -Capture
  Write-Host $list.Output

  if ($list.Code -ne 0) {
    Write-Host "Could not list KV namespaces." -ForegroundColor Yellow
    return $null
  }

  return Get-KVNamespaceIdFromListOutput $list.Output
}

function Ensure-KVNamespace {
  Step "Ensuring KV namespace"
  $toml = Get-Content -LiteralPath $WranglerToml -Raw -Encoding UTF8

  if ($toml -match 'id\s*=\s*"([a-f0-9]{32})"' -and $Matches[1] -ne "PUT_KV_NAMESPACE_ID_HERE") {
    Write-Host "wrangler.toml already has a KV namespace id: $($Matches[1])" -ForegroundColor Green
    return
  }

  $existingId = Find-ExistingKVNamespace
  if ($existingId) {
    Write-Host "Existing KV namespace DOWNLOAD_STATS found: $existingId" -ForegroundColor Green
    Set-KVNamespaceIdInToml $existingId
    return
  }

  Write-Host "No existing DOWNLOAD_STATS namespace found. Creating it..." -ForegroundColor Yellow
  $created = Run-Wrangler -WranglerArgs @("kv", "namespace", "create", $BindingName) -Capture
  Write-Host $created.Output

  if ($created.Code -ne 0) {
    if ($created.Output -match "already exists") {
      Write-Host "KV namespace already exists. Listing namespaces and using existing id..." -ForegroundColor Yellow
      $existingId = Find-ExistingKVNamespace
      if ($existingId) {
        Set-KVNamespaceIdInToml $existingId
        return
      }
    }
    throw "KV namespace creation failed."
  }

  if ($created.Output -match "(?m)^COMMANDS\s*$" -or $created.Output -match "wrangler docs") {
    throw "Wrangler did not receive the KV arguments correctly."
  }

  $id = $null
  if ($created.Output -match 'id\s*=\s*"([^"]+)"') {
    $id = $Matches[1]
  } elseif ($created.Output -match '"id"\s*:\s*"([^"]+)"') {
    $id = $Matches[1]
  } elseif ($created.Output -match "([a-f0-9]{32})") {
    $id = $Matches[1]
  }

  if (-not $id) {
    Write-Host "Could not parse id from create output. Trying list..." -ForegroundColor Yellow
    $id = Find-ExistingKVNamespace
  }

  if (-not $id) {
    throw "Could not parse or find KV namespace id."
  }

  Set-KVNamespaceIdInToml $id
}


function Deploy-Worker {
  Step "Deploying Cloudflare Worker"
  $deploy = Run-Wrangler -WranglerArgs @("deploy") -Capture
  Write-Host $deploy.Output

  if ($deploy.Code -ne 0) {
    $needsWorkersDev = ($deploy.Output -match "register a workers.dev subdomain") -or
                       ($deploy.Output -match "workers/onboarding") -or
                       ($deploy.Output -match "publishing to workers.dev")

    if ($needsWorkersDev) {
      Write-Host ""
      Write-Host "Cloudflare requires a workers.dev subdomain before first Worker publishing." -ForegroundColor Yellow

      $onboardingUrl = $null
      if ($deploy.Output -match '(https://dash\.cloudflare\.com/[^\s"]+/workers/onboarding)') {
        $onboardingUrl = $Matches[1]
      } else {
        $onboardingUrl = "https://dash.cloudflare.com/"
      }

      Write-Host "Opening Cloudflare Workers onboarding:" -ForegroundColor Yellow
      Write-Host $onboardingUrl -ForegroundColor Yellow
      Start-Process $onboardingUrl

      Write-Host ""
      Write-Host "In the browser:" -ForegroundColor Cyan
      Write-Host "1. Register a workers.dev subdomain." -ForegroundColor Cyan
      Write-Host "2. Use a simple name, for example: fic-windows-utilities or gvraftogiannis." -ForegroundColor Cyan
      Write-Host "3. Do not add a custom domain now." -ForegroundColor Cyan
      Write-Host "4. When Cloudflare finishes setup, return here." -ForegroundColor Cyan
      Write-Host ""

      Read-Host "Press ENTER here after the workers.dev subdomain is registered"

      Step "Retrying Cloudflare Worker deploy"
      $deploy = Run-Wrangler -WranglerArgs @("deploy") -Capture
      Write-Host $deploy.Output

      if ($deploy.Code -ne 0) {
        throw "Worker deployment failed after workers.dev onboarding."
      }
    } else {
      throw "Worker deployment failed."
    }
  }

  $url = $null
  if ($deploy.Output -match '(https://[a-zA-Z0-9.-]+\.workers\.dev)') {
    $url = $Matches[1]
  }

  if (-not $url) {
    Write-Host ""
    Write-Host "Could not auto-detect workers.dev URL from deploy output." -ForegroundColor Yellow
    $url = Read-Host "Paste the Worker URL shown by Cloudflare/Wrangler"
  }

  if (-not $url.StartsWith("https://")) {
    throw "Invalid Worker URL: $url"
  }

  return $url.TrimEnd("/")
}

function Update-SiteWorkerConfig($workerUrl) {
  Step "Updating site Worker configuration"
  $js = @"
// F.I.C. Windows Utilities counters Worker configuration.
// Generated by 20_DEPLOY_CLOUDFLARE_WORKER.cmd
window.FIC_COUNTER_WORKER_BASE = "$workerUrl";
"@
  Set-Content -LiteralPath $WorkerConfigJs -Value $js -Encoding UTF8
  Write-Host "Worker URL configured in assets/js/worker-config.js:" -ForegroundColor Green
  Write-Host $workerUrl -ForegroundColor Green
}

function Push-Site {
  Step "Pushing updated GitHub Pages site"
  if (Test-Path -LiteralPath $RepairScript) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $RepairScript
  } else {
    Write-Host "Repair_Enable_GitHub_Pages.ps1 not found. Push the site manually." -ForegroundColor Yellow
  }
}

Ensure-Node
Ensure-CloudflareLogin
Ensure-KVNamespace
$workerUrl = Deploy-Worker
Update-SiteWorkerConfig $workerUrl
Push-Site

Step "Done"
Write-Host "Cloudflare Worker active:" -ForegroundColor Green
Write-Host $workerUrl -ForegroundColor Green
Write-Host ""
Write-Host "Test endpoints:"
Write-Host "$workerUrl/api/stats"
Write-Host "$workerUrl/download/latencycheck"
Write-Host "$workerUrl/download/harddisktemp"
Write-Host ""
Write-Host "After GitHub Pages finishes building, refresh:"
Write-Host "https://raftog.github.io/FIC-Windows-Utilities-Site/#statistics"
