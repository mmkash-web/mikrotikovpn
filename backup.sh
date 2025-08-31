#!/bin/bash

# MikroTik VPN Management System - Backup Script
# This script creates comprehensive backups of the VPN management system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Project directory
PROJECT_DIR="/opt/mikrotik-vpn"
BACKUPS_DIR="$PROJECT_DIR/backups"

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

# Function to create backup
create_backup() {
    local backup_name="mikrotik_vpn_backup_$(date +%Y%m%d_%H%M%S)"
    local backup_file="$BACKUPS_DIR/$backup_name.tar.gz"
    
    log "Creating backup: $backup_name"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUPS_DIR"
    
    # Create temporary directory for backup
    local temp_dir=$(mktemp -d)
    
    # Copy project files
    if [ -d "$PROJECT_DIR" ]; then
        cp -r "$PROJECT_DIR" "$temp_dir/"
        log "Copied project files"
    else
        warning "Project directory not found"
    fi
    
    # Copy OpenVPN configuration
    if [ -d "/etc/openvpn" ]; then
        cp -r /etc/openvpn "$temp_dir/"
        log "Copied OpenVPN configuration"
    else
        warning "OpenVPN configuration not found"
    fi
    
    # Copy systemd service files
    if [ -f "/etc/systemd/system/openvpn@server.service" ]; then
        cp /etc/systemd/system/openvpn@server.service "$temp_dir/"
        log "Copied systemd service files"
    fi
    
    if [ -f "/etc/systemd/system/mikrotik-vpn.service" ]; then
        cp /etc/systemd/system/mikrotik-vpn.service "$temp_dir/"
    fi
    
    # Copy firewall rules
    if command -v iptables-save &> /dev/null; then
        iptables-save > "$temp_dir/iptables.rules"
        log "Saved firewall rules"
    fi
    
    # Create backup manifest
    cat > "$temp_dir/backup_manifest.txt" << EOF
MikroTik VPN Management System Backup
=====================================
Backup Date: $(date)
Backup Name: $backup_name
System: $(uname -a)
OpenVPN Version: $(openvpn --version 2>/dev/null | head -1 || echo "Not installed")

Included Files:
- Project directory: $PROJECT_DIR
- OpenVPN configuration: /etc/openvpn
- Systemd services: /etc/systemd/system/openvpn@server.service
- Firewall rules: iptables.rules

Backup Size: $(du -sh "$temp_dir" | cut -f1)
EOF
    
    # Create the backup archive
    if tar -czf "$backup_file" -C "$temp_dir" .; then
        log "Backup created successfully: $backup_file"
        
        # Get backup size
        local backup_size=$(du -h "$backup_file" | cut -f1)
        echo -e "${GREEN}✓ Backup completed successfully!${NC}"
        echo -e "${BLUE}Backup file:${NC} $backup_file"
        echo -e "${BLUE}Backup size:${NC} $backup_size"
        
        # Clean up temporary directory
        rm -rf "$temp_dir"
        
        return 0
    else
        error "Failed to create backup archive"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to list existing backups
list_backups() {
    echo -e "${CYAN}=== Existing Backups ===${NC}"
    
    if [ ! -d "$BACKUPS_DIR" ] || [ -z "$(ls -A "$BACKUPS_DIR" 2>/dev/null)" ]; then
        echo -e "${YELLOW}No backups found.${NC}"
        return
    fi
    
    local backup_count=0
    for backup in "$BACKUPS_DIR"/*.tar.gz; do
        if [[ -f "$backup" ]]; then
            local backup_name=$(basename "$backup")
            local backup_size=$(du -h "$backup" | cut -f1)
            local backup_date=$(stat -c %y "$backup" | cut -d' ' -f1)
            local backup_time=$(stat -c %y "$backup" | cut -d' ' -f2 | cut -d'.' -f1)
            
            echo -e "${GREEN}Backup $((++backup_count)):${NC}"
            echo -e "  ${BLUE}Name:${NC} $backup_name"
            echo -e "  ${BLUE}Size:${NC} $backup_size"
            echo -e "  ${BLUE}Date:${NC} $backup_date $backup_time"
            echo ""
        fi
    done
    
    echo -e "${BLUE}Total backups:${NC} $backup_count"
}

# Function to restore backup
restore_backup() {
    if [ $# -eq 0 ]; then
        echo -e "${YELLOW}Usage: $0 restore <backup_file>${NC}"
        return 1
    fi
    
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        error "Backup file not found: $backup_file"
    fi
    
    echo -e "${YELLOW}This will restore the system from backup.${NC}"
    echo -e "${YELLOW}This action cannot be undone!${NC}"
    read -p "Are you sure you want to continue? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Restore cancelled.${NC}"
        return 0
    fi
    
    log "Restoring from backup: $backup_file"
    
    # Create temporary directory for extraction
    local temp_dir=$(mktemp -d)
    
    # Extract backup
    if tar -xzf "$backup_file" -C "$temp_dir"; then
        log "Backup extracted successfully"
        
        # Stop services before restore
        systemctl stop openvpn@server 2>/dev/null || true
        
        # Restore project files
        if [ -d "$temp_dir/mikrotik-vpn" ]; then
            rm -rf "$PROJECT_DIR"
            mv "$temp_dir/mikrotik-vpn" "$PROJECT_DIR"
            log "Restored project files"
        fi
        
        # Restore OpenVPN configuration
        if [ -d "$temp_dir/openvpn" ]; then
            rm -rf /etc/openvpn
            mv "$temp_dir/openvpn" /etc/
            log "Restored OpenVPN configuration"
        fi
        
        # Restore systemd services
        if [ -f "$temp_dir/openvpn@server.service" ]; then
            cp "$temp_dir/openvpn@server.service" /etc/systemd/system/
            log "Restored systemd service"
        fi
        
        if [ -f "$temp_dir/mikrotik-vpn.service" ]; then
            cp "$temp_dir/mikrotik-vpn.service" /etc/systemd/system/
        fi
        
        # Restore firewall rules
        if [ -f "$temp_dir/iptables.rules" ]; then
            iptables-restore < "$temp_dir/iptables.rules"
            log "Restored firewall rules"
        fi
        
        # Reload systemd and restart services
        systemctl daemon-reload
        systemctl enable openvpn@server
        systemctl start openvpn@server
        
        # Clean up
        rm -rf "$temp_dir"
        
        echo -e "${GREEN}✓ Restore completed successfully!${NC}"
        log "System restored from backup"
        
    else
        error "Failed to extract backup"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to clean old backups
clean_old_backups() {
    local retention_days=${1:-30}
    
    echo -e "${YELLOW}This will remove backups older than $retention_days days.${NC}"
    read -p "Are you sure you want to continue? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Cleanup cancelled.${NC}"
        return 0
    fi
    
    log "Cleaning backups older than $retention_days days"
    
    local removed_count=0
    local current_time=$(date +%s)
    local cutoff_time=$((current_time - retention_days * 24 * 60 * 60))
    
    for backup in "$BACKUPS_DIR"/*.tar.gz; do
        if [[ -f "$backup" ]]; then
            local backup_time=$(stat -c %Y "$backup")
            if [ "$backup_time" -lt "$cutoff_time" ]; then
                rm "$backup"
                log "Removed old backup: $(basename "$backup")"
                removed_count=$((removed_count + 1))
            fi
        fi
    done
    
    echo -e "${GREEN}✓ Cleanup completed!${NC}"
    echo -e "${BLUE}Removed backups:${NC} $removed_count"
}

# Function to display backup statistics
show_backup_stats() {
    echo -e "${CYAN}=== Backup Statistics ===${NC}"
    
    if [ ! -d "$BACKUPS_DIR" ]; then
        echo -e "${YELLOW}Backup directory not found.${NC}"
        return
    fi
    
    local total_backups=0
    local total_size=0
    
    for backup in "$BACKUPS_DIR"/*.tar.gz; do
        if [[ -f "$backup" ]]; then
            total_backups=$((total_backups + 1))
            local size=$(stat -c %s "$backup")
            total_size=$((total_size + size))
        fi
    done
    
    echo -e "${BLUE}Total backups:${NC} $total_backups"
    echo -e "${BLUE}Total size:${NC} $(numfmt --to=iec $total_size)"
    
    if [ "$total_backups" -gt 0 ]; then
        local avg_size=$((total_size / total_backups))
        echo -e "${BLUE}Average backup size:${NC} $(numfmt --to=iec $avg_size)"
        
        # Show oldest and newest backup
        local oldest_backup=$(ls -t "$BACKUPS_DIR"/*.tar.gz 2>/dev/null | tail -1)
        local newest_backup=$(ls -t "$BACKUPS_DIR"/*.tar.gz 2>/dev/null | head -1)
        
        if [ -n "$oldest_backup" ]; then
            echo -e "${BLUE}Oldest backup:${NC} $(basename "$oldest_backup")"
        fi
        
        if [ -n "$newest_backup" ]; then
            echo -e "${BLUE}Newest backup:${NC} $(basename "$newest_backup")"
        fi
    fi
}

# Main function
main() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
    
    # Check command line arguments
    case ${1:-create} in
        "create")
            create_backup
            ;;
        "list")
            list_backups
            ;;
        "restore")
            restore_backup "$2"
            ;;
        "clean")
            clean_old_backups "$2"
            ;;
        "stats")
            show_backup_stats
            ;;
        "help"|"-h"|"--help")
            echo -e "${CYAN}MikroTik VPN Management System - Backup Script${NC}"
            echo ""
            echo -e "${BLUE}Usage:${NC} $0 [command] [options]"
            echo ""
            echo -e "${BLUE}Commands:${NC}"
            echo -e "  create    - Create a new backup (default)"
            echo -e "  list      - List existing backups"
            echo -e "  restore   - Restore from backup file"
            echo -e "  clean     - Clean old backups (default: 30 days)"
            echo -e "  stats     - Show backup statistics"
            echo -e "  help      - Show this help message"
            echo ""
            echo -e "${BLUE}Examples:${NC}"
            echo -e "  $0                    # Create backup"
            echo -e "  $0 list              # List backups"
            echo -e "  $0 restore backup.tar.gz  # Restore backup"
            echo -e "  $0 clean 7           # Clean backups older than 7 days"
            ;;
        *)
            error "Unknown command: $1. Use 'help' for usage information."
            ;;
    esac
}

# Run main function
main "$@" 