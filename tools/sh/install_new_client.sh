#!/bin/bash
# ==============================================================================
# BUGWORLD 2026 - INSTALLER TOOLCHAIN
# SCRIPT: install_new_client.sh (LEDGER AWARE)
# DOCTRINE: Ground Zero (Pillar B: TASK-057, Pillar C: IPO, NEW PROPOSAL BCD/CCD)
# ==============================================================================

set -euo pipefail

WORKSPACE_ROOT="/mnt/c/dbug/workspace"
ROOT_CONFIG="$WORKSPACE_ROOT/config.json"
SECRETS_DIR="$WORKSPACE_ROOT/.secrets"

# 1. READ BUGWORLD CONTEXT (Public Config)
if [ ! -f "$ROOT_CONFIG" ]; then
    echo "FATAL: Root config.json not found. Run install_bugworld.sh first."
    exit 1
fi

# Robust JSON parsing for GUID_BA
if command -v python3 &> /dev/null; then
    GUID_BA=$(python3 -c "import json, sys; print(json.load(open(sys.argv[1]))['GUID_BA'])" "$ROOT_CONFIG")
else
    GUID_BA=$(grep -o '"GUID_BA"[[:space:]]*:[[:space:]]*"[^"]*"' "$ROOT_CONFIG" | sed 's/.*"\([^"]*\)"$/\1/')
fi

if [[ ! "$GUID_BA" =~ ^[a-zA-Z0-9]{11}$ ]]; then
    echo "FATAL [TASK-057]: GUID_BA in root config is invalid."
    exit 1
fi

BCD_PATH="$WORKSPACE_ROOT/sessions/$GUID_BA/0/config"
if [ ! -d "$BCD_PATH" ]; then
    echo "FATAL: BCD not found at $BCD_PATH."
    exit 1
fi

# 2. FSC62 GUID GENERATOR
generate_fsc62_guid() {
    local guid=""
    while true; do
        if guid=$(tr -dc 'a-zA-Z0-9' < /dev/urandom 2>/dev/null | head -c 22); then
            :
        else
            guid=$(openssl rand -base64 32 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 22)
        fi
        if [[ ${#guid} -eq 22 ]] && [[ "$guid" =~ [A-Z] ]]; then
            echo "$guid"
            break
        fi
    done
}

echo "=== NEW CLIENT ONBOARDING PROTOCOL INITIATED ==="

# 3. GENERATE GUID_C (CLIENT ID) & SPLIT
GUID_C=$(generate_fsc62_guid)
GUID_CA="${GUID_C:0:11}"
GUID_CB="${GUID_C:11:11}"

# 4. TASK-057 PRE-FLIGHT VALIDATION GATE
if [[ ! "$GUID_CA" =~ ^[a-zA-Z0-9]{11}$ ]]; then
    echo "FATAL [TASK-057]: GUID_CA failed 11-character validation. Aborting."
    exit 1
fi
echo "✅ [TASK-057]: GUID_CA (client_base_name) validated ($GUID_CA)."

# 5. MATERIALIZE guid_ca.json IN BCD
echo "{\"GUID_CA\": \"$GUID_CA\"}" > "$BCD_PATH/guid_ca.json"
echo "✅ guid_ca.json materialized in BCD."

# 6. MATERIALIZE CCD (Client Config Directory)
CCD_PATH="$WORKSPACE_ROOT/sessions/$GUID_CA/0/config"
mkdir -p "$CCD_PATH"
echo "✅ CCD materialized at: $CCD_PATH"

# 7. UPDATE SECURITY LEDGER (The "Reservation" Fulfillment)
DATE_STAMP=$(date +%Y-%m-%d)
SECRET_FILE="$SECRETS_DIR/${DATE_STAMP}.json"

if [ -f "$SECRET_FILE" ]; then
    # Use python3 to safely update the JSON without breaking formatting
    if command -v python3 &> /dev/null; then
        python3 -c "
import json
with open('$SECRET_FILE', 'r') as f:
    data = json.load(f)
data['GUID_C'] = '$GUID_C'
data['GUID_CA'] = '$GUID_CA'
data['GUID_CB'] = '$GUID_CB'
with open('$SECRET_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
        echo "✅ Security Ledger updated with Client GUIDs at: $SECRET_FILE"
    else
        echo "⚠️  Warning: python3 not found. Cannot update JSON ledger cleanly. Manual update required."
    fi
else
    echo "⚠️  Warning: Daily ledger $SECRET_FILE not found. Creating new one."
    cat << EOF > "$SECRET_FILE"
{
  "installation_date": "$DATE_STAMP",
  "GUID_A": "UNKNOWN (Run install_bugworld.sh first)",
  "GUID_B": "UNKNOWN",
  "GUID_BA": "$GUID_BA",
  "GUID_BB": "UNKNOWN",
  "GUID_C": "$GUID_C",
  "GUID_CA": "$GUID_CA",
  "GUID_CB": "$GUID_CB"
}
EOF
    chmod 600 "$SECRET_FILE"
fi

# 8. DETERMINISTIC PTS GENERATION (OCCR / ZTTD ENFORCED)
CLIENT_CODE_NAME="${GUID_CA}-" 

CHAR_EXPANSION=""
for (( i=0; i<${#CLIENT_CODE_NAME}; i++ )); do
    CHAR_EXPANSION+="${CLIENT_CODE_NAME:$i:1}\\"
done
CHAR_EXPANSION="${CHAR_EXPANSION%\\}" 

DERIVED_PAIR="${CLIENT_CODE_NAME: -2}"

PTS="C:/dbug/superid/$GUID_BA/0/$CHAR_EXPANSION/$DERIVED_PAIR/mcp/server.py"

echo "=== CLIENT ONBOARDING COMPLETE ==="
echo "Client Base Name (GUID_CA): $GUID_CA"
echo "Derived PTS:                $PTS"