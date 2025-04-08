#!/bin/bash

# Load config
source games.config

# Log file path: change this as needed
LOG_FILE="/home/shashank/custom-scripts/steam-tracker/logs/steam_tracker.log"

# Game IDs(inclued requried game IDs here)
declare -A GAME_IDS
GAME_IDS=(
    ["Left_4_Dead"]=500
    ["Left_4_Dead_2"]=550
    ["Half_life"]=70
    ["Half_life_2"]=220
)

#---------------------------------DO NOT EDIT BELOW THIS LINE-----------------------------------#

# Email Configuration
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT=587
THRESHOLD=5
CURRENCY="IN"

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

# Display current date and time
log_message "Time: $(date)"

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
