param(
    [Parameter(Mandatory=$false)]
    [string]$PackagePath = (Join-Path $PSScriptRoot 'FIC_Viewer_V1.2.5_SECUREINPUT_BUILD_READY'),

    [Parameter(Mandatory=$false)]
    [string]$CertificateSubject = 'FIC Viewer Private Code Signing',

    [Parameter(Mandatory=$false)]
    [switch]$EnableTestMode
)

$ErrorActionPreference = 'Stop'

function Find-SignTool {
    $roots = @(
        "${env:ProgramFiles(x86)}\Windows Kits\10\bin",
        "${env:ProgramFiles}\Windows Kits\10\bin"
    ) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($root in $roots) {
        $tool = Get-ChildItem $root -Recurse -File -Filter signtool.exe -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\x64\\signtool\.exe$' } |
            Sort-Object FullName -Descending |
            Select-Object -First 1
        if ($tool) { return $tool.FullName }
    }

    throw 'signtool.exe x64 not found. Install Windows SDK/WDK first.'
}

if (-not (Test-Path -LiteralPath $PackagePath)) {
    throw "Package folder not found: $PackagePath"
}

$inf = Join-Path $PackagePath 'FICVhid.inf'
$sys = Join-Path $PackagePath 'FICVhid.sys'
$cat = Join-Path $PackagePath 'FICVhid.cat'

foreach ($path in @($inf,$sys,$cat)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required package file missing: $path"
    }
}

$cert = Get-ChildItem Cert:\CurrentUser\My,Cert:\LocalMachine\My -CodeSigningCert -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Subject -eq "CN=$CertificateSubject" -or
        $_.FriendlyName -eq $CertificateSubject
    } |
    Where-Object { $_.HasPrivateKey -and $_.NotAfter -gt (Get-Date) } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1

if (-not $cert) {
    throw "Code-signing certificate with private key not found: $CertificateSubject"
}

$signtool = Find-SignTool
$machineStore = $cert.PSParentPath -like '*LocalMachine*'

Write-Host "Package:     $PackagePath"
Write-Host "Certificate: $($cert.Subject)"
Write-Host "Thumbprint:  $($cert.Thumbprint)"
Write-Host "SignTool:    $signtool"

$args = @('sign','/v','/fd','SHA256','/sha1',$cert.Thumbprint)
if ($machineStore) { $args += '/sm' }
$args += $cat

& $signtool @args
if ($LASTEXITCODE -ne 0) {
    throw "SignTool sign failed with exit code $LASTEXITCODE"
}

& $signtool verify /v /pa $cat
if ($LASTEXITCODE -ne 0) {
    throw "Catalog signature verification failed with exit code $LASTEXITCODE"
}

& $signtool verify /v /pa /c $cat $inf
if ($LASTEXITCODE -ne 0) {
    throw "INF catalog coverage verification failed with exit code $LASTEXITCODE"
}

& $signtool verify /v /pa /c $cat $sys
if ($LASTEXITCODE -ne 0) {
    throw "SYS catalog coverage verification failed with exit code $LASTEXITCODE"
}

if ($EnableTestMode) {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run PowerShell as Administrator when using -EnableTestMode.'
    }

    & bcdedit.exe /set testsigning on
    if ($LASTEXITCODE -ne 0) {
        throw "BCDEdit failed with exit code $LASTEXITCODE"
    }

    Write-Host 'Test Mode enabled. Reboot Windows before installing the driver.'
}

Write-Host ''
Write-Host 'FIC Viewer V1.2.5 VHF catalog signing: SUCCESS'
Write-Host "Signed catalog: $cat"
Write-Host 'No private key was copied into the package.'
