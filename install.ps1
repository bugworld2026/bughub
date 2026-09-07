<#
.SYNOPSIS
    BUGHUB Installer - Phase 2 Installation System
.DESCRIPTION
    Deterministic installer for BUGWORLD 2026 ecosystem with permanent node doctrine.
    Creates two permanent PTS/APTS pairs (secret_agent + superid) and three-root structure.
    
    Aligns with:
    - memory.md §14.8 (Machine-Agnostic Schema)
    - memory.md §16 (BUGWORLD Governance)
    - tasks_manifest.json TASK-060 through TASK-073
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[a-z0-9A-Z-]+$')]
    [string]$GUID,
    
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^[a-z0-9-]+$')]
    [string]$ENV,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipATA,
    
    [Parameter(Mandatory=$false)]
    [switch]$ForcePermanent,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Import installer module
$modulePath = Join-Path $PSScriptRoot "src\installer\Install-Manifest.psm1"
Import-Module $modulePath -Force

# Configuration
$InstallerVersion = "1.0.0"
$BUGWORLD_ROOT = "C:\dbug"
$WorkspacePath = Join-Path $BUGWORLD_ROOT "workspace"
$DocsPath = Join-Path $WorkspacePath "docs"
$SessionsPath = Join-Path $WorkspacePath "sessions\x\0\logs"
$ManifestPath = Join-Path $DocsPath "install_manifest.json"
$LogPath = Join-Path $SessionsPath "install_$((Get-Date).ToString('yyyyMMdd_HHmmss')).log"

if (-not (Test-Path $SessionsPath)) {
    New-Item -ItemType Directory -Force -Path $SessionsPath | Out-Null
}

function Write-InstallLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    switch ($Level) {
        'SUCCESS' { Write-Host $logEntry -ForegroundColor Green }
        'WARNING' { Write-Host $logEntry -ForegroundColor Yellow }
        'ERROR' { Write-Host $logEntry -ForegroundColor Red }
        default { Write-Host $logEntry }
    }
    $logEntry | Out-File -FilePath $LogPath -Append -Encoding UTF8
}

function Initialize-InstallManifest {
    [CmdletBinding()]
    param()
    Write-InstallLog "Creating installation manifest..." -Level INFO
    $manifest = New-InstallManifest -GUID $GUID -ENV $ENV -InstallerVersion $InstallerVersion
    if ($DryRun) { Write-InstallLog "[DRY RUN] Manifest would be saved to: $ManifestPath" -Level WARNING; return $manifest }
    Save-InstallManifest -Manifest $manifest -Path $ManifestPath
    Write-InstallLog "Installation manifest created: $ManifestPath" -Level SUCCESS
    return $manifest
}

function Create-ThreeRootStructure {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)] [hashtable]$Manifest)
    Write-InstallLog "Creating three-root filesystem structure..." -Level INFO
    $allPaths = @($Manifest.filesystem.roots) + @($Manifest.filesystem.directories)
    foreach ($path in $allPaths) {
        if ($DryRun) { Write-InstallLog "[DRY RUN] Would create directory: $path" -Level WARNING }
        else {
            if (-not (Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null; Write-InstallLog "Created: $path" -Level SUCCESS }
            else { Write-InstallLog "Already exists: $path" -Level INFO }
        }
    }
}

function Create-ServiceStubs {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)] [hashtable]$Manifest)
    Write-InstallLog "Creating 12 permanent service stubs..." -Level INFO
    $servicesPath = Join-Path $BUGWORLD_ROOT "workspace\services"
    foreach ($service in $Manifest.filesystem.services) {
        $servicePath = Join-Path $servicesPath $service.name
        if ($DryRun) { Write-InstallLog "[DRY RUN] Would create service stub: $($service.name) (Port $($service.port))" -Level WARNING; continue }
        if (-not (Test-Path $servicePath)) {
            New-Item -ItemType Directory -Force -Path $servicePath | Out-Null
            $packageJson = @{name=$service.name; version="1.0.0"; description="BUGWORLD 2026 - $($service.name)"} | ConvertTo-Json
            $packageJson | Out-File -FilePath (Join-Path $servicePath "package.json") -Encoding UTF8
            Write-InstallLog "Created service stub: $($service.name) (Port $($service.port))" -Level SUCCESS
        }
    }
}

