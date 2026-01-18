# Snapshot Guide

Speed up node synchronization using snapshots.

## Overview

Snapshots allow you to quickly sync your node by downloading a pre-synced database state instead of syncing from genesis. This can save hours or even days of sync time.

## When to Use Snapshots

- **New node setup** - Get synced quickly instead of days of block sync
- **After pruning issues** - Restore from a known good state
- **Disk corruption recovery** - Recover without re-syncing from genesis
- **Fast recovery** - Get back online quickly after issues

## How to Apply Snapshots

1. Launch Valley of Story:
   ```bash
   bash <(curl -s https://raw.githubusercontent.com/hubofvalley/Testnet-Guides/main/Story%20Protocol/resources/valleyofStory.sh)
   ```
2. Select **"Node Interactions"** → **"Apply Snapshot"**
3. Choose your preferred snapshot provider
4. Follow the prompts

## What the Snapshot Script Does

1. **Stops services** - Stops story and story-geth
2. **Backs up important files** - Saves validator keys
3. **Downloads snapshot** - From selected provider
4. **Extracts data** - Replaces chain data
5. **Restores keys** - Puts validator keys back
6. **Restarts services** - Brings node back online

## Available Snapshot Providers

The script presents multiple snapshot providers to choose from. Each provider may have different:
- Snapshot freshness (how recent)
- Compression format
- Download speed
- Pruning settings

## Before Applying a Snapshot

### Backup Important Files

The snapshot script handles backups automatically, but important files include:

| File | Location | Purpose |
|------|----------|---------|
| `priv_validator_key.json` | `$HOME/.story/story/config/` | Validator key |
| `private_key.txt` | `$HOME/.story/story/config/` | EVM private key |
| `node_key.json` | `$HOME/.story/story/config/` | Node identity |

You can also backup manually via:
1. Launch Valley of Story
2. Select **"Node Management"** → **"Backup Validator Key"**

## After Applying a Snapshot

### Verify Services are Running

1. Launch Valley of Story
2. Select **"Node Interactions"** → **"Show Validator Node Status"**

### Monitor Progress

1. Launch Valley of Story
2. Select **"Node Interactions"** → **"Show Consensus Client & Geth Logs Together"**

## Snapshot Data Locations

| Component | Data Location |
|-----------|---------------|
| Story (consensus) | `$HOME/.story/story/data/` |
| Story-Geth (execution) | `$HOME/.story/geth/aeneid/` |

## Troubleshooting

### Snapshot Download Failed
- Check internet connectivity
- Try a different snapshot provider (re-run **"Apply Snapshot"**)
- Verify disk space availability

### Node Not Starting After Snapshot
1. Check logs via **"Show Consensus Client Logs"**
2. Verify data directories exist
3. Check if validator keys were restored

### Wrong Chain Data
- Ensure you're using an Aeneid testnet snapshot
- Verify chain ID matches: `aeneid` (chain ID: 1315)

### Catching Up Is Slow
- This is normal initially after snapshot apply
- The node needs to sync from snapshot height to current
- Monitor via **"Show Validator Node Status"**
- Usually stabilizes within an hour

## Disk Space Considerations

| Component | Approximate Size |
|-----------|-----------------|
| Story snapshot | 50-150 GB (varies) |
| Story-Geth snapshot | 30-100 GB (varies) |
| Working space during extraction | 2x snapshot size |

Ensure you have enough free space before applying.

## Related Documentation

- [Validator Node Guide](validator-node.md)
- [Cosmovisor Setup](cosmovisor.md)
