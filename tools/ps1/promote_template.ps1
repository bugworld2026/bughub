# promote_template_v2.ps1
# Purpose: Moves a validated PS1 script from src\templates\ps1 to tools\ps1 
# and automatically strips the "_PARTIAL" suffix to indicate production readiness.

param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptName
)

$templateDir = "C:\dbug\workspace\bughub-installer\src\templates\ps1"
$toolsDir = "C:\dbug\workspace\bughub-installer\tools\ps1"
$sourcePath = Join-Path $templateDir $ScriptName

if (-not (Test-Path $sourcePath)) {
    Write-Host "FATAL: Template not found at $sourcePath" -ForegroundColor Red
    exit 1
}

# LOGIC: Strip the _PARTIAL suffix for the production name
$cleanName = $ScriptName -replace '_PARTIAL', ''
$destPath = Join-Path $toolsDir $cleanName

if (Test-Path $destPath) {
    Write-Host "WARNING: A validated script named '$cleanName' already exists in tools. Overwriting..." -ForegroundColor Yellow
}

# Execute Move
Move-Item -Path $sourcePath -Destination $destPath -Force

Write-Host "[+] Successfully promoted '$ScriptName'." -ForegroundColor Green
Write-Host "    Renamed to production standard: '$cleanName'" -ForegroundColor Cyan
Write-Host "    Ready for execution: .\$cleanName" -ForegroundColor DarkGray