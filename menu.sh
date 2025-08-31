#!/bin/bash

# MikroTik VPN Management System - Menu System
# This script provides a comprehensive menu for managing MikroTik VPN connections

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Project directory
PROJECT_DIR="/opt/mikrotik-vpn"
ROUTERS_DIR="$PROJECT_DIR/routers"
LOGS_DIR="$PROJECT_DIR/logs"
BACKUPS_DIR="$PROJECT_DIR/backups"
CONFIG_DIR="$PROJECT_DIR/config"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOGS_DIR/menu.log"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOGS_DIR/menu.log"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Function to clear screen
clear_screen() {
    clear
}

# Function to display header
display_header() {
    clear_screen
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  MikroTik VPN Management System${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BLUE}Version: 1.0${NC}"
    echo -e "${BLUE}Date: $(date)${NC}"
    echo ""
}

# Function to check if OpenVPN is running
check_openvpn_status() {
    if systemctl is-active --quiet openvpn@server; then
        echo -e "${GREEN}✓ OpenVPN Server: Running${NC}"
        return 0
    else
        echo -e "${RED}✗ OpenVPN Server: Stopped${NC}"
        return 1
    fi
}

# Function to get server IP
get_server_ip() {
    local ip=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    echo "$ip"
}

# Function to display system status
display_system_status() {
    echo -e "${PURPLE}=== System Status ===${NC}"
    check_openvpn_status
    echo -e "${BLUE}Server IP: $(get_server_ip)${NC}"
    echo -e "${BLUE}OpenVPN Port: 1194${NC}"
    echo -e "${BLUE}VPN Network: 10.8.0.0/24${NC}"
    
    # Count routers
    local router_count=0
    if [ -d "$ROUTERS_DIR" ]; then
        router_count=$(ls "$ROUTERS_DIR"/router*.conf 2>/dev/null | wc -l)
    fi
    echo -e "${BLUE}Configured Routers: $router_count${NC}"
    
    # Check disk space
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "${BLUE}Disk Usage: $disk_usage${NC}"
    
    # Check memory usage
    local mem_usage=$(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
    echo -e "${BLUE}Memory Usage: $mem_usage${NC}"
    echo ""
}

# Function to add a new router
add_router() {
    echo -e "${CYAN}=== Add New Router ===${NC}"
    
    # Get VPS address
    local vps_address
    read -p "Enter VPS IP or domain name: " vps_address
    
    if [ -z "$vps_address" ]; then
        error "VPS address cannot be empty"
        return 1
    fi
    
    # Get router name (optional)
    local router_name
    read -p "Enter router name (optional): " router_name
    
    # Generate configuration
    log "Generating configuration for new router..."
    if "$PROJECT_DIR/mikrotik_config_generator.sh" "$vps_address" "$router_name"; then
        log "Router configuration generated successfully"
        echo -e "${GREEN}✓ Router configuration generated successfully!${NC}"
    else
        error "Failed to generate router configuration"
        return 1
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to remove a router
remove_router() {
    echo -e "${CYAN}=== Remove Router ===${NC}"
    
    # List existing routers
    if [ ! -d "$ROUTERS_DIR" ] || [ -z "$(ls -A "$ROUTERS_DIR"/router*.conf 2>/dev/null)" ]; then
        echo -e "${YELLOW}No routers configured.${NC}"
        echo ""
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${BLUE}Configured routers:${NC}"
    local i=1
    for file in "$ROUTERS_DIR"/router*.conf; do
        if [[ -f "$file" ]]; then
            local router_num=$(basename "$file" .conf | sed 's/router//')
            local router_name=$(grep "^ROUTER_NAME=" "$file" | cut -d'=' -f2)
            echo -e "  $i. Router $router_num - $router_name"
            i=$((i + 1))
        fi
    done
    
    echo ""
    read -p "Enter router number to remove: " choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
        error "Invalid choice"
        return 1
    fi
    
    # Find the router file
    local router_files=($(ls "$ROUTERS_DIR"/router*.conf 2>/dev/null | sort -V))
    if [ "$choice" -gt "${#router_files[@]}" ] || [ "$choice" -lt 1 ]; then
        error "Invalid router number"
        return 1
    fi
    
    local router_file="${router_files[$((choice-1))]}"
    local router_num=$(basename "$router_file" .conf | sed 's/router//')
    
    # Confirm deletion
    echo -e "${YELLOW}Are you sure you want to remove Router $router_num? (y/N):${NC}"
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Remove router files
        rm -f "$router_file"
        rm -f "$ROUTERS_DIR/router${router_num}_commands.txt"
        log "Removed router $router_num"
        echo -e "${GREEN}✓ Router $router_num removed successfully!${NC}"
    else
        echo -e "${BLUE}Operation cancelled.${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to list routers
list_routers() {
    echo -e "${CYAN}=== Configured Routers ===${NC}"
    
    if [ ! -d "$ROUTERS_DIR" ] || [ -z "$(ls -A "$ROUTERS_DIR"/router*.conf 2>/dev/null)" ]; then
        echo -e "${YELLOW}No routers configured.${NC}"
        echo ""
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${BLUE}Router configurations:${NC}"
    echo ""
    
    for file in "$ROUTERS_DIR"/router*.conf; do
        if [[ -f "$file" ]]; then
            local router_num=$(basename "$file" .conf | sed 's/router//')
            local router_name=$(grep "^ROUTER_NAME=" "$file" | cut -d'=' -f2)
            local vps_address=$(grep "^VPS_ADDRESS=" "$file" | cut -d'=' -f2)
            local username=$(grep "^USERNAME=" "$file" | cut -d'=' -f2)
            local created_date=$(grep "^CREATED_DATE=" "$file" | cut -d'=' -f2-)
            
            echo -e "${GREEN}Router $router_num:${NC}"
            echo -e "  Name: $router_name"
            echo -e "  VPS Address: $vps_address"
            echo -e "  Username: $username"
            echo -e "  Created: $created_date"
            echo -e "  Config File: $file"
            echo -e "  Commands File: $ROUTERS_DIR/router${router_num}_commands.txt"
            echo ""
        fi
    done
    
    read -p "Press Enter to continue..."
}

# Function to view router details
view_router_details() {
    echo -e "${CYAN}=== View Router Details ===${NC}"
    
    # List existing routers
    if [ ! -d "$ROUTERS_DIR" ] || [ -z "$(ls -A "$ROUTERS_DIR"/router*.conf 2>/dev/null)" ]; then
        echo -e "${YELLOW}No routers configured.${NC}"
        echo ""
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${BLUE}Configured routers:${NC}"
    local i=1
    for file in "$ROUTERS_DIR"/router*.conf; do
        if [[ -f "$file" ]]; then
            local router_num=$(basename "$file" .conf | sed 's/router//')
            local router_name=$(grep "^ROUTER_NAME=" "$file" | cut -d'=' -f2)
            echo -e "  $i. Router $router_num - $router_name"
            i=$((i + 1))
        fi
    done
    
    echo ""
    read -p "Enter router number to view: " choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
        error "Invalid choice"
        return 1
    fi
    
    # Find the router file
    local router_files=($(ls "$ROUTERS_DIR"/router*.conf 2>/dev/null | sort -V))
    if [ "$choice" -gt "${#router_files[@]}" ] || [ "$choice" -lt 1 ]; then
        error "Invalid router number"
        return 1
    fi
    
    local router_file="${router_files[$((choice-1))]}"
    local router_num=$(basename "$router_file" .conf | sed 's/router//')
    local commands_file="$ROUTERS_DIR/router${router_num}_commands.txt"
    
    echo ""
    echo -e "${CYAN}=== Router $router_num Details ===${NC}"
    echo ""
    
    # Display configuration
    echo -e "${BLUE}Configuration:${NC}"
    cat "$router_file"
    echo ""
    
    # Display commands
    if [ -f "$commands_file" ]; then
        echo -e "${BLUE}MikroTik Commands:${NC}"
        cat "$commands_file"
    else
        echo -e "${YELLOW}Commands file not found.${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to backup configurations
backup_configurations() {
    echo -e "${CYAN}=== Backup Configurations ===${NC}"
    
    if [ ! -d "$BACKUPS_DIR" ]; then
        mkdir -p "$BACKUPS_DIR"
    fi
    
    local backup_file="$BACKUPS_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    log "Creating backup..."
    
    if tar -czf "$backup_file" -C "$PROJECT_DIR" . 2>/dev/null; then
        log "Backup created successfully: $backup_file"
        echo -e "${GREEN}✓ Backup created successfully!${NC}"
        echo -e "${BLUE}Backup file: $backup_file${NC}"
    else
        error "Failed to create backup"
        return 1
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to monitor connections
monitor_connections() {
    echo -e "${CYAN}=== Monitor Connections ===${NC}"
    
    if [ -f "$PROJECT_DIR/monitor.sh" ]; then
        "$PROJECT_DIR/monitor.sh"
    else
        echo -e "${YELLOW}Monitoring script not found.${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to view logs
view_logs() {
    echo -e "${CYAN}=== View Logs ===${NC}"
    
    echo -e "${BLUE}Available logs:${NC}"
    echo "  1. OpenVPN Log"
    echo "  2. System Log"
    echo "  3. Menu Log"
    echo "  4. Config Generator Log"
    echo ""
    
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1)
            if [ -f "/var/log/openvpn/openvpn.log" ]; then
                echo -e "${BLUE}=== OpenVPN Log ===${NC}"
                tail -50 /var/log/openvpn/openvpn.log
            else
                echo -e "${YELLOW}OpenVPN log not found.${NC}"
            fi
            ;;
        2)
            echo -e "${BLUE}=== System Log ===${NC}"
            journalctl -u openvpn@server --no-pager -l | tail -50
            ;;
        3)
            if [ -f "$LOGS_DIR/menu.log" ]; then
                echo -e "${BLUE}=== Menu Log ===${NC}"
                tail -50 "$LOGS_DIR/menu.log"
            else
                echo -e "${YELLOW}Menu log not found.${NC}"
            fi
            ;;
        4)
            if [ -f "$LOGS_DIR/config_generator.log" ]; then
                echo -e "${BLUE}=== Config Generator Log ===${NC}"
                tail -50 "$LOGS_DIR/config_generator.log"
            else
                echo -e "${YELLOW}Config generator log not found.${NC}"
            fi
            ;;
        *)
            error "Invalid choice"
            return 1
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to display main menu
display_menu() {
    echo -e "${PURPLE}Main Menu:${NC}"
    echo "  1. Add MikroTik Router"
    echo "  2. Remove MikroTik Router"
    echo "  3. List MikroTik Routers"
    echo "  4. View Router Details"
    echo "  5. Backup Configurations"
    echo "  6. Monitor Connections"
    echo "  7. View Logs"
    echo "  8. System Status"
    echo "  9. Exit"
    echo ""
}

# Function to handle menu choice
handle_choice() {
    local choice=$1
    
    case $choice in
        1)
            add_router
            ;;
        2)
            remove_router
            ;;
        3)
            list_routers
            ;;
        4)
            view_router_details
            ;;
        5)
            backup_configurations
            ;;
        6)
            monitor_connections
            ;;
        7)
            view_logs
            ;;
        8)
            display_system_status
            read -p "Press Enter to continue..."
            ;;
        9)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            error "Invalid choice. Please enter a number between 1 and 9."
            read -p "Press Enter to continue..."
            ;;
    esac
}

# Main function
main() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
    
    # Create necessary directories
    mkdir -p "$ROUTERS_DIR" "$LOGS_DIR" "$BACKUPS_DIR" "$CONFIG_DIR"
    
    # Main menu loop
    while true; do
        display_header
        display_system_status
        display_menu
        
        read -p "Enter your choice (1-9): " choice
        handle_choice "$choice"
    done
}

# Run main function
main "$@" 