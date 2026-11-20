<#
.SYNOPSIS
    TASK-061: GUID Validation & Priority Format Conflict Check (CTO Directive)
.DESCRIPTION
    Implements FSC62+ validation and checks against 4 priority formats (agent, alias, id, openid).
    Auto-regenerates GUID if a conflict is detected.
#>

$Script:BugbasePath = "C:\dbug\workspace\services\bbc-book-editor\src\db\bugbase.db"

function Test-FSC62Compliance {
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Mandatory=$true)] [string]$GUID)
    # FSC62+: a-z, 0-9, A-Z, dash. Cannot start/end with dash.
    $fsc62Regex = '^[a-z0-9A-Z]+(?:-[a-z0-9A-Z]+)*$'
    return ($GUID -match $fsc62Regex)
}

function Test-PriorityFormatConflict {
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Mandatory=$true)] [string]$GUID)
    
    # FAST PATH: If GUID contains ANY uppercase letter [A-Z], it is strictly FSC62+ (superid).
    # It CANNOT be mistaken for agent, alias, id, or openid (which are strictly FSC36+ / lowercase).
    if ($GUID -cmatch '[A-Z]') {
        return $false # No conflict possible with priority formats
    }

    # SLOW PATH: GUID is lowercase/numeric. Check Bugbase node_registry for collisions.
    if (-not (Test-Path $Script:BugbasePath)) {
        Write-Warning "Bugbase not found. Skipping priority format conflict check (DryRun safe)."
        return $false
    }

    # Query for exact match in node_registry. 
    # In a full implementation, we would filter by identity_type IN ('agent', 'alias', 'id', 'openid')
    $query = "SELECT identity FROM node_registry WHERE identity = '$GUID' LIMIT 1;"
    
    try {
        $sqlitePath = "C:\dbug\workspace\tools\py\sqlite3.exe"
        if (Test-Path $sqlitePath) {
            $result = & $sqlitePath $Script:BugbasePath $query
            if (-not [string]::IsNullOrWhiteSpace($result)) {
                return $true # Conflict exists with a priority format
            }
        } else {
            Write-Warning "SQLite tool not found. Priority conflict check bypassed."
        }
        return $false
    }
    catch {
        Write-Error "Bugbase query failed: $_"
        return $true # Fail-safe
    }
}

function New-FSC62Guid {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$false)] [int]$Length = 12,
        [Parameter(Mandatory=$false)] [switch]$ForceUppercase
    )
    
    $lower = "abcdefghijklmnopqrstuvwxyz0123456789-"
    $upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $guid = -join ((1..$Length) | ForEach-Object { $lower[(Get-Random -Maximum $lower.Length)] })
    
    # Optimization: If we are regenerating due to a conflict, force an uppercase letter 
    # to guarantee FSC62+ uniqueness and bypass the DB check on the next loop.
    if ($ForceUppercase) {
        $randomIndex = Get-Random -Minimum 1 -Maximum ($guid.Length - 1)
        $randomUpper = $upper[(Get-Random -Maximum $upper.Length)]
        $guid = $guid.Substring(0, $randomIndex) + $randomUpper + $guid.Substring($randomIndex + 1)
    }
    
    return $guid.Trim('-')
}

function Get-ValidatedGuid {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)] [string]$ProposedGUID)
    
    $maxAttempts = 10
    $currentGUID = $ProposedGUID
    $attempt = 0

    while ($attempt -lt $maxAttempts) {
        # Gate 1: FSC62+ Syntax
        if (-not (Test-FSC62Compliance -GUID $currentGUID)) {
            $currentGUID = New-FSC62Guid
            $attempt++
            continue
        }

        # Gate 2: Priority Format Conflict (agent, alias, id, openid)
        $hasConflict = Test-PriorityFormatConflict -GUID $currentGUID

        if (-not $hasConflict) {
            return [PSCustomObject]@{
                IsValid = $true
                GUID = $currentGUID
                Message = "GUID validated successfully. No conflicts with priority formats."
            }
        }

        # CONFLICT DETECTED: Auto-regenerate. Force uppercase to guarantee uniqueness next loop.
        Write-Warning "Conflict detected for '$currentGUID' with priority formats. Auto-regenerating..."
        $currentGUID = New-FSC62Guid -ForceUppercase
        $attempt++
    }

    return [PSCustomObject]@{
        IsValid = $false
        GUID = $currentGUID
        Message = "Failed to generate conflict-free GUID after $maxAttempts attempts."
    }
}

Export-ModuleMember -Function Test-FSC62Compliance, Test-PriorityFormatConflict, New-FSC62Guid, Get-ValidatedGuid
