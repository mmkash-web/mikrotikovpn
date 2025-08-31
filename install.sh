#!/bin/bash

# MikroTik VPN Management System - Installation Script
# This script installs and sets up the complete MikroTik VPN management system

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

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

# Function to check system requirements
check_requirements() {
    log "Checking system requirements..."
    
    # Check if running on Ubuntu/Debian
    if ! command -v apt-get &> /dev/null; then
        error "This script requires Ubuntu/Debian system with apt package manager"
    fi
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        warning "curl not found, installing..."
        apt-get update -y
        apt-get install -y curl
    fi
    
    # Check if tar is available
    if ! command -v tar &> /dev/null; then
        warning "tar not found, installing..."
        apt-get update -y
        apt-get install -y tar
    fi
    
    log "System requirements check completed"
}

# Function to create project structure
create_project_structure() {
    log "Creating project directory structure..."
    
    # Create main project directory
    mkdir -p "$PROJECT_DIR"
    
    # Create subdirectories
    mkdir -p "$PROJECT_DIR"/{config,logs,backups,routers,templates}
    
    # Set proper permissions
    chown -R root:root "$PROJECT_DIR"
    chmod -R 755 "$PROJECT_DIR"
    
    log "Project directory structure created"
}

# Function to copy scripts to project directory
copy_scripts() {
    log "Copying scripts to project directory..."
    
    # Get the directory where this script is located
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Copy main scripts
    if [ -f "$script_dir/vps_setup.sh" ]; then
        cp "$script_dir/vps_setup.sh" "$PROJECT_DIR/"
        chmod +x "$PROJECT_DIR/vps_setup.sh"
        log "Copied vps_setup.sh"
    else
        warning "vps_setup.sh not found in current directory"
    fi
    
    if [ -f "$script_dir/mikrotik_config_generator.sh" ]; then
        cp "$script_dir/mikrotik_config_generator.sh" "$PROJECT_DIR/"
        chmod +x "$PROJECT_DIR/mikrotik_config_generator.sh"
        log "Copied mikrotik_config_generator.sh"
    else
        warning "mikrotik_config_generator.sh not found in current directory"
    fi
    
    if [ -f "$script_dir/menu.sh" ]; then
        cp "$script_dir/menu.sh" "$PROJECT_DIR/"
        chmod +x "$PROJECT_DIR/menu.sh"
        log "Copied menu.sh"
    else
        warning "menu.sh not found in current directory"
    fi
    
    if [ -f "$script_dir/README.md" ]; then
        cp "$script_dir/README.md" "$PROJECT_DIR/"
        log "Copied README.md"
    else
        warning "README.md not found in current directory"
    fi
    
    log "Scripts copied successfully"
}

# Function to create additional utility scripts
create_utility_scripts() {
    log "Creating utility scripts..."
    
    # Create uninstall script
    cat > "$PROJECT_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

# MikroTik VPN Management System - Uninstall Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/opt/mikrotik-vpn"

echo -e "${YELLOW}This will remove the MikroTik VPN Management System${NC}"
echo -e "${YELLOW}This action cannot be undone!${NC}"
read -p "Are you sure you want to continue? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Uninstallation cancelled.${NC}"
    exit 0
fi

echo -e "${YELLOW}Stopping OpenVPN service...${NC}"
systemctl stop openvpn@server 2>/dev/null || true
systemctl disable openvpn@server 2>/dev/null || true

echo -e "${YELLOW}Removing project files...${NC}"
rm -rf "$PROJECT_DIR"

echo -e "${YELLOW}Removing OpenVPN configuration...${NC}"
rm -rf /etc/openvpn/server
rm -f /etc/openvpn/server.conf
rm -f /etc/systemd/system/openvpn@server.service

echo -e "${YELLOW}Reloading systemd...${NC}"
systemctl daemon-reload

echo -e "${GREEN}Uninstallation completed successfully!${NC}"
echo -e "${YELLOW}Note: You may need to manually remove firewall rules if needed.${NC}"
EOF

    chmod +x "$PROJECT_DIR/uninstall.sh"
    
    # Create update script
    cat > "$PROJECT_DIR/update.sh" << 'EOF'
#!/bin/bash

# MikroTik VPN Management System - Update Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="/opt/mikrotik-vpn"

echo -e "${BLUE}Updating MikroTik VPN Management System...${NC}"

# Backup current configuration
echo -e "${YELLOW}Creating backup...${NC}"
"$PROJECT_DIR/backup.sh"

# Update system packages
echo -e "${YELLOW}Updating system packages...${NC}"
apt-get update -y
apt-get upgrade -y

# Update OpenVPN if needed
echo -e "${YELLOW}Checking OpenVPN updates...${NC}"
apt-get install --only-upgrade openvpn -y

echo -e "${GREEN}Update completed successfully!${NC}"
echo -e "${YELLOW}Please restart the system if kernel updates were installed.${NC}"
EOF

    chmod +x "$PROJECT_DIR/update.sh"
    
    # Create status script
    cat > "$PROJECT_DIR/status.sh" << 'EOF'
#!/bin/bash

# MikroTik VPN Management System - Status Script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_DIR="/opt/mikrotik-vpn"

echo -e "${CYAN}=== MikroTik VPN Management System Status ===${NC}"
echo ""

# Check OpenVPN status
if systemctl is-active --quiet openvpn@server; then
    echo -e "${GREEN}✓ OpenVPN Server: Running${NC}"
else
    echo -e "${RED}✗ OpenVPN Server: Stopped${NC}"
fi

# Check project directory
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${GREEN}✓ Project Directory: Exists${NC}"
else
    echo -e "${RED}✗ Project Directory: Missing${NC}"
fi

# Count configured routers
if [ -d "$PROJECT_DIR/routers" ]; then
    router_count=$(ls "$PROJECT_DIR/routers"/router*.conf 2>/dev/null | wc -l)
    echo -e "${BLUE}Configured Routers: $router_count${NC}"
else
    echo -e "${YELLOW}Configured Routers: 0 (routers directory missing)${NC}"
fi

# Check system resources
echo ""
echo -e "${CYAN}=== System Resources ===${NC}"
echo -e "${BLUE}Disk Usage: $(df -h / | awk 'NR==2 {print $5}')${NC}"
echo -e "${BLUE}Memory Usage: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')${NC}"
echo -e "${BLUE}Load Average: $(uptime | awk -F'load average:' '{print $2}')${NC}"

# Check OpenVPN connections
echo ""
echo -e "${CYAN}=== OpenVPN Connections ===${NC}"
if [ -f "/var/log/openvpn/status.log" ]; then
    echo -e "${BLUE}Active Connections:${NC}"
    grep -E "^OpenVPN CLIENT LIST|^ROUTING TABLE|^GLOBAL STATS" /var/log/openvpn/status.log || echo "No active connections"
else
    echo -e "${YELLOW}Status log not found${NC}"
fi
EOF

    chmod +x "$PROJECT_DIR/status.sh"
    
    log "Utility scripts created successfully"
}

