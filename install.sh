#!/bin/bash

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
rest='\033[0m'

# Install required packages
install_packages() {
    local packages=(curl jq bc)
    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            if [ -n "$(command -v apt)" ]; then
                sudo apt update && sudo apt install -y "$pkg"
            elif [ -n "$(command -v yum)" ]; then
                sudo yum install -y "$pkg"
            else
                echo -e "${red}Please install $pkg manually.${rest}"
                exit 1
            fi
        fi
    done
}

install_packages

# Get authentication token
echo -e "${green}Please enter your Bearer token:${rest}"
read -r AUTH_TOKEN

# Function to get card list
get_card_list() {
    curl -s -H "Authorization: Bearer $AUTH_TOKEN" \
         "https://api.oppogame.ir/v2/telegram-bot/mine-cards"
}

# Function to select a card
select_card() {
    local card_id="$1"
    local response=$(curl -s -X POST -H "Authorization: Bearer $AUTH_TOKEN" \
         "https://api.oppogame.ir/v2/telegram-bot/mine-cards/$card_id")
    
    if [[ $response == *"error"* ]]; then
        echo "Error selecting card $card_id: $response"
        return 1
    else
        echo "Card $card_id successfully selected."
        return 0
    fi
}

# Main function
main() {
    while true; do
        echo -e "${blue}Fetching card list...${rest}"
        card_list=$(get_card_list)
        
        echo -e "${green}Sorting cards based on coin to profit ratio...${rest}"
        sorted_cards=$(echo "$card_list" | jq -r '.results | sort_by(.effect_function.params.coin_amount / .effect_function.params.dst_amount) | reverse | .[].id')
        
        for card_id in $sorted_cards; do
            echo -e "${yellow}Attempting to select card $card_id${rest}"
            if select_card "$card_id"; then
                echo -e "${green}Card $card_id successfully selected.${rest}"
                break
            else
                echo -e "${red}Error selecting card $card_id. Moving to next card...${rest}"
            fi
        done
        
        echo -e "${purple}Waiting for 5 seconds before repeating...${rest}"
        sleep 5
    done
}

# Execute main function
main
