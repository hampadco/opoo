#!/bin/bash

# رنگ‌ها
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
rest='\033[0m'

# نصب بسته‌های مورد نیاز
install_packages() {
    local packages=(curl jq bc)
    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            if [ -n "$(command -v apt)" ]; then
                sudo apt update && sudo apt install -y "$pkg"
            elif [ -n "$(command -v yum)" ]; then
                sudo yum install -y "$pkg"
            else
                echo -e "${red}لطفا $pkg را به صورت دستی نصب کنید.${rest}"
                exit 1
            fi
        fi
    done
}

install_packages

# دریافت توکن احراز هویت
echo -e "${green}لطفا توکن احراز هویت خود را وارد کنید:${rest}"
read -r AUTH_TOKEN

# تابع دریافت لیست کارت‌ها
get_card_list() {
    curl -s -H "Authorization: Bearer $AUTH_TOKEN" \
         "https://api.oppogame.ir/v2/telegram-bot/mine-cards"
}

# تابع انتخاب کارت
select_card() {
    local card_id="$1"
    local response=$(curl -s -X POST -H "Authorization: Bearer $AUTH_TOKEN" \
         "https://api.oppogame.ir/v2/telegram-bot/mine-cards/$card_id")
    
    if [[ $response == *"error"* ]]; then
        echo "خطا در انتخاب کارت $card_id: $response"
        return 1
    else
        echo "کارت $card_id با موفقیت انتخاب شد."
        return 0
    fi
}

# تابع اصلی
main() {
    while true; do
        echo -e "${blue}دریافت لیست کارت‌ها...${rest}"
        card_list=$(get_card_list)
        
        echo -e "${green}مرتب‌سازی کارت‌ها براساس نسبت سکه به پروفیت...${rest}"
        sorted_cards=$(echo "$card_list" | jq -r '.results | sort_by(.effect_function.params.coin_amount / .effect_function.params.dst_amount) | reverse | .[].id')
        
        for card_id in $sorted_cards; do
            echo -e "${yellow}تلاش برای انتخاب کارت $card_id${rest}"
            if select_card "$card_id"; then
                echo -e "${green}کارت $card_id با موفقیت انتخاب شد.${rest}"
                break
            else
                echo -e "${red}خطا در انتخاب کارت $card_id. در حال رفتن به کارت بعدی...${rest}"
            fi
        done
        
        echo -e "${purple}انتظار برای 5 ثانیه قبل از تکرار...${rest}"
        sleep 5
    done
}

# اجرای تابع اصلی
main
