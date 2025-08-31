#!/bin/bash

# MikroTik VPN Management System - Quick Install Script
# This script provides a one-click installation for users who clone from GitHub

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
echo -e "${CYAN}  Quick Install Script${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    echo -e "${YELLOW}Please run: sudo $0${NC}"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "$SCRIPT_DIR/install.sh" ]; then
    echo -e "${RED}Error: install.sh not found in current directory${NC}"
    echo -e "${YELLOW}Please make sure you're running this from the project root directory${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Running as root${NC}"
echo -e "${GREEN}✓ Project files found${NC}"
echo ""

# Make all scripts executable
echo -e "${BLUE}Making scripts executable...${NC}"
chmod +x "$SCRIPT_DIR"/*.sh
echo -e "${GREEN}✓ Scripts made executable${NC}"
echo ""

# Run the main installation
echo -e "${BLUE}Starting installation...${NC}"
if "$SCRIPT_DIR/install.sh"; then
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Installation Completed Successfully!${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo -e "  1. Run VPS setup: ${BLUE}$SCRIPT_DIR/vps_setup.sh${NC}"
    echo -e "  2. Start management menu: ${BLUE}$SCRIPT_DIR/menu.sh${NC}"
    echo -e "  3. Or use quick commands: ${BLUE}mikrotik-vpn${NC}"
    echo ""
    echo -e "${YELLOW}Note: The system has been installed to /opt/mikrotik-vpn${NC}"
    echo -e "${YELLOW}All scripts are now available as system commands${NC}"
else
    echo -e "${RED}Installation failed. Please check the error messages above.${NC}"
    exit 1
fi 