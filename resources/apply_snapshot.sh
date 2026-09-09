#!/bin/bash
set -eo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load service name configuration
source $HOME/.bash_profile 2>/dev/null
STORY_SERVICE_NAME=${STORY_SERVICE_NAME:-story}
STORY_GETH_SERVICE_NAME=${STORY_GETH_SERVICE_NAME:-story-geth}
is_valid_service_name() { [[ "$1" =~ ^[A-Za-z0-9_.@-]+$ ]]; }
is_valid_service_name "$STORY_SERVICE_NAME" && is_valid_service_name "$STORY_GETH_SERVICE_NAME" || {
    echo -e "${RED}Invalid Story service name configuration. Refusing snapshot application.${NC}" >&2
    exit 1
}

# Snapshot URLs

# Grand Valley Snapshot URLs (dynamic, use API for filenames)
GRANDVALLEY_PRUNED_API_URL="https://pruned-snapshot-testnet-story.grandvalleys.com/pruned_snapshot_state.json"
GRANDVALLEY_PRUNED_BASE_URL="https://pruned-snapshot-testnet-story.grandvalleys.com"
# Archive snapshot URLs (not available yet, but reserved for future)
GRANDVALLEY_ARCHIVE_API_URL="https://pruned-snapshot-testnet-story.grandvalleys.com/archive_snapshot_state.json"
GRANDVALLEY_ARCHIVE_BASE_URL="https://pruned-snapshot-testnet-story.grandvalleys.com"

# MAND_PRUNED_GETH_SNAPSHOT_URL="https://snapshots2.mandragora.io/story/geth_snapshot.lz4"
# MAND_PRUNED_STORY_SNAPSHOT_URL="https://snapshots2.mandragora.io/story/story_snapshot.lz4"
# MAND_ARCHIVE_GETH_SNAPSHOT_URL="https://snapshots.mandragora.io/geth_snapshot.lz4"
# MAND_ARCHIVE_STORY_SNAPSHOT_URL="https://snapshots.mandragora.io/story_snapshot.lz4"

#MAND_PRUNED_API_URL="https://snapshots2.mandragora.io/story/info.json"
#MAND_ARCHIVE_API_URL="https://snapshots.mandragora.io/info.json"

#ITR_PRUNED_API_URL_1="https://server-1.itrocket.net/testnet/story/.current_state.json"
#ITR_ARCHIVE_API_URL_1="https://server-5.itrocket.net/testnet/story/.current_state.json"
#ITR_PRUNED_API_URL_2="https://server-3.itrocket.net/testnet/story/.current_state.json"
#ITR_ARCHIVE_API_URL_2="https://server-8.itrocket.net/testnet/story/.current_state.json"

#CROUTON_SNAPSHOT_URL="https://storage.crouton.digital/testnet/story/snapshots/story_latest.tar.lz4"
#CROUTON_API_URL="https://storage.crouton.digital/testnet/story/snapshots/block_status.json"

#JOSEPHTRAN_PRUNED_GETH_SNAPSHOT_URL="https://story.josephtran.co/Geth_snapshot.lz4"
#JOSEPHTRAN_PRUNED_STORY_SNAPSHOT_URL="https://story.josephtran.co/Story_snapshot.lz4"
#JOSEPHTRAN_ARCHIVE_GETH_SNAPSHOT_URL="https://story.josephtran.co/archive_Geth_snapshot.lz4"
#JOSEPHTRAN_ARCHIVE_STORY_SNAPSHOT_URL="https://story.josephtran.co/archive_Story_snapshot.lz4"

#JOSEPHTRAN_PRUNED_API_URL="https://story.josephtran.co/prune_snapshot_info.json"
#JOSEPHTRAN_ARCHIVE_API_URL="https://story.josephtran.co/archive_snapshot_info.json"

#ORIGINSTAKE_PRUNED_API_URL="https://snapshot.originstake.com/story_snapshot_metadata.json"
#ORIGINSTAKE_ARCHIVE_API_URL="https://snapshot.originstake.com/full/story_full_snapshot_metadata.json"

# DTEAM Story Testnet Snapshots
DTEAM_PRUNED_GETH_SNAPSHOT_URL="https://download.dteam.tech/story/testnet/pruned/latest-geth-snapshot"
DTEAM_PRUNED_STORY_SNAPSHOT_URL="https://download.dteam.tech/story/testnet/pruned/latest-snapshot"
DTEAM_PRUNED_API_URL="https://data.dteam.tech/story/testnet/snapshot"

