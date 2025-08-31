#!/bin/bash

# MikroTik VPN Management System - Deployment Script
# This script helps users deploy the system after cloning from GitHub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  MikroTik VPN Management System${NC}"
echo -e "${CYAN}  Deployment Script${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Function to check system requirements
check_requirements() {
    echo -e "${BLUE}Checking system requirements...${NC}"
    
    # Check if running on Ubuntu/Debian
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            echo -e "${GREEN}✓ OS: $PRETTY_NAME${NC}"
        else
            echo -e "${YELLOW}⚠ OS: $PRETTY_NAME (Ubuntu/Debian recommended)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Could not determine OS${NC}"
    fi
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        echo -e "${GREEN}✓ Running as root${NC}"
    else
        echo -e "${RED}✗ Not running as root${NC}"
        echo -e "${YELLOW}Please run: sudo $0${NC}"
        exit 1
    fi
    
    # Check internet connectivity
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}✓ Internet connectivity${NC}"
    else
        echo -e "${RED}✗ No internet connectivity${NC}"
        exit 1
    fi
    
    echo ""
}

# Function to show deployment options
show_options() {
    echo -e "${CYAN}Deployment Options:${NC}"
    echo "  1. Full Installation (Recommended)"
    echo "     - Installs complete system"
    echo "     - Sets up OpenVPN server"
    echo "     - Creates system commands"
    echo ""
    echo "  2. VPS Setup Only"
    echo "     - Sets up OpenVPN server"
    echo "     - Generates certificates"
    echo "     - Configures firewall"
    echo ""
    echo "  3. Router Management Only"
    echo "     - Installs management tools"
    echo "     - No OpenVPN server setup"
    echo ""
    echo "  4. Custom Installation"
    echo "     - Choose specific components"
    echo ""
}

