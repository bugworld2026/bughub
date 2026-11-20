# ==============================================================================
# BUGWORLD 2026 - Path Safety & OCCR Module (TASK-0004)
# Agent: admin-q | Ratified by: adminq
# Mandates: TASK-057 (Regex + No Traversal), OCCR (Odd Character Count Rule)
# ==============================================================================

function Validate-PathInterpolation {
    param([string]$InputString)
    
    # Mandate: Block path traversal
    if ($InputString -match '\.\.') {
        Write-Host "FATAL: Path traversal detected." -ForegroundColor Red
        return $false
    }
    
    # Mandate: Canonical FSC62+ ordering (a-z, 0-9, A-Z, then _/.\\:-)
    $validPattern = '^[a-z0-9A-Z_\/\\:\.\-]+$'
    if ($InputString -notmatch $validPattern) {
        Write-Host "FATAL: Invalid characters in input string. Must match FSC62+ canonical set." -ForegroundColor Red
        return $false
    }
    
    return $true
}

function Compute-OCCR {
    param([string]$base_name)
    
    $len = $base_name.Length
    $is_odd = ($len % 2 -ne 0)
    
    if ($is_odd) {
        $code_name = "${base_name}-"
    } else {
        $code_name = $base_name
    }
    
    return @{
        base_name      = $base_name
        code_name      = $code_name
        char_count     = $len
        odd_char_count = $is_odd
    }
}