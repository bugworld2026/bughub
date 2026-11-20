#!/bin/bash
# ============================================================================
# INSTALL NEW CLIENT (IPO - Initial Probationary Onboarding)
# Mandate: Creates USoT config, initializes Bugbase, loads Cassette 2cp1.
# Location: C:\dbug\workspace\bughub-installer\tools\sh\install_new_client.sh
# ============================================================================
set -euo pipefail

# --- 1. Arguments & Defaults ---
GUID=${1:-""}
ENV=${2:-"0"}
WORKSPACE_ROOT="C:/dbug/workspace"
CONFIG_PATH="$WORKSPACE_ROOT/config.json"

# --- 2. FSC62 Pre-flight Validation (Pillar B) ---
if [[ -z "$GUID" ]]; then
    echo "FATAL: GUID is required. Usage: ./install_new_client.sh <GUID> [ENV]"
    exit 1
fi

# Regex: Exactly 22 alphanumeric chars, at least one uppercase, zero dashes.
if ! [[ "$GUID" =~ ^[a-zA-Z0-9]{22}$ ]] || ! [[ "$GUID" =~ [A-Z] ]]; then
    echo "FATAL: GUID '$GUID' violates FSC62 doctrine (22 chars, alphanumeric, >=1 uppercase, no dashes)."
    exit 1
fi

# --- 3. USoT Config Safety Gate (Once and Only Once) ---
if [[ -f "$CONFIG_PATH" ]]; then
    echo "FATAL: USoT config already exists at $CONFIG_PATH. Aborting to prevent overwrite."
    echo "Run uninstall_new_client.sh first if you need to reset."
    exit 1
fi

echo "=== BUGWORLD IPO INSTALLER ==="
echo "GUID: $GUID | ENV: $ENV"

# --- 4. Directory Materialization (PIPS Compliant) ---
SESSIONS_ROOT="$WORKSPACE_ROOT/sessions"
CONFIG_DIR="$SESSIONS_ROOT/$GUID/$ENV/config"
LOGS_DIR="$SESSIONS_ROOT/$GUID/$ENV/logs"

mkdir -p "$CONFIG_DIR"
mkdir -p "$LOGS_DIR"

# --- 5. Character-by-Char Expansion for Superid Path ---
# OCCR/ZTTD: GUID is 22 chars (even), so code_name = base_name (no trailing dash).
CHAR_EXPANSION=$(echo "$GUID" | sed 's/./&\\/g' | sed 's/\\$//')
SUPERID_PTS_PATH="C:/dbug/superid/$GUID/$ENV/$CHAR_EXPANSION/mcp"

mkdir -p "$SUPERID_PTS_PATH"

# --- 6. Generate USoT Config (UTF-8 No BOM) ---
# Using printf to avoid BOM issues common with some echo implementations.
printf '{\n  "GUID": "%s",\n  "ENV": "%s",\n  "TEAM_PARAM": "000000",\n  "SESSIONS_ROOT": "%s",\n  "LOGS_DIR": "%s",\n  "CONFIG_DIR": "%s"\n}\n' \
    "$GUID" "$ENV" "$SESSIONS_ROOT" "$LOGS_DIR" "$CONFIG_DIR" > "$CONFIG_PATH"

echo "✅ USoT Config created at: $CONFIG_PATH"

# --- 7. Initialize Bugbase & Load Cassette 2cp1 ---
BUGBASE_PATH="$CONFIG_DIR/bugbase.db"
SQL_SCRIPT="$WORKSPACE_ROOT/tools/sql/initialize_ipo_bugbase.sqlite.sql"

if [[ -f "$SQL_SCRIPT" ]]; then
    echo "Initializing Bugbase at $BUGBASE_PATH..."
    # We use Node.js to execute the SQL to ensure better-sqlite3 compatibility
    # This assumes the script is run from an environment where node is available
    # and better-sqlite3 is installed in a reachable node_modules (e.g., bbc-book-editor).
    # For a truly standalone installer, we might bundle a small sqlite3 binary or use a different approach.
    # For now, we generate a temp node script.
    
    NODE_INIT_SCRIPT=$(cat <<EOF
const Database = require('better-sqlite3');
const fs = require('fs');
const db = new Database('$BUGBASE_PATH');
const sql = fs.readFileSync('$SQL_SCRIPT', 'utf8');
db.exec(sql);

// Load Cassette 2cp1 (Ground Zero Pillar C)
const insertCassette = db.prepare("INSERT OR IGNORE INTO cassette_assets (cassette_id, asset_type, target_path, materialization_status, drive_number, guid, env) VALUES (?, ?, ?, ?, ?, ?, ?)");
insertCassette.run('2cp1', 'alpha', 'C:/dbug/agent/$GUID/$ENV/-\\-\\--/index/1/mcp/server.py', 'inserted', 2, '$GUID', '$ENV');
insertCassette.run('2cp1', 'alpha', 'C:/dbug/team/$GUID/$ENV/000000/1/mcp/server.py', 'inserted', 2, '$GUID', '$ENV');

console.log('Bugbase initialized and Cassette 2cp1 loaded.');
db.close();
EOF
)
    # Execute via Node (assuming we are in or near a service directory with better-sqlite3)
    # In a real deployment, this path would be absolute to the installer's node_modules.
    echo "$NODE_INIT_SCRIPT" | node -
else
    echo "WARN: SQL script not found at $SQL_SCRIPT. Bugbase initialization skipped."
fi

# --- 8. Materialize Client Superid PTS Stub (Port 2000 - Experimental/Probationary) ---
# Ground Zero Pillar C: "The resulting PTS will deterministically bind to port 2000"
STUB_PATH="$SUPERID_PTS_PATH/server.py"
if [[ ! -f "$STUB_PATH" ]]; then
    cat > "$STUB_PATH" <<'PYEOF'
import socketserver, json, struct, os
PORT = 2000 # Probationary/Experimental Port
BASE_NAME = os.environ.get('MCP_BASE_NAME', 'client_superid')
state = {'base_name': BASE_NAME, 'port': PORT, 'role': 'client_superid', 'is_promoted': False}

class H(socketserver.BaseRequestHandler):
    def handle(self):
        try:
            raw = self.request.recv(4)
            if len(raw) < 4: return
            ln = struct.unpack('>I', raw)[0]
            data = self.request.recv(ln)
            req = json.loads(data)
            resp = state if req.get('action') == 'GET_STATUS' else {'error': 'unknown'}
            out = json.dumps(resp).encode('utf-8')
            self.request.sendall(struct.pack('>I', len(out)) + out)
        except: pass

with socketserver.TCPServer(('127.0.0.1', PORT), H) as s: s.serve_forever()
PYEOF
    echo "✅ Client Superid PTS stub materialized at: $STUB_PATH (Port 2000)"
fi

echo "=== IPO INSTALLATION COMPLETE ==="
echo "Next Step: Run bootstrap_unified_ritual.ps1 to activate ATA for Team 000000."