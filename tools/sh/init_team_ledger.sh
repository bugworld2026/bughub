#!/bin/bash
# ==============================================================================
# BUGWORLD 2026 - TEAM LEDGER INITIALIZATION
# SCRIPT: init_team_ledger.sh
# PURPOSE: Seed the team_ledger table in both IPO and Canonical Bugbases.
# ==============================================================================

set -euo pipefail

# 1. DEFINE DATABASE PATHS
IPO_DB="/mnt/c/dbug/workspace/sessions/ERGeFmPi65M/0/db/bugbase.db"
CANONICAL_DB="/mnt/c/dbug/workspace/sessions/8nrFLQ2s1Yp/0/db/bugbase.db"

# Ensure the 'db' directories exist (in case they weren't created by previous scripts)
mkdir -p "$(dirname "$IPO_DB")"
mkdir -p "$(dirname "$CANONICAL_DB")"

# 2. ENSURE SQLITE3 IS INSTALLED
if ! command -v sqlite3 &> /dev/null; then
    echo "⚠️  sqlite3 not found. Installing via apt..."
    sudo apt-get update && sudo apt-get install -y sqlite3
fi

# 3. DEFINE SQL SCHEMA & SEED DATA
# Note: Using 'INSERT OR IGNORE' to make this script idempotent (safe to run multiple times)
SQL_STATEMENT="
CREATE TABLE IF NOT EXISTS team_ledger (
    ledger_index INTEGER PRIMARY KEY AUTOINCREMENT,
    team_param TEXT NOT NULL UNIQUE,
    primary_base TEXT NOT NULL,
    secondary_base TEXT NOT NULL,
    tertiary_base TEXT NOT NULL,
    registration_date TEXT NOT NULL,
    status TEXT DEFAULT 'active',
    bugworld_base_name TEXT NOT NULL
);

INSERT OR IGNORE INTO team_ledger (team_param, primary_base, secondary_base, tertiary_base, registration_date, status, bugworld_base_name)
VALUES ('000000', 'dsa1', 'dsa2', 'dsa3', '2026-09-23', 'active', '8nrFLQ2s1Yp');

INSERT OR IGNORE INTO team_ledger (team_param, primary_base, secondary_base, tertiary_base, registration_date, status, bugworld_base_name)
VALUES ('284593', 'q', '-q', 'qq', '2026-09-23', 'active', '8nrFLQ2s1Yp');
"

# 4. EXECUTE AGAINST IPO BUGBASE
echo "=== INITIALIZING IPO BUGBASE (Client Context) ==="
sqlite3 "$IPO_DB" "$SQL_STATEMENT"
echo "✅ IPO Bugbase updated. Current ledger contents:"
sqlite3 -header -column "$IPO_DB" "SELECT ledger_index, team_param, primary_base, secondary_base, tertiary_base, status FROM team_ledger;"

echo ""

# 5. EXECUTE AGAINST CANONICAL BUGBASE
echo "=== INITIALIZING CANONICAL BUGBASE (Bugworld Context) ==="
sqlite3 "$CANONICAL_DB" "$SQL_STATEMENT"
echo "✅ Canonical Bugbase updated. Current ledger contents:"
sqlite3 -header -column "$CANONICAL_DB" "SELECT ledger_index, team_param, primary_base, secondary_base, tertiary_base, status FROM team_ledger;"

echo ""
echo "🚀 TEAM LEDGER INITIALIZATION COMPLETE."