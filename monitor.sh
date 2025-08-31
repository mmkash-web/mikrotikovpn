#!/bin/bash

# MikroTik VPN Management System - Monitoring Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_DIR="/opt/mikrotik-vpn"
LOGS_DIR="$PROJECT_DIR/logs"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

check_openvpn_status() {
    if systemctl is-active --quiet openvpn@server; then
        echo -e "${GREEN}✓ OpenVPN Server: Running${NC}"
        return 0
    else
        echo -e "${RED}✗ OpenVPN Server: Stopped${NC}"
        return 1
    fi
}

display_active_connections() {
    echo -e "${CYAN}=== Active VPN Connections ===${NC}"
    
    if [ -f "/var/log/openvpn/status.log" ]; then
        local client_section=$(sed -n '/OpenVPN CLIENT LIST/,/ROUTING TABLE/p' /var/log/openvpn/status.log | grep -v "OpenVPN CLIENT LIST" | grep -v "ROUTING TABLE" | grep -v "^$")
        
        if [ -n "$client_section" ]; then
            echo -e "${BLUE}Connected Clients:${NC}"
            echo "$client_section" | while IFS= read -r line; do
                if [[ $line =~ ^[0-9] ]]; then
                    local client_name=$(echo "$line" | awk '{print $1}')
                    local client_ip=$(echo "$line" | awk '{print $2}')
                    echo -e "  ${GREEN}Client:${NC} $client_name ${BLUE}IP:${NC} $client_ip"
                fi
            done
        else
            echo -e "${YELLOW}No active connections${NC}"
        fi
    else
        echo -e "${YELLOW}Status log not found${NC}"
    fi
    echo ""
}

display_system_resources() {
    echo -e "${CYAN}=== System Resources ===${NC}"
    
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local mem_info=$(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1, $2, $3}')
    
    echo -e "${BLUE}CPU Usage:${NC} ${cpu_usage}%"
    echo -e "${BLUE}Memory Usage:${NC} $mem_info"
    echo -e "${BLUE}Disk Usage:${NC} $disk_usage"
    echo -e "${BLUE}Load Average:${NC} $load_avg"
    echo ""
}

display_recent_logs() {
    echo -e "${CYAN}=== Recent OpenVPN Logs ===${NC}"
    
    if [ -f "/var/log/openvpn/openvpn.log" ]; then
        echo -e "${BLUE}Last 20 log entries:${NC}"
        tail -20 /var/log/openvpn/openvpn.log
    else
        echo -e "${YELLOW}OpenVPN log file not found${NC}"
    fi
    echo ""
}

main() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        exit 1
    fi
    
    mkdir -p "$LOGS_DIR"
    
    echo -e "${CYAN}=== OpenVPN Status ===${NC}"
    check_openvpn_status
    
    echo -e "${CYAN}=== System Status ===${NC}"
    systemctl status openvpn@server --no-pager -l
    
    display_active_connections
    display_system_resources
    display_recent_logs
}

main "$@" 