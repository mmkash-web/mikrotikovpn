#!/bin/bash

# MikroTik VPN Management System - Startup Script
# This script ensures all services are running after system reboot

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Project directory
PROJECT_DIR="/opt/mikrotik-vpn"
LOGS_DIR="$PROJECT_DIR/logs"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] STARTUP: $1" >> "$LOGS_DIR/startup.log"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] STARTUP WARNING: $1" >> "$LOGS_DIR/startup.log"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] STARTUP ERROR: $1" >> "$LOGS_DIR/startup.log"
}

# Function to wait for network
wait_for_network() {
    log "Waiting for network to be ready..."
    
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        if ping -c 1 8.8.8.8 &> /dev/null; then
            log "Network is ready"
            return 0
        fi
        
        attempts=$((attempts + 1))
        sleep 2
    done
    
    warning "Network not ready after $max_attempts attempts"
    return 1
}

# Function to check and enable IP forwarding
ensure_ip_forwarding() {
    log "Checking IP forwarding..."
    
    local ip_forward=$(cat /proc/sys/net/ipv4/ip_forward)
    
    if [ "$ip_forward" -eq 1 ]; then
        log "IP forwarding is already enabled"
    else
        warning "IP forwarding is disabled, enabling..."
        echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
        sysctl -p > /dev/null 2>&1
        log "IP forwarding enabled"
    fi
}

# Function to check and restore firewall rules
ensure_firewall_rules() {
    log "Checking firewall rules..."
    
    local vpn_rules=$(iptables -L -n | grep -c "1194\|tun0" || echo "0")
    
    if [ "$vpn_rules" -gt 0 ]; then
        log "Firewall rules are configured ($vpn_rules rules found)"
    else
        warning "Firewall rules are missing, restoring..."
        
        # Restore basic VPN firewall rules
        iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE 2>/dev/null || true
        iptables -A INPUT -p udp --dport 1194 -j ACCEPT 2>/dev/null || true
        iptables -A INPUT -i tun0 -j ACCEPT 2>/dev/null || true
        iptables -A FORWARD -i tun0 -j ACCEPT 2>/dev/null || true
        iptables -A FORWARD -o tun0 -j ACCEPT 2>/dev/null || true
        
        # Save rules
        netfilter-persistent save 2>/dev/null || true
        log "Firewall rules restored"
    fi
}

# Function to check and start OpenVPN service
ensure_openvpn_service() {
    log "Checking OpenVPN service..."
    
    if systemctl is-active --quiet openvpn@server; then
        log "OpenVPN service is running"
    else
        warning "OpenVPN service is not running, starting..."
        
        # Check if OpenVPN is installed
        if ! command -v openvpn &> /dev/null; then
            error "OpenVPN is not installed. Please run the setup script first."
            return 1
        fi
        
        # Check if configuration exists
        if [ ! -f "/etc/openvpn/server.conf" ]; then
            error "OpenVPN configuration not found. Please run the setup script first."
            return 1
        fi
        
        # Start OpenVPN service
        systemctl start openvpn@server
        
        # Wait for service to start
        sleep 5
        
        if systemctl is-active --quiet openvpn@server; then
            log "OpenVPN service started successfully"
        else
            error "Failed to start OpenVPN service"
            return 1
        fi
    fi
}

# Function to check VPN interface
ensure_vpn_interface() {
    log "Checking VPN interface..."
    
    # Wait a bit for OpenVPN to create the interface
    sleep 3
    
    if ip link show tun0 &> /dev/null; then
        log "VPN interface (tun0) is active"
    else
        warning "VPN interface (tun0) is not active"
        
        # Check if OpenVPN is running
        if systemctl is-active --quiet openvpn@server; then
            warning "OpenVPN is running but interface is missing. This may be normal during startup."
        else
            error "OpenVPN service is not running"
            return 1
        fi
    fi
}

