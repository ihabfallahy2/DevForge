#!/bin/bash

#######################################
# Webhook Server
# Lightweight HTTP server for handling git webhooks
#######################################

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=lib/discord.sh
source "${SCRIPT_DIR}/discord.sh"

#######################################
# Server Functions
#######################################

# Start webhook server
# Arguments:
#   $1 - Port (default: 9000)
#   $2 - Secret
#   $3 - Project directory
start_webhook_server() {
    local port="${1:-9000}"
    local secret="$2"
    local project_dir="$3"
    
    if [[ -z "$secret" ]]; then
        log_error "Webhook secret is required"
        return 1
    fi
    
    if ! check_command nc; then
        log_error "netcat (nc) is required for webhook server"
        return 1
    fi
    
    log_info "Starting webhook server on port $port..."
    
    # Create a FIFO pipe for the server
    local pipe="/tmp/webhook_pipe_$$"
    mkfifo "$pipe"
    trap 'rm -f $pipe' EXIT
    
    # Infinite loop to handle requests
    while true; do
        # Use netcat to listen and pipe to handler
        # This is a very basic implementation. For production, a real server (Go/Node/Python) is better.
        # But for a bash bootstrapper, this is "universal".
        
        # However, keeping a bash script running as a server is fragile.
        # A better approach might be to install a systemd service that runs a small python script.
        # Since we install Python/Node, we could generate a small server script.
        
        # Let's generate a Python script instead, it's more robust than netcat in bash
        start_python_webhook_server "$port" "$secret" "$project_dir"
        
        # If python fails or returns, wait a bit and retry
        sleep 5
    done
}

# Start Python webhook server
# Arguments:
#   $1 - Port
#   $2 - Secret
#   $3 - Project directory
start_python_webhook_server() {
    local port="$1"
    local secret="$2"
    local project_dir="$3"
    
    # Create server script
    local server_script="/tmp/webhook_server_$$.py"
    
    cat > "$server_script" << EOF
import http.server
import hmac
import hashlib
import json
import os
import subprocess
import sys

PORT = int(os.environ.get('PORT', 9000))
SECRET = os.environ.get('WEBHOOK_SECRET', '').encode('utf-8')
PROJECT_DIR = os.environ.get('PROJECT_DIR', '.')

class WebhookHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        # Read headers
        content_length = int(self.headers.get('Content-Length', 0))
        signature = self.headers.get('X-Hub-Signature-256')
        
        # Read body
        body = self.rfile.read(content_length)
        
        # Validate signature
        if not self.validate_signature(body, signature):
            self.send_response(403)
            self.end_headers()
            self.wfile.write(b'Invalid signature')
            return
            
        # Parse payload
        try:
            payload = json.loads(body)
        except json.JSONDecodeError:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b'Invalid JSON')
            return
            
        # Check if push event (GitHub)
        if 'ref' in payload:
            ref = payload['ref']
            branch = ref.split('/')[-1]
            print(f"Received push to {branch}")
            
            # Trigger deploy
            self.trigger_deploy(branch)
            
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'OK')
        
    def validate_signature(self, body, signature):
        if not SECRET:
            return True # No secret configured, allow all (unsafe but configurable)
        if not signature:
            return False
            
        # GitHub sends sha256=...
        if signature.startswith('sha256='):
            signature = signature[7:]
            
        mac = hmac.new(SECRET, body, hashlib.sha256)
        expected = mac.hexdigest()
        
        return hmac.compare_digest(expected, signature)
        
    def trigger_deploy(self, branch):
        # Run deploy script
        deploy_script = os.path.join(PROJECT_DIR, 'deploy.sh')
        if os.path.exists(deploy_script):
            print(f"Triggering deploy for {branch}...")
            # We run this async so we don't block the response
            subprocess.Popen([deploy_script], cwd=PROJECT_DIR, env=os.environ.copy())
        else:
            print("No deploy.sh found")

print(f"Starting webhook server on port {PORT}")
http.server.HTTPServer(('0.0.0.0', PORT), WebhookHandler).serve_forever()
EOF

    # Run python script
    export PORT="$port"
    export WEBHOOK_SECRET="$secret"
    export PROJECT_DIR="$project_dir"
    
    if check_command python3; then
        python3 "$server_script"
    elif check_command python; then
        python "$server_script"
    else
        log_error "Python is required for webhook server"
        return 1
    fi
}

export -f start_webhook_server

log_debug "webhook-server.sh loaded successfully"
