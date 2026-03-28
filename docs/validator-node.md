# Validator Node Guide

Deploy and manage a Story Protocol validator node on testnet (Aeneid).

## Overview

A validator node participates in Story Protocol's consensus mechanism by validating transactions and producing blocks. Running a validator requires:
- Meeting hardware requirements
- Staking at least 1024 IP tokens
- Maintaining high uptime (~99%+)

## System Requirements

| Category | Requirements |
|----------|--------------|
| CPU | 8+ cores |
| RAM | 32+ GB |
| Storage | 500+ GB NVMe SSD |
| Bandwidth | 100+ MBit/s |
| OS | Ubuntu 22.04/24.04 (recommended) |

## Installation

### How to Install

1. Launch Valley of Story:
   ```bash
   bash <(curl -s https://raw.githubusercontent.com/hubofvalley/Testnet-Guides/main/Story%20Protocol/resources/valleyofStory.sh)
   ```
2. Select **"Node Interactions"** → **"Deploy/re-Deploy Validator Node"**
3. Follow the interactive prompts

### What Gets Installed

| Component | Details |
|-----------|---------|
| **story** | Consensus client (v1.5.2) |
| **story-geth** | Execution client (v1.2.1) |
| **story.service** | Systemd service for consensus |
| **story-geth.service** | Systemd service for execution |
| **Data directory** | `$HOME/.story` |

### Port Configuration

Default ports (adjustable during install with prefix, e.g., entering `38` gives ports like `38657`):

| Default Port | With prefix 38 | Service |
|--------------|----------------|---------|
| 26657 | 38657 | Cosmos RPC |
| 26656 | 38656 | P2P |
| 8545 | 38545 | EVM-RPC |
| 8546 | 38546 | WebSocket |

## Creating a Validator

After your node is fully synced:

1. Launch Valley of Story
2. Select **"Validator/Key Interactions"** → **"Create Validator"**
3. Enter your private key (or press Enter to use local key)
4. Configure:
   - **Moniker**: Your validator name
   - **Stake amount**: Minimum 1024 IP
   - **Stake type**: 
     - Locked (non-withdrawable)
     - Unlocked (withdrawable)
   - **Commission rate**: e.g., 10 for 10%
   - **Max commission change rate**: e.g., 5 for 5% daily max increase
   - **Max commission rate**: e.g., 50 for 50% maximum

### Minimum Requirements
- 1024 IP tokens for staking
- Additional IP for gas fees

## Staking Operations

### Delegate to a Validator

1. Launch Valley of Story
2. Select **"Validator/Key Interactions"** → **"Stake Tokens"**
3. Choose delegation target:
   - **Grand Valley** - Delegate to Grand Valley validator
   - **Self** - Delegate to your own validator
   - **Another validator** - Enter validator pubkey
4. Select RPC (default or Grand Valley's)
5. Enter amount in IP (e.g., 1024)
6. Provide private key (or use local)

### Unstake Tokens

1. Launch Valley of Story
2. Select **"Validator/Key Interactions"** → **"Unstake Tokens"**
3. Choose:
   - Unstake from self
   - Unstake from another validator
4. Enter amount to unstake

## Updating

### Update Consensus Client (story)

1. Launch Valley of Story
2. Select **"Node Interactions"** → **"Manage Consensus Client"** → **"Update Consensus Client Version"**

This includes Cosmovisor migration and deployment.

### Update Execution Client (story-geth)

1. Launch Valley of Story
2. Select **"Node Interactions"** → **"Update Geth Version"**

## Service Management

| Action | Menu Path |
|--------|-----------|
| Restart both | **"Node Management"** → **"Restart Validator Node"** |
| Restart consensus only | **"Node Management"** → **"Restart Consensus Client Only"** |
| Restart geth only | **"Node Management"** → **"Restart Geth Only"** |
| Stop both | **"Node Management"** → **"Stop Validator Node"** |
| Stop consensus only | **"Node Management"** → **"Stop Consensus Client Only"** |
| Stop geth only | **"Node Management"** → **"Stop Geth Only"** |

## Viewing Logs

| Logs | Menu Path |
|------|-----------|
| Combined logs | **"Node Interactions"** → **"Show Consensus Client & Geth Logs Together"** |
| Consensus logs only | **"Node Interactions"** → **"Show Consensus Client Logs"** |
| Geth logs only | **"Node Interactions"** → **"Show Geth Logs"** |

## Monitoring Node Status

1. Launch Valley of Story
2. Select **"Node Interactions"** → **"Show Validator Node Status"**

This displays:
- Consensus client block height
- Execution client (story-geth) block height
- Consensus client peers connected
- Execution client peers connected
- Real-time block height comparison
- Block difference (how far behind/ahead you are)

## Adding Peers

1. Launch Valley of Story
2. Select **"Node Interactions"** → **"Add Peers"**
3. Choose:
   - **Add peers manually** - Enter comma-separated peer addresses
   - **Use Grand Valley's peers** - Auto-fetch from Grand Valley's RPC

## Key Management

### Export EVM Key

1. Launch Valley of Story
2. Select **"Validator/Key Interactions"** → **"Export EVM Key"**

This shows your EVM address and private key.

### Query Validator Public Key

1. Launch Valley of Story
2. Select **"Validator/Key Interactions"** → **"Query Validator Public Key"**

Returns your Compressed Public Key (hex) for staking operations.

### Query Balance

1. Launch Valley of Story
2. Select **"Validator/Key Interactions"** → **"Query Balance"**
3. Choose:
   - Query your own EVM address
   - Query another EVM address

## Backup and Recovery

### Backup Validator Key

1. Launch Valley of Story
2. Select **"Node Management"** → **"Backup Validator Key"**

This copies `priv_validator_key.json` to your `$HOME` directory.

### Important Files to Backup

| File | Location | Purpose |
|------|----------|---------|
| `priv_validator_key.json` | `$HOME/.story/story/config/` | Validator signing key |
| `private_key.txt` | `$HOME/.story/story/config/` | EVM private key |
| Node data | `$HOME/.story/` | Full node data |

## Validator Responsibilities

- **Uptime**: Maintain 99%+ uptime to avoid slashing
- **Updates**: Keep node software current (story and story-geth)
- **Security**: Protect your keys and server
- **Backups**: Regular backups of keys and data
- **Monitoring**: Watch for missed blocks and peer connectivity

## Deleting the Node

> ⚠️ **WARNING**: Backup your seeds phrase, EVM private key, and `priv_validator_key.json` before deleting!

1. Launch Valley of Story
2. Select **"Node Management"** → **"Delete Validator Node"**

This removes:
- Systemd services
- Binaries
- All data in `$HOME/.story`

## Troubleshooting

### Node Not Syncing
1. Check peer connectivity via **"Show Validator Node Status"**
2. Add more peers via **"Add Peers"** option
3. Consider applying a snapshot via **"Apply Snapshot"**

### Negative Block Difference
This is normal - it means Story's official RPC is behind your node's height.

### Connection Issues
1. Verify firewall allows P2P ports
2. Check if your IP is reachable
3. Add Grand Valley's peers via **"Add Peers"**

## Install Story App Only

If you only need to execute transactions without running a full node:

1. Launch Valley of Story
2. Select **"Install the Story App only"**

This installs the `story` binary (v1.5.2) for signing transactions.

## Related Documentation

- [Cosmovisor Setup](cosmovisor.md)
- [Snapshot Application](snapshots.md)
- [Node Scheduler](scheduler.md)
