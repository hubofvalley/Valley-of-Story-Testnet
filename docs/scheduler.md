# Node Scheduler Guide

Schedule automated node start/stop operations.

## Overview

The scheduler uses the Linux `at` command to schedule node operations at specific times. This is useful for:
- **Coordinated upgrades** - Schedule restarts at upgrade height time
- **Maintenance windows** - Plan downtime during low-activity periods
- **Automated restarts** - Schedule periodic restarts if needed
- **Upgrade preparation** - Stop nodes before manual upgrades

## How It Works

The scheduler:
1. Installs the `at` daemon if not present
2. Schedules jobs using `at -t` with UTC time conversion
3. Logs all scheduled jobs for tracking
4. Executes systemd commands at the scheduled time

## Usage

1. Launch Valley of Story:
   ```bash
   bash <(curl -s https://raw.githubusercontent.com/hubofvalley/Testnet-Guides/main/Story%20Protocol/resources/valleyofStory.sh)
   ```
2. Select **"Node Management"** → **"Schedule Stop/Restart Validator Node"**

## Menu Options

| Option | Description |
|--------|-------------|
| **1. List scheduled jobs** | View all pending scheduled operations with details |
| **2. Stop and disable Story services** | Schedule `systemctl stop` + `systemctl disable` |
| **3. Restart and enable Story services** | Schedule `systemctl restart` + `systemctl enable` |
| **4. Remove a scheduled job** | Cancel a pending operation by job ID |
| **5. Exit** | Return to main menu |

## Scheduling a Job

When scheduling, you'll enter the time in UTC:

| Field | Range | Example |
|-------|-------|---------|
| Year | 4 digits | 2026 |
| Month | 1-12 | 1 (January) |
| Day | 1-31 | 15 |
| Hour | 0-23 (24h) | 14 (2 PM) |
| Minute | 0-59 | 30 |
| Second | 0-59 | 0 |

### Example

To schedule a restart for January 15, 2026 at 14:30:00 UTC:
```
year: 2026
month: 1
day: 15
hour: 14
minute: 30
second: 0
```

## Time Handling

- **Input**: All times are entered as UTC
- **Conversion**: Script converts UTC to your server's local timezone
- **Execution**: Jobs run at the equivalent local time
- **Seconds**: Handled via `sleep` (at daemon only supports minute precision)

## What Gets Scheduled

### Stop and Disable
Stops and disables both `story` and `story-geth` services.

### Restart and Enable
Reloads daemon, enables, and restarts both services.

## Job Management

### Viewing Jobs

Select option 1 to see all scheduled jobs with:
- Job ID
- Scheduled time
- Action type (stop/disable or restart/enable)

Example output:
```
5    Sat Jan 15 14:30:00 2026 | action: restart/enable | scheduled: 2026-01-15 14:30:00 UTC
```

### Removing Jobs

1. Select option 4
2. View the list of jobs
3. Enter the job ID to remove
4. Job is cancelled and removed from queue

## Use Cases

### Scheduled Upgrade

1. Check upgrade time announcement (usually in UTC)
2. Schedule a stop 5 minutes before upgrade
3. Perform manual upgrade after scheduled stop
4. Schedule restart after upgrade window

### Maintenance Window

1. Schedule stop at maintenance start time
2. Perform maintenance tasks
3. Schedule restart when ready

### Coordinated Network Upgrade

1. All validators agree on upgrade time
2. Each schedules restart at the same UTC time
3. Network resumes together

## Troubleshooting

### Jobs Not Executing
1. Return to scheduler menu and select option 1 to verify job exists
2. Ensure the scheduled time hasn't passed
3. Check that atd service is running on your system

### Wrong Execution Time
- Remember: input is UTC, execution is local time
- Check the confirmation message for the converted local time

### Cannot Remove Job
1. Use option 1 to view current jobs
2. Verify the job ID exists
3. Use option 4 with the correct job ID

## Related Documentation

- [Validator Node Guide](validator-node.md)
