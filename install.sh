#!/bin/bash

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
purple='\033[0;35m'
cyan='\033[0;36m'
blue='\033[0;34m'
rest='\033[0m'

# Function to install necessary packages
install_packages() {
    local packages=(curl jq bc)
    local missing_packages=()

    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            missing_packages+=("$pkg")
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        if [ -n "$(command -v pkg)" ]; then
            pkg install "${missing_packages[@]}" -y
        elif [ -n "$(command -v apt)" ]; then
            sudo apt update -y
            sudo apt install "${missing_packages[@]}" -y
        elif [ -n "$(command -v yum)" ]; then
            sudo yum update -y
            sudo yum install "${missing_packages[@]}" -y
        elif [ -n "$(command -v dnf)" ]; then
            sudo dnf update -y
            sudo dnf install "${missing_packages[@]}" -y
        else
            echo -e "${yellow}Unsupported package manager. Please install required packages manually.${rest}"
            exit 1
        fi
    fi
}

# Install the necessary packages
install_packages

# Clear the screen
clear

# Prompt for Authorization
echo -e "${purple}============================${rest}"
echo -en "${green}Enter Authorization [${cyan}Example: ${yellow}Bearer 171852....${green}]: ${rest}"
read -r Authorization
echo -e "${purple}============================${rest}"

# Function to get the list of cards
get_card_list() {
    curl -s -X GET \
      -H "Authorization: $Authorization" \
      -H "Origin: https://oppogame.ir" \
      -H "Referer: https://oppogame.ir/" \
      https://api.oppogame.ir/v2/telegram-bot/mine-cards
}

# Function to select a card
select_card() {
    card_id="$1"
    curl -s -X POST \
      -H "Authorization: $Authorization" \
      -H "Origin: https://oppogame.ir" \
      -H "Referer: https://oppogame.ir/" \
      "https://api.oppogame.ir/v2/telegram-bot/mine-cards/$card_id"
}

# Function to get the best card
get_best_card() {
    echo "$1" | jq -r '.results[] | select(.status == "STARTED") | .id as $id | .effect_function.params | {id: $id, ratio: (.dst_amount / .coin_amount)}' | jq -s 'sort_by(-.ratio)[0]'
}

# Main script logic
main() {
    while true; do
        # Get the list of cards
        card_list=$(get_card_list)

        # Get the best card
        best_card=$(get_best_card "$card_list")

        if [ -z "$best_card" ]; then
            echo -e "${yellow}No suitable card found. Waiting for 60 seconds before trying again...${rest}"
            sleep 60
            continue
        fi

        card_id=$(echo "$best_card" | jq -r '.id')
        ratio=$(echo "$best_card" | jq -r '.ratio')

        echo -e "${purple}============================${rest}"
        echo -e "${green}Best card to select:${yellow} $card_id${rest}"
        echo -e "${blue}Profit/Cost Ratio: ${cyan}$ratio${rest}"
        echo ""

        echo -e "${green}Attempting to select card '${yellow}$card_id${green}'...${rest}"
        selection_result=$(select_card "$card_id")

        if echo "$selection_result" | jq -e '.id' > /dev/null; then
            echo -e "${green}Card ${yellow}'$card_id'${green} selected successfully.${rest}"
        else
            echo -e "${red}Failed to select card ${yellow}'$card_id'${red}. Error: ${cyan}$(echo "$selection_result" | jq -r '.detail')${rest}"
        fi

        echo -e "${green}Waiting for 10 seconds before next selection...${rest}"
        sleep 10
    done
}

# Execute the main function
main
