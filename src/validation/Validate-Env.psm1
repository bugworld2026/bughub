<#
.SYNOPSIS
    TASK-062: ENV Input & Multi-Environment Support Module
.DESCRIPTION
    Implements ENV format validation and uniqueness checks within the client's GUID scope.
    Aligns with memory.md §14.8 (Machine-Agnostic Schema).
#>

$Script:BugbasePath = "C:\dbug\workspace\services\bbc-book-editor\src\db\bugbase.db"

function Test-EnvFormat {
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Mandatory=$true)] [string]$ENV)
    
    # ENV must be alphanumeric + dash. Case-insensitive for format, but case-sensitive for uniqueness.
    $envRegex = '^[a-zA-Z0-9-]+$'
    return ($ENV -match $envRegex)
}

function Test-EnvUniqueness {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)] [string]$GUID,
        [Parameter(Mandatory=$true)] [string]$ENV
    )
    
    if (-not (Test-Path $Script:BugbasePath)) {
        Write-Warning "Bugbase not found. Skipping ENV uniqueness check (DryRun safe)."
        return $true # Assume unique if DB is missing
    }

    # Query client_registry for existing ENVs under this specific GUID
    # Note: In a full implementation, we would filter by GUID and check if ENV already exists.
    $query = "SELECT env FROM client_registry WHERE guid = '$GUID' AND env = '$ENV' LIMIT 1;"
    
    try {
        $sqlitePath = "C:\dbug\workspace\tools\py\sqlite3.exe"
        if (Test-Path $sqlitePath) {
            $result = & $sqlitePath $Script:BugbasePath $query
            if (-not [string]::IsNullOrWhiteSpace($result)) {
                return $false # Conflict exists (ENV already used for this GUID)
            }
        } else {
            Write-Warning "SQLite tool not found. ENV uniqueness check bypassed."
        }
        return $true # Unique
    }
    catch {
        Write-Error "Bugbase query failed: $_"
        return $false # Fail-safe
    }
}

function Get-ValidatedEnv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string]$GUID,
        [Parameter(Mandatory=$true)] [string]$ProposedENV
    )
    
    $validationResult = [PSCustomObject]@{
        ENV = $ProposedENV
        Format_Valid = $false
        Is_Unique = $false
        IsValid = $false
        Message = ""
    }

    # Gate 1: Format Validation
    if (-not (Test-EnvFormat -ENV $ProposedENV)) {
        $validationResult.Message = "ENV violates format rules (alphanumeric + dash only)."
        return $validationResult
    }
    $validationResult.Format_Valid = $true

    # Gate 2: Uniqueness within GUID scope
    if (-not (Test-EnvUniqueness -GUID $GUID -ENV $ProposedENV)) {
        $validationResult.Message = "ENV '$ProposedENV' is already in use for GUID '$GUID'."
        return $validationResult
    }
    $validationResult.Is_Unique = $true

    # Passed all gates
    $validationResult.IsValid = $true
    $validationResult.Message = "ENV validated successfully."
    return $validationResult
}

Export-ModuleMember -Function Test-EnvFormat, Test-EnvUniqueness, Get-ValidatedEnv