function Create-MCPNodeStubs {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)] [hashtable]$Manifest)
    Write-InstallLog "Creating MCP node stubs..." -Level INFO
    $agentPath = Join-Path $BUGWORLD_ROOT "agent\x\0\$GUID\$ENV"
    foreach ($node in $Manifest.filesystem.mcp_nodes) {
        $identityForm = $node.identity -replace '^dbug', ''
        $nodePath = Join-Path $agentPath "$identityForm\$identityForm\mcp"
        if ($DryRun) { Write-InstallLog "[DRY RUN] Would create MCP node: $($node.identity) (Port $($node.port))" -Level WARNING; continue }
        if (-not (Test-Path $nodePath)) {
            New-Item -ItemType Directory -Force -Path $nodePath | Out-Null
            $serverPy = "# BUGWORLD 2026 - MCP Node Stub`n# Identity: $($node.identity)`n# Port: $($node.port)`n# Role: $($node.role)"
            $serverPy | Out-File -FilePath (Join-Path $nodePath "server.py") -Encoding UTF8
            Write-InstallLog "Created MCP node stub: $($node.identity) (Port $($node.port))" -Level SUCCESS
        }
    }
}

function Create-PermanentNodes {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)] [hashtable]$Manifest)
    Write-InstallLog "Creating PERMANENT nodes (secret_agent + superid)..." -Level INFO
    Write-InstallLog "⚠️  These nodes CANNOT be removed without --force-permanent flag" -Level WARNING
    $permanentNodes = @(
        @{Path=$Manifest.permanent_nodes.secret_agent.path; Identity=$Manifest.permanent_nodes.secret_agent.identity},
        @{Path=$Manifest.permanent_nodes.superid.path; Identity=$Manifest.permanent_nodes.superid.identity}
    )
    foreach ($node in $permanentNodes) {
        $nodeDir = Split-Path -Parent $node.Path
        if ($DryRun) { Write-InstallLog "[DRY RUN] Would create PERMANENT node: $($node.Identity)" -Level WARNING; continue }
        if (-not (Test-Path $nodeDir)) {
            New-Item -ItemType Directory -Force -Path $nodeDir | Out-Null
            $serverPy = "# BUGWORLD 2026 - PERMANENT NODE`n# Identity: $($node.Identity)`n# Permanent: TRUE"
            $serverPy | Out-File -FilePath $node.Path -Encoding UTF8
            Write-InstallLog "✅ Created PERMANENT node: $($node.Identity)" -Level SUCCESS
        }
    }
}

function Write-RegistryKeys {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)] [hashtable]$Manifest)
    Write-InstallLog "Writing Windows registry keys..." -Level INFO
    if ($DryRun) { return }
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) { Write-InstallLog "⚠️  Not running as administrator. Registry keys will not be written." -Level WARNING; return }
    try {
        $bugworldKey = "HKLM:\SOFTWARE\BUGWORLD"
        if (-not (Test-Path $bugworldKey)) { New-Item -Path $bugworldKey -Force | Out-Null }
        New-ItemProperty -Path $bugworldKey -Name "InstallPath" -Value $BUGWORLD_ROOT -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $bugworldKey -Name "Version" -Value $InstallerVersion -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $bugworldKey -Name "GUID" -Value $GUID -PropertyType String -Force | Out-Null
        New-ItemProperty -Path $bugworldKey -Name "ENV" -Value $ENV -PropertyType String -Force | Out-Null
        Write-InstallLog "Registry keys written to: HKLM:\SOFTWARE\BUGWORLD" -Level SUCCESS
    } catch { Write-InstallLog "Failed to write registry keys: $_" -Level ERROR }
}

function Set-EnvironmentVariables {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)] [hashtable]$Manifest)
    Write-InstallLog "Setting environment variables..." -Level INFO
    if ($DryRun) { return }
    try {
        [Environment]::SetEnvironmentVariable("BUGWORLD_ROOT", $BUGWORLD_ROOT, "Machine")
        [Environment]::SetEnvironmentVariable("BUGWORLD_GUID", $GUID, "Machine")
        [Environment]::SetEnvironmentVariable("BUGWORLD_ENV", $ENV, "Machine")
        Write-InstallLog "Environment variables set (machine-level)" -Level SUCCESS
    } catch { Write-InstallLog "Failed to set environment variables: $_" -Level ERROR }
}

