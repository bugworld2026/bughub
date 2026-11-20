#!/usr/bin/env bash
# ============================================================================
# BUGWORLD 2026 — BUGHUB INSTALLER (Phase 3 · shell-first)  v1.0.0
# Path: C:\dbug\workspace\bughub-installer\tools\sh\install_bugworld.sh
#
# DOCTRINE ANCHORS — Encoding Protocol Compendium (Session Close 2026-11-19):
#   Root ............ .osc = raw 8-bit/byte stream; all pathways branch from it.
#   Regimes ......... IPO (BUGSWITCH=OFF) = graph/explain only; FULL (ON) = encode via :2012.
#   Mandatory ERS ... 6-bit End Rendering Schema chunk always appended (overflow 0-5).
#   Parity firewall . Data chunks = SBP NOT Dominant; overflow/ERS = SBP Dominant.
#   Collision ....... no emitted code may merge into 000000 / 111111.
#   Pipeline save ... two-step encode -> 4 artifacts {src}_input.raw/.txt,
#                     {tgt}_output.raw/.txt into
#                     .../sessions/{GUID_CA}/{ENV}/analysis/pipeline/{a-f}/{YYYY-MM-DD}/
#                     (matches resolvePipelinePath() in gaia-machine osc_processor.ts).
#   DBC/TBC ......... double-chunk ERS families; 000 pad exclusive DBC/QBC,
#                     111 pad exclusive TBC; terminal EOF 110011.
#
# Mirrors the PowerShell Unified Launcher: dynamic cascade + [a]-[e] menu.
# ============================================================================
set -uo pipefail   # no -e: interactive menu + optional probes must not abort

# ── Workspace auto-detect (Git-Bash /c/... or WSL /mnt/c/...) ──────────────
for cand in /c/dbug/workspace /mnt/c/dbug/workspace; do
  [[ -d "$cand" ]] && { WORKSPACE_ROOT="${WORKSPACE_ROOT:-$cand}"; break; }
done
WORKSPACE_ROOT="${WORKSPACE_ROOT:-/c/dbug/workspace}"
ENV="${ENV:-0}"
SECRETS="$WORKSPACE_ROOT/.secrets"
SESSIONS="$WORKSPACE_ROOT/sessions"
SERVICES="$WORKSPACE_ROOT/services"

c(){ printf '\033[1;36m%s\033[0m\n' "$*"; }
ok(){ printf '  \033[1;32m[OK]\033[0m %s\n' "$*"; }
warn(){ printf '  \033[1;33m[WARN]\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31mFATAL: %s\033[0m\n' "$*"; exit 1; }