# Function to display the menu
show_menu() {
    echo -e "${GREEN}Choose a snapshot provider:${NC}"
    # echo "1. Mandragora"
    # echo "2. ITRocket"
    # echo "3. CroutonDigital"
    # echo "4. Josephtran (J•Node)"
    # echo "5. OriginStake"
    echo "1. Grand Valley"
    echo "2. DTEAM"
    echo "3. Exit"
}

# Function to check if a URL is available
check_url() {
    local url=$1
    if curl -fsSIL --retry 2 --connect-timeout 10 --max-time 30 "$url" >/dev/null; then
        echo -e "${GREEN}Available${NC}"
    else
        echo -e "${RED}Not available at the moment${NC}"
        return 1
    fi
}

validate_snapshot_archive() {
    local archive="$1" listing="$2"
    [ -s "$archive" ] || { echo -e "${RED}Snapshot archive is empty.${NC}" >&2; return 1; }
    lz4 -t "$archive" >/dev/null
    lz4 -dc "$archive" | tar -tf - > "$listing"
    grep -qE '(^|/)\.\.(\/|$)|^/' "$listing" && {
        echo -e "${RED}Snapshot archive contains an unsafe path.${NC}" >&2
        return 1
    }
    awk '$1 !~ /^[-d]/ { exit 1 }' <(lz4 -dc "$archive" | tar -tvf -) || {
        echo -e "${RED}Snapshot archive contains a link or special file.${NC}" >&2
        return 1
    }
}

prepare_snapshot_files() {
    local stage="$1" listing="$stage/listing"
    mkdir -p "$stage/story" "$stage/geth"
    case "$provider_choice" in
        1|2)
            [ -n "${STORY_SNAPSHOT_URL:-}" ] && [ -n "${GETH_SNAPSHOT_URL:-}" ] || {
                echo -e "${RED}Snapshot provider did not resolve both consensus and execution archives.${NC}" >&2
                return 1
            }
            curl -fsSL --retry 3 --connect-timeout 10 --max-time 3600 "$STORY_SNAPSHOT_URL" -o "$download_location/$STORY_SNAPSHOT_FILE"
            curl -fsSL --retry 3 --connect-timeout 10 --max-time 3600 "$GETH_SNAPSHOT_URL" -o "$download_location/$GETH_SNAPSHOT_FILE"
            if [ -n "${GV_SHA256_STORY:-}" ]; then
                [[ "$GV_SHA256_STORY" =~ ^[0-9a-fA-F]{64}$ ]] || { echo -e "${RED}Provider returned an invalid Story checksum.${NC}" >&2; return 1; }
                printf '%s  %s\n' "$GV_SHA256_STORY" "$download_location/$STORY_SNAPSHOT_FILE" | sha256sum --check --status
            fi
            if [ -n "${GV_SHA256_GETH:-}" ]; then
                [[ "$GV_SHA256_GETH" =~ ^[0-9a-fA-F]{64}$ ]] || { echo -e "${RED}Provider returned an invalid Story-Geth checksum.${NC}" >&2; return 1; }
                printf '%s  %s\n' "$GV_SHA256_GETH" "$download_location/$GETH_SNAPSHOT_FILE" | sha256sum --check --status
            fi
            validate_snapshot_archive "$download_location/$STORY_SNAPSHOT_FILE" "$listing.story"
            validate_snapshot_archive "$download_location/$GETH_SNAPSHOT_FILE" "$listing.geth"
            lz4 -dc "$download_location/$STORY_SNAPSHOT_FILE" | tar -xf - -C "$stage/story"
            lz4 -dc "$download_location/$GETH_SNAPSHOT_FILE" | tar -xf - -C "$stage/geth"
            [ -d "$stage/story/data" ] || { echo -e "${RED}Consensus archive did not contain data/.${NC}" >&2; return 1; }
            [ -d "$stage/geth/chaindata" ] || { echo -e "${RED}Execution archive did not contain chaindata/.${NC}" >&2; return 1; }
            ;;
        *)
            echo -e "${RED}Unsupported snapshot provider.${NC}" >&2
            return 1
            ;;
    esac
}

# Function to display snapshot details

display_snapshot_details() {
    local api_url=$1
    local snapshot_info=$(curl -s $api_url)
    local snapshot_height

    if [[ $api_url == *"grandvalley"* || $api_url == *"grandvalleys.com"* ]]; then
        snapshot_height=$(echo "$snapshot_info" | jq -r '.snapshot_height')
        sha256_story=$(echo "$snapshot_info" | jq -r '.sha256_story')
        sha256_geth=$(echo "$snapshot_info" | jq -r '.sha256_geth')
        echo -e "${YELLOW}SHA256 (story):${NC} $sha256_story"
        echo -e "${YELLOW}SHA256 (story-geth):${NC} $sha256_geth"
        echo -e "${GREEN}Snapshot Height:${NC} $snapshot_height"
    elif [[ $api_url == *"dteam"* ]]; then
        # DTEAM: ambil latest.height dari API
        snapshot_height=$(echo "$snapshot_info" | jq -r '.latest.height')
    # elif [[ $api_url == *"mandragora"* ]]; then
    #     snapshot_height=$(echo "$snapshot_info" | grep -oP '"snapshot_height":\s*"\K\d+')
    # elif [[ $api_url == *"originstake"* ]]; then
    #     snapshot_height=$(echo "$snapshot_info" | jq -r '.height')
    # elif [[ $api_url == *"josephtran"* ]]; then
    #     snapshot_height=$(echo "$snapshot_info" | grep -oP '"block_height":\s*\K\d+')
    # elif [[ $api_url == *"crouton"* ]]; then
    #     snapshot_height=$(echo "$snapshot_info" | grep -oP '"latest_block_height":\s*"\K\d+')
    # else
    #     snapshot_height=$(echo "$snapshot_info" | jq -r '.snapshot_height')
    fi

    echo -e "${GREEN}Snapshot Height:${NC} $snapshot_height"

    # Get the real-time block height
    realtime_block_height=$(curl -s -X POST "https://aeneid.storyrpc.io" -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result' | xargs printf "%d\n")

    # Calculate the difference
    block_difference=$((realtime_block_height - snapshot_height))

    echo -e "${GREEN}Real-time Block Height:${NC} $realtime_block_height"
    echo -e "${GREEN}Block Difference:${NC} $block_difference"
}

# Function to choose snapshot for DTEAM
choose_DTEAM_snapshot() {
    GETH_SNAPSHOT_FILE="dteam_geth_snapshot.lz4"
    STORY_SNAPSHOT_FILE="dteam_consensus_snapshot.lz4"
    GETH_SNAPSHOT_URL=$DTEAM_PRUNED_GETH_SNAPSHOT_URL
    STORY_SNAPSHOT_URL=$DTEAM_PRUNED_STORY_SNAPSHOT_URL

    # Tampilkan detail snapshot DTEAM
    display_snapshot_details $DTEAM_PRUNED_API_URL

    prompt_back_or_continue
}

# Function to choose snapshot type for Grand Valley
choose_grandvalley_snapshot() {
    echo -e "${GREEN}Choose the type of snapshot for Grand Valley:${NC}"
    echo "1. Pruned"
    echo "2. Archive"
    read -p "Enter your choice: " snapshot_type_choice

    case "$snapshot_type_choice" in
        1)
            # Set variables for downstream steps (download/use)
            local snapshot_info story_file geth_file
            if ! snapshot_info="$(curl -fsS "$GRANDVALLEY_PRUNED_API_URL")"; then
                echo -e "${RED}Failed to fetch snapshot info.${NC}"
                return 1
            fi

            story_file=$(jq -r '.story_snapshot_file_name // empty' <<<"$snapshot_info")
            geth_file=$(jq -r '.story_geth_snapshot_file_name // empty' <<<"$snapshot_info")
            GETH_SNAPSHOT_URL="${GRANDVALLEY_PRUNED_BASE_URL}/${geth_file}"
            STORY_SNAPSHOT_URL="${GRANDVALLEY_PRUNED_BASE_URL}/${story_file}"
            echo -e "${GREEN}Checking availability and details of Pruned snapshot:${NC}"
            echo -n "GETH Snapshot: "
            check_url $GETH_SNAPSHOT_URL
            echo -n "STORY Snapshot: "
            check_url $STORY_SNAPSHOT_URL

            prompt_back_or_continue

            # All detail printing lives in this function now:
            display_snapshot_details "$GRANDVALLEY_PRUNED_API_URL" || return 1

            SNAPSHOT_API_URL="$GRANDVALLEY_PRUNED_API_URL"
            STORY_SNAPSHOT_FILE="$story_file"
            GETH_SNAPSHOT_FILE="$geth_file"

            export GV_SHA256_STORY
            export GV_SHA256_GETH
            GV_SHA256_STORY=$(jq -r '.sha256_story // empty' <<<"$snapshot_info")
            GV_SHA256_GETH=$(jq -r '.sha256_geth // empty' <<<"$snapshot_info")
            ;;
        2)
            echo -e "${YELLOW}Archive snapshot is not available yet. Option reserved for future use.${NC}"
            prompt_back_or_continue
            return
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac

    prompt_back_or_continue
}