# Function to create systemd service for auto-start
create_systemd_service() {
    log "Creating systemd service for auto-start..."
    
    cat > /etc/systemd/system/mikrotik-vpn.service << 'EOF'
[Unit]
Description=MikroTik VPN Management System
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecStop=/bin/true

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable mikrotik-vpn.service
    
    log "Systemd service created"
}

# Function to create symbolic links
create_symbolic_links() {
    log "Creating symbolic links..."
    
    # Create symbolic links in /usr/local/bin for easy access
    ln -sf "$PROJECT_DIR/menu.sh" /usr/local/bin/mikrotik-vpn
    ln -sf "$PROJECT_DIR/status.sh" /usr/local/bin/mikrotik-status
    ln -sf "$PROJECT_DIR/backup.sh" /usr/local/bin/mikrotik-backup
    ln -sf "$PROJECT_DIR/monitor.sh" /usr/local/bin/mikrotik-monitor
    
    log "Symbolic links created"
}

# Function to create initial configuration
create_initial_config() {
    log "Creating initial configuration..."
    
    # Create a basic configuration file
    cat > "$PROJECT_DIR/config/system.conf" << 'EOF'
# MikroTik VPN Management System Configuration
# This file contains system-wide configuration settings

# OpenVPN Settings
OPENVPN_PORT=1194
OPENVPN_PROTOCOL=udp
VPN_NETWORK=10.8.0.0/24
VPN_MASK=255.255.255.0

# Security Settings
CIPHER=AES-256-CBC
AUTH=SHA256
TLS_VERSION_MIN=1.2

# Logging Settings
LOG_LEVEL=3
LOG_FILE=/var/log/openvpn/openvpn.log
STATUS_LOG=/var/log/openvpn/status.log

# Backup Settings
BACKUP_RETENTION_DAYS=30
BACKUP_DIR=/opt/mikrotik-vpn/backups

# Monitoring Settings
MONITOR_INTERVAL=60
CONNECTION_TIMEOUT=30
EOF

    chmod 600 "$PROJECT_DIR/config/system.conf"
    
    log "Initial configuration created"
}

# Function to display installation summary
display_summary() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}  Installation Completed Successfully!${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${BLUE}Project Directory:${NC} $PROJECT_DIR"
    echo -e "${BLUE}Main Menu:${NC} $PROJECT_DIR/menu.sh"
    echo -e "${BLUE}Quick Access:${NC} mikrotik-vpn"
    echo ""
    echo -e "${GREEN}Available Commands:${NC}"
    echo -e "  mikrotik-vpn     - Start the main menu"
    echo -e "  mikrotik-status  - Check system status"
    echo -e "  mikrotik-backup  - Create backup"
    echo -e "  mikrotik-monitor - Monitor connections"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  1. Run: $PROJECT_DIR/vps_setup.sh"
    echo -e "  2. Run: $PROJECT_DIR/menu.sh"
    echo -e "  3. Add your first MikroTik router"
    echo ""
    echo -e "${BLUE}Documentation:${NC} $PROJECT_DIR/README.md"
    echo -e "${BLUE}Uninstall:${NC} $PROJECT_DIR/uninstall.sh"
    echo ""
}

# Main installation function
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  MikroTik VPN Management System${NC}"
    echo -e "${CYAN}  Installation Script${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # Check requirements
    check_root
    check_requirements
    
    # Create project structure
    create_project_structure
    
    # Copy scripts
    copy_scripts
    
    # Create utility scripts
    create_utility_scripts
    
    # Create systemd service
    create_systemd_service
    
    # Create symbolic links
    create_symbolic_links
    
    # Create initial configuration
    create_initial_config
    
    # Display summary
    display_summary
    
    log "Installation completed successfully!"
}

# Run main function
main "$@" 