#!/bin/bash
# ==============================================================================
# BUGWORLD 2026 - INSTALLER TOOLCHAIN
# SCRIPT: install_bugworld.sh (SECURITY HARDENED)
# DOCTRINE: Ground Zero (Pillar B: TASK-057, Pillar C: IPO, NEW PROPOSAL)
# ==============================================================================

set -euo pipefail

# 1. DEFINE WORKSPACE ROOT
WORKSPACE_ROOT="/mnt/c/dbug/workspace"
ROOT_CONFIG="$WORKSPACE_ROOT/config.json"
SECRETS_DIR="$WORKSPACE_ROOT/.secrets"

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

# 3. TASK-057 PRE-FLIGHT VALIDATION GATE
validate_11char_base() {
    local base_name="$1"
    local label="$2"
    if [[ ! "$base_name" =~ ^[a-zA-Z0-9]{11}$ ]]; then
        echo "FATAL [TASK-057]: $label failed 11-character FSC62 validation. Aborting."
        exit 1
    fi
    echo "✅ [TASK-057]: $label validated successfully ($base_name)."
}

echo "=== BUGWORLD INSTALLATION PROTOCOL INITIATED ==="

# 4. GENERATE GUID_A (API KEY - PRIVATE) & GUID_B (BUGWORLD ID)
echo "Generating FSC62 compliant GUIDs..."
GUID_A=$(generate_fsc62_guid)
GUID_B=$(generate_fsc62_guid)

# 5. SPLIT GUID_B
GUID_BA="${GUID_B:0:11}"
GUID_BB="${GUID_B:11:11}"

# 6. ENFORCE TASK-057 PATH SAFETY GATE
validate_11char_base "$GUID_BA" "GUID_BA (bugworld_base_name)"

# 7. MATERIALIZE ROOT CONFIG (PUBLIC - GUID_A EXCLUDED)
mkdir -p "$WORKSPACE_ROOT"
# SECURITY FIX: Only GUID_BA is public. GUID_A is strictly private.
echo "{\"GUID_BA\": \"$GUID_BA\"}" > "$ROOT_CONFIG"
echo "✅ Public config.json materialized at: $ROOT_CONFIG"

# 8. MATERIALIZE BCD (Bugworld Config Directory)
BCD_PATH="$WORKSPACE_ROOT/sessions/$GUID_BA/0/config"
mkdir -p "$BCD_PATH"
echo "✅ BCD materialized at: $BCD_PATH"

# 9. SECURITY LEDGER INITIALIZATION (The "Reservation")
mkdir -p "$SECRETS_DIR"
DATE_STAMP=$(date +%Y-%m-%d)
SECRET_FILE="$SECRETS_DIR/${DATE_STAMP}.json"

# Create/Update the daily ledger. 
# Note: GUID_C and GUID_CA are null here; install_new_client.sh will populate them.
cat << EOF > "$SECRET_FILE"
{
  "installation_date": "$DATE_STAMP",
  "GUID_A": "$GUID_A",
  "GUID_B": "$GUID_B",
  "GUID_BA": "$GUID_BA",
  "GUID_BB": "$GUID_BB",
  "GUID_C": null,
  "GUID_CA": null,
  "GUID_CB": null
}
EOF

# Restrict permissions: Owner read/write only. No group, no others.
chmod 600 "$SECRET_FILE"
echo "✅ Security Ledger initialized at: $SECRET_FILE (Permissions: 600)"

echo "=== BUGWORLD INSTALLATION COMPLETE ==="
echo "Bugworld Base Name (GUID_BA): $GUID_BA"
echo "⚠️  IMPORTANT: GUID_A is stored securely in $SECRET_FILE"