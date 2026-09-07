# BUGHUB Installer Documentation

## Permanent Node Doctrine
The installer creates two permanent PTS/APTS pairs that cannot be ejected:
1. **secret_agent**: Second System node under C:\\dbug\\agent\\
2. **superid**: SuperID-root node under C:\\dbug\\superid\\

## Installation Workflow
1. GUID validation (FSC62+ compliance)
2. ENV input (multi-environment support)
3. Filesystem installation (three-root structure)
4. Registry integration
5. Optional ATA ritual execution
6. SECOND FOUNDATION wizard setup

## Uninstallation
- Standard uninstall preserves permanent nodes
- Use \--force-permanent\ flag for complete removal
