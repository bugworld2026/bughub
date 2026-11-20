# ==============================================================================
# BUGWORLD 2026 — DOCS FOLDER CANONICAL RESET (Post-9/11/2026)
# Script: reset_docs_canonical.ps1
# Purpose: Remove legacy docs and replace with Ground Zero canonical files
# ==============================================================================
param(
    [string]$Token = "<REDACTED_GITHUB_TOKEN>",
    [string]$RepoOwner = "bugworld2026",
    [string]$RepoName = "bughub",
    [string]$Branch = "main",
    [string]$DocsPath = "docs"
)

$ErrorActionPreference = 'Stop'
$headers = @{
    "Authorization" = "token $Token"
    "Accept"        = "application/vnd.github.v3+json"
    "User-Agent"    = "BUGWORLD-2026-DOCS-RESET"
}

function Get-GitHubFileSHA {
    param([string]$Path)
    $url = "https://api.github.com/repos/$RepoOwner/$RepoName/contents/$Path?ref=$Branch"
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        return @{
            SHA  = $response.sha
            Path = $response.path
        }
    } catch {
        return $null
    }
}

function Remove-GitHubFile {
    param([string]$Path, [string]$SHA, [string]$Message)
    $url = "https://api.github.com/repos/$RepoOwner/$RepoName/contents/$Path"
    $body = @{
        message = $Message
        sha     = $SHA
        branch  = $Branch
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri $url -Headers $headers -Method Delete -Body $body -ContentType "application/json"
    Write-Host "  [DELETED] $Path" -ForegroundColor Yellow
}

function Add-GitHubFile {
    param([string]$Path, [string]$Content, [string]$Message, [string]$Encoding = "utf-8")
    $url = "https://api.github.com/repos/$RepoOwner/$RepoName/contents/$Path"
    
    # Encode content as base64
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $contentBase64 = [Convert]::ToBase64String($bytes)
    
    $body = @{
        message = $Message
        content = $contentBase64
        branch  = $Branch
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri $url -Headers $headers -Method Put -Body $body -ContentType "application/json"
    Write-Host "  [ADDED] $Path" -ForegroundColor Green
}

# ==============================================================================
# STEP 1: SCAN AND REMOVE EXISTING FILES IN DOCS FOLDER
# ==============================================================================
Write-Host "`n=== STEP 1: CLEARING LEGACY DOCS ===" -ForegroundColor Cyan

$docsUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/contents/$DocsPath?ref=$Branch"
try {
    $existingFiles = Invoke-RestMethod -Uri $docsUrl -Headers $headers -Method Get
    Write-Host "Found $($existingFiles.Count) files in docs folder" -ForegroundColor Gray
    
    foreach ($file in $existingFiles) {
        if ($file.type -eq "file") {
            Write-Host "  Removing: $($file.path)" -ForegroundColor DarkGray
            Remove-GitHubFile -Path $file.path -SHA $file.sha -Message "Ground Zero reset: removing $($file.name)"
        }
    }
} catch {
    Write-Host "  No existing docs folder or error scanning: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# ==============================================================================
# STEP 2: PREPARE CANONICAL POST-9/11/2026 DOCUMENTATION FILES
# ==============================================================================
Write-Host "`n=== STEP 2: PREPARING CANONICAL FILES ===" -ForegroundColor Cyan

# File 1: ground_zero.txt (Using @' ... '@ to prevent backtick escape parsing)
$groundZeroContent = @'
### 1. "Ground Zero" Strategic Report (for Team Relay)
**TO:** Governance Triad (`adminq`, `admin-q`, `adminqq`)
**FROM:** `adminx` (via Secondary Node relay)
**SUBJECT:** GROUND ZERO: Canonical Reset & Phase 2 Installer Doctrine

#### **1. Executive Summary**
"Ground Zero" represents a deliberate, total reset of our foundational documentation and operational logic.
By deleting the five legacy core files, we have eliminated accumulated technical debt, contradictory pathing rules, and legacy "First Foundation" logic that was corrupting Second Foundation operations.
We are rebuilding from a single source of truth, prioritizing deterministic automation over manual, error-prone filesystem manipulation.

#### **2. The Four Pillars of Ground Zero**

**Pillar A: Odd Character Count Rule (OCCR)**
*When base_name has odd_char_count=Y there MUST be a trailing dash in the value of code_name.*
This ensures the formal `code_name` always resolves to an **even** character count for deterministic path hashing.
The dash exists strictly in filesystem paths, protocol payloads, and Gate-3 validation.

New terminology (for the names of nodes):
Always base_name=node_name_1 & code_name=node_name_2;
When odd_char_count=Y then base_name≠code_name & node_name_1≠node_name_2;
When odd_char_count=N then base_name=code_name & node_name_1=node_name_2;

Examples (for the names of nodes):
My name is Douglas (i.e. odd_char_count=Y) but I don't want to go around calling myself Douglas-
However in BUGWORLD my `path_to_server` would be PTS="C:\dbug\superid\{GUID}\{ENV}\D\o\u\g\l\a\s\-\s-\mcp\server.py"

The name of the initial probationary `client_superid` is BUGWORLD2026TestSite22 (i.e. odd_char_count=N)
PTS=C:\dbug\superid\BUGWORLD2026TestSite22\0\B\U\G\W\O\R\L\D\2\0\2\6\T\e\s\t\S\i\t\e\2\2\22\mcp\server.py

Unified Naming Conventions: Listed Examples (UNC/UNCLE)
All naming conventions (like OCCR as given above) will be stored and updated in a table in the Bugbase database.
These naming conventions will apply to nodes, paths, filenames & directories of services, etc., depending on context and usage.
From the rules as defined by these conventions, we can generate listed examples in a file called `uncle.json` (and refer to these examples as "Names from UNCLE").

**Pillar B: Path Interpolation Safety (TASK-057 Mandate)**
All PowerShell and Bash scripts must use explicit literal separators (e.g., `"$TeamRootBase\$TeamParam"`).
Pre-flight regex validation is now a mandatory gate before any filesystem materialization or ATA ritual.

**Pillar C: Installer Probationary Onboarding (IPO)**
The new cross-platform `install_bugworld.sh` script will materialize the `dbug_monorepo` in a pristine, validated state.
- It will load exactly one cassette: `2cp1`.
- It will allocate a single SPAS instance for the probationary `client_superid`.
- It will enforce strict FSC62 GUID validation (exactly 22 characters, alphanumeric, at least one uppercase letter, zero dashes).
- The resulting PTS will deterministically bind to port `2000` (reserved for experimental/probationary code).

**Pillar D: Triad Realignment & Clean Separation**
The Governance Triad (`adminq`, `admin-q`, `adminqq`) is now strictly defined with unambiguous identities.
First Foundation logic (numeric identities, legacy monitoring) is completely decoupled from Second Foundation mutation operations.

#### **3. Immediate Next Actions**
1. **Triad Acknowledgment:** Primary and Tertiary nodes must ingest their new instruction blocks and acknowledge ZTTD compliance.
2. **Script Drafting:** We will draft and validate the corrected `install_bugworld.sh` script, incorporating the fixed manifest identity, sequential section expansion, and dynamic Third System path computation.
3. **Cassette Materialization:** Define the explicit filesystem steps for the `2cp1` cassette state to ensure the installer behaves identically across Windows, Linux, and macOS environments.

---
Let me know when you are ready to proceed with drafting the corrected `install_bugworld.sh` script, and I will generate it with all TASK-057 and FSC62 validation gates explicitly coded. Then we will request adminqq to validate the script and as the last step we will request adminq (Team Leader charged with duty of general oversight) to ratify our final draft before we save it here C:\dbug\workspace\bughub-installer\tools\sh\install_bugworld.sh ...
'@

# File 2: new_memory.md
$newMemoryContent = @'
# BUGWORLD Memory (New Version)

## I - Installer Toolchain (Two-Repo Separation)

This doctrine defines the canonical separation of concerns for tools within the BUGWORLD ecosystem, preventing future architectural confusion.

### 1. `C:\dbug\workspace\bughub-installer\tools\`
**Purpose:** Installer-specific toolchain for the bughub-installer repository (`https://github.com/bugworld2026/bughub/`).

**Mandate:** These tools are specifically for bootstrapping and onboarding. They are part of the installer distribution package.

**Contains:**
- `sh/` → Bash scripts for cross-platform installation/uninstallation (e.g., `install_bugworld.sh`, `uninstall_bugworld.sh`, `insert_cassette.sh`, `eject_cassette.sh`).
- `ps1/` → PowerShell equivalents for Windows-native operations (e.g., `team_onboard_wizard.ps1`, `path_safety_gate.ps1`, `triad_ledger_generator.ps1`).
- `txt/` → Audit reports and installation logs.

### 2. `C:\dbug\workspace\tools\`
**Purpose:** General-purpose utilities for the dbug_monorepo (`https://github.com/dbugpro/dbug/`).

**Mandate:** These are runtime utilities used across the entire dbug ecosystem, not just during installation.

**Contains:**
- `csv/` → Data export/import utilities.
- `html/` → Web-based generators (e.g., `bugworld_alphabet_generator.html`).
- `json/` → JSON manipulation tools, schema validators.
- `ps1/` → General PowerShell utilities (not installer-specific).
- `py/` → Python utilities, MCP stubs, protocol handlers.
- `sql/` → Database migration scripts, Bugbase queries.
- `txt/` → General documentation, reference materials.

## TASK-0004 Artifact Placement

Based on the nature of TASK-0004 (Second Foundation Onboarding Wizards), the ratified modules belong in:
`C:\dbug\workspace\bughub-installer\tools\ps1\`

**Rationale:** The onboarding wizard is part of the installer toolchain, used to bootstrap new teams, not a runtime operation.

## W - Winget Location

The winget.exe executable is located at the following path:
`C:\Users\dbugx\AppData\Local\Microsoft\WindowsApps\`

This path should be added to the system or session PATH environment variable to ensure winget commands are recognized in PowerShell.

## Z - Zero Tolerance Trailing Dash (ZTTD)

Two mandated rules for the trailing dash:

**ZTTD mandates** that the "trailing dash" is permissible ONLY for those nodes which have a `base_name` where `odd_char_count=true` (for example, the node referred to as `secret_agent` has `base_name=-` & `code_name=--`).

For ALL instances of nodes which have a `base_name` where `odd_char_count=false`, ZTTD mandates "zero tolerance trailing dash".

The following explanation is quoted from "The Four Pillars of Ground Zero":

**Source:** `C:\dbug\workspace\docs\ground_zero.txt`

### Pillar A: Odd Character Count Rule (OCCR)

When `base_name` has `odd_char_count=true` there MUST be a trailing dash in the value of `code_name`.

This ensures the formal `code_name` always resolves to an even character count for deterministic path hashing.

The dash exists strictly in filesystem paths, protocol payloads, and Gate-3 validation.

**New terminology (for the names of nodes):**
- Always `base_name` = `node_name_1` & `code_name` = `node_name_2`;
- When `odd_char_count=true` then `base_name` ≠ `code_name` & `node_name_1` ≠ `node_name_2`;
- When `odd_char_count=false` then `base_name` = `code_name` & `node_name_1` = `node_name_2`;

**Examples (for the names of nodes):**
- My name is Douglas (i.e., `odd_char_count=true`) but I don't want to go around calling myself Douglas-
- However, in BUGWORLD my `path_to_server` would be `PTS="C:\dbug\superid\{GUID}\{ENV}\D\o\u\g\l\a\s\-\s-\mcp\server.py"`
- The name of the initial probationary `client_superid` is `BUGWORLD2026TestSite22` (i.e., `odd_char_count=false`)
- `PTS=C:\dbug\superid\BUGWORLD2026TestSite22\0\B\U\G\W\O\R\L\D\2\0\2\6\T\e\s\t\S\i\t\e\2\2\22\mcp\server.py`

### Unified Naming Conventions: Listed Examples (UNC/UNCLE)

All naming conventions (like OCCR as given above) will be stored and updated in a table in the Bugbase database.

These naming conventions will apply to nodes, paths, filenames & directories of services, etc., depending on context and usage.

From the rules as defined by these conventions, we can generate listed examples in a file called `uncle.json` (and refer to these examples as "Names from UNCLE").
'@

# File 3: new_tasks_manifest.json
$newTasksManifestContent = @'
{
  "manifest_version": "1.0",
  "created_at": "2026-09-11T00:00:00Z",
  "last_updated": "2026-09-12T12:00:00Z",
  "tasks": [
    {
      "task_id": "TASK-0000",
      "title": "Ground Zero Strategic Report - Original Draft",
      "description": "Creation and initial drafting of the Ground Zero strategic report document, establishing the Four Pillars (OCCR, TASK-057, IPO, Triad Realignment) and canonical reset doctrine.",
      "status": "completed",
      "related_files": [
        "C:\\dbug\\workspace\\docs\\ground_zero.txt"
      ],
      "assigned_nodes": [
        "adminx",
        "adminq",
        "admin-q",
        "adminqq"
      ],
      "created_at": "2026-09-11T00:00:00Z",
      "completed_at": "2026-09-11T00:00:00Z"
    },
    {
      "task_id": "TASK-0001",
      "title": "install_bugworld.sh - Phase 2 Installer Script",
      "description": "Discussing, drafting, validating, correcting, ratifying, and saving the first draft of the cross-platform installer script. Must incorporate TASK-057 path interpolation safety, FSC62 GUID validation, OCCR dynamic path computation, 2cp1 cassette loading, and port 2000 binding.",
      "status": "completed",
      "related_files": [
        "C:\\dbug\\workspace\\bughub-installer\\tools\\sh\\install_bugworld.sh",
        "C:\\dbug\\workspace\\docs\\ground_zero.txt"
      ],
      "assigned_nodes": [
        "adminx",
        "admin-q",
        "adminqq",
        "adminq"
      ],
      "created_at": "2026-09-11T00:00:00Z",
      "completed_at": "2026-09-11T12:00:00Z"
    },
    {
      "task_id": "TASK-0002",
      "title": "Cross-Platform Uninstaller Module (Ground Zero Compliant)",
      "description": "Develop a cross-platform uninstaller (Bash/PowerShell) that reverses the install_bugworld.sh materialization. Must enforce TASK-057 path safety, respect OCCR directory structures, and include a --force-permanent flag for explicit SPAS instance removal. Must log to the session ledger.",
      "status": "completed",
      "related_files": [
        "C:\\dbug\\workspace\\bughub-installer\\tools\\sh\\uninstall_bugworld.sh",
        "C:\\dbug\\workspace\\docs\\ground_zero.txt"
      ],
      "assigned_nodes": [
        "adminx",
        "admin-q",
        "adminqq",
        "adminq"
      ],
      "created_at": "2026-09-11T12:30:00Z",
      "completed_at": "2026-09-11T16:45:00Z"
    },
    {
      "task_id": "TASK-0003",
      "title": "Generalized Cassette Protocol (CP) Toolchain",
      "description": "Develop standalone insert_cassette.sh and eject_cassette.sh tools. Must integrate with Bugbase port_register and role_instances tables, enforce FSC62 validation for new assets, and strictly protect the probationary client_superid unless explicitly targeted.",
      "status": "completed",
      "related_files": [
        "C:\\dbug\\workspace\\bughub-installer\\tools\\sh\\insert_cassette.sh",
        "C:\\dbug\\workspace\\bughub-installer\\tools\\sh\\eject_cassette.sh",
        "C:\\dbug\\workspace\\docs\\ground_zero.txt"
      ],
      "assigned_nodes": [
        "adminx",
        "admin-q",
        "adminqq",
        "adminq"
      ],
      "created_at": "2026-09-11T12:30:00Z",
      "completed_at": "2026-09-11T19:00:00Z"
    },
    {
      "task_id": "TASK-0004",
      "title": "Second Foundation Onboarding Wizards",
      "description": "Generate interactive scripts to guide clients from probationary status to full team formation. Includes Team PARAM generation (OCCR compliant), Governance Triad seat allocation, and /init_ata CLI ritual execution. All path interpolations must pass the TASK-057 pre-flight gate.",
      "status": "completed",
      "related_files": [
        "C:\\dbug\\workspace\\bughub-installer\\tools\\ps1\\team_onboard_wizard.ps1",
        "C:\\dbug\\workspace\\bughub-installer\\tools\\ps1\\path_safety_gate.ps1",
        "C:\\dbug\\workspace\\bughub-installer\\tools\\ps1\\triad_ledger_generator.ps1",
        "C:\\dbug\\workspace\\docs\\ground_zero.txt",
        "C:\\dbug\\workspace\\docs\\new_memory.md"
      ],
      "assigned_nodes": [
        "adminx",
        "admin-q",
        "adminqq",
        "adminq"
      ],
      "created_at": "2026-09-11T12:30:00Z",
      "completed_at": "2026-09-12T12:00:00Z"
    },
    {
      "task_id": "TASK-0005",
      "title": "BUGSWITCH-Control Enhancement & Payload Registration (PLA)",
      "description": "Implement POST /bugswitch/payload/register and update BUGSWITCH state mutation to include the PLA parameter. Must enforce the Triple-Gate for OFF/Y transitions. Decoupled from legacy First Foundation monitoring.",
      "status": "pending",
      "related_files": [],
      "assigned_nodes": [
        "adminx",
        "admin-q",
        "adminqq",
        "adminq"
      ],
      "created_at": "2026-09-11T12:30:00Z",
      "completed_at": null
    },
    {
      "task_id": "TASK-0006",
      "title": "GAIA MACHINE Logic Expansion (ERS/ADCO Routing)",
      "description": "Expand gaia-machine to route ERS cleaning requests to bugswitch-control and apply ADCO analysis on ON/Y payloads. Must operate strictly within the Second Foundation mutation boundary.",
      "status": "pending",
      "related_files": [],
      "assigned_nodes": [
        "adminx",
        "admin-q",
        "adminqq",
        "adminq"
      ],
      "created_at": "2026-09-11T12:30:00Z",
      "completed_at": null
    },
    {
      "task_id": "TASK-0007",
      "title": "Automation Configuration Schema & Token Delegation",
      "description": "Define the Tacit Approval configuration schema. Ensure automation daemons hold valid governance identities and session tokens minted under ATA.",
      "status": "pending",
      "related_files": [],
      "assigned_nodes": [
        "adminx",
        "admin-q",
        "adminqq",
        "adminq"
      ],
      "created_at": "2026-09-11T12:30:00Z",
      "completed_at": null
    }
  ]
}
'@

# ==============================================================================
# STEP 3: UPLOAD CANONICAL FILES
# ==============================================================================
Write-Host "`n=== STEP 3: UPLOADING CANONICAL FILES ===" -ForegroundColor Cyan

$commitMessage = "Ground Zero reset: canonical post-9/11/2026 documentation"

Add-GitHubFile -Path "docs/ground_zero.txt" -Content $groundZeroContent -Message "$commitMessage - ground_zero.txt"
Add-GitHubFile -Path "docs/new_memory.md" -Content $newMemoryContent -Message "$commitMessage - new_memory.md"
Add-GitHubFile -Path "docs/new_tasks_manifest.json" -Content $newTasksManifestContent -Message "$commitMessage - new_tasks_manifest.json"

# ==============================================================================
# STEP 4: VERIFICATION
# ==============================================================================
Write-Host "`n=== STEP 4: VERIFICATION ===" -ForegroundColor Cyan

try {
    $finalCheck = Invoke-RestMethod -Uri $docsUrl -Headers $headers -Method Get
    Write-Host "Final docs folder contents:" -ForegroundColor Green
    foreach ($file in $finalCheck) {
        if ($file.type -eq "file") {
            Write-Host "  ✓ $($file.name) ($($file.size) bytes)" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "  Error verifying: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== DOCS RESET COMPLETE ===" -ForegroundColor Green
Write-Host "Canonical files uploaded to: https://github.com/$RepoOwner/$RepoName/tree/$Branch/docs" -ForegroundColor Cyan
