# Cosmovisor Guide

Set up Cosmovisor for automatic validator node upgrades.

## Overview

Cosmovisor is a process manager that handles binary upgrades for Cosmos SDK-based chains. It monitors for upgrade proposals and automatically swaps binaries when an upgrade height is reached.

## Benefits

- **Automatic upgrades** - No manual intervention required at upgrade height
- **Zero downtime** - Seamless binary swaps during chain upgrades
- **Rollback support** - Keeps backups of previous versions
- **Pre-download** - Can download new binaries before upgrade height

## What Cosmovisor Does

1. Runs your `story` binary as a subprocess
2. Monitors for governance upgrade proposals
3. When upgrade height is reached:
   - Stops the current binary
   - Swaps to the new binary
   - Restarts automatically

## Migration to Cosmovisor

### Option 1: Migration Only

Migrate an existing validator to Cosmovisor without updating:

1. Launch Valley of Story:
   ```bash
   bash <(curl -s https://raw.githubusercontent.com/hubofvalley/Testnet-Guides/main/Story%20Protocol/resources/valleyofStory.sh)
   ```
2. Select **"Node Interactions"** → **"Manage Consensus Client"** → **"Migrate to Cosmovisor only"**

This will:
- Install Cosmovisor if not present
- Set up the directory structure
- Update your systemd service file
- Move current binary to Cosmovisor's genesis folder

### Option 2: Migration + Update

Migrate and update to the latest version:

1. Launch Valley of Story
2. Select **"Node Interactions"** → **"Manage Consensus Client"** → **"Update Consensus Client Version"**

This includes:
- Cosmovisor migration
- Binary update to latest version
- Service file configuration

## Directory Structure

After migration, your validator uses this structure:

```
$HOME/.story/story/cosmovisor/
├── current -> genesis (or upgrades/<upgrade-name>)
├── genesis/
│   └── bin/
│       └── story          # Initial/current binary
├── upgrades/
│   └── <upgrade-name>/
│       └── bin/
│           └── story      # Upgraded binary
└── backup/                # Backup of previous versions
```

### Key Directories

| Directory | Purpose |
|-----------|---------|
| `genesis/bin/` | Initial binary or current version |
| `upgrades/<name>/bin/` | Upgraded binaries per upgrade |
| `backup/` | Automatic backups before upgrades |
| `current` | Symlink to active version |

## Environment Variables

After migration, these are configured in your systemd service:

| Variable | Value | Purpose |
|----------|-------|---------|
| `DAEMON_NAME` | story | Binary name |
| `DAEMON_HOME` | $HOME/.story/story | Data directory |
| `DAEMON_DATA_BACKUP_DIR` | .../backup | Backup location |

## Checking Cosmovisor Status

1. Launch Valley of Story
2. Select **"Node Interactions"** → **"Show Validator Node Status"**

This shows your node status including what version is running.

## Troubleshooting

### Cosmovisor Not Starting
1. Check logs via **"Node Interactions"** → **"Show Consensus Client Logs"**
2. Verify the node was properly migrated

### Wrong Binary Running
1. Use **"Manage Consensus Client"** → **"Update Consensus Client Version"** to fix

### Service File Issues
1. Re-run **"Manage Consensus Client"** → **"Migrate to Cosmovisor only"** to reset configuration

## Related Documentation

- [Validator Node Guide](validator-node.md)
- [Snapshot Application](snapshots.md)
