#!/bin/bash

# MikroTik VPN Management System - VPS Setup Script
# This script sets up OpenVPN server on a VPS for MikroTik router connections

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

# Create necessary directories
log "Creating project directories..."
mkdir -p /opt/mikrotik-vpn/{config,logs,backups,routers,templates}
mkdir -p /etc/openvpn/server
mkdir -p /var/log/openvpn

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update system packages
log "Updating system packages..."
apt-get update -y || error "Failed to update packages"

# Install required packages
log "Installing required packages..."
apt-get install -y openvpn easy-rsa openssl iptables-persistent netfilter-persistent || error "Failed to install packages"

# Generate Diffie-Hellman parameters
log "Generating Diffie-Hellman parameters (this may take a while)..."
openssl dhparam -out /etc/openvpn/server/dh2048.pem 2048 || error "Failed to generate DH parameters"

# Generate CA certificate and key
log "Generating CA certificate and key..."
openssl req -x509 -newkey rsa:2048 -nodes -keyout /etc/openvpn/server/ca.key -out /etc/openvpn/server/ca.crt -days 3650 -subj "/C=US/ST=State/L=Locality/O=MikroTikVPN/CN=CA" || error "Failed to generate CA certificate"

# Generate server certificate and key
log "Generating server certificate and key..."
openssl req -newkey rsa:2048 -nodes -keyout /etc/openvpn/server/server.key -out /etc/openvpn/server/server.csr -subj "/C=US/ST=State/L=Locality/O=MikroTikVPN/CN=server" || error "Failed to generate server certificate request"
openssl x509 -req -in /etc/openvpn/server/server.csr -CA /etc/openvpn/server/ca.crt -CAkey /etc/openvpn/server/ca.key -CAcreateserial -out /etc/openvpn/server/server.crt -days 3650 || error "Failed to sign server certificate"

