# ==============================================================================
# BUGWORLD 2026 - Triad Allocation & Ledger Generator (TASK-0004)
# Agent: adminqq | Ratified by: adminq
# Mandates: Canonical Second Foundation ports, Terminology Enforcement, TASK-057
# ==============================================================================

function New-TeamLedger {
    param(
        [string]$TeamParam,
        [string]$PrimarySeat,
        [string]$SecondarySeat,
        [string]$TertiarySeat,
        [string]$base_name
    )

    # Compute OCCR for path generation
    $OCCR = Compute-OCCR -base_name $base_name
    
    # Mandate: Strict Terminology. Standalone "identity" is FORBIDDEN. 
    $ledger = [ordered]@{
        manifest_version = "1.0"
        team_param       = $TeamParam
        generated_at     = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        naming_convention = [ordered]@{
            base_name      = $OCCR.base_name
            code_name      = $OCCR.code_name
            char_count     = $OCCR.char_count
            odd_char_count = $OCCR.odd_char_count
        }
        governance_triad = @(
            [ordered]@{ 
                seat           = "primary"
                base_name      = $PrimarySeat
                code_name      = (Compute-OCCR -base_name $PrimarySeat).code_name
                port           = 4117
                status         = "allocated"
            },
            [ordered]@{ 
                seat           = "secondary"
                base_name      = $SecondarySeat
                code_name      = (Compute-OCCR -base_name $SecondarySeat).code_name
                port           = 4147
                status         = "allocated"
            },
            [ordered]@{ 
                seat           = "tertiary"
                base_name      = $TertiarySeat
                code_name      = (Compute-OCCR -base_name $TertiarySeat).code_name
                port           = 4177
                status         = "allocated"
            }
        )
        core_identity    = "dbug${base_name}"
        admin_identity   = "admin${base_name}"
        ata_status       = "pending_ritual"
    }

    # Materialize Ledger with EXPLICIT LITERAL SEPARATORS (TASK-057 Pillar B)
    $ledgerDir = "C:\dbug\workspace\sessions\x\0"
    if (-not (Test-Path $ledgerDir)) { New-Item -ItemType Directory -Path $ledgerDir -Force | Out-Null }
    
    # Explicit interpolation prevents edge-case merge errors
    $ledgerPath = "$ledgerDir\ata_state_team_${TeamParam}.json" 
    
    # TASK-057 Gate check before write
    if (-not (Validate-PathInterpolation -InputString $ledgerPath)) {
        throw "FATAL: Ledger path failed validation."
    }

    $ledger | ConvertTo-Json -Depth 10 | Out-File -FilePath $ledgerPath -Encoding UTF8
    Write-Host "Ledger materialized: $ledgerPath" -ForegroundColor Green
    
    return $ledgerPath
}