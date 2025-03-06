#!/bin/bash

# Log file path
LOG_FILE="/home/shashank/Desktop/steam-tracker/log/steam_tracker.log"

# Game IDs
declare -A GAME_IDS
GAME_IDS=(
    ["Left_4_Dead"]=500
    ["Left_4_Dead_2"]=550
    ["Portal_2"]=620
    ["Counter_Strike_Global_Offensive"]=730
    ["Terraria"]=105600
    ["Don_t_Starve_Together"]=322330
    ["Among_Us"]=945360
    ["Valheim"]=892970
    ["Cyberpunk_2077"]=1091500
    ["Red_Dead_Redemption_2"]=1174180
    ["Grand_Theft_Auto_V"]=271590
    ["The_Witcher_3_Wild_Hunt"]=292030
    ["The_Elder_Scrolls_V_Skyrim"]=72850
    ["Fallout_4"]=377160
    ["Dying_Light"]=239140
    ["The_Forest"]=242760
    ["Subnautica"]=264710
    ["Rust"]=252490
    ["ARK_Survival_Evolved"]=346110
    ["Dead_by_Daylight"]=381210
    ["Phasmophobia"]=739630
    ["Raft"]=648800
    ["Stardew_Valley"]=413150
    ["Hades"]=1145360
    ["Sekiro_Shadows_Die_Twice"]=814380
    ["Dark_Souls_III"]=374320
    ["Hollow_Knight"]=367520
    ["Celeste"]=504230
    ["Ori_and_the_Blind_Forest_Definitive_Edition"]=387290
    ["Cuphead"]=268910
    ["Undertale"]=391540
    ["Katana_ZERO"]=447530
    ["Hyper_Light_Drifter"]=257850
    ["Enter_the_Gungeon"]=311690
    ["Hotline_Miami"]=219150
)
CURRENCY="IN"

# Email Configuration
EMAIL_SENDER="shashank21dark@gmail.com"
EMAIL_RECEIVER="shashank21lazer@gmail.com"
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT=587

THRESHOLD=5

# Function to log messages
log_message() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Function to get Steam game price
get_steam_price() {
    local app_id="$1"
    local response=$(curl -s "https://store.steampowered.com/api/appdetails?appids=${app_id}&cc=${CURRENCY}")
    local success=$(echo "$response" | jq -r ".\"${app_id}\".success")
    
    if [[ "$success" == "true" ]]; then
        local final_price=$(echo "$response" | jq -r ".\"${app_id}\".data.price_overview.final")
        local discount=$(echo "$response" | jq -r ".\"${app_id}\".data.price_overview.discount_percent")
        
        if [[ "$final_price" != "null" ]]; then
            echo "$(bc <<< "scale=2; $final_price / 100") $discount"
        else
            echo "Free 0"
        fi
    else
        echo "null null"
    fi
}

# Function to send email alert
send_email() {
    local subject="🔥 Steam Sale Alert: Multiple Games on Discount!"
    local body="The following games are currently on sale:\n\n"
    
    for entry in "${DISCOUNTED_GAMES[@]}"; do
        body+="$entry\n"
    done
    
    body+="\nCheck Steam store for more details."
    
    # Create the email message
    {
        echo "Subject: ${subject}"
        echo "To: ${EMAIL_RECEIVER}"
        echo "From: ${EMAIL_SENDER}"
        echo "Content-Type: text/plain; charset=UTF-8"
        echo
        echo -e "$body"
    } | msmtp --debug --account=gmail "$EMAIL_RECEIVER" >/dev/null 2>&1

    log_message "✅ Email sent with all discounted games."
}

# Array to store discounted games
DISCOUNTED_GAMES=()

# Main loop to check game prices
for game in "${!GAME_IDS[@]}"; do
    app_id=${GAME_IDS[$game]}
    read price discount <<< $(get_steam_price "$app_id")
    
    if [[ "$price" != "null" ]]; then
        message="${game}: ₹${price} (${discount}% off)"
        log_message "$message"
        if (( discount > THRESHOLD )); then
            DISCOUNTED_GAMES+=("${game}: ₹${price} (${discount}% off)\nCheck here: https://store.steampowered.com/app/${app_id}/")
        fi
    else
        log_message "Failed to fetch price for ${game}"
    fi
    
    sleep 1  # Avoid hitting API rate limits
done

# Send a single email if there are discounted games
if [[ ${#DISCOUNTED_GAMES[@]} -gt 0 ]]; then
    send_email
fi