# Set proper permissions
chmod 600 /etc/openvpn/server/*.key
chmod 644 /etc/openvpn/server/*.crt

# Create OpenVPN server configuration
log "Creating OpenVPN server configuration..."
cat > /etc/openvpn/server.conf << 'EOF'
# OpenVPN Server Configuration for MikroTik VPN Management System
port 1194
proto udp
dev tun
ca /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/server.crt
key /etc/openvpn/server/server.key
dh /etc/openvpn/server/dh2048.pem

# Security settings
cipher AES-256-CBC
auth SHA256
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384

# Network settings
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"

# Connection settings
keepalive 10 120
comp-lzo
persist-key
persist-tun

# Logging
status /var/log/openvpn/status.log
log-append /var/log/openvpn/openvpn.log
verb 3

# Security
user nobody
group nogroup
chroot /var/lib/openvpn

# Additional security
explicit-exit-notify 1
EOF

# Enable IP forwarding
log "Enabling IP forwarding..."
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p

# Configure firewall rules
log "Configuring firewall rules..."
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
iptables -A INPUT -p udp --dport 1194 -j ACCEPT
iptables -A INPUT -i tun0 -j ACCEPT
iptables -A FORWARD -i tun0 -j ACCEPT
iptables -A FORWARD -o tun0 -j ACCEPT

# Save iptables rules
netfilter-persistent save || warning "Failed to save iptables rules"

# Create systemd service file
log "Creating systemd service..."
cat > /etc/systemd/system/openvpn@server.service << 'EOF'
[Unit]
Description=OpenVPN service for %I
After=network.target

[Service]
Type=notify
PrivateTmp=true
ExecStart=/usr/sbin/openvpn --config /etc/openvpn/%i.conf

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable OpenVPN
systemctl daemon-reload
systemctl enable openvpn@server
systemctl start openvpn@server

# Check if OpenVPN started successfully
if systemctl is-active --quiet openvpn@server; then
    log "OpenVPN server started successfully"
else
    error "Failed to start OpenVPN server"
fi

# Create monitoring script
log "Creating monitoring script..."
cat > /opt/mikrotik-vpn/monitor.sh << 'EOF'
#!/bin/bash
# Monitor OpenVPN connections

echo "=== OpenVPN Status ==="
systemctl status openvpn@server --no-pager -l

echo -e "\n=== Active Connections ==="
if [ -f /var/log/openvpn/status.log ]; then
    cat /var/log/openvpn/status.log
else
    echo "No status log found"
fi

echo -e "\n=== Recent Logs ==="
tail -20 /var/log/openvpn/openvpn.log
EOF

chmod +x /opt/mikrotik-vpn/monitor.sh

# Create backup script
log "Creating backup script..."
cat > /opt/mikrotik-vpn/backup.sh << 'EOF'
#!/bin/bash
# Backup OpenVPN configuration

BACKUP_DIR="/opt/mikrotik-vpn/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/openvpn_backup_$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_FILE" \
    /etc/openvpn/server \
    /etc/openvpn/server.conf \
    /opt/mikrotik-vpn/routers \
    /opt/mikrotik-vpn/config

echo "Backup created: $BACKUP_FILE"
EOF

chmod +x /opt/mikrotik-vpn/backup.sh

# Create configuration template
log "Creating MikroTik configuration template..."
cat > /opt/mikrotik-vpn/templates/mikrotik_template.txt << EOF
# MikroTik Router Configuration Template
# Generated on: $(date)

# OpenVPN Client Configuration
/interface ovpn-client add
    name=ovpn-client
    connect-to=$VPS_ADDRESS
    port=1194
    user={{USERNAME}}
    password={{PASSWORD}}
    mode=ip
    protocol=udp
    verify-server-certificate=no
    cipher=aes256
    auth=sha256

# Route Configuration (optional - uncomment if needed)
# /ip route add dst-address=0.0.0.0/0 gateway=ovpn-client

# Firewall rules (optional - uncomment if needed)
# /ip firewall filter add chain=forward action=accept src-address=10.8.0.0/24
EOF

# Get server IP address and domain
SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')

# Ask for domain name
echo -e "\n${BLUE}Domain Configuration${NC}"
echo "Current VPS IP: $SERVER_IP"
echo ""
echo -e "${YELLOW}Benefits of using a domain:${NC}"
echo -e "  ✓ Change VPS providers without reconfiguring routers"
echo -e "  ✓ More professional than IP addresses"
echo -e "  ✓ Easier SSL certificate management"
echo -e "  ✓ Load balancing and failover capabilities"
echo ""
read -p "Enter your domain name (e.g., remote.netbill.site) or press Enter to use IP only: " DOMAIN_NAME

if [ -n "$DOMAIN_NAME" ]; then
    echo -e "\n${GREEN}Domain name: $DOMAIN_NAME${NC}"
    echo -e "${YELLOW}IMPORTANT: Create an A record in your DNS:${NC}"
    echo -e "  $DOMAIN_NAME    A    $SERVER_IP"
    echo -e "  TTL: 300 (or lowest available)"
    echo ""
    echo -e "${BLUE}DNS Setup Instructions:${NC}"
    echo -e "  1. Go to your domain provider (Cloudflare, GoDaddy, etc.)"
    echo -e "  2. Find DNS management section"
    echo -e "  3. Add A record: $DOMAIN_NAME → $SERVER_IP"
    echo -e "  4. Wait for DNS propagation (5-60 minutes)"
    echo ""
    read -p "Press Enter after creating the DNS record..."
    
    # Verify domain resolution
    echo -e "\n${BLUE}Verifying domain configuration...${NC}"
    local attempts=0
    local max_attempts=5
    
    while [ $attempts -lt $max_attempts ]; do
        local domain_ip=$(nslookup "$DOMAIN_NAME" 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}')
        
        if [ -n "$domain_ip" ] && [ "$domain_ip" != "Address:" ]; then
            if [ "$domain_ip" = "$SERVER_IP" ]; then
                echo -e "${GREEN}✓ SUCCESS: Domain '$DOMAIN_NAME' correctly points to this VPS${NC}"
                VPS_ADDRESS="$DOMAIN_NAME"
                break
            else
                echo -e "${YELLOW}⚠ Domain resolves to $domain_ip (expected: $SERVER_IP)${NC}"
                echo -e "${YELLOW}DNS may still be propagating...${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ Domain does not resolve yet (attempt $((attempts + 1))/$max_attempts)${NC}"
        fi
        
        attempts=$((attempts + 1))
        if [ $attempts -lt $max_attempts ]; then
            echo -e "${BLUE}Waiting 30 seconds before retry...${NC}"
            sleep 30
        fi
    done
    
    if [ $attempts -eq $max_attempts ]; then
        echo -e "${YELLOW}⚠ Domain verification incomplete. You can:${NC}"
        echo -e "  1. Continue setup and verify later with: ./domain_manager.sh verify $DOMAIN_NAME"
        echo -e "  2. Check DNS settings and try again"
        echo -e "  3. Use IP address for now and add domain later"
        echo ""
        read -p "Continue with domain '$DOMAIN_NAME' anyway? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            VPS_ADDRESS="$DOMAIN_NAME"
            echo -e "${GREEN}Continuing with domain: $DOMAIN_NAME${NC}"
        else
            VPS_ADDRESS="$SERVER_IP"
            echo -e "${BLUE}Using IP address: $VPS_ADDRESS${NC}"
        fi
    fi
else
    VPS_ADDRESS="$SERVER_IP"
    echo -e "${BLUE}Using IP address only: $VPS_ADDRESS${NC}"
fi

# Save domain configuration for later use
if [ -n "$DOMAIN_NAME" ]; then
    mkdir -p /opt/mikrotik-vpn/config
    cat > /opt/mikrotik-vpn/config/domain.conf << EOF
# Domain Configuration
DOMAIN_NAME="$DOMAIN_NAME"
VPS_IP="$SERVER_IP"
VPS_ADDRESS="$VPS_ADDRESS"
CONFIGURED_DATE="$(date)"
EOF
    echo -e "${GREEN}✓ Domain configuration saved${NC}"
fi

# Create initial configuration summary
log "Creating configuration summary..."
cat > /opt/mikrotik-vpn/config/setup_summary.txt << EOF
MikroTik VPN Management System - Setup Summary
==============================================

Setup completed on: $(date)
Server IP: $SERVER_IP
VPS Address: $VPS_ADDRESS
OpenVPN Port: 1194
VPN Network: 10.8.0.0/24

Certificate Information:
- CA Certificate: /etc/openvpn/server/ca.crt
- Server Certificate: /etc/openvpn/server/server.crt
- Server Key: /etc/openvpn/server/server.key
- DH Parameters: /etc/openvpn/server/dh2048.pem

Important Files:
- OpenVPN Config: /etc/openvpn/server.conf
- Status Log: /var/log/openvpn/status.log
- OpenVPN Log: /var/log/openvpn/openvpn.log

Management Scripts:
- Monitor: /opt/mikrotik-vpn/monitor.sh
- Backup: /opt/mikrotik-vpn/backup.sh

Next Steps:
1. Run the menu system: /opt/mikrotik-vpn/menu.sh
2. Add your first MikroTik router
3. Configure the router with the generated settings

Security Notes:
- Certificates are valid for 10 years
- Default encryption: AES-256-CBC with SHA256
- Firewall rules have been configured
- IP forwarding is enabled
EOF

# Set proper permissions
chown -R root:root /opt/mikrotik-vpn
chmod -R 755 /opt/mikrotik-vpn
chmod 600 /opt/mikrotik-vpn/config/setup_summary.txt

# Final status check
log "Performing final status check..."
if systemctl is-active --quiet openvpn@server; then
    log "✓ OpenVPN server is running"
else
    error "✗ OpenVPN server is not running"
fi

if [ -f /etc/openvpn/server/ca.crt ]; then
    log "✓ Certificates generated successfully"
else
    error "✗ Certificate generation failed"
fi

if [ -f /etc/openvpn/server.conf ]; then
    log "✓ Configuration file created"
else
    error "✗ Configuration file creation failed"
fi

# Display summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  VPS Setup Completed Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${BLUE}Server Information:${NC}"
echo -e "  IP Address: $SERVER_IP"
echo -e "  VPS Address: $VPS_ADDRESS"
echo -e "  OpenVPN Port: 1194"
echo -e "  VPN Network: 10.8.0.0/24"
echo -e "\n${BLUE}Next Steps:${NC}"
echo -e "  1. Run the menu system: /opt/mikrotik-vpn/menu.sh"
echo -e "  2. Add your first MikroTik router"
echo -e "  3. Configure the router with generated settings"
echo -e "\n${BLUE}Useful Commands:${NC}"
echo -e "  Monitor connections: /opt/mikrotik-vpn/monitor.sh"
echo -e "  Backup configuration: /opt/mikrotik-vpn/backup.sh"
echo -e "  Check OpenVPN status: systemctl status openvpn@server"
echo -e "\n${YELLOW}Configuration summary saved to: /opt/mikrotik-vpn/config/setup_summary.txt${NC}"

log "VPS setup completed successfully!" 