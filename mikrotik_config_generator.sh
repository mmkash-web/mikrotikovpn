#!/bin/bash

# MikroTik VPN Management System - Configuration Generator
# This script generates MikroTik router configurations for OpenVPN connections

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project directory
PROJECT_DIR="/opt/mikrotik-vpn"
ROUTERS_DIR="$PROJECT_DIR/routers"
LOGS_DIR="$PROJECT_DIR/logs"
TEMPLATES_DIR="$PROJECT_DIR/templates"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOGS_DIR/config_generator.log"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOGS_DIR/config_generator.log"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOGS_DIR/config_generator.log"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Function to generate random string
generate_random_string() {
    local length=$1
    tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "$length" | head -n 1
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a ip_parts <<< "$ip"
        for part in "${ip_parts[@]}"; do
            if [[ $part -lt 0 || $part -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Function to validate domain name
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    fi
    return 1
}

# Function to get next router number
get_next_router_number() {
    local max_num=0
    if [ -d "$ROUTERS_DIR" ]; then
        for file in "$ROUTERS_DIR"/router*.conf; do
            if [[ -f "$file" ]]; then
                local num=$(basename "$file" .conf | sed 's/router//')
                if [[ $num -gt $max_num ]]; then
                    max_num=$num
                fi
            fi
        done
    fi
    echo $((max_num + 1))
}

# Function to generate MikroTik configuration
generate_mikrotik_config() {
    local router_num=$1
    local vps_address=$2
    local username=$3
    local password=$4
    local router_name=$5
    
    local config_file="$ROUTERS_DIR/router${router_num}.conf"
    local mikrotik_commands_file="$ROUTERS_DIR/router${router_num}_commands.txt"
    
    # Create router configuration file
    cat > "$config_file" << EOF
# MikroTik Router Configuration
# Generated on: $(date)
# Router Number: $router_num
# Router Name: $router_name

VPS_ADDRESS=$vps_address
USERNAME=$username
PASSWORD=$password
ROUTER_NAME=$router_name
CREATED_DATE=$(date)
EOF

    # Create MikroTik commands file
    cat > "$mikrotik_commands_file" << EOF
# MikroTik Router Commands for Router $router_num
# Generated on: $(date)
# Router Name: $router_name
# 
# Copy and paste these commands into your MikroTik router's terminal or WinBox

# ========================================
# OpenVPN Client Configuration
# ========================================

# Remove existing OVPN client if it exists
/interface ovpn-client remove [find name="ovpn-client"]

# Add new OVPN client
/interface ovpn-client add \\
    name=ovpn-client \\
    connect-to=$vps_address \\
    port=1194 \\
    user=$username \\
    password=$password \\
    mode=ip \\
    protocol=udp \\
    verify-server-certificate=no \\
    cipher=aes256 \\
    auth=sha256 \\
    comment="VPN Client for $router_name"

# ========================================
# Optional: Route Configuration
# ========================================
# Uncomment the following lines if you want all traffic to go through VPN

# Remove existing default route if it exists
# /ip route remove [find dst-address=0.0.0.0/0]

# Add default route through VPN (optional)
# /ip route add dst-address=0.0.0.0/0 gateway=ovpn-client comment="VPN Default Route"

# ========================================
# Optional: Firewall Rules
# ========================================
# Uncomment the following lines for additional security

# Allow VPN traffic
# /ip firewall filter add chain=forward action=accept src-address=10.8.0.0/24 comment="Allow VPN Traffic"

# ========================================
# Enable the OVPN client
# ========================================
/interface ovpn-client enable ovpn-client

# ========================================
# Check connection status
# ========================================
/interface ovpn-client print
/interface ovpn-client monitor ovpn-client once

# ========================================
# Useful monitoring commands
# ========================================
# Monitor VPN connection: /interface ovpn-client monitor ovpn-client
# Check VPN status: /interface ovpn-client print
# View VPN logs: /log print where topics~"ovpn"
EOF

    # Set proper permissions
    chmod 600 "$config_file"
    chmod 644 "$mikrotik_commands_file"
    
    log "Generated configuration for router $router_num ($router_name)"
}

# Function to display configuration summary
display_summary() {
    local router_num=$1
    local vps_address=$2
    local username=$3
    local password=$4
    local router_name=$5
    
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}  Configuration Generated Successfully!${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "\n${BLUE}Router Information:${NC}"
    echo -e "  Router Number: $router_num"
    echo -e "  Router Name: $router_name"
    echo -e "  VPS Address: $vps_address"
    echo -e "  Username: $username"
    echo -e "  Password: $password"
    echo -e "\n${BLUE}Files Created:${NC}"
    echo -e "  Configuration: $ROUTERS_DIR/router${router_num}.conf"
    echo -e "  Commands: $ROUTERS_DIR/router${router_num}_commands.txt"
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "  1. Copy the commands from: $ROUTERS_DIR/router${router_num}_commands.txt"
    echo -e "  2. Paste them into your MikroTik router's terminal or WinBox"
    echo -e "  3. The VPN connection should establish automatically"
    echo -e "\n${GREEN}Connection Details:${NC}"
    echo -e "  Protocol: UDP"
    echo -e "  Port: 1194"
    echo -e "  Encryption: AES-256-CBC"
    echo -e "  Authentication: SHA256"
    echo -e "\n${YELLOW}Note: Keep the password secure and don't share it!${NC}"
}

# Main script logic
main() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
    
    # Create necessary directories
    mkdir -p "$ROUTERS_DIR" "$LOGS_DIR" "$TEMPLATES_DIR"
    
    # Check if VPS address is provided
    if [ $# -eq 0 ]; then
        echo -e "${YELLOW}Usage: $0 <VPS_IP_OR_DOMAIN> [ROUTER_NAME]${NC}"
        echo -e "${BLUE}Example: $0 192.168.1.100 MyRouter${NC}"
        echo -e "${BLUE}Example: $0 vps.example.com OfficeRouter${NC}"
        exit 1
    fi
    
    local vps_address=$1
    local router_name=${2:-"Router$(get_next_router_number)"}
    
    # Validate VPS address
    if ! validate_ip "$vps_address" && ! validate_domain "$vps_address"; then
        error "Invalid VPS address: $vps_address"
    fi
    
    # Get next router number
    local router_num=$(get_next_router_number)
    
    # Generate credentials
    log "Generating credentials for router $router_num..."
    local username="router${router_num}_$(generate_random_string 6)"
    local password=$(generate_random_string 12)
    
    # Generate configuration
    log "Generating MikroTik configuration..."
    generate_mikrotik_config "$router_num" "$vps_address" "$username" "$password" "$router_name"
    
    # Display summary
    display_summary "$router_num" "$vps_address" "$username" "$password" "$router_name"
    
    # Log the generation
    log "Configuration generation completed for router $router_num"
    
    # Create a quick reference file
    cat > "$ROUTERS_DIR/quick_reference.txt" << EOF
Quick Reference - Router $router_num
====================================
Router Name: $router_name
VPS Address: $vps_address
Username: $username
Password: $password
Commands File: router${router_num}_commands.txt
EOF
    
    echo -e "\n${GREEN}✓ Configuration generation completed successfully!${NC}"
}

# Run main function with all arguments
main "$@" 