# Function to check project directory
ensure_project_directory() {
    log "Checking project directory..."
    
    if [ ! -d "$PROJECT_DIR" ]; then
        error "Project directory not found: $PROJECT_DIR"
        return 1
    fi
    
    # Create necessary subdirectories
    mkdir -p "$PROJECT_DIR"/{logs,backups,routers,config,templates}
    
    # Ensure scripts are executable
    chmod +x "$PROJECT_DIR"/*.sh 2>/dev/null || true
    
    log "Project directory is ready"
}

# Function to check system resources
check_system_resources() {
    log "Checking system resources..."
    
    # Check disk space
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        warning "Disk usage is high: ${disk_usage}%"
    else
        log "Disk usage is normal: ${disk_usage}%"
    fi
    
    # Check memory usage
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$mem_usage" -gt 90 ]; then
        warning "Memory usage is high: ${mem_usage}%"
    else
        log "Memory usage is normal: ${mem_usage}%"
    fi
    
    # Check load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    log "System load: $load_avg"
}

# Function to run health check
run_health_check() {
    log "Running health check..."
    
    if [ -f "$PROJECT_DIR/health_check.sh" ]; then
        "$PROJECT_DIR/health_check.sh" check
    else
        warning "Health check script not found"
    fi
}

# Function to display startup summary
display_startup_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Startup Process Completed${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Check OpenVPN status
    if systemctl is-active --quiet openvpn@server; then
        echo -e "${GREEN}✓ OpenVPN Service: Running${NC}"
    else
        echo -e "${RED}✗ OpenVPN Service: Stopped${NC}"
    fi
    
    # Check VPN interface
    if ip link show tun0 &> /dev/null; then
        echo -e "${GREEN}✓ VPN Interface: Active${NC}"
    else
        echo -e "${YELLOW}⚠ VPN Interface: Checking...${NC}"
    fi
    
    # Check firewall
    local vpn_rules=$(iptables -L -n | grep -c "1194\|tun0" || echo "0")
    if [ "$vpn_rules" -gt 0 ]; then
        echo -e "${GREEN}✓ Firewall Rules: Configured${NC}"
    else
        echo -e "${RED}✗ Firewall Rules: Missing${NC}"
    fi
    
    # Check IP forwarding
    local ip_forward=$(cat /proc/sys/net/ipv4/ip_forward)
    if [ "$ip_forward" -eq 1 ]; then
        echo -e "${GREEN}✓ IP Forwarding: Enabled${NC}"
    else
        echo -e "${RED}✗ IP Forwarding: Disabled${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}System is ready for VPN connections${NC}"
    echo -e "${BLUE}Use 'mikrotik-vpn' to manage routers${NC}"
    echo -e "${BLUE}Use 'mikrotik-monitor' to check status${NC}"
}

# Main startup function
main_startup() {
    log "Starting MikroTik VPN Management System startup process..."
    
    # Wait for network
    wait_for_network
    
    # Ensure project directory
    ensure_project_directory
    
    # Check system resources
    check_system_resources
    
    # Ensure IP forwarding
    ensure_ip_forwarding
    
    # Ensure firewall rules
    ensure_firewall_rules
    
    # Ensure OpenVPN service
    ensure_openvpn_service
    
    # Ensure VPN interface
    ensure_vpn_interface
    
    # Run health check
    run_health_check
    
    # Display summary
    display_startup_summary
    
    log "Startup process completed successfully"
}

# Function to setup startup service
setup_startup_service() {
    log "Setting up startup service..."
    
    cat > /etc/systemd/system/vpn-startup.service << 'EOF'
[Unit]
Description=VPN Management System Startup Service
After=network.target openvpn@server.service
Wants=openvpn@server.service

[Service]
Type=oneshot
ExecStart=/opt/mikrotik-vpn/startup.sh
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable vpn-startup.service
    systemctl start vpn-startup.service
    
    log "Startup service installed and enabled"
    log "Service will run automatically on boot"
}

# Function to show help
show_help() {
    echo -e "${BLUE}Usage:${NC} $0 [option]"
    echo ""
    echo -e "${BLUE}Options:${NC}"
    echo -e "  startup   - Run startup process (default)"
    echo -e "  setup     - Setup as system service"
    echo -e "  help      - Show this help"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  $0              # Run startup process"
    echo -e "  $0 setup        # Install as system service"
}

# Main execution
case ${1:-startup} in
    "startup")
        main_startup
        ;;
    "setup")
        setup_startup_service
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        show_help
        exit 1
        ;;
esac 