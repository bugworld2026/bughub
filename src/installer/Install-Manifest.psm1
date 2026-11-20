<#
.SYNOPSIS
    BUGHUB Installer Manifest Module
.DESCRIPTION
    Manages the installation manifest JSON schema and tracking for TASK-060
    Aligns with BUGWORLD 2026 Permanent Node Doctrine and Machine-Agnostic Schema
#>

$Script:ManifestPath = "C:\dbug\workspace\docs\install_manifest.json"
$Script:SchemaPath = Join-Path $PSScriptRoot "..\..\config\install_manifest_schema.json"

function New-InstallManifest {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^[a-z0-9A-Z-]+$')]
        [string]$GUID,
        
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^[a-z0-9-]+$')]
        [string]$ENV,
        
        [Parameter(Mandatory=$false)]
        [string]$InstallerVersion = "1.0.0"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    
    # Generate superid form from GUID (FSC62+ transformation)
    $superidForm = Get-SuperidFromGuid -GUID $GUID
    
    $manifest = @{
        manifest_version = "1.0.0"
        created_at = $timestamp
        client_info = @{
            guid = $GUID
            env = $ENV
            installed_at = $timestamp
            installer_version = $InstallerVersion
        }
        permanent_nodes = @{
            secret_agent = @{
                type = "PTS/APTS"
                identity = "dbugsecret-agent"
                admin_identity = "adminsecret-agent"
                path = "C:\dbug\agent\x\0\$GUID\$ENV\secret-agent\mcp\server.py"
                port = 0  # To be allocated
                permanent = $true
                services_access = @(2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012)
            }
            superid = @{
                type = "PTS/APTS"
                identity = "dbug$superidForm"
                admin_identity = "admin$superidForm"
                path = "C:\dbug\superid\x\0\$GUID\$ENV\$superidForm\mcp\server.py"
                port = 0  # To be allocated
                permanent = $true
                services_access = @(2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012)
                generation_rule = "FSC62+ alphabet (a-z, 0-9, A-Z, dash) derived from GUID"
            }
        }
        filesystem = @{
            roots = @(
                "C:\dbug\agent\",
                "C:\dbug\superid\",
                "C:\dbug\workspace\"
            )
            directories = @(
                "C:\dbug\workspace\services\",
                "C:\dbug\workspace\sessions\x\0\logs\",
                "C:\dbug\workspace\docs\",
                "C:\dbug\workspace\theia-blueprint\",
                "C:\dbug\workspace\tiangan-core\"
            )
            services = @(
                @{port=2001; name="tiangan-core"},
                @{port=2002; name="orchestrator"},
                @{port=2003; name="agent-dashboard"},
                @{port=2004; name="alias-monitor"},
                @{port=2005; name="bugswitch-control"},
                @{port=2006; name="bbc-book-editor"},
                @{port=2007; name="calculator-electron"},
                @{port=2008; name="maths-reader"},
                @{port=2009; name="button-express"},
                @{port=2010; name="theia-blueprint"},
                @{port=2011; name="health-orchestrator"},
                @{port=2012; name="gaia-machine"}
            )
            mcp_nodes = @(
                @{port=2103; identity="dbugc-"; role="Primary"},
                @{port=2217; identity="dbug-q"; role="Secondary"},
                @{port=2124; identity="dbugx-"; role="Tertiary"},
                @{port=2116; identity="dbugp-"; role="Guest"},
                @{port=2117; identity="dbugq-"; role="Guest"},
                @{port=2317; identity="dbugqq"; role="Guest"}
            )
            alias_root = @{
                port = 3101
                alias = "absol"
                formal = "absol-"
                path = "C:\dbug\alias\x\0\a\b\s\o\l-\l-\mcp\server.py"
            }
        }
        registry = @{
            keys = @(
                "HKLM\SOFTWARE\BUGWORLD\InstallPath",
                "HKLM\SOFTWARE\BUGWORLD\Version",
                "HKLM\SOFTWARE\BUGWORLD\GUID",
                "HKLM\SOFTWARE\BUGWORLD\ENV",
                "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\BUGWORLD"
            )
            environment_variables = @(
                "BUGWORLD_ROOT",
                "BUGWORLD_GUID",
                "BUGWORLD_ENV"
            )
        }
        cassette_workflow = @{
            insert = @{
                tool = "tools/py/insert_cassette.py"
                manifests = "C:\dbug\tools\csv\"
                target_drive = "NcpM (thousand-series)"
            }
            eject = @{
                tool = "tools/py/eject_cassette.py"
                preserves = @("secret_agent", "superid")
            }
        }
        governance = @{
            triple_gate = @{
                bugswitch_required = "OFF"
                ata_required = $true
                identity_validation = "governance_triad"
            }
            wizards = @(
                "Wizard 1: Team Formation",
                "Wizard 2: ATA Ritual",
                "Wizard 3: BUGSWITCH Toggle",
                "Wizard 4: BBC BOOK Editing"
            )
        }
        validation = @{
            guid_validation = @{
                alphabet = "FSC62+ (a-z, 0-9, A-Z, dash)"
                conflict_check = "Bugbase node_registry lookup"
                tool = "tools/py/validate_guid.ps1"
            }
            env_validation = @{
                format = "alphanumeric + dash"
                uniqueness = "per GUID scope"
                multi_env_support = $true
            }
        }
    }
    
    return $manifest
}

function Get-SuperidFromGuid {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$GUID
    )
    
    # FSC62+ transformation: convert GUID to superid form
    # This is a simplified version - actual implementation would use FSC62+ rules
    $superidForm = $GUID -replace '[^a-z0-9A-Z-]', ''
    if ([string]::IsNullOrEmpty($superidForm)) {
        $superidForm = "superid-" + (Get-Date -Format "yyyyMMdd")
    }
    
    return $superidForm
}

function Save-InstallManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Manifest,
        
        [Parameter(Mandatory=$false)]
        [string]$Path = $Script:ManifestPath
    )
    
    # Ensure directory exists
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    
    # Convert to JSON and save
    $json = $Manifest | ConvertTo-Json -Depth 10
    $json | Out-File -FilePath $Path -Encoding UTF8
    
    Write-Verbose "Install manifest saved to: $Path"
}

function Test-InstallManifest {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Path = $Script:ManifestPath
    )
    
    if (-not (Test-Path $Path)) {
        Write-Verbose "Install manifest not found at: $Path"
        return $false
    }
    
    try {
        $manifest = Get-Content -Path $Path -Raw | ConvertFrom-Json
        Write-Verbose "Install manifest validated successfully"
        return $true
    }
    catch {
        Write-Error "Invalid install manifest: $_"
        return $false
    }
}

function Get-InstallManifest {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Path = $Script:ManifestPath
    )
    
    if (-not (Test-Path $Path)) {
        throw "Install manifest not found at: $Path"
    }
    
    $manifest = Get-Content -Path $Path -Raw | ConvertFrom-Json
    return $manifest
}

# Export module members
Export-ModuleMember -Function `
    New-InstallManifest, `
    Save-InstallManifest, `
    Test-InstallManifest, `
    Get-InstallManifest, `
    Get-SuperidFromGuid