# Function to full installation
full_installation() {
    echo -e "${BLUE}Starting full installation...${NC}"
    
    # Make scripts executable
    chmod +x "$SCRIPT_DIR"/*.sh
    
    # Run installation
    if "$SCRIPT_DIR/install.sh"; then
        echo -e "${GREEN}✓ Installation completed${NC}"
        
        # Ask if user wants to run VPS setup
        echo ""
        read -p "Do you want to set up the OpenVPN server now? (y/N): " setup_vpn
        
        if [[ "$setup_vpn" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Setting up OpenVPN server...${NC}"
            "$SCRIPT_DIR/vps_setup.sh"
        fi
        
        echo ""
        echo -e "${GREEN}✓ Full installation completed!${NC}"
        echo -e "${BLUE}You can now use: mikrotik-vpn${NC}"
    else
        echo -e "${RED}Installation failed${NC}"
        exit 1
    fi
}

# Function to VPS setup only
vps_setup_only() {
    echo -e "${BLUE}Setting up VPS OpenVPN server...${NC}"
    
    # Make scripts executable
    chmod +x "$SCRIPT_DIR"/*.sh
    
    # Run VPS setup
    if "$SCRIPT_DIR/vps_setup.sh"; then
        echo -e "${GREEN}✓ VPS setup completed!${NC}"
    else
        echo -e "${RED}VPS setup failed${NC}"
        exit 1
    fi
}

# Function to router management only
router_management_only() {
    echo -e "${BLUE}Installing router management tools...${NC}"
    
    # Create project directory
    mkdir -p /opt/mikrotik-vpn/{config,logs,backups,routers,templates}
    
    # Copy management scripts
    cp "$SCRIPT_DIR/menu.sh" /opt/mikrotik-vpn/
    cp "$SCRIPT_DIR/mikrotik_config_generator.sh" /opt/mikrotik-vpn/
    cp "$SCRIPT_DIR/monitor.sh" /opt/mikrotik-vpn/
    cp "$SCRIPT_DIR/backup.sh" /opt/mikrotik-vpn/
    
    # Make executable
    chmod +x /opt/mikrotik-vpn/*.sh
    
    # Create symbolic links
    ln -sf /opt/mikrotik-vpn/menu.sh /usr/local/bin/mikrotik-vpn
    ln -sf /opt/mikrotik-vpn/monitor.sh /usr/local/bin/mikrotik-monitor
    ln -sf /opt/mikrotik-vpn/backup.sh /usr/local/bin/mikrotik-backup
    
    echo -e "${GREEN}✓ Router management tools installed!${NC}"
    echo -e "${BLUE}You can now use: mikrotik-vpn${NC}"
}

# Function to custom installation
custom_installation() {
    echo -e "${CYAN}Custom Installation Options:${NC}"
    echo ""
    
    local install_vps=false
    local install_router_mgmt=false
    local install_monitoring=false
    local install_backup=false
    
    read -p "Install OpenVPN server setup? (y/N): " install_vps_choice
    if [[ "$install_vps_choice" =~ ^[Yy]$ ]]; then
        install_vps=true
    fi
    
    read -p "Install router management tools? (y/N): " install_router_choice
    if [[ "$install_router_choice" =~ ^[Yy]$ ]]; then
        install_router_mgmt=true
    fi
    
    read -p "Install monitoring tools? (y/N): " install_monitoring_choice
    if [[ "$install_monitoring_choice" =~ ^[Yy]$ ]]; then
        install_monitoring=true
    fi
    
    read -p "Install backup tools? (y/N): " install_backup_choice
    if [[ "$install_backup_choice" =~ ^[Yy]$ ]]; then
        install_backup=true
    fi
    
    # Create project directory
    mkdir -p /opt/mikrotik-vpn/{config,logs,backups,routers,templates}
    
    # Install selected components
    if [ "$install_vps" = true ]; then
        echo -e "${BLUE}Installing VPS setup...${NC}"
        chmod +x "$SCRIPT_DIR/vps_setup.sh"
        cp "$SCRIPT_DIR/vps_setup.sh" /opt/mikrotik-vpn/
    fi
    
    if [ "$install_router_mgmt" = true ]; then
        echo -e "${BLUE}Installing router management...${NC}"
        chmod +x "$SCRIPT_DIR/menu.sh"
        chmod +x "$SCRIPT_DIR/mikrotik_config_generator.sh"
        cp "$SCRIPT_DIR/menu.sh" /opt/mikrotik-vpn/
        cp "$SCRIPT_DIR/mikrotik_config_generator.sh" /opt/mikrotik-vpn/
    fi
    
    if [ "$install_monitoring" = true ]; then
        echo -e "${BLUE}Installing monitoring tools...${NC}"
        chmod +x "$SCRIPT_DIR/monitor.sh"
        cp "$SCRIPT_DIR/monitor.sh" /opt/mikrotik-vpn/
    fi
    
    if [ "$install_backup" = true ]; then
        echo -e "${BLUE}Installing backup tools...${NC}"
        chmod +x "$SCRIPT_DIR/backup.sh"
        cp "$SCRIPT_DIR/backup.sh" /opt/mikrotik-vpn/
    fi
    
    # Create symbolic links for installed components
    if [ "$install_router_mgmt" = true ]; then
        ln -sf /opt/mikrotik-vpn/menu.sh /usr/local/bin/mikrotik-vpn
    fi
    
    if [ "$install_monitoring" = true ]; then
        ln -sf /opt/mikrotik-vpn/monitor.sh /usr/local/bin/mikrotik-monitor
    fi
    
    if [ "$install_backup" = true ]; then
        ln -sf /opt/mikrotik-vpn/backup.sh /usr/local/bin/mikrotik-backup
    fi
    
    echo -e "${GREEN}✓ Custom installation completed!${NC}"
}

# Main function
main() {
    check_requirements
    show_options
    
    echo ""
    read -p "Choose deployment option (1-4): " choice
    
    case $choice in
        1)
            full_installation
            ;;
        2)
            vps_setup_only
            ;;
        3)
            router_management_only
            ;;
        4)
            custom_installation
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Deployment Completed Successfully!${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${BLUE}Project installed to:${NC} /opt/mikrotik-vpn"
    echo -e "${BLUE}Documentation:${NC} /opt/mikrotik-vpn/README.md"
    echo ""
    echo -e "${GREEN}Thank you for using MikroTik VPN Management System!${NC}"
}

# Run main function
main "$@" 