# Function to choose snapshot type for Mandragora
choose_mandragora_snapshot() {
    echo -e "${GREEN}Choose the type of snapshot for Mandragora:${NC}"
    echo "1. Pruned"
    echo "2. Archive"
    read -p "Enter your choice: " snapshot_type_choice

    case $snapshot_type_choice in
        1)
            SNAPSHOT_API_URL=$MAND_PRUNED_API_URL
            GETH_SNAPSHOT_URL=$MAND_PRUNED_GETH_SNAPSHOT_URL
            STORY_SNAPSHOT_URL=$MAND_PRUNED_STORY_SNAPSHOT_URL
            ;;
        2)
            SNAPSHOT_API_URL=$MAND_ARCHIVE_API_URL
            GETH_SNAPSHOT_URL=$MAND_ARCHIVE_GETH_SNAPSHOT_URL
            STORY_SNAPSHOT_URL=$MAND_ARCHIVE_STORY_SNAPSHOT_URL
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac

    display_snapshot_details $SNAPSHOT_API_URL

    prompt_back_or_continue
}

# Function to choose snapshot type for ITRocket
choose_itrocket_snapshot() {
    echo -e "${GREEN}Choose the type of snapshot for ITRocket:${NC}"
    echo "1. Pruned"
    echo "2. Archive"
    read -p "Enter your choice: " snapshot_type_choice

    case $snapshot_type_choice in
        1)
            echo -e "${GREEN}Checking availability and details of Pruned snapshots:${NC}"
            echo -n "Pruned Snapshot (Server 1): "
            check_url $ITR_PRUNED_API_URL_1
            if [[ $? -eq 0 ]]; then
                display_snapshot_details $ITR_PRUNED_API_URL_1
            fi
            echo -n "Pruned Snapshot (Server 3): "
            check_url $ITR_PRUNED_API_URL_2
            if [[ $? -eq 0 ]]; then
                display_snapshot_details $ITR_PRUNED_API_URL_2
            fi

            echo -e "${GREEN}Choose the server for Pruned snapshot:${NC}"
            echo "1. Server 1"
            echo "2. Server 3"
            read -p "Enter your choice: " server_choice

            case $server_choice in
                1)
                    SNAPSHOT_API_URL=$ITR_PRUNED_API_URL_1
                    SERVER_BASE_URL="https://server-1.itrocket.net/testnet/story/"
                    ;;
                2)
                    SNAPSHOT_API_URL=$ITR_PRUNED_API_URL_2
                    SERVER_BASE_URL="https://server-3.itrocket.net/testnet/story/"
                    ;;
                *)
                    echo -e "${RED}Invalid choice. Exiting.${NC}"
                    exit 1
                    ;;
            esac
            ;;
        2)
            echo -e "${GREEN}Checking availability and details of Archive snapshots:${NC}"
            echo -n "Archive Snapshot (Server 5): "
            check_url $ITR_ARCHIVE_API_URL_1
            if [[ $? -eq 0 ]]; then
                display_snapshot_details $ITR_ARCHIVE_API_URL_1
            fi
            echo -n "Archive Snapshot (Server 8): "
            check_url $ITR_ARCHIVE_API_URL_2
            if [[ $? -eq 0 ]]; then
                display_snapshot_details $ITR_ARCHIVE_API_URL_2
            fi

            echo -e "${GREEN}Choose the server for Archive snapshot:${NC}"
            echo "1. Server 5"
            echo "2. Server 8"
            read -p "Enter your choice: " server_choice

            case $server_choice in
                1)
                    SNAPSHOT_API_URL=$ITR_ARCHIVE_API_URL_1
                    SERVER_BASE_URL="https://server-5.itrocket.net/testnet/story/"
                    ;;
                2)
                    SNAPSHOT_API_URL=$ITR_ARCHIVE_API_URL_2
                    SERVER_BASE_URL="https://server-8.itrocket.net/testnet/story/"
                    ;;
                *)
                    echo -e "${RED}Invalid choice. Exiting.${NC}"
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac

    prompt_back_or_continue

    FILE_NAME=$(curl -s $SNAPSHOT_API_URL | jq -r '.snapshot_name')
    GETH_FILE_NAME=$(curl -s $SNAPSHOT_API_URL | jq -r '.snapshot_geth_name')
    GETH_SNAPSHOT_URL="$SERVER_BASE_URL$GETH_FILE_NAME"
    STORY_SNAPSHOT_URL="$SERVER_BASE_URL$FILE_NAME"
}

