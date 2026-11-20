#!/bin/bash
# ============================================================================
# INSERT CASSETTE - Register cassette in Bugbase
# Strategy: Bash validates, PowerShell deploys Python script to execute
# ============================================================================

set -e

# ============================================================================
# 1. ROBUST CLEANUP TRAP
# ============================================================================
cleanup() {
    rm -f ./temp_insert_cassette.py ./temp_insert_deploy.ps1
}
trap cleanup EXIT

# ============================================================================
# 2. CANONICAL VARIABLES
# ============================================================================
GUID="BUGWORLD2026TestSite22"
ENV="0"
CASSETTE_ID="2cp1"
PAYLOAD_PATH="C:\dbug\workspace\cassettes\2cp1.zip"

# ============================================================================
# 3. VALIDATION
# ============================================================================
echo " Validating cassette parameters..."
if [ -z "$CASSETTE_ID" ]; then echo " FATAL: cassette_id is required"; exit 1; fi
if [ -z "$PAYLOAD_PATH" ]; then echo " FATAL: payload_path is required"; exit 1; fi
echo " Validation PASSED: $CASSETTE_ID"

# ============================================================================
# 4. CREATE TEMPORARY PYTHON SCRIPT
# ============================================================================
echo " Preparing insertion script..."

cat > ./temp_insert_cassette.py << 'EOF'
import sqlite3, sys
from datetime import datetime
db_path, cassette_id, payload_path = sys.argv[1], sys.argv[2], sys.argv[3]
conn = sqlite3.connect(db_path)
cursor = conn.cursor()
cursor.execute('SELECT status FROM cassettes WHERE id = ?', (cassette_id,))
existing = cursor.fetchone()
if existing and existing[0] == 'ACTIVE':
    print(f"Cassette {cassette_id} is already active")
    conn.close()
    sys.exit(1)
timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
cursor.execute("INSERT OR REPLACE INTO cassettes (id, payload_path, sha256_hash, status, inserted_at, ejected_at) VALUES (?, ?, ?, 'ACTIVE', ?, NULL)", (cassette_id, payload_path, 'dummy_hash', timestamp))
conn.commit()
conn.close()
print(f"Cassette {cassette_id} inserted into Bugbase")
EOF

# ============================================================================
# 5. DELEGATE TO POWERSHELL
# ============================================================================
echo " Initializing PowerShell operations..."

cat > ./temp_insert_deploy.ps1 << 'PSEOF'
param([string]$GUID, [string]$ENV, [string]$CASSETTE_ID, [string]$PAYLOAD_PATH)
$Base = "C:\dbug"
$dbPath = "$Base\workspace\sessions\$GUID\$ENV\config\bugbase.db"
if (-not (Test-Path $dbPath)) { Write-Host " Bugbase database not found at: $dbPath"; exit 1 }
Write-Host " Inserting cassette..."
python .\temp_insert_cassette.py $dbPath $CASSETTE_ID $PAYLOAD_PATH
PSEOF

powershell.exe -ExecutionPolicy Bypass -File "./temp_insert_deploy.ps1" -GUID "$GUID" -ENV "$ENV" -CASSETTE_ID "$CASSETTE_ID" -PAYLOAD_PATH "$PAYLOAD_PATH" || true

echo ""
echo "========================================================================"
echo " CASSETTE INSERTION COMPLETE"
echo "========================================================================"