# ── STEP 0: Dynamic Cascade Resolution (Compendium: .secrets -> BA -> CA) ──
resolve_cascade() {
  c "=== RESOLVING CONFIGURATION CASCADE ==="
  [[ -d "$SECRETS" ]] || die "Secrets directory not found: $SECRETS"
  local latest
  latest=$(ls -t "$SECRETS"/*.json 2>/dev/null | head -1)
  [[ -n "$latest" ]] || die "No .json files in $SECRETS"
  ok "Latest secret file: $(basename "$latest")"
  GUID_BA=$(jq -r '.GUID_BA // empty' "$latest")
  [[ -n "$GUID_BA" ]] || die "GUID_BA missing in $(basename "$latest")"
  ok "Resolved GUID_BA: $GUID_BA"

  local cafile="$SESSIONS/$GUID_BA/$ENV/config/guid_ca.json"
  [[ -f "$cafile" ]] || die "guid_ca.json not found at $cafile"
  GUID_CA=$(jq -r '.GUID_CA // empty' "$cafile")
  [[ -n "$GUID_CA" ]] || die "GUID_CA missing in guid_ca.json"
  ok "Resolved GUID_CA: $GUID_CA"

  BA_ENV="$SESSIONS/$GUID_BA/$ENV";  CA_ENV="$SESSIONS/$GUID_CA/$ENV"
  BA_DB="$BA_ENV/db/bugbase.db";     CA_DB="$CA_ENV/db/bugbase.db"
  BA_ATA="$BA_ENV/config/ata_state.json"; CA_ATA="$CA_ENV/config/ata_state.json"
  LAUNCHER_LOG="$BA_ENV/logs/launcher/launcher.log"
  ok "Path structure validated with ENV=$ENV"
}

# ── STEP 1: Canonical Services (11) + BUGSWITCH sync + regime probe ────────
is_listening(){ (ss -ltn 2>/dev/null || netstat -ltn) | grep -q ":$1 "; }
start_services(){
  c "[INFO] Starting 11 Canonical Services..."
  local svc=(
    "2001|tiangan-core|$WORKSPACE_ROOT/tiangan-core|lib/backend/main.js"
    "2002|bbc-book-editor|$SERVICES/bbc-book-editor|src/index.js"
    "2003|orchestrator|$SERVICES/orchestrator|src/index.js"
    "2004|alias-monitor|$SERVICES/alias-monitor|server.js"
    "2005|bugswitch-control|$SERVICES/bugswitch-control|src/index.js"
    "2006|agent-dashboard|$SERVICES/agent-dashboard|lib/backend/main.js"
    "2007|maths-reader|$SERVICES/maths-reader|src/index.js"
    "2008|calculator-electron|$SERVICES/calculator-electron|src/index.js"
    "2009|button-express|$SERVICES/button-express|src/index.js"
    "2011|health-inspector|$SERVICES/health-inspector|src/index.js"
    "2012|gaia-machine|$SERVICES/gaia-machine|server.js"
  )
  local all_up=1 s port name dir entry
  for s in "${svc[@]}"; do
    IFS='|' read -r port name dir entry <<< "$s"
    [[ -d "$dir" ]] || { warn "$name dir missing — skip"; continue; }
    if is_listening "$port"; then ok "$name already on :$port"; continue; fi
    if [[ -f "$dir/$entry" ]]; then
      ( cd "$dir" && node "$entry" >/dev/null 2>&1 & )
      ok "Started $name on :$port"
    else warn "$name entry missing ($entry) — skip"; fi
  done
  sleep 3
  for s in "${svc[@]}"; do
    IFS='|' read -r port name _ _ <<< "$s"
    if is_listening "$port"; then ok ":$port ($name) LISTENING"; else warn ":$port ($name) NOT LISTENING"; all_up=0; fi
  done
  [[ $all_up -eq 1 ]] && ok "All canonical services operational." || warn "Some services failed — check logs."
}

sync_bugswitch(){ # $1=ON|OFF
  local state="$1"
  c "[INFO] BUGSWITCH Toggle Protocol ($state)..."
  curl -s -m 5 -X POST http://127.0.0.1:2002/internal/bugswitch-changed \
    -H 'Content-Type: application/json' -d "{\"newState\":\"$state\"}" >/dev/null \
    && ok "Synchronized ($state). Token cache cleared." \
    || warn "Could not reach bbc-book-editor :2002 (state saved in ata_state.json)."
}

verify_gaia(){ # ties installer -> OSC Inspector regime (Compendium: FULL regime gate)
  local s
  s=$(curl -s -m 3 http://127.0.0.1:2012/api/osc/bugswitch-state 2>/dev/null) || { warn "gaia-machine :2012 unreachable"; return; }
  ok "gaia-machine regime probe: $s"
}

# ── ATA / DB / log writers (fixed comma logic) ─────────────────────────────
write_ata(){ # $1=bugswitch  $2..=team_param list
  local bs="$1"; shift
  local teams_json="" t nodes first=1
  for t in "$@"; do
    if [[ "$t" == "000000" ]]; then nodes='["client","dsa_1","dsa_2","dsa_3"]'; else nodes='["client"]'; fi
    [[ $first -eq 0 ]] && teams_json+=","
    teams_json+="{\"team_param\":\"$t\",\"nodes\":$nodes}"
    first=0
  done
  mkdir -p "$(dirname "$BA_ATA")"
  printf '{\n  "timestamp": "%s",\n  "bugswitch": "%s",\n  "teams": [%s]\n}\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$bs" "$teams_json" > "$BA_ATA"
  ok "Wrote Canonical ATA: $BA_ATA"
}
touch_ca(){ mkdir -p "$(dirname "$CA_ATA")"; : > "$CA_ATA"; ok "Created IPO Validator: $CA_ATA"; }
rm_ca(){ [[ -f "$CA_ATA" ]] && rm -f "$CA_ATA" && ok "Deleted IPO Validator: $CA_ATA"; }
ensure_db(){ mkdir -p "$(dirname "$BA_DB")"; [[ -f "$BA_DB" ]] || : > "$BA_DB"; }
log(){ mkdir -p "$(dirname "$LAUNCHER_LOG")"; printf '# BUGWORLD Launcher Log - %s\n# Mode: %s\n# BUGSWITCH: %s\n' "$(date)" "$1" "$2" > "$LAUNCHER_LOG"; ok "Launcher log: $LAUNCHER_LOG"; }

# ── STEP 2: Menu (parity with PowerShell launcher [a]-[e]) ─────────────────
menu(){
  c "=== UNIFIED BUGWORLD LAUNCHER MENU ==="
  echo "[a] IPO Phase learning mode (no ATA, BUGSWITCH=ON)"
  echo "[b] FIRST FOUNDATION: ATA with Team 0 (BUGSWITCH=OFF) + Services"
  echo "[c] FIRST + SECOND FOUNDATION: DOUBLE_ATA (BUGSWITCH=OFF) + Services"
  echo "[d] DOUBLE_ATA + IPO access (BUGSWITCH=OFF, dual ata) + Services"
  echo "[e] PRE-FOUNDATION TESTING: Simulated DOUBLE_ATA (BUGSWITCH=ON, Services DOWN)"
  read -rp "Enter choice [a/b/c/d/e]: " ch
  local t2=""
  case "${ch,,}" in
    a) touch_ca
       [[ -f "$BA_ATA" ]] && warn "$BA_ATA EXISTS (should NOT for pure IPO)" || ok "$BA_ATA absent"
       [[ -f "$BA_DB"  ]] && warn "$BA_DB EXISTS (should NOT for pure IPO)"  || ok "$BA_DB absent"
       c ">>> IPO Phase ready. BUGSWITCH=ON <<<";;
    b) rm_ca; ensure_db; write_ata OFF 000000; log "FIRST FOUNDATION (Team 0)" OFF; start_services; sync_bugswitch OFF; verify_gaia
       c ">>> FIRST FOUNDATION. BUGSWITCH=OFF <<<";;
    c) rm_ca; ensure_db; read -rp "  second team param (e.g. 284593): " t2; t2=${t2:-UNKNOWN_TEAM}
       write_ata OFF 000000 "$t2"; log "DOUBLE_ATA (000000,$t2)" OFF; start_services; sync_bugswitch OFF; verify_gaia
       c ">>> DOUBLE_ATA. BUGSWITCH=OFF <<<";;
    d) rm_ca; ensure_db; read -rp "  second team param (e.g. 284593): " t2; t2=${t2:-UNKNOWN_TEAM}
       write_ata OFF 000000 "$t2"; touch_ca; log "DOUBLE_ATA + IPO" OFF; start_services; sync_bugswitch OFF; verify_gaia
       c ">>> DOUBLE_ATA + IPO access. Dual DBs:"; echo "  [1] $BA_DB"; echo "  [2] $CA_DB";;
    e) ensure_db; touch_ca; read -rp "  second team param (sim): " t2; t2=${t2:-UNKNOWN_TEAM}
       write_ata ON 000000 "$t2"; log "PRE-FOUNDATION (sim DOUBLE_ATA)" ON
       c ">>> PRE-FOUNDATION: BUGSWITCH=ON, Services DOWN, dual DBs:"; echo "  [1] $BA_DB"; echo "  [2] $CA_DB";;
    *) die "Invalid choice.";;
  esac
}

# ── BOOTSTRAP GUARD: this is what prevented the C:\Users\dbugx accident ────
main(){
  local here; here=$(pwd -W 2>/dev/null || pwd)
  case "$here" in
    /c/Users/*|/mnt/c/Users/*|C:\\Users\\*)
      die "Refusing to operate in user profile ($here). cd to $WORKSPACE_ROOT/bughub-installer first.";;
  esac
  command -v jq >/dev/null 2>&1 || die "jq required (install via: winget install jqlang.jq)."
  resolve_cascade
  menu
}
main "$@"