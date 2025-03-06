# Steam Sale Alert Email Script

This script automatically sends email notifications when a game on Steam goes on sale. It uses **msmtp** to send emails via Gmail.

## Features
- Fetches game discounts from Steam (if implemented).
- Sends email alerts with the game's discount and price.
- Uses `msmtp` for SMTP-based email sending.
- Supports silent email sending without console output.

## Prerequisites
### Install `msmtp`
Ensure `msmtp` is installed on your system:
```bash
sudo apt update && sudo apt install msmtp -y  # Ubuntu/Debian
sudo yum install msmtp -y                     # RHEL/CentOS
```

### Configure `msmtp`
1. Create the `~/.msmtprc` configuration file:
    ```bash
    nano ~/.msmtprc
    ```
2. Add the following configuration (replace placeholders with your details):
    ```
    defaults
    auth           on
    tls            on
    tls_trust_file /etc/ssl/certs/ca-certificates.crt
    logfile        ~/.msmtp.log
    
    account gmail
    host smtp.gmail.com
    port 587
    from your-email@gmail.com
    user your-email@gmail.com
    password your-app-password  # Use an App Password instead of your real password
    
    account default : gmail
    ```
3. Secure the configuration file:
    ```bash
    chmod 600 ~/.msmtprc
    ```
4. Test `msmtp`:
    ```bash
    echo -e "Subject: Test Email\n\nHello from msmtp!" | msmtp recipient@example.com
    ```

## Usage
1. Set environment variables in your script:
    ```bash
    EMAIL_SENDER="your-email@gmail.com"
    EMAIL_RECEIVER="recipient@example.com"
    declare -A GAME_IDS=(
        ["Left_4_Dead_2"]="500"
        ["Overcooked_2"]="728880"
    )
    ```
2. Run the script manually or via cron:
    ```bash
    ./your-script.sh
    ```

## Script Breakdown
### `send_email()` function
```bash
send_email() {
    local game="$1"
    local price="$2"
    local discount="$3"
    local subject="🔥 Steam Sale Alert: ${game} is ${discount}% Off!"
    local body="The game '${game}' is now available at ₹${price} with a discount of ${discount}%!\n\nCheck it here: https://store.steampowered.com/app/${GAME_IDS[$game]}/"
    
    {
        echo "Subject: ${subject}"
        echo "To: ${EMAIL_RECEIVER}"
        echo "From: ${EMAIL_SENDER}"
        echo "Content-Type: text/plain; charset=UTF-8"
        echo
        echo -e "$body"
    } | msmtp --account=gmail "$EMAIL_RECEIVER" >/dev/null 2>&1
    
    log_message "✅ Email sent for ${game}: ₹${price} (${discount}% off)"
}
```

## Suppressing Console Output
The command:
```bash
>/dev/null 2>&1
```
- `>/dev/null` discards normal output.
- `2>&1` redirects errors to normal output (which is discarded).

To log errors instead of suppressing them:
```bash
>/dev/null 2>>msmtp_errors.log
```

## Automating with Cron
To run this script at regular intervals, add a cron job:
```bash
crontab -e
```
Add the following line to check for sales every day at 10 AM:
```bash
0 10 * * * /path/to/your-script.sh
```

## Troubleshooting
- Check `msmtp` logs:
    ```bash
    cat ~/.msmtp.log
    ```
- Test SMTP manually:
    ```bash
    msmtp --debug --account=gmail recipient@example.com
    ```
- Ensure App Password is used instead of the real password.



