# ==============================================================================
# BUGWORLD 2026 - Second Foundation Onboarding Wizard (TASK-0004)
# Agent: adminx | Ratified by: adminq
# Mandates: ZTTD (Corrected), TASK-057, OCCR
# ==============================================================================
param(
    [string]$TeamParam = "",
    [switch]$ForceGovernanceOverride
)

$ErrorActionPreference = 'Stop'

# Dot-source the foundation modules
$ScriptDir = $PSScriptRoot
. "$ScriptDir\path_safety_gate.ps1"
. "$ScriptDir\triad_ledger_generator.ps1"

Write-Host "=== BUGWORLD 2026: Second Foundation Onboarding Wizard ===" -ForegroundColor Cyan

# 1. Collect Team PARAM
if ([string]::IsNullOrWhiteSpace($TeamParam)) {
    $TeamParam = Read-Host "Enter new Team PARAM (alphanumeric, 6-10 chars)"
}

# 2. TASK-057 Pre-flight Validation Gate
if (-not (Validate-PathInterpolation -InputString $TeamParam)) {
    Write-Host "FATAL: Team PARAM failed TASK-057 validation." -ForegroundColor Red
    exit 1
}

# 3. Governance Triad Seat Allocation Prompt
Write-Host "`nAllocating Governance Triad seats for Team $TeamParam..." -ForegroundColor Yellow
$primarySeat   = Read-Host "Assign Primary Seat base_name (default: q)"
$secondarySeat = Read-Host "Assign Secondary Seat base_name (default: -q)"
$tertiarySeat  = Read-Host "Assign Tertiary Seat base_name (default: qq)"

# Default fallbacks
if ([string]::IsNullOrWhiteSpace($primarySeat)) { $primarySeat = "q" }
if ([string]::IsNullOrWhiteSpace($secondarySeat)) { $secondarySeat = "-q" }
if ([string]::IsNullOrWhiteSpace($tertiarySeat)) { $tertiarySeat = "qq" }

# Display allocation (ZTTD compliant: displays base_name as provided)
Write-Host "`nTriad Allocation Confirmed:" -ForegroundColor Green
Write-Host "  Primary   : $primarySeat"
Write-Host "  Secondary : $secondarySeat"
Write-Host "  Tertiary  : $tertiarySeat"

# 4. Generate Ledger
$operatorBaseName = "x" # Hardcoded for the invoking operator on BUGBASE-PC2
Write-Host "`nGenerating Team Ledger..." -ForegroundColor Cyan
New-TeamLedger -TeamParam $TeamParam -PrimarySeat $primarySeat -SecondarySeat $secondarySeat -TertiarySeat $tertiarySeat -base_name $operatorBaseName

# 5. Trigger /init_ata CLI Ritual
Write-Host "`nInitiating ATA CLI Ritual..." -ForegroundColor Cyan
$ataCommand = "/init_ata --team=$TeamParam --primary=$primarySeat --secondary=$secondarySeat --tertiary=$tertiarySeat"
if ($ForceGovernanceOverride) {
    $ataCommand += " --force-governance-override"
}

Write-Host "Executing: $ataCommand" -ForegroundColor DarkGray

Write-Host "`n=== ONBOARDING WIZARD COMPLETE ===" -ForegroundColor Green
Write-Host "Team $TeamParam successfully prepared for Second Foundation integration." -ForegroundColor Green
Read-Host 'Press ENTER to close the wizard...'

