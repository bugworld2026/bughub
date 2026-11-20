#!/usr/bin/env bash
# ============================================================================
# install_bugworld.sh (v4)
# BUGWORLD 2026 - Initial Probationary Onboarding (IPO) Installer
# ============================================================================
set -euo pipefail

validate_fsc62() {
    local guid="$1"
    local label="$2"
    if [[ ${#guid} -ne 22 ]]; then echo "ERROR: $label must be exactly 22 characters" >&2; return 1; fi
    if [[ ! "$guid" =~ ^[a-zA-Z0-9]+$ ]]; then echo "ERROR: $label must be alphanumeric only" >&2; return 1; fi
    if [[ ! "$guid" =~ [A-Z] ]]; then echo "ERROR: $label must contain at least one uppercase letter" >&2; return 1; fi
    if [[ "$guid" == *"-"* ]]; then echo "ERROR: $label must contain zero dashes" >&2; return 1; fi
    return 0
}

generate_fsc62_guid() {
    local random_str=$(tr -dc 'a-z0-9A-Z' < /dev/urandom | head -c 21)
    echo "${random_str}A"
}

echo "=== BUGWORLD 2026: INITIAL PROBATIONARY ONBOARDING (IPO) ==="
echo "[1/5] Generating FSC62 GUIDs in volatile memory..."

GUID_A=$(generate_fsc62_guid)
GUID_B=$(generate_fsc62_guid)
GUID_C=$(generate_fsc62_guid)

validate_fsc62 "$GUID_A" "GUID_A" || exit 1
validate_fsc62 "$GUID_B" "GUID_B" || exit 1
validate_fsc62 "$GUID_C" "GUID_C" || exit 1

echo "      ✅ GUID_A, GUID_B, GUID_C generated and validated"

GUID_BA="${GUID_B:0:11}"
GUID_CA="${GUID_C:0:11}"

echo "[2/5] Extracting public base names..."
echo "      ✅ bugworld_base_name (GUID_BA): $GUID_BA"
echo "      ✅ client_base_name (GUID_CA): $GUID_CA"

echo "[3/5] Materializing public filesystem structure..."
SESSIONS_ROOT="C:/dbug/workspace/sessions"
CONFIG_DIR="${SESSIONS_ROOT}/${GUID_BA}/0/config"
CLIENT_CONFIG_DIR="${SESSIONS_ROOT}/${GUID_CA}/0/config"

mkdir -p "$CONFIG_DIR"
mkdir -p "$CLIENT_CONFIG_DIR"
mkdir -p "${SESSIONS_ROOT}/${GUID_BA}/0/logs"

echo "      ✅ Created session directories"

echo "[4/5] Writing public configuration files..."
cat > "C:/dbug/workspace/config.json" <<EOF
{
  "bugworld_base_name": "${GUID_BA}",
  "env": "0",
  "team_param": "000000",
  "sessions_root": "C:\\dbug\\workspace\\sessions",
  "logs_dir": "C:\\dbug\\workspace\\sessions\\${GUID_BA}\\0\\logs",
  "config_dir": "C:\\dbug\\workspace\\sessions\\${GUID_BA}\\0\\config"
}
EOF

cat > "${CONFIG_DIR}/guid_ca.json" <<EOF
{
  "client_base_name": "${GUID_CA}",
  "host_bugworld_base_name": "${GUID_BA}",
  "status": "probationary",
  "validation_state": "pending"
}
EOF
echo "      ✅ Written config.json and guid_ca.json"

echo "[5/5] Secure Handoff & Volatile Memory Wipe..."
mkdir -p "C:/dbug/.vault"

cat > "C:/dbug/.vault/secrets.json" <<EOF
{
  "GUID_A": "${GUID_A}",
  "GUID_B": "${GUID_B}",
  "GUID_C": "${GUID_C}",
  "warning": "CRITICAL: Move this file to a secure, offline location immediately and delete C:\\dbug\\.vault"
}
EOF

echo "      ✅ Private GUIDs securely written to C:\\dbug\\.vault\\secrets.json"
echo "⚠️  CRITICAL: Move C:\\dbug\\.vault\\secrets.json to a secure, offline location NOW."
read -p "Press ENTER once secured to wipe memory variables..."

unset GUID_A GUID_B GUID_C
echo "      ✅ Volatile memory purged via unset."

echo ""
echo "=== IPO COMPLETE ==="
echo "Public routing established for: $GUID_BA"
echo "Client routing established for: $GUID_CA"
