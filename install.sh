#!/bin/bash
# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
purple='\033[0;35m'
cyan='\033[0;36m'
blue='\033[0;34m'
rest='\033[0m'

# ... (بقیه توابع بدون تغییر می‌مانند) ...

# Function to get the best card
get_best_card() {
    echo "$1" | jq -r '
        .results[] 
        | select(.status == "STARTED" and .requirement.cards == []) 
        | .id as $id 
        | .effect_function.params 
        | select(.dst_amount != null and .coin_amount != null and .coin_amount != 0) 
        | {id: $id, ratio: (.dst_amount / .coin_amount)}
    ' | jq -s 'sort_by(-.ratio) | .[0]'
}

# Main script logic
main() {
    declare -A failed_cards
    while true; do
        # Get the list of cards
        card_list=$(get_card_list)
        
        # Get the best card
        best_card=$(get_best_card "$card_list")
        
        if [ -z "$best_card" ] || [ "$best_card" = "null" ]; then
            echo -e "${yellow}No suitable card found. Waiting for 60 seconds before trying again...${rest}"
            sleep 60
            continue
        fi

        card_id=$(echo "$best_card" | jq -r '.id')
        ratio=$(echo "$best_card" | jq -r '.ratio')

        # Skip this card if it has failed recently
        if [[ ${failed_cards[$card_id]} -ge 3 ]]; then
            echo -e "${yellow}Skipping card ${card_id} due to multiple recent failures.${rest}"
            continue
        fi

        echo -e "${purple}============================${rest}"
        echo -e "${green}Best card to select:${yellow} $card_id${rest}"
        echo -e "${blue}Profit/Cost Ratio: ${cyan}$ratio${rest}"
        echo ""

        echo -e "${green}Attempting to select card '${yellow}$card_id${green}'...${rest}"
        selection_result=$(select_card "$card_id")

        if echo "$selection_result" | jq -e '.id' > /dev/null; then
            echo -e "${green}Card ${yellow}'$card_id'${green} selected successfully.${rest}"
            failed_cards[$card_id]=0
        else
            error_message=$(echo "$selection_result" | jq -r '.message // .detail // "Unknown error"')
            echo -e "${red}Failed to select card ${yellow}'$card_id'${red}. Error: ${cyan}$error_message${rest}"
            failed_cards[$card_id]=$((${failed_cards[$card_id]:-0} + 1))
            
            if [[ $error_message == *"depends on another card"* ]]; then
                echo -e "${yellow}This card depends on another card. Skipping for now.${rest}"
            fi
        fi

        echo -e "${green}Waiting for 10 seconds before next selection...${rest}"
        sleep 10
    done
}

# Execute the main function
main
