<p align="center">
  <img src="resources/vos_menu.png" alt="Valley of Story Logo" width="500">
</p>

<h1 align="center">Valley of Story Testnet</h1>

<p align="center">
  <strong>Toolkit for deploying and managing Story Protocol validator nodes on testnet (Aeneid)</strong>
</p>

<p align="center">
  <a href="https://www.story.foundation" target="_blank">Story Protocol</a> •
  <a href="https://docs.story.foundation" target="_blank">Official Docs</a> •
  <a href="https://github.com/hubofvalley" target="_blank">Grand Valley</a>
</p>

---

## Overview

Valley of Story Testnet is an open-source project by **Grand Valley** that provides automated scripts for deploying and managing Story Protocol validator nodes on the **Aeneid testnet**.

## System Requirements

| Category | Requirements |
|----------|--------------|
| CPU | 8+ cores |
| RAM | 32+ GB |
| Storage | 500+ GB NVMe SSD |
| Bandwidth | 100+ MBit/s |

## Getting started

Run the main interactive menu:

```bash
bash <(curl -s https://raw.githubusercontent.com/hubofvalley/Testnet-Guides/main/Story%20Protocol/resources/valleyofStory.sh)
```

## Features

The Valley of Story menu provides:

### Node Interactions
- Deploy/re-deploy validator node (with Cosmovisor)
- Manage consensus client (migrate to Cosmovisor or update version)
- Apply snapshots
- Add peers
- Update Geth version
- Show node status and logs

### Validator/Key Interactions
- Create validator
- Query validator public key
- Query balance
- Stake/unstake tokens
- Export EVM key

### Node Management
- Start/stop/restart services
- Backup validator key
- Schedule stop/restart operations
- Delete validator node

## Current Versions

| Component | Version |
|-----------|---------|
| Story (consensus) | v1.5.2 |
| Story-Geth (execution) | v1.2.1 |
| Chain | aeneid |
| Chain ID | 1315 |

## Grand Valley Public Endpoints

| Type | URL |
|------|-----|
| Cosmos RPC | `https://lightnode-rpc-story.grandvalleys.com` |
| EVM RPC | `https://lightnode-json-rpc-story.grandvalleys.com` |
| Cosmos REST API | `https://lightnode-api-story.grandvalleys.com` |
| Cosmos WebSocket | `wss://lightnode-rpc-story.grandvalleys.com/websocket` |
| EVM WebSocket | `wss://lightnode-wss-story.grandvalleys.com` |
| Peer | `7e311e22cff1a0d39c3758e342fa4c2ee1aea461@peer-story.grandvalleys.com:28656` |

## Privacy & Security

- **No external data storage** - All operations run locally
- **No phishing links** - All URLs are for legitimate Story operations
- **Open source** - Full audit trail available
- Please verify script integrity before running

## Documentation

For detailed documentation, see the [docs/](docs/) folder.

## Links

**Story Protocol:**
- [Website](https://www.story.foundation) | [Docs](https://docs.story.foundation) | [X/Twitter](https://x.com/StoryProtocol)

**Grand Valley:**
- [GitHub](https://github.com/hubofvalley) | [X/Twitter](https://x.com/bacvalley) | [Testnet Guide](https://github.com/hubofvalley/Testnet-Guides/tree/main/Story%20Protocol)

**Validators & Explorers:**
- [Aeneid Staking](https://aeneid.staking.story.foundation/validators/0x1b5452a212db06F6D6879C292157396B6dCa44d7)
- [Aeneid StoryScan](https://aeneid.storyscan.app/validators/storyvaloper1rd299gsjmvr0d458ns5jz4eeddku53xhm5j2j4)

## Contact

Email: letsbuidltogether@grandvalleys.com

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
