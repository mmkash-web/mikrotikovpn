#!/bin/bash

# MikroTik VPN Management System - Domain Manager

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Get current VPS IP
get_current_vps_ip() {
    curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'
}

# Check domain resolution
check_domain_resolution() {
    local domain=$1
    nslookup "$domain" 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}'
}

# Show DNS setup instructions
show_dns_instructions() {
    local domain=$1
    local vps_ip=$2
    
    echo -e "\n${BLUE}DNS Configuration for: $domain${NC}"
    echo -e "VPS IP: $vps_ip"
    echo ""
    echo -e "${YELLOW}Create this A record in your DNS provider:${NC}"
    echo -e "  Type: A"
    echo -e "  Name: $domain"
    echo -e "  Value: $vps_ip"
    echo -e "  TTL: 300"
    echo ""
    echo -e "${YELLOW}Wait 5-60 minutes for DNS propagation${NC}"
}

# Verify domain configuration
verify_domain_config() {
    local domain=$1
    local current_ip=$(get_current_vps_ip)
    local domain_ip=$(check_domain_resolution "$domain")
    
    echo -e "\n${BLUE}Verifying: $domain${NC}"
    echo -e "Current VPS IP: $current_ip"
    
    if [ -z "$domain_ip" ]; then
        echo -e "${RED}✗ Domain does not resolve${NC}"
        return 1
    fi
    
    echo -e "Domain resolves to: $domain_ip"
    
    if [ "$current_ip" = "$domain_ip" ]; then
        echo -e "${GREEN}✓ SUCCESS: Domain points to this VPS${NC}"
        return 0
    else
        echo -e "${RED}✗ ERROR: Domain points to different IP${NC}"
        return 1
    fi
}

# Main execution
case ${1:-help} in
    "setup")
        if [ -z "$2" ]; then
            echo "Usage: $0 setup <domain>"
            exit 1
        fi
        show_dns_instructions "$2" "$(get_current_vps_ip)"
        ;;
    "verify")
        if [ -z "$2" ]; then
            echo "Usage: $0 verify <domain>"
            exit 1
        fi
        verify_domain_config "$2"
        ;;
    "help"|"-h"|"--help"|"")
        echo -e "${BLUE}Usage:${NC} $0 <command> [domain]"
        echo ""
        echo -e "${BLUE}Commands:${NC}"
        echo -e "  setup <domain>    - Show DNS setup instructions"
        echo -e "  verify <domain>   - Verify domain configuration"
        echo -e "  help              - Show this help"
        echo ""
        echo -e "${BLUE}Examples:${NC}"
        echo -e "  $0 setup remote.netbill.site"
        echo -e "  $0 verify remote.netbill.site"
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac 