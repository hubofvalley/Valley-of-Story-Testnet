*# AI Agent Instructions (Valley of Story Testnet Repository)

Scope:
- These instructions apply to all files and changes in this repository.

Repository goals:
- Provide safe, minimal, and reliable operational tooling for Story testnet nodes.
- The primary entrypoint script is `valleyofStory.sh`; prioritize its correctness and stability.

Global rules for AI agents:
- Read this file before making changes.
- Keep changes minimal and focused on the request.
- Preserve existing behavior unless a change is explicitly requested.
- Do not remove features without confirmation.
- Avoid adding new dependencies; if required, explain why and keep the footprint small.
- Do not introduce network calls, telemetry, or external services without explicit approval.
- These instructions constitute the global rules for the Valley of Story Testnet Repository.

Safety and operations:
- Be cautious with commands that affect the system (`sudo`, `apt-get`, `systemctl`, scheduling).
- Do not change operational command sequences without confirmation.
- Prefer clear, deterministic behavior over convenience.

Shell scripting rules (applies to all bash scripts):
- Scripts may use `set -euo pipefail`; ensure all variables are initialized.
- Always quote variables (`"$var"`) and use `printf` for time/date formatting.
- Keep error handling explicit and user-facing messages clear.

Logging rules:
- Preserve existing log formats and file locations unless explicitly changed.
- For job logs, keep the format: `job_id|action|dt_human|dt_at|created_utc`.

Key locations (reference only):
- `resources/valleyofStory.sh`: primary entrypoint script for this repo.
- `resources/story_validator_node_install_mainnet.sh`: testnet validator install flow.
- `resources/story_update.sh`: Story node update flow.
- `resources/story-geth_update.sh`: Story geth update flow.
- `resources/cosmovisor_migration.sh`: cosmovisor migration helper.
- `resources/apply_snapshot.sh`: snapshot apply helper.
- `resources/story_node_schedule.sh`: scheduling helper script.
- `~/.story/story_schedule_jobs.log`: job log (created at runtime).
- `resources/*.png` and `resources/brand-kit/*.svg`: UI/branding assets used by the repo.

Light testing (optional and safe):
- `bash -n resources/story_node_schedule.sh`
*