function Invoke-ATARitual {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)] [hashtable]$Manifest)
    if ($SkipATA) { Write-InstallLog "Skipping ATA ritual (--SkipATA specified)" -Level WARNING; return }
    Write-InstallLog "Executing ATA Unified Ritual..." -Level INFO
    if ($DryRun) { return }
    $ataScript = Join-Path $PSScriptRoot "tools\ata\bootstrap_and_ata_pc3_295905.ps1"
    if (Test-Path $ataScript) { & $ataScript -User "dbugx" -Promote "all" -Triad "force"; Write-InstallLog "ATA ritual completed" -Level SUCCESS }
    else { Write-InstallLog "ATA script not found, skipping" -Level WARNING }
}

function Start-Installation {
    [CmdletBinding()]
    param()
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  BUGWORLD 2026 - Phase 2 Installer" -ForegroundColor Cyan
    Write-Host "  Version: $InstallerVersion" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-InstallLog "Installation started" -Level INFO
    if ($DryRun) { Write-InstallLog "️  DRY RUN MODE - No changes will be made" -Level WARNING }
    try {
        $manifest = Initialize-InstallManifest
        Create-ThreeRootStructure -Manifest $manifest
        Create-ServiceStubs -Manifest $manifest
        Create-MCPNodeStubs -Manifest $manifest
        Create-PermanentNodes -Manifest $manifest
        Write-RegistryKeys -Manifest $manifest
        Set-EnvironmentVariables -Manifest $manifest
        Invoke-ATARitual -Manifest $manifest
        Write-Host "============================================================" -ForegroundColor Green
        if ($DryRun) { Write-Host "  DRY RUN COMPLETE" -ForegroundColor Yellow } else { Write-Host "  INSTALLATION SUCCESSFUL" -ForegroundColor Green }
        Write-Host "============================================================" -ForegroundColor Green
        Write-InstallLog "Installation completed" -Level SUCCESS
    } catch {
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host "  INSTALLATION FAILED" -ForegroundColor Red
        Write-Host "============================================================" -ForegroundColor Red
        Write-InstallLog "Installation failed: $_" -Level ERROR
        exit 1
    }
}

# ============================================================================
# TASK-061: GUID Validation Module Integration (Bugbase Conflict Check)
# ============================================================================
$validationModulePath = Join-Path $PSScriptRoot "src\validation\Validate-Guid.psm1"
Import-Module $validationModulePath -Force

Write-InstallLog "Validating GUID against Bugbase node_registry: $GUID (TASK-061)" -Level INFO
$guidValidation = Get-ValidatedGuid -ProposedGUID $GUID

if (-not $guidValidation.IsValid) {
    Write-InstallLog "❌ GUID VALIDATION FAILED: $($guidValidation.Message)" -Level ERROR
    Write-Host "Installation aborted. Please provide a valid, unique FSC62+ compliant GUID." -ForegroundColor Red
    exit 1
}
Write-InstallLog "✅ GUID validation passed (FSC62+ compliant and no Bugbase conflicts)." -Level SUCCESS

# ============================================================================
# TASK-062: ENV Validation Module Integration (Multi-Environment Support)
# ============================================================================
$envValidationModulePath = Join-Path $PSScriptRoot "src\validation\Validate-Env.psm1"
Import-Module $envValidationModulePath -Force

Write-InstallLog "Validating ENV '$ENV' for GUID '$GUID' (TASK-062)" -Level INFO
$envValidation = Get-ValidatedEnv -GUID $GUID -ProposedENV $ENV

if (-not $envValidation.IsValid) {
    Write-InstallLog "❌ ENV VALIDATION FAILED: $($envValidation.Message)" -Level ERROR
    Write-Host "Installation aborted. Please provide a valid, unique ENV identifier." -ForegroundColor Red
    exit 1
}
Write-InstallLog "✅ ENV validation passed (Format valid and unique within GUID scope)." -Level SUCCESS

# Execute installation
Start-Installation