# Function to choose snapshot type for Josephtran
choose_josephtran_snapshot() {
    echo -e "${GREEN}Choose the type of snapshot for Josephtran:${NC}"
    echo "1. Pruned"
    echo "2. Archive"
    read -p "Enter your choice: " snapshot_type_choice

    case $snapshot_type_choice in
        1)
            SNAPSHOT_API_URL=$JOSEPHTRAN_PRUNED_API_URL
            GETH_SNAPSHOT_URL=$JOSEPHTRAN_PRUNED_GETH_SNAPSHOT_URL
            STORY_SNAPSHOT_URL=$JOSEPHTRAN_PRUNED_STORY_SNAPSHOT_URL
            ;;
        2)
            SNAPSHOT_API_URL=$JOSEPHTRAN_ARCHIVE_API_URL
            GETH_SNAPSHOT_URL=$JOSEPHTRAN_ARCHIVE_GETH_SNAPSHOT_URL
            STORY_SNAPSHOT_URL=$JOSEPHTRAN_ARCHIVE_STORY_SNAPSHOT_URL
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac

    display_snapshot_details $SNAPSHOT_API_URL

    prompt_back_or_continue
}

# Function to choose snapshot type for OriginStake
choose_originstake_snapshot() {
    echo -e "${GREEN}Choose the type of snapshot for OriginStake:${NC}"
    echo "1. Pruned"
    echo "2. Archive"
    read -p "Enter your choice: " snapshot_type_choice

    case $snapshot_type_choice in
        1)
            SNAPSHOT_API_URL=$ORIGINSTAKE_PRUNED_API_URL
            ;;
        2)
            SNAPSHOT_API_URL=$ORIGINSTAKE_ARCHIVE_API_URL
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac

    display_snapshot_details $SNAPSHOT_API_URL

    prompt_back_or_continue

    FILE_NAME=$(curl -s $SNAPSHOT_API_URL | jq -r '.name')
    SNAPSHOT_URL="https://snapshot.originstake.com/$FILE_NAME"
}

# Function to decompress snapshots for Mandragora, ITRocket, and Josephtran
decompress_snapshots() {
    lz4 -c -d $GETH_SNAPSHOT_FILE | tar -xv -C $HOME/.story/geth/aeneid/geth
    lz4 -c -d $STORY_SNAPSHOT_FILE | tar -xv -C $HOME/.story/story
}

# Function to decompress snapshot for CroutonDigital and OriginStake
decompress_crouton_originstake_snapshot() {
    lz4 -c -d $SNAPSHOT_FILE | tar -xv -C $HOME/.story
}

# Function to prompt user to back or continue
prompt_back_or_continue() {
    read -p "Press Enter to continue or type 'back' to go back to the menu: " user_choice
    if [[ $user_choice == "back" ]]; then
        main_script
    fi
}

# Function to check if cosmovisor is installed
check_cosmovisor() {
    if command -v cosmovisor &> /dev/null; then
        echo -e "${GREEN}Cosmovisor is installed.${NC}"
        return 0
    else
        echo -e "${RED}Cosmovisor is not installed.${NC}"
        return 1
    fi
}

# Snapshot height does not safely select a consensus binary version.
# Never send an operator to an obsolete update option based on archive height.
suggest_update() {
    local snapshot_height=$1
    local current_version
    current_version=$(cosmovisor version 2>&1 | awk '/^Version/ {print $2}' || true)
    current_version=${current_version:-unknown}
    echo -e "${YELLOW}Current consensus client version: $current_version${NC}"
    echo -e "${YELLOW}Snapshot height: $snapshot_height${NC}"
    echo -e "${YELLOW}No automatic consensus-version mapping is performed. Review the current Story release separately before any upgrade.${NC}"
    update_choice="n"
}

