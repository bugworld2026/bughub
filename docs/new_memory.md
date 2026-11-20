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