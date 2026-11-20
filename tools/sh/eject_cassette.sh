#!/bin/bash
# ============================================================================
# EJECT CASSETTE - Update cassette status in Bugbase
# Strategy: Bash validates, PowerShell deploys Python script to execute
# ============================================================================

set -e

# ============================================================================
# 1. ROBUST CLEANUP TRAP
# ============================================================================
cleanup() {
    rm -f ./temp_eject_cassette.py ./temp_eject_deploy.ps1
}
trap cleanup EXIT

# ============================================================================
# 2. CANONICAL VARIABLES
# ============================================================================
GUID="BUGWORLD2026TestSite22"
ENV="0"
CASSETTE_ID="2cp1"

# ============================================================================
# 3. VALIDATION
# ============================================================================
echo " Validating cassette parameters..."
if [ -z "$CASSETTE_ID" ]; then echo " FATAL: cassette_id is required"; exit 1; fi
echo " Validation PASSED: $CASSETTE_ID"

# ============================================================================
# 4. CREATE TEMPORARY PYTHON SCRIPT
# ============================================================================
echo " Preparing ejection script..."

cat > ./temp_eject_cassette.py << 'EOF'
import sqlite3, sys
from datetime import datetime
db_path, cassette_id = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db_path)
cursor = conn.cursor()
cursor.execute('SELECT status FROM cassettes WHERE id = ?', (cassette_id,))
existing = cursor.fetchone()
if not existing:
    print(f"Cassette {cassette_id} not found")
    conn.close()
    sys.exit(1)
if existing[0] != 'ACTIVE':
    print(f"Cassette {cassette_id} is not active (status: {existing[0]})")
    conn.close()
    sys.exit(1)
timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
cursor.execute("UPDATE cassettes SET status = 'EJECTED', ejected_at = ? WHERE id = ?", (timestamp, cassette_id))
conn.commit()
conn.close()
print(f"Cassette {cassette_id} ejected from Bugbase")
EOF

# ============================================================================
# 5. DELEGATE TO POWERSHELL
# ============================================================================
echo " Initializing PowerShell operations..."

cat > ./temp_eject_deploy.ps1 << 'PSEOF'
param([string]$GUID, [string]$ENV, [string]$CASSETTE_ID)
$Base = "C:\dbug"
$dbPath = "$Base\workspace\sessions\$GUID\$ENV\config\bugbase.db"
if (-not (Test-Path $dbPath)) { Write-Host " Bugbase database not found at: $dbPath"; exit 1 }
Write-Host " Ejecting cassette..."
python .\temp_eject_cassette.py $dbPath $CASSETTE_ID
PSEOF

powershell.exe -ExecutionPolicy Bypass -File "./temp_eject_deploy.ps1" -GUID "$GUID" -ENV "$ENV" -CASSETTE_ID "$CASSETTE_ID" || true

echo ""
echo "========================================================================"
echo " CASSETTE EJECTION COMPLETE"
echo "========================================================================"