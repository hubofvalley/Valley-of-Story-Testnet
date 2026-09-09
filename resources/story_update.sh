#!/bin/bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Load service name configuration
source $HOME/.bash_profile 2>/dev/null
STORY_SERVICE_NAME=${STORY_SERVICE_NAME:-story}
STORY_GETH_SERVICE_NAME=${STORY_GETH_SERVICE_NAME:-story-geth}
is_valid_service_name() { [[ "$1" =~ ^[A-Za-z0-9_.@-]+$ ]]; }
is_valid_service_name "$STORY_SERVICE_NAME" && is_valid_service_name "$STORY_GETH_SERVICE_NAME" || {
    echo "Invalid Story service name configuration. Refusing update." >&2
    exit 1
}

# Function to install cosmovisor
install_cosmovisor() {
    echo "Installing cosmovisor..."
    if ! go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest; then
        echo "Failed to install cosmovisor. Exiting."
        exit 1
    fi
}

# Function to initialize cosmovisor
init_cosmovisor() {
    echo "Initializing cosmovisor..."

    # Download the current Aeneid consensus version.
    mkdir -p "$HOME/story-v1.7.0"
    if ! wget -P "$HOME/story-v1.7.0" https://github.com/piplabs/story/releases/download/v1.7.0/story-linux-amd64 -O "$HOME/story-v1.7.0/story"; then
        echo "Failed to download the genesis binary. Exiting."
        exit 1
    fi

    # Initialize cosmovisor
    if ! cosmovisor init "$HOME/story-v1.7.0/story"; then
        echo "Failed to initialize cosmovisor. Exiting."
        exit 1
    fi

    cd $HOME/go/bin/
    sudo rm -r story
    ln -s $HOME/.story/story/cosmovisor/current/bin/story story
    sudo chown -R $USER:$USER $HOME/go/bin/story
    sudo chmod +x $HOME/go/bin/story
    sudo rm -r $HOME/.story/story/data/upgrade-info.json
    mkdir -p $HOME/.story/story/cosmovisor/upgrades
    mkdir -p $HOME/.story/story/cosmovisor/backup
}

# Function to initialize cosmovisor
init_cosmovisor110() {
    sudo systemctl stop "$STORY_SERVICE_NAME" "$STORY_GETH_SERVICE_NAME"

    # Download genesis story version
    mkdir -p "$HOME/story-v1.7.0"
    wget -P "$HOME/story-v1.7.0" https://github.com/piplabs/story/releases/download/v1.7.0/story-linux-amd64 -O "$HOME/story-v1.7.0/story"

    # Initialize cosmovisor
    sudo rm -r $HOME/.story/story/cosmovisor
    cosmovisor init "$HOME/story-v1.7.0/story"
    cd $HOME/go/bin/
    sudo rm -r story
    ln -s $HOME/.story/story/cosmovisor/current/bin/story story
    sudo chown -R $USER:$USER $HOME/go/bin/story
    sudo chmod +x $HOME/go/bin/story
    sudo rm -r $HOME/.story/story/data/upgrade-info.json
    mkdir -p $HOME/.story/story/cosmovisor/upgrades
    mkdir -p $HOME/.story/story/cosmovisor/backup
    sudo systemctl restart "$STORY_SERVICE_NAME" "$STORY_GETH_SERVICE_NAME"
}

# Ask the user if cosmovisor is installed
read -p "Do you have cosmovisor installed? (y/n): " cosmovisor_installed

if [ "$cosmovisor_installed" == "y" ]; then
    echo "Cosmovisor is already installed. Skipping installation and initialization."
else
    install_cosmovisor
    init_cosmovisor
fi

# Define variables
input1=$(which cosmovisor)
input2=$(find "$HOME/.story/story" -type d -name "story" -print -quit)
input3=$(find "$HOME/.story/story/cosmovisor" -type d -name "backup" -print -quit)
story_file_name=story-linux-amd64

# Check if cosmovisor is installed
if [ -z "$input1" ]; then
    echo "cosmovisor is not installed. Please install it first."
    exit 1
fi

# Check if story directory exists
if [ -z "$input2" ]; then
    echo "Story directory not found. Please ensure it exists."
    exit 1
fi

# Check if backup directory exists
if [ -z "$input3" ]; then
    echo "Backup directory not found. Please ensure it exists."
    exit 1
fi

# Export environment variables
echo "export DAEMON_NAME=story" >> $HOME/.bash_profile
echo "export DAEMON_HOME=$input2" >> $HOME/.bash_profile
echo "export DAEMON_DATA_BACKUP_DIR=$input3" >> $HOME/.bash_profile
source $HOME/.bash_profile

# Create or update the systemd service file
sudo tee "/etc/systemd/system/${STORY_SERVICE_NAME}.service" > /dev/null <<EOF
[Unit]
Description=Cosmovisor Story Node
After=network.target

[Service]
User=${USER}
Type=simple
WorkingDirectory=${HOME}/.story/story
ExecStart=${input1} run run
StandardOutput=journal
StandardError=journal
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
LimitNPROC=65536
Environment="DAEMON_NAME=story"
Environment="DAEMON_HOME=${input2}"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_DATA_BACKUP_DIR=${input3}"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to apply changes
sudo systemctl daemon-reload

# Function to update to a specific version
update_version() {
    local version=$1
    local download_url=$2
    local upgrade_height=$3

    # Create directory and download the binary
    cd $HOME
    mkdir -p $HOME/story-$version
    if ! wget -P $HOME/story-$version $download_url/$story_file_name -O $HOME/story-$version/story; then
        echo "Failed to download the binary. Exiting."
        exit 1
    fi

    # Set ownership and permissions
    sudo chown -R $USER:$USER $HOME/.story && \
    sudo chown -R $USER:$USER $HOME/go/bin/story && \
    sudo chmod +x $HOME/story-$version/story && \
    sudo chmod +x $HOME/go/bin/story && \
    sudo rm -f $HOME/.story/story/data/upgrade-info.json && \
    sudo rm -rf "$HOME/.story/story/cosmovisor/upgrades/$version"

    # Copy the updated binary to the cosmovisor genesis directory
    GENESIS_DIR="$HOME/.story/story/cosmovisor/genesis/bin"
    cp "$HOME/story-$version/story" "$GENESIS_DIR/story"
    sudo chown -R $USER:$USER "$GENESIS_DIR/story"
    sudo chmod +x "$GENESIS_DIR/story"

    # Add the upgrade to cosmovisor
    if ! cosmovisor add-upgrade $version $HOME/story-$version/story --upgrade-height $upgrade_height --force; then
        echo "Failed to add upgrade to cosmovisor. Exiting."
        exit 1
    fi
}

# Function to update to a version where halt height is determined on-chain (no --upgrade-height flag)
update_version_no_height() {
    local version=$1
    local download_url=$2
    local upgrade_name=$3

    # Create directory and download the binary
    cd $HOME
    mkdir -p $HOME/story-$version
    if ! wget -P $HOME/story-$version $download_url/$story_file_name -O $HOME/story-$version/story; then
        echo "Failed to download the binary. Exiting."
        exit 1
    fi

    # Set ownership and permissions
    sudo chown -R $USER:$USER $HOME/.story && \
    sudo chown -R $USER:$USER $HOME/go/bin/story && \
    sudo chmod +x $HOME/story-$version/story && \
    sudo chmod +x $HOME/go/bin/story && \
    sudo rm -f $HOME/.story/story/data/upgrade-info.json && \
    sudo rm -rf "$HOME/.story/story/cosmovisor/upgrades/$upgrade_name"

    # Copy the updated binary to the cosmovisor genesis directory
    GENESIS_DIR="$HOME/.story/story/cosmovisor/genesis/bin"
    cp "$HOME/story-$version/story" "$GENESIS_DIR/story"
    sudo chown -R $USER:$USER "$GENESIS_DIR/story"
    sudo chmod +x "$GENESIS_DIR/story"

    # Add the upgrade to cosmovisor (no --upgrade-height, halt height is on-chain)
    if ! cosmovisor add-upgrade $upgrade_name $HOME/story-$version/story; then
        echo "Failed to add upgrade to cosmovisor. Exiting."
        exit 1
    fi
}

# Historical batch upgrades are intentionally disabled in the active Aeneid flow.
batch_update_version() {
    echo "Historical batch upgrades are disabled; no obsolete binary was staged." >&2
    return 1
}

# Menu for selecting the version
rpc_response=$(curl -fsS --connect-timeout 10 --max-time 30 -X POST "https://aeneid.storyrpc.io" -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}')
block_hex=$(jq -er '.result | select(type == "string" and test("^0x[0-9a-fA-F]+$"))' <<< "$rpc_response")
realtime_block_height=$((16#${block_hex#0x}))
(( realtime_block_height > 0 )) || { echo "RPC returned an invalid block height." >&2; exit 1; }
echo "Choose the supported Aeneid consensus version:"
echo -e "j. ${YELLOW}v1.7.0${RESET} (${GREEN}Seneca${RESET} Upgrade height: $(LC_NUMERIC='en_US.UTF-8' printf "%'d" $((realtime_block_height + 100))))"
echo "Historical versions are not offered by this active update flow."
read -r -p "Enter j to stage v1.7.0, or anything else to cancel: " choice

case $choice in
    j)
        update_version "v1.7.0" "https://github.com/piplabs/story/releases/download/v1.7.0" $((realtime_block_height + 100))
        ;;
    *)
        echo "Update cancelled. No obsolete version was staged."
        exit 1
        ;;
esac

echo "Let's Buidl Story Together"
