#!/bin/bash

# Log file path
LOG_FILE="/home/shashank/Desktop/steam-tracker/log/steam_tracker.log"

# Game IDs
declare -A GAME_IDS
GAME_IDS=(
    ["Left_4_Dead"]=500
    ["Left_4_Dead_2"]=550
)
CURRENCY="IN"

# Email Configuration
EMAIL_SENDER="shashank21dark@gmail.com"
EMAIL_RECEIVER="shashank21lazer@gmail.com"
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT=587

THREASHOLD=50

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
    local game="$1"
    local price="$2"
    local discount="$3"
    local subject="🔥 Steam Sale Alert: ${game} is ${discount}% Off!"
    local body="The game '${game}' is now available at ₹${price} with a discount of ${discount}%!\n\nCheck it here: https://store.steampowered.com/app/${GAME_IDS[$game]}/"
    
    # Create the email message
    {
        echo "Subject: ${subject}"
        echo "To: ${EMAIL_RECEIVER}"
        echo "From: ${EMAIL_SENDER}"
        echo "Content-Type: text/plain; charset=UTF-8"
        echo
        echo -e "$body"
    } | msmtp --debug --account=gmail "$EMAIL_RECEIVER" >/dev/null 2>&1

    log_message "✅ Email sent for ${game}: ₹${price} (${discount}% off)"
}


# Main loop to check game prices
for game in "${!GAME_IDS[@]}"; do
    app_id=${GAME_IDS[$game]}
    read price discount <<< $(get_steam_price "$app_id")
    
    if [[ "$price" != "null" ]]; then
        message="${game}: ₹${price} (${discount}% off)"
        log_message "$message"
        if (( discount > $THREASHOLD )); then
            send_email "$game" "$price" "$discount"
        fi
    else
        log_message "Failed to fetch price for ${game}"
    fi
    
    sleep 1  # Avoid hitting API rate limits
done
