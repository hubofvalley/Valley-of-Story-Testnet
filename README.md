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
bash <(curl -fsSL https://raw.githubusercontent.com/hubofvalley/Valley-of-Story-Testnet/main/resources/valleyofStory.sh)
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
| Story (consensus) | v1.7.0 |
| Story-Geth (execution) | v1.2.1 |
| Chain | aeneid |
| Chain ID | 1315 |

## Grand Valley endpoint status

Grand Valley endpoint entries are not guaranteed to be live. Verify current endpoint availability and network identity before use; the toolkit does not claim active-validator-set membership or continuous public service availability.

## Privacy & Security

- **Local key/data boundary** - Keys and node data remain on your machine; network requests go only to the endpoint or release sources selected by the workflow
- **No phishing links** - All URLs are for legitimate Story operations
- **Open source** - Full audit trail available
- Please verify script integrity before running

## Documentation

For detailed documentation, see the [docs/](docs/) folder.

## Links

**Story Protocol:**
- [Website](https://www.story.foundation) | [Docs](https://docs.story.foundation) | [X/Twitter](https://x.com/StoryProtocol)

**Grand Valley:**
- [GitHub](https://github.com/hubofvalley) | [X/Twitter](https://x.com/bacvalley) | [Testnet toolkit](https://github.com/hubofvalley/Valley-of-Story-Testnet)

**Validators & Explorers:**
- [Aeneid Staking](https://aeneid.staking.story.foundation/validators/0x1b5452a212db06F6D6879C292157396B6dCa44d7)
- [Aeneid StoryScan](https://aeneid.storyscan.app/validators/storyvaloper1rd299gsjmvr0d458ns5jz4eeddku53xhm5j2j4)

## Contact

Email: letsbuidltogether@grandvalleys.com

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
