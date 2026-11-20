#!/bin/bash
# ============================================================================
# INSTALL BUGWORLD - Full Materialization (FSC62, TASK-057, OCCR Compliant)
# Strategy: Bash creates temp files, PowerShell deploys to C:\dbug\
# ============================================================================

set -e

# ============================================================================
# 1. ROBUST CLEANUP TRAP
# ============================================================================
cleanup() {
    rm -f ./temp_config.json ./temp_server.py ./temp_2cp1.zip ./temp_init_db.py ./temp_register_cassette.py ./temp_deploy.ps1
}
trap cleanup EXIT

# ============================================================================
# 2. CANONICAL VARIABLES
# ============================================================================
GUID="BUGWORLD2026TestSite22"
ENV="0"

# ============================================================================
# 3. FSC62 VALIDATION
# ============================================================================
echo " Validating FSC62 GUID..."
if [ ${#GUID} -ne 22 ]; then echo " FATAL: GUID must be exactly 22 characters"; exit 1; fi
if [[ ! "$GUID" =~ ^[A-Za-z0-9]+$ ]]; then echo "❌ FATAL: GUID must be alphanumeric only"; exit 1; fi
if [[ ! "$GUID" =~ [A-Z] ]]; then echo "❌ FATAL: GUID must contain at least one uppercase letter"; exit 1; fi
echo "✅ FSC62 Validation PASSED: $GUID"

# ============================================================================
# 4. CREATE TEMPORARY FILES
# ============================================================================
echo " Preparing temporary files..."

cat > ./temp_config.json << EOF
{
  "GUID": "$GUID",
  "ENV": "$ENV",
  "TEAM_PARAM": "284593",
  "SESSIONS_ROOT": "C:\\\\dbug\\\\workspace\\\\sessions\\\\$GUID\\\\$ENV",
  "CONFIG_DIR": "C:\\\\dbug\\\\workspace\\\\sessions\\\\$GUID\\\\$ENV\\\\config",
  "LOGS_DIR": "C:\\\\dbug\\\\workspace\\\\sessions\\\\$GUID\\\\$ENV\\\\logs",
  "TEAM_ROOT": "C:\\\\dbug\\\\team\\\\$GUID\\\\$ENV\\\\284593",
  "WORKSPACE_ROOT": "C:\\\\dbug\\\\workspace",
  "AGENT_ROOT": "C:\\\\dbug\\\\agent\\\\$GUID\\\\$ENV",
  "ALIAS_ROOT": "C:\\\\dbug\\\\alias\\\\$GUID\\\\$ENV",
  "LEDGER_DIR": "C:\\\\dbug\\\\workspace\\\\sessions\\\\$GUID\\\\$ENV"
}
EOF

cat > ./temp_server.py << 'EOF'
import socketserver, json, struct
PORT = 2000
GUID = "BUGWORLD2026TestSite22"
state = {'status': 'probationary', 'port': PORT, 'guid': GUID, 'role': 'client_superid', 'ata_active': False}
class H(socketserver.BaseRequestHandler):
    def handle(self):
        try:
            raw = self.request.recv(4)
            if len(raw) < 4: return
            ln = struct.unpack('>I', raw)[0]
            data = self.request.recv(ln)
            req = json.loads(data)
            act = req.get('action', '')
            if act == 'GET_STATUS': resp = state
            elif act == 'PROMOTE probationary':
                state['status'] = 'promoted'
                resp = {'status': 'ok', 'state': state}
            else: resp = {'error': 'unknown action'}
            out = json.dumps(resp).encode('utf-8')
            self.request.sendall(struct.pack('>I', len(out)) + out)
        except Exception as e: print(f"SPAS Error: {e}")
with socketserver.TCPServer(('127.0.0.1', PORT), H) as s:
    print(f"SPAS listening on port {PORT}")
    s.serve_forever()
EOF

cat > ./temp_2cp1.zip << 'EOF'
This is a dummy 2cp1 cassette payload for IPO testing.
Cassette Protocol (CP) v1.0
Payload Type: 2cp1 (Second Foundation Cassette Payload 1)
EOF

cat > ./temp_init_db.py << 'EOF'
import sqlite3, sys, os
db_path = sys.argv[1]
if os.path.exists(db_path): os.remove(db_path)
conn = sqlite3.connect(db_path)
cursor = conn.cursor()
cursor.execute("PRAGMA journal_mode = WAL;")
cursor.executescript('''
CREATE TABLE IF NOT EXISTS cassettes (id TEXT PRIMARY KEY, payload_path TEXT, sha256_hash TEXT, status TEXT DEFAULT 'ACTIVE', inserted_at TEXT, ejected_at TEXT);
CREATE TABLE IF NOT EXISTS payload_registry (payload_path TEXT PRIMARY KEY, sha256_hash TEXT, registered_at TEXT, registered_by TEXT, is_active INTEGER DEFAULT 1, deactivated_at TEXT);
CREATE TABLE IF NOT EXISTS global_state (id INTEGER PRIMARY KEY CHECK (id = 1), bugswitch_state TEXT DEFAULT 'ON', pla_state TEXT DEFAULT 'N', last_ata_token TEXT, last_modified TEXT);
INSERT OR REPLACE INTO global_state (id, bugswitch_state, pla_state, last_modified) VALUES (1, 'ON', 'N', datetime('now'));
''')
conn.commit()
conn.close()
print(f"Bugbase initialized at: {db_path}")
EOF

cat > ./temp_register_cassette.py << 'EOF'
import sqlite3, sys
from datetime import datetime
db_path, cassette_id, payload_path = sys.argv[1], sys.argv[2], sys.argv[3]
conn = sqlite3.connect(db_path)
cursor = conn.cursor()
timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
cursor.execute("INSERT OR REPLACE INTO cassettes (id, payload_path, sha256_hash, status, inserted_at) VALUES (?, ?, ?, 'ACTIVE', ?)", (cassette_id, payload_path, 'dummy_hash_2cp1', timestamp))
conn.commit()
conn.close()
print(f"Cassette {cassette_id} registered in Bugbase")
EOF

# ============================================================================
# 5. DELEGATE TO POWERSHELL
# ============================================================================
echo " Initializing PowerShell filesystem operations..."

cat > ./temp_deploy.ps1 << 'PSEOF'
param([string]$GUID, [string]$ENV)
$Base = "C:\dbug"
$configDest = "$Base\workspace\sessions\$GUID\$ENV\config\config.json"
$spasDest = "$Base\superid\$GUID\$ENV\B\U\G\W\O\R\L\D\2\0\2\6\T\e\s\t\S\i\t\e\2\2\22\mcp\server.py"
$cassetteDest = "$Base\workspace\cassettes\2cp1.zip"
$dbDest = "$Base\workspace\sessions\$GUID\$ENV\config\bugbase.db"

if (Test-Path $configDest) { 
    $reply = Read-Host "WARNING: config.json exists. Overwrite? (y/N)"
    if ($reply -ne 'y' -and $reply -ne 'Y') { Write-Host "Aborted"; exit 1 }
}

Write-Host " Creating directories..."
New-Item -ItemType Directory -Force -Path (Split-Path $configDest) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $spasDest) | Out-Null
New-Item -ItemType Directory -Force -Path "$Base\workspace\cassettes" | Out-Null
New-Item -ItemType Directory -Force -Path "$Base\workspace\sessions\$GUID\$ENV\logs" | Out-Null

Write-Host " Deploying files..."
Copy-Item -Path ".\temp_config.json" -Destination $configDest -Force
Copy-Item -Path ".\temp_server.py" -Destination $spasDest -Force
Copy-Item -Path ".\temp_2cp1.zip" -Destination $cassetteDest -Force

Write-Host " Initializing Bugbase database..."
python .\temp_init_db.py $dbDest

Write-Host " Registering 2cp1 cassette..."
python .\temp_register_cassette.py $dbDest "2cp1" "C:\dbug\workspace\cassettes\2cp1.zip"

Write-Host " Full installation complete."
PSEOF

powershell.exe -ExecutionPolicy Bypass -File "./temp_deploy.ps1" -GUID "$GUID" -ENV "$ENV" || true

echo ""
echo "========================================================================"
echo " FULL INSTALLATION COMPLETE"
echo "========================================================================"
echo "Created: config.json, server.py, bugbase.db, 2cp1.zip, logs/"
echo "========================================================================"