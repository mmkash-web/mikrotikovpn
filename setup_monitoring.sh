#!/bin/bash

# MikroTik VPN Management System - Monitoring Setup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="/opt/mikrotik-vpn"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Setup cron jobs
setup_cron_jobs() {
    log "Setting up cron jobs for automated monitoring..."
    
    # Health check every 5 minutes
    (crontab -l 2>/dev/null; echo "*/5 * * * * /opt/mikrotik-vpn/health_check.sh check >> /opt/mikrotik-vpn/logs/cron.log 2>&1") | crontab -
    
    # Backup every 6 hours
    (crontab -l 2>/dev/null; echo "0 */6 * * * /opt/mikrotik-vpn/backup.sh create >> /opt/mikrotik-vpn/logs/cron.log 2>&1") | crontab -
    
    # System status every hour
    (crontab -l 2>/dev/null; echo "0 * * * * /opt/mikrotik-vpn/monitor.sh >> /opt/mikrotik-vpn/logs/cron.log 2>&1") | crontab -
    
    log "Cron jobs installed successfully"
}

# Setup systemd services
setup_systemd_services() {
    log "Setting up systemd services..."
    
    # Health monitoring service
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

    # Startup service
    cat > /etc/systemd/system/vpn-startup.service << 'EOF'
[Unit]
Description=VPN Management System Startup Service
After=network.target openvpn@server.service

[Service]
Type=oneshot
ExecStart=/opt/mikrotik-vpn/startup.sh startup
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable vpn-health-monitor.service
    systemctl enable vpn-startup.service
    
    log "Systemd services configured successfully"
}

# Setup log rotation
setup_log_rotation() {
    log "Setting up log rotation..."
    
    cat > /etc/logrotate.d/mikrotik-vpn << 'EOF'
/opt/mikrotik-vpn/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}

/var/log/openvpn/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF

    log "Log rotation configured successfully"
}

# Main setup
main_setup() {
    log "Starting monitoring setup..."
    
    mkdir -p "$PROJECT_DIR"/{config,logs}
    
    setup_cron_jobs
    setup_systemd_services
    setup_log_rotation
    
    systemctl start vpn-health-monitor.service
    systemctl start vpn-startup.service
    
    log "Monitoring setup completed successfully"
    
    echo ""
    echo -e "${BLUE}Monitoring Features Installed:${NC}"
    echo -e "  ✓ Health checks every 5 minutes"
    echo -e "  ✓ Automatic backups every 6 hours"
    echo -e "  ✓ System monitoring every hour"
    echo -e "  ✓ Log rotation daily"
    echo -e "  ✓ Startup service on boot"
    echo ""
    echo -e "${GREEN}Services are now running automatically!${NC}"
}

# Show help
show_help() {
    echo -e "${BLUE}Usage:${NC} $0 [option]"
    echo ""
    echo -e "${BLUE}Options:${NC}"
    echo -e "  setup     - Setup complete monitoring (default)"
    echo -e "  cron      - Setup cron jobs only"
    echo -e "  services  - Setup systemd services only"
    echo -e "  help      - Show this help"
}

# Main execution
case ${1:-setup} in
    "setup")
        main_setup
        ;;
    "cron")
        setup_cron_jobs
        ;;
    "services")
        setup_systemd_services
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