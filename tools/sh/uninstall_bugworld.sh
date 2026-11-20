#!/bin/bash
# ============================================================================
# UNINSTALL BUGWORLD - Full Deletion with Recursive Cleanup
# Strategy: PowerShell handles Windows paths and recursive empty dir removal
# ============================================================================

set -e

# ============================================================================
# 1. ROBUST CLEANUP TRAP
# ============================================================================
cleanup() {
    rm -f ./temp_uninstall.ps1
}
trap cleanup EXIT

# ============================================================================
# 2. CANONICAL VARIABLES
# ============================================================================
GUID="BUGWORLD2026TestSite22"
ENV="0"

# ============================================================================
# 3. CONFIRMATION
# ============================================================================
echo "========================================================================"
echo " UNINSTALL BUGWORLD - Full Deletion"
echo "========================================================================"
echo ""
echo "This will DELETE:"
echo "  - config.json"
echo "  - bugbase.db"
echo "  - server.py (SPAS stub)"
echo "  - 2cp1.zip (cassette)"
echo "  - logs/ directory"
echo "  - All empty OCCR-expanded directories up to the GUID root"
echo ""
read -p "Are you sure? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall aborted"
    exit 0
fi

# ============================================================================
# 4. DELEGATE TO POWERSHELL
# ============================================================================
echo " Initializing PowerShell deletion..."

cat > ./temp_uninstall.ps1 << 'PSEOF'
param([string]$GUID, [string]$ENV)

$Base = "C:\dbug"
$configDest = "$Base\workspace\sessions\$GUID\$ENV\config\config.json"
$spasDest = "$Base\superid\$GUID\$ENV\B\U\G\W\O\R\L\D\2\0\2\6\T\e\s\t\S\i\t\e\2\2\22\mcp\server.py"
$cassetteDest = "$Base\workspace\cassettes\2cp1.zip"
$dbDest = "$Base\workspace\sessions\$GUID\$ENV\config\bugbase.db"
$logsDir = "$Base\workspace\sessions\$GUID\$ENV\logs"

Write-Host " Deleting files..."

$files = @($configDest, $spasDest, $cassetteDest, $dbDest)
foreach ($file in $files) {
    if (Test-Path $file) {
        Remove-Item -Force -Path $file
        Write-Host "Deleted: $file"
    } else { Write-Host "Not found: $file" }
}

if (Test-Path $logsDir) {
    Remove-Item -Recurse -Force -Path $logsDir
    Write-Host "Deleted: $logsDir"
}

# Recursive Empty Directory Cleanup
Write-Host " Cleaning up empty directories recursively..."
$dirsToCheck = @(
    (Split-Path $configDest),
    (Split-Path $spasDest)
)

foreach ($startDir in $dirsToCheck) {
    $current = $startDir
    while ($current -and $current -ne "$Base\superid\$GUID" -and $current -ne "$Base\workspace\sessions\$GUID") {
        if (Test-Path $current) {
            $items = Get-ChildItem -Path $current -Force
            if ($items.Count -eq 0) {
                Remove-Item -Force -Path $current
                Write-Host "Removed empty dir: $current"
                $current = Split-Path $current
            } else { break }
        } else { break }
    }
}

Write-Host " Full uninstallation complete."
PSEOF

powershell.exe -ExecutionPolicy Bypass -File "./temp_uninstall.ps1" -GUID "$GUID" -ENV "$ENV" || true

echo ""
echo "========================================================================"
echo " FULL UNINSTALLATION COMPLETE"
echo "========================================================================"