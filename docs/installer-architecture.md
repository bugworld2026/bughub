# BUGHUB Installer Architecture

## Overview
The BUGHUB installer implements a deterministic, doctrine-compliant installation system for the BUGWORLD 2026 ecosystem, enforcing the Permanent Node Doctrine and Triple-Gate Write Model.

## Core Principles

### 1. Permanent Node Doctrine
Two non-removable PTS/APTS pairs are created during installation:
- **secret_agent**: Second System agent-root node
- **superid**: FSC62+ superid-root node generated from client GUID

These nodes CANNOT be removed by standard uninstall or EJECT_CASSETTE operations.

### 2. Three-Root Structure
```
C:\dbug\
├── agent\          (Second System agent-root)
├── superid\        (superid-root, FSC62+)
└── workspace\      (services, sessions, docs, frameworks)
```

### 3. Machine-Agnostic Schema
All paths follow the canonical shape: `{root}\x\0\{sequential_section}\{derived_pairs}\{end_of_path}`

### 4. GUID & ENV Workflow
- **GUID**: FSC62+-validated unique identifier (a-z, 0-9, A-Z, dash)
- **ENV**: Environment identifier (alphanumeric + dash), multiple per GUID allowed
- Path interpolation: `C:\dbug\agent\x\0\{GUID}\{ENV}\...`

## Installation Phases

### Phase 1: Validation
1. Validate GUID (FSC62+ compliance, Bugbase conflict check)
2. Validate ENV (uniqueness per GUID)
3. Check administrative privileges
4. Verify system requirements (PowerShell 7+, Windows 10/11)

### Phase 2: Filesystem Installation
1. Create three-root structure
2. Materialize 12 permanent service stubs (2001-2012)
3. Materialize MCP node stubs (2103-2317)
4. Create Third System alias root (absol, 3101)
5. Create permanent nodes (secret_agent + superid)
6. Write install_manifest.json

### Phase 3: Registry Integration
1. Write HKLM registry keys
2. Configure environment variables
3. Optional PATH modification

### Phase 4: Governance Setup
1. Optional ATA ritual execution
2. Bugbase registration
3. Generate SECOND FOUNDATION wizards

### Phase 5: Cassette Integration
1. Load optional cassette manifests
2. Wire to port_register
3. Validate service connectivity

## Uninstallation Doctrine

Standard uninstall preserves permanent nodes. Full removal requires explicit `--force-permanent` flag.

## Governance Constraints

- **Triple-Gate Write Model**: All state-changing operations require BUGSWITCH=OFF, ATA validation, and governance identity
- **Cassette Protocol**: Temporary nodes loaded via INSERT_CASSETTE can be ejected; permanent nodes protected
- **Service Topology**: 12 permanent services (2001-2012) started in strict ascending order

## Dependencies

- PowerShell 7.6.5+
- Node.js 24.18.0 (Theia Blueprint)
- Node.js 18.20.8 (tiangan-core)
- Windows Administrator privileges
- SQLite (Bugbase)

## References

- `memory.md` §14.8 (Machine-Agnostic Schema)
- `memory.md` §16 (BUGWORLD Governance)
- `tasks_manifest.json` TASK-060 through TASK-073
- `bugworld_glossary.json` (Canonical Terminology)