# Main script
main_script() {
    show_menu
    read -p "Enter your choice: " provider_choice

    provider_name=""

    case $provider_choice in
        1)
            provider_name="Grand Valley"
            echo -e "${GREEN}Grand Valley snapshot selected.${NC}"
            echo -e "HEYLO MY STORYFAM... LETS SYNC FASTOOOOOOR!."

            if ! choose_grandvalley_snapshot; then
                echo -e "${RED}Grand Valley snapshot selection failed. Nothing was changed.${NC}" >&2
                exit 1
            fi

            # Suggest update based on snapshot block height
            snapshot_height=$(curl -fsS "$SNAPSHOT_API_URL" | jq -r '.snapshot_height // empty')
            [ -n "$snapshot_height" ] || { echo -e "${RED}Snapshot metadata did not contain a height.${NC}" >&2; exit 1; }
            suggest_update "$snapshot_height"

            # Ask the user if they want to delete the downloaded snapshot files
            read -p "When the snapshot has been applied (decompressed), do you want to delete the uncompressed files? (y/n): " delete_choice
            ;;
        2)
            provider_name="DTEAM"
            echo -e "${GREEN}DTEAM snapshot selected.${NC}"
            echo -e "Grand Valley extends its gratitude to ${YELLOW}$provider_name${NC} for providing snapshot support."
            echo -n "Checking DTEAM Geth snapshot: "
            check_url $DTEAM_PRUNED_GETH_SNAPSHOT_URL
            echo -n "Checking DTEAM Consensus snapshot: "
            check_url $DTEAM_PRUNED_STORY_SNAPSHOT_URL

            prompt_back_or_continue

            # Pilih snapshot DTEAM (set variabel, tampilkan detail, prompt back/continue)
            if ! choose_DTEAM_snapshot; then
                echo -e "${RED}DTEAM snapshot selection failed. Nothing was changed.${NC}" >&2
                exit 1
            fi

            # Suggest update based on snapshot block height
            snapshot_height=$(curl -fsS "$DTEAM_PRUNED_API_URL" | jq -r '.latest.height // empty')
            [ -n "$snapshot_height" ] || { echo -e "${RED}Snapshot metadata did not contain a height.${NC}" >&2; exit 1; }
            suggest_update "$snapshot_height"

            read -p "When the snapshot has been applied (decompressed), do you want to delete the uncompressed files? (y/n): " delete_choice
            ;;
        3)
            echo -e "${GREEN}Exiting.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac
        # 1)
        #     provider_name="Mandragora"
        #     echo -e "Grand Valley extends its gratitude to ${YELLOW}$provider_name${NC} for providing snapshot support."
        #     echo -e "${GREEN}Checking availability of Mandragora snapshots:${NC}"
        #     echo -n "Pruned GETH Snapshot: "
        #     check_url $MAND_PRUNED_GETH_SNAPSHOT_URL
        #     echo -n "Pruned STORY Snapshot: "
        #     check_url $MAND_PRUNED_STORY_SNAPSHOT_URL
        #     echo -n "Archive GETH Snapshot: "
        #     check_url $MAND_ARCHIVE_GETH_SNAPSHOT_URL
        #     echo -n "Archive STORY Snapshot: "
        #     check_url $MAND_ARCHIVE_STORY_SNAPSHOT_URL
        #     prompt_back_or_continue
        #     choose_mandragora_snapshot
        #     GETH_SNAPSHOT_FILE="geth_snapshot.lz4"
        #     STORY_SNAPSHOT_FILE="story_snapshot.lz4"
        #     # Suggest update based on snapshot block height
        #     snapshot_height=$(curl -s $SNAPSHOT_API_URL | grep -oP '"snapshot_height":\s*\K\d+')
        #     suggest_update $snapshot_height
        #     # Ask the user if they want to delete the downloaded snapshot files
        #     read -p "When the snapshot has been applied (decompressed), do you want to delete the uncompressed files? (y/n): " delete_choice
        #     ;;
        # 2)
        #     provider_name="ITRocket"
        #     echo -e "${GREEN}ITRocket snapshot selected.${NC}"
        #     echo -e "Grand Valley extends its gratitude to ${YELLOW}$provider_name${NC} for providing snapshot support."
        #     echo -e "${GREEN}Checking availability of ITRocket snapshots:${NC}"
        #     echo -n "Pruned Snapshot (Server 1): "
        #     check_url $ITR_PRUNED_API_URL_1
        #     echo -n "Pruned Snapshot (Server 3): "
        #     check_url $ITR_PRUNED_API_URL_2
        #     echo -n "Archive Snapshot (Server 5): "
        #     check_url $ITR_ARCHIVE_API_URL_1
        #     echo -n "Archive Snapshot (Server 8): "
        #     check_url $ITR_ARCHIVE_API_URL_2
        #     prompt_back_or_continue
        #     choose_itrocket_snapshot
        #     GETH_SNAPSHOT_FILE=$GETH_FILE_NAME
        #     STORY_SNAPSHOT_FILE=$FILE_NAME
        #     # Suggest update based on snapshot block height
        #     snapshot_height=$(curl -s $SNAPSHOT_API_URL | jq -r '.snapshot_height')
        #     suggest_update $snapshot_height
        #     # Ask the user if they want to delete the downloaded snapshot files
        #     read -p "When the snapshot has been applied (decompressed), do you want to delete the uncompressed files? (y/n): " delete_choice
        #     ;;
        # 3)
        #     provider_name="CroutonDigital"
        #     echo -e "${GREEN}CroutonDigital snapshot selected.${NC}"
        #     echo -e "Grand Valley extends its gratitude to ${YELLOW}$provider_name${NC} for providing snapshot support."
        #     echo -e "${GREEN}Checking availability of CroutonDigital snapshot:${NC}"
        #     echo -n "Archive Snapshot: "
        #     check_url $CROUTON_SNAPSHOT_URL
        #     prompt_back_or_continue
        #     SNAPSHOT_FILE="story_latest.tar.lz4"
        #     SNAPSHOT_URL=$CROUTON_SNAPSHOT_URL
        #     # Display snapshot details
        #     display_snapshot_details $CROUTON_API_URL
        #     # Suggest update based on snapshot block height
        #     snapshot_height=$(curl -s $CROUTON_API_URL | grep -oP '"latest_block_height":\s*"\K\d+')
        #     suggest_update $snapshot_height
        #     # Ask the user if they want to delete the downloaded snapshot files
        #     read -p "When the snapshot has been applied (decompressed), do you want to delete the uncompressed files? (y/n): " delete_choice
        #     ;;
        # 4)
        #    provider_name="Josephtran"
        #    echo -e "${GREEN}Josephtran snapshot selected.${NC}"
        #    echo -e "Grand Valley extends its gratitude to ${YELLOW}$provider_name${NC} for providing snapshot support."
        #
        #    echo -e "${GREEN}Checking availability of Josephtran snapshots:${NC}"
        #    echo -n "Pruned GETH Snapshot: "
        #    check_url $JOSEPHTRAN_PRUNED_GETH_SNAPSHOT_URL
        #    echo -n "Pruned STORY Snapshot: "
        #    check_url $JOSEPHTRAN_PRUNED_STORY_SNAPSHOT_URL
        #    echo -n "Archive GETH Snapshot: "
        #    check_url $JOSEPHTRAN_ARCHIVE_GETH_SNAPSHOT_URL
        #    echo -n "Archive STORY Snapshot: "
        #    check_url $JOSEPHTRAN_ARCHIVE_STORY_SNAPSHOT_URL

        #    prompt_back_or_continue

        #    choose_josephtran_snapshot
        #    GETH_SNAPSHOT_FILE="Geth_snapshot.lz4"
        #    STORY_SNAPSHOT_FILE="Story_snapshot.lz4"

            # Suggest update based on snapshot block height
        #    snapshot_height=$(curl -s $SNAPSHOT_API_URL | grep -oP '"block_height":\s*\K\d+')
        #    suggest_update $snapshot_height

            # Ask the user if they want to delete the downloaded snapshot files
        #    read -p "When the snapshot has been applied (decompressed), do you want to delete the uncompressed files? (y/n): " delete_choice
        #    ;;
        # 5)
        #    provider_name="OriginStake"
        #    echo -e "${GREEN}OriginStake snapshot selected.${NC}"
        #    echo -e "Grand Valley extends its gratitude to ${YELLOW}$provider_name${NC} for providing snapshot support."

        #    echo -e "${GREEN}Checking availability of OriginStake snapshots:${NC}"
        #    echo -n "Pruned Snapshot: "
        #    check_url $ORIGINSTAKE_PRUNED_API_URL
        #    echo -n "Archive Snapshot: "
        #    check_url $ORIGINSTAKE_ARCHIVE_API_URL

        #    prompt_back_or_continue

        #    choose_originstake_snapshot
        #    SNAPSHOT_FILE=$FILE_NAME
        #    SNAPSHOT_URL=$SNAPSHOT_URL

            # Suggest update based on snapshot block height
        #    snapshot_height=$(curl -s $SNAPSHOT_API_URL | jq -r '.height')
        #    suggest_update $snapshot_height

            # Ask the user if they want to delete the downloaded snapshot files
        #    read -p "When the snapshot has been applied (decompressed), do you want to delete the uncompressed files? (y/n): " delete_choice
        #    ;;

    # Download and fully stage the snapshot before touching live chain data.
    read -r -p "Enter the directory where you want to download the snapshots (default is $HOME): " download_location
    download_location=${download_location:-$HOME}
    mkdir -p "$download_location"
    cd "$download_location"
    sudo apt-get install wget lz4 jq -y
    snapshot_stage=$(mktemp -d)
    trap 'rm -rf "$snapshot_stage"' EXIT
    prepare_snapshot_files "$snapshot_stage"

    echo -e "${GREEN}Snapshot archives downloaded, decompressed, and structurally validated.${NC}"
    read -r -p "Type APPLY-STORY-SNAPSHOT to stop services and replace chain data: " confirm
    if [ "$confirm" != "APPLY-STORY-SNAPSHOT" ]; then
        echo -e "${YELLOW}Snapshot cancelled before downtime.${NC}"
        exit 0
    fi
    read -r -p "When the snapshot has been applied, delete the downloaded archives? (y/n): " delete_choice

    story_was_active=no
    geth_was_active=no
    story_was_enabled=no
    geth_was_enabled=no
    sudo systemctl is-active --quiet "$STORY_SERVICE_NAME" && story_was_active=yes || true
    sudo systemctl is-active --quiet "$STORY_GETH_SERVICE_NAME" && geth_was_active=yes || true
    sudo systemctl is-enabled --quiet "$STORY_SERVICE_NAME" && story_was_enabled=yes || true
    sudo systemctl is-enabled --quiet "$STORY_GETH_SERVICE_NAME" && geth_was_enabled=yes || true
    if ! sudo systemctl stop "$STORY_GETH_SERVICE_NAME" "$STORY_SERVICE_NAME"; then
        echo -e "${RED}Could not stop both Story services; refusing data replacement.${NC}" >&2
        [ "$story_was_active" = yes ] && sudo systemctl start "$STORY_SERVICE_NAME" || true
        [ "$geth_was_active" = yes ] && sudo systemctl start "$STORY_GETH_SERVICE_NAME" || true
        exit 1
    fi
    if sudo systemctl is-active --quiet "$STORY_GETH_SERVICE_NAME" || sudo systemctl is-active --quiet "$STORY_SERVICE_NAME"; then
        echo -e "${RED}Story services remain active after stop; refusing data replacement.${NC}" >&2
        [ "$story_was_active" = yes ] && sudo systemctl start "$STORY_SERVICE_NAME" || true
        [ "$geth_was_active" = yes ] && sudo systemctl start "$STORY_GETH_SERVICE_NAME" || true
        exit 1
    fi

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    backup_root="$HOME/.story/.valley-snapshot-backup-$timestamp"
    mkdir -p "$backup_root"
    cp -a "$HOME/.story/story/data" "$backup_root/story-data"
    cp "$HOME/.story/story/data/priv_validator_state.json" "$backup_root/priv_validator_state.json"
    if [ -d "$HOME/.story/geth/aeneid/geth/chaindata" ]; then
        cp -a "$HOME/.story/geth/aeneid/geth/chaindata" "$backup_root/geth-chaindata"
    fi

    sudo rm -rf "$HOME/.story/story/data" "$HOME/.story/geth/aeneid/geth/chaindata"
    mkdir -p "$HOME/.story/story" "$HOME/.story/geth/aeneid/geth"
    cp -a "$snapshot_stage/story/data" "$HOME/.story/story/data"
    cp -a "$snapshot_stage/geth/chaindata" "$HOME/.story/geth/aeneid/geth/chaindata"
    cp "$backup_root/priv_validator_state.json" "$HOME/.story/story/data/priv_validator_state.json"
    sudo chown -R "$USER:$USER" "$HOME/.story"

    if [[ "$delete_choice" == "y" || "$delete_choice" == "Y" ]]; then
        rm -f "$download_location/$GETH_SNAPSHOT_FILE" "$download_location/$STORY_SNAPSHOT_FILE"
        echo -e "${GREEN}Downloaded snapshot files have been deleted.${NC}"
    else
        echo -e "${GREEN}Downloaded snapshot files have been kept.${NC}"
    fi

    if [ "$story_was_enabled" = yes ]; then sudo systemctl enable "$STORY_SERVICE_NAME"; else sudo systemctl disable "$STORY_SERVICE_NAME" >/dev/null 2>&1 || true; fi
    if [ "$geth_was_enabled" = yes ]; then sudo systemctl enable "$STORY_GETH_SERVICE_NAME"; else sudo systemctl disable "$STORY_GETH_SERVICE_NAME" >/dev/null 2>&1 || true; fi
    if [ "$story_was_active" = yes ]; then sudo systemctl restart "$STORY_SERVICE_NAME"; fi
    if [ "$geth_was_active" = yes ]; then sudo systemctl restart "$STORY_GETH_SERVICE_NAME"; fi
    if [ "$story_was_active" != yes ] && [ "$geth_was_active" != yes ]; then
        echo -e "${YELLOW}Services were inactive before the snapshot and remain stopped.${NC}"
    fi

    echo -e "${GREEN}Snapshot setup completed successfully.${NC}"
    echo -e "${YELLOW}Pre-snapshot backup retained at: $backup_root${NC}"
}

main_script
