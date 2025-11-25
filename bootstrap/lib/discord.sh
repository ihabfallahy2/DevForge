#!/bin/bash

#######################################
# Discord Notifications
# Sends rich notifications to Discord webhooks
#######################################

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/common.sh"

#######################################
# Notification Functions
#######################################

# Send raw JSON payload to Discord
# Arguments:
#   $1 - Webhook URL
#   $2 - JSON payload
send_discord_payload() {
    local webhook_url="$1"
    local payload="$2"
    
    if [[ -z "$webhook_url" ]]; then
        log_warn "No Discord webhook URL provided"
        return 1
    fi
    
    log_debug "Sending Discord notification..."
    
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$webhook_url")
        
    if [[ "$response" =~ ^2 ]]; then
        log_debug "Discord notification sent successfully"
        return 0
    else
        log_error "Failed to send Discord notification (HTTP $response)"
        return 1
    fi
}

# Send simple message
# Arguments:
#   $1 - Webhook URL
#   $2 - Message content
send_discord_message() {
    local webhook_url="$1"
    local message="$2"
    
    # Escape JSON string
    local escaped_message
    escaped_message=$(echo "$message" | jq -R .)
    
    local payload="{\"content\": $escaped_message}"
    send_discord_payload "$webhook_url" "$payload"
}

# Send rich embed notification
# Arguments:
#   $1 - Webhook URL
#   $2 - Title
#   $3 - Description
#   $4 - Color (decimal)
#   $5 - Fields (JSON array of objects)
send_discord_embed() {
    local webhook_url="$1"
    local title="$2"
    local description="$3"
    local color="${4:-3447003}" # Default blue
    local fields="${5:-[]}"
    
    # Construct JSON payload using jq to ensure validity
    local payload
    payload=$(jq -n \
        --arg title "$title" \
        --arg desc "$description" \
        --argjson color "$color" \
        --argjson fields "$fields" \
        '{
            embeds: [{
                title: $title,
                description: $desc,
                color: $color,
                fields: $fields,
                timestamp: (now | todate),
                footer: {
                    text: "Universal Bootstrapper"
                }
            }]
        }')
        
    send_discord_payload "$webhook_url" "$payload"
}

#######################################
# Event Notifications
#######################################

# Notify deploy start
# Arguments:
#   $1 - Webhook URL
#   $2 - Project Name
#   $3 - Environment
#   $4 - Branch
notify_deploy_start() {
    local webhook_url="$1"
    local project="$2"
    local env="$3"
    local branch="$4"
    
    local fields
    fields=$(jq -n \
        --arg env "$env" \
        --arg branch "$branch" \
        '[
            {name: "Environment", value: $env, inline: true},
            {name: "Branch", value: $branch, inline: true}
        ]')
        
    send_discord_embed \
        "$webhook_url" \
        "🚀 Deploy Started: $project" \
        "Deployment process has been initiated." \
        3447003 \
        "$fields"
}

# Notify deploy success
# Arguments:
#   $1 - Webhook URL
#   $2 - Project Name
#   $3 - Environment
#   $4 - Duration
notify_deploy_success() {
    local webhook_url="$1"
    local project="$2"
    local env="$3"
    local duration="$4"
    
    local fields
    fields=$(jq -n \
        --arg env "$env" \
        --arg duration "$duration" \
        '[
            {name: "Environment", value: $env, inline: true},
            {name: "Duration", value: $duration, inline: true},
            {name: "Status", value: "✅ Healthy", inline: true}
        ]')
        
    send_discord_embed \
        "$webhook_url" \
        "✅ Deploy Successful: $project" \
        "Application has been successfully deployed and verified." \
        5763719 \
        "$fields"
}

# Notify deploy failure
# Arguments:
#   $1 - Webhook URL
#   $2 - Project Name
#   $3 - Environment
#   $4 - Error Message
#   $5 - Mention (optional)
notify_deploy_failure() {
    local webhook_url="$1"
    local project="$2"
    local env="$3"
    local error="$4"
    local mention="${5:-}"
    
    local fields
    fields=$(jq -n \
        --arg env "$env" \
        --arg error "$error" \
        '[
            {name: "Environment", value: $env, inline: true},
            {name: "Error", value: $error, inline: false}
        ]')
    
    local content=""
    if [[ -n "$mention" ]]; then
        content="$mention"
    fi
    
    # Construct payload with content (mention) and embed
    local payload
    payload=$(jq -n \
        --arg content "$content" \
        --arg title "❌ Deploy Failed: $project" \
        --arg desc "Deployment failed. Please check logs." \
        --argjson color 15548997 \
        --argjson fields "$fields" \
        '{
            content: $content,
            embeds: [{
                title: $title,
                description: $desc,
                color: $color,
                fields: $fields,
                timestamp: (now | todate),
                footer: {
                    text: "Universal Bootstrapper"
                }
            }]
        }')
        
    send_discord_payload "$webhook_url" "$payload"
}

export -f send_discord_message
export -f send_discord_embed
export -f notify_deploy_start
export -f notify_deploy_success
export -f notify_deploy_failure

log_debug "discord.sh loaded successfully"
