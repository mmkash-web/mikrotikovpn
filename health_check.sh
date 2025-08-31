#!/bin/bash

# MikroTik VPN Management System - Health Check Script

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
ALERT_LOG="$LOGS_DIR/health_alerts.log"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] HEALTH: $1" >> "$LOGS_DIR/health.log"
}

alert() {
    echo -e "${RED}[ALERT] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ALERT: $1" >> "$ALERT_LOG"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check OpenVPN service
check_openvpn_service() {
    if systemctl is-active --quiet openvpn@server; then
        log "OpenVPN service is running"
        return 0
    else
        alert "OpenVPN service is down!"
        return 1
    fi
}

# Check VPN interface
check_vpn_interface() {
    if ip link show tun0 &> /dev/null; then
        log "VPN interface (tun0) is active"
        return 0
    else
        alert "VPN interface (tun0) is missing!"
        return 1
    fi
}

# Check firewall rules
check_firewall_rules() {
    local vpn_rules=$(iptables -L -n | grep -c "1194\|tun0" || echo "0")
    
    if [ "$vpn_rules" -gt 0 ]; then
        log "Firewall rules are configured ($vpn_rules rules found)"
        return 0
    else
        alert "Firewall rules are missing!"
        return 1
    fi
}

# Check IP forwarding
check_ip_forwarding() {
    local ip_forward=$(cat /proc/sys/net/ipv4/ip_forward)
    
    if [ "$ip_forward" -eq 1 ]; then
        log "IP forwarding is enabled"
        return 0
    else
        alert "IP forwarding is disabled!"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -lt 90 ]; then
        log "Disk usage is normal: ${disk_usage}%"
        return 0
    else
        warning "Disk usage is high: ${disk_usage}%"
        return 1
    fi
}

# Check memory usage
check_memory_usage() {
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    
    if [ "$mem_usage" -lt 90 ]; then
        log "Memory usage is normal: ${mem_usage}%"
        return 0
    else
        warning "Memory usage is high: ${mem_usage}%"
        return 1
    fi
}

# Check active connections
check_active_connections() {
    if [ -f "/var/log/openvpn/status.log" ]; then
        local active_connections=$(grep -c "^[0-9]" /var/log/openvpn/status.log || echo "0")
        log "Active VPN connections: $active_connections"
        return 0
    else
        warning "OpenVPN status log not found"
        return 1
    fi
}

# Restart OpenVPN service
restart_openvpn() {
    warning "Restarting OpenVPN service..."
    systemctl restart openvpn@server
    sleep 5
    
    if systemctl is-active --quiet openvpn@server; then
        log "OpenVPN service restarted successfully"
        return 0
    else
        alert "OpenVPN restart failed!"
        return 1
    fi
}

# Restore firewall rules
restore_firewall_rules() {
    warning "Restoring firewall rules..."
    
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE 2>/dev/null || true
    iptables -A INPUT -p udp --dport 1194 -j ACCEPT 2>/dev/null || true
    iptables -A INPUT -i tun0 -j ACCEPT 2>/dev/null || true
    iptables -A FORWARD -i tun0 -j ACCEPT 2>/dev/null || true
    iptables -A FORWARD -o tun0 -j ACCEPT 2>/dev/null || true
    
    netfilter-persistent save 2>/dev/null || true
    log "Firewall rules restored"
}

# Enable IP forwarding
enable_ip_forwarding() {
    warning "Enabling IP forwarding..."
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
    log "IP forwarding enabled"
}

# Perform automatic repairs
perform_repairs() {
    local issues_found=0
    
    if ! check_openvpn_service; then
        if restart_openvpn; then
            log "OpenVPN service repaired"
        else
            issues_found=$((issues_found + 1))
        fi
    fi
    
    if ! check_firewall_rules; then
        restore_firewall_rules
        issues_found=$((issues_found + 1))
    fi
    
    if ! check_ip_forwarding; then
        enable_ip_forwarding
        issues_found=$((issues_found + 1))
    fi
    
    return $issues_found
}

# Main health check
main_health_check() {
    log "Starting health check..."
    
    local total_checks=0
    local passed_checks=0
    local failed_checks=0
    
    check_openvpn_service && passed_checks=$((passed_checks + 1)) || failed_checks=$((failed_checks + 1))
    total_checks=$((total_checks + 1))
    
    check_vpn_interface && passed_checks=$((passed_checks + 1)) || failed_checks=$((failed_checks + 1))
    total_checks=$((total_checks + 1))
    
    check_firewall_rules && passed_checks=$((passed_checks + 1)) || failed_checks=$((failed_checks + 1))
    total_checks=$((total_checks + 1))
    
    check_ip_forwarding && passed_checks=$((passed_checks + 1)) || failed_checks=$((failed_checks + 1))
    total_checks=$((total_checks + 1))
    
    check_disk_space && passed_checks=$((passed_checks + 1)) || failed_checks=$((failed_checks + 1))
    total_checks=$((total_checks + 1))
    
    check_memory_usage && passed_checks=$((passed_checks + 1)) || failed_checks=$((failed_checks + 1))
    total_checks=$((total_checks + 1))
    
    check_active_connections && passed_checks=$((passed_checks + 1)) || failed_checks=$((failed_checks + 1))
    total_checks=$((total_checks + 1))
    
    log "Health check completed: $passed_checks/$total_checks checks passed"
    
    if [ "$failed_checks" -gt 0 ]; then
        warning "$failed_checks issues detected, attempting repairs..."
        perform_repairs
    else
        log "All systems are healthy!"
    fi
}

# Setup monitoring service
setup_monitoring_service() {
    log "Setting up health monitoring service..."
    
    cat > /etc/systemd/system/vpn-health-monitor.service << 'EOF'
[Unit]
Description=VPN Health Monitoring Service
After=network.target openvpn@server.service

[Service]
Type=simple
ExecStart=/opt/mikrotik-vpn/health_check.sh monitor
Restart=always
RestartSec=300
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable vpn-health-monitor.service
    systemctl start vpn-health-monitor.service
    
    log "Health monitoring service installed and started"
}

# Run continuous monitoring
run_continuous_monitoring() {
    log "Starting continuous health monitoring..."
    
    while true; do
        main_health_check
        log "Waiting 5 minutes until next check..."
        sleep 300
    done
}

# Show help
show_help() {
    echo -e "${BLUE}Usage:${NC} $0 [option]"
    echo ""
    echo -e "${BLUE}Options:${NC}"
    echo -e "  check     - Run health check (default)"
    echo -e "  monitor   - Run continuous monitoring"
    echo -e "  setup     - Setup monitoring service"
    echo -e "  help      - Show this help"
}

# Main execution
case ${1:-check} in
    "check")
        main_health_check
        ;;
    "monitor")
        run_continuous_monitoring
        ;;
    "setup")
        setup_monitoring_service
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