# MikroTik VPN Management System

A comprehensive system for managing OpenVPN connections between MikroTik routers and VPS servers.

## Project Overview

This project provides a complete solution for:
- Setting up OpenVPN servers on VPS instances
- Generating MikroTik router configurations
- Managing multiple router connections through a menu system
- Monitoring and maintaining VPN connections
- **Domain-based VPN management** with automatic DNS verification
- **Enterprise-grade reliability** with health monitoring and auto-recovery
- **Professional deployment** with GitHub Actions and comprehensive documentation

### 🚀 **Key Benefits**
- **One-Click Installation**: Complete setup with a single command
- **Domain Flexibility**: Change VPS providers without reconfiguring routers
- **Automatic Recovery**: System recovers automatically after reboots
- **Professional Management**: Integrated menu system with domain management
- **Production Ready**: Health monitoring, backups, and logging included

## Project Structure

```
project/
├── vps_setup.sh              # VPS OpenVPN server setup script (with domain support)
├── mikrotik_config_generator.sh  # MikroTik configuration generator
├── menu.sh                   # Main menu system (with domain management)
├── domain_manager.sh         # Domain management and verification
├── health_check.sh           # System health monitoring
├── startup.sh                # Startup and recovery management
├── setup_monitoring.sh       # Automated monitoring setup
├── install.sh                # Installation script
├── uninstall.sh              # Uninstallation script
├── backup.sh                 # Backup utility
├── monitor.sh                # Connection monitoring
├── quick_install.sh          # One-click installation
├── deploy.sh                 # Interactive deployment
├── config/
│   ├── domain.conf           # Domain configuration
│   ├── setup_summary.txt     # System setup summary
│   └── system.conf           # System configuration
├── routers/
│   ├── router1.conf
│   ├── router1_commands.txt
│   ├── router2.conf
│   └── ...
├── logs/
│   ├── health.log
│   ├── startup.log
│   └── system.log
├── backups/
│   └── ...
├── templates/
│   ├── mikrotik_template.txt
│   └── openvpn_template.conf
├── .github/workflows/
│   └── test.yml              # GitHub Actions testing
├── LICENSE                   # MIT License
├── CONTRIBUTING.md           # Contribution guidelines
├── CHANGELOG.md              # Version history
└── README.md
```

## Features

- **Automated VPS Setup**: Complete OpenVPN server installation and configuration
- **Router Management**: Add, remove, and manage multiple MikroTik routers
- **Configuration Generation**: Automatic generation of router-specific configs
- **Backup System**: Backup and restore configurations with automated scheduling
- **Monitoring**: Real-time connection monitoring and health checks
- **Security**: Built-in security best practices with 2048-bit RSA certificates
- **Logging**: Comprehensive logging system with automatic rotation
- **Reliability**: Automatic recovery after reboots and system failures
- **Health Monitoring**: Continuous health checks with automatic repairs
- **Startup Services**: Ensures all services start automatically on boot
- **Domain Support**: Use domain names instead of IP addresses for flexible VPS management
- **Integrated Domain Management**: Built-in domain setup, verification, and management
- **Smart Configuration**: Automatic domain detection and usage in router configs
- **DNS Verification**: Automatic verification that domain points to VPS IP
- **Professional Deployment**: GitHub Actions, comprehensive documentation, and licensing

## Prerequisites

- Ubuntu/Debian VPS with root access
- MikroTik router with RouterOS
- Basic knowledge of networking and VPN concepts

## Quick Start

### Option 1: One-Click Installation (Recommended)
```bash
# Clone the repository
git clone https://github.com/mmkash-web/mikrotikovpn.git
cd mikrotikovpn

# Run one-click installation (includes all enhanced features)
sudo ./quick_install.sh
```

### Complete Installation Walkthrough

#### Step 1: VPS Setup
```bash
# 1. Clone the repository
git clone https://github.com/mmkash-web/mikrotikovpn.git
cd mikrotikovpn

# 2. Run one-click installation
sudo ./quick_install.sh

# 3. Setup VPS with domain support
sudo ./vps_setup.sh
# During setup, you'll be prompted for:
# - Domain name (e.g., remote.netbill.site)
# - DNS configuration instructions
# - Automatic domain verification
```

#### Step 2: Domain Configuration
```bash
# If you didn't setup domain during VPS setup, you can do it now:
sudo ./domain_manager.sh setup remote.netbill.site

# Or use the integrated menu system:
sudo ./menu.sh
# Select option 9: Domain Management
# Then option 1: Setup new domain
```

#### Step 3: Router Management
```bash
# Access the management menu
sudo ./menu.sh

# Add your first router:
# 1. Select option 1: Add MikroTik Router
# 2. System will automatically use configured domain
# 3. Enter router name (optional)
# 4. Configuration files will be generated

# Router configuration files will be created in:
# /opt/mikrotik-vpn/routers/router1_commands.txt
# /opt/mikrotik-vpn/routers/router1.conf
```

#### Step 4: Enhanced Monitoring (Optional)
```bash
# Setup automated monitoring and health checks
sudo ./setup_monitoring.sh

# This installs:
# - Health monitoring service (every 5 minutes)
# - Startup service (automatic recovery)
# - Automated backups (every 6 hours)
# - Log rotation and cleanup
```

### Option 2: Manual Installation
1. **Clone or download this project to your VPS**
   ```bash
   git clone https://github.com/mmkash-web/mikrotikovpn.git
   cd mikrotikovpn
   ```

2. **Make scripts executable and run installation:**
   ```bash
   chmod +x *.sh
   sudo ./install.sh
   ```

3. **Set up the VPS OpenVPN server:**
   ```bash
   sudo ./vps_setup.sh
   ```

4. **Start the management menu:**
   ```bash
   sudo ./menu.sh
   ```

### Option 3: Custom Deployment
```bash
# Clone and run deployment script
git clone https://github.com/mmkash-web/mikrotikovpn.git
cd mikrotikovpn
chmod +x *.sh
sudo ./deploy.sh
```

## Platform-Specific Instructions

### Linux/Unix Systems (VPS, Ubuntu, Debian)
The scripts are designed for Linux systems and will work out of the box after cloning:

```bash
git clone https://github.com/mmkash-web/mikrotikovpn.git
cd mikrotikovpn
chmod +x *.sh
sudo ./quick_install.sh
```

### Windows Development
If you're developing on Windows and want to contribute to the project:

```cmd
# Clone the repository
git clone https://github.com/mmkash-web/mikrotikovpn.git
cd mikrotikovpn

# Initialize git (if not already done)
git init
git add .
git commit -m "Initial commit: MikroTik VPN Management System"

# Connect to GitHub repository
git remote add origin https://github.com/mmkash-web/mikrotikovpn.git
git branch -M main
git push -u origin main
```

**Note:** The `chmod` command is not available on Windows. Scripts will be made executable when users clone to Linux systems.

### Windows Subsystem for Linux (WSL)
If you want to test the scripts on Windows using WSL:

```bash
# Install WSL if not already installed
wsl --install

# Clone and test in WSL
git clone https://github.com/mmkash-web/mikrotikovpn.git
cd mikrotikovpn
chmod +x *.sh
sudo ./quick_install.sh
```

## Detailed Setup Instructions

### 1. VPS Setup

The `vps_setup.sh` script will:
- Update system packages
- Install OpenVPN and required dependencies
- Generate SSL certificates
- Configure OpenVPN server
- Set up firewall rules
- Enable and start services
- **Domain Configuration**: Interactive domain setup with DNS verification
- **Automatic Verification**: Checks if domain points to VPS IP
- **Configuration Storage**: Saves domain settings for future use

### 2. Router Configuration

The `mikrotik_config_generator.sh` script will:
- Generate unique credentials for each router
- Create router-specific configuration files
- Provide copy-paste ready MikroTik commands

### 3. Menu System

The menu system provides:
- Add new routers
- Remove existing routers
- List all configured routers
- Backup configurations
- Monitor connections
- System status
- **Domain Management**: Setup, verify, change, and remove domains
- **Smart Router Addition**: Automatic domain detection and usage
- **Enhanced Status Display**: Shows domain information in system status

## Security Considerations

- All certificates are generated with 2048-bit RSA keys
- Default port 1194 (UDP) for OpenVPN
- Firewall rules included for basic security
- Unique credentials for each router
- Certificate-based authentication
- Domain-based connections for enhanced security
- Automatic certificate validation
- Secure configuration storage

## Troubleshooting

### Common Issues

1. **OpenVPN service not starting**
   - Check logs: `journalctl -u openvpn`
   - Verify certificate files exist
   - Check firewall settings

2. **Router cannot connect**
   - Verify VPS IP/domain is correct
   - Check port 1194 is open
   - Ensure router configuration is correct
   - Verify domain DNS resolution: `sudo ./domain_manager.sh verify your-domain.com`

3. **Connection drops**
   - Check VPS resources
   - Verify network stability
   - Review OpenVPN logs

4. **Script permission errors on Linux**
   - Run: `chmod +x *.sh`
   - Ensure you're running as root: `sudo ./script.sh`

5. **Windows development issues**
   - Use Git Bash or WSL for better compatibility
   - Scripts are designed for Linux deployment, not Windows execution

### Log Files

- OpenVPN logs: `/var/log/openvpn.log`
- System logs: `/var/log/syslog`
- Application logs: `/opt/mikrotik-vpn/logs/`
- Health monitoring logs: `/opt/mikrotik-vpn/logs/health.log`
- Startup logs: `/opt/mikrotik-vpn/logs/startup.log`
- Domain management logs: `/opt/mikrotik-vpn/logs/config_generator.log`

### Platform-Specific Solutions

#### Linux/Unix Systems
```bash
# Fix permission issues
chmod +x *.sh

# Check if running as root
whoami

# Run with sudo if needed
sudo ./script.sh
```

#### Windows Development
```cmd
# Use Git Bash for better compatibility
# Or install WSL for Linux environment
wsl --install

# In WSL, scripts work normally
wsl
git clone https://github.com/mmkash-web/mikrotikovpn.git
cd mikrotikovpn
chmod +x *.sh
sudo ./quick_install.sh
```

## Maintenance

### Regular Tasks

1. **Backup configurations:**
   ```bash
   ./backup.sh
   ```

2. **Monitor connections:**
   ```bash
   ./monitor.sh
   ```

3. **Update system:**
   ```bash
   apt update && apt upgrade
   ```

4. **Verify domain configuration:**
   ```bash
   sudo ./domain_manager.sh verify your-domain.com
   ```

5. **Check system health:**
   ```bash
   sudo ./health_check.sh check
   ```

### Enhanced Reliability Features

#### **Automatic Recovery After Reboots**
- **Startup Service**: Automatically ensures all VPN services are running
- **Health Monitoring**: Continuous health checks every 5 minutes
- **Auto-Repair**: Automatically fixes common issues without manual intervention

#### **Domain-Based VPN Connections**
- **Flexible VPS Management**: Use domain names instead of hardcoded IP addresses
- **Easy VPS Migration**: Change VPS providers without reconfiguring routers
- **Professional Setup**: More professional than IP-based connections
- **Load Balancing**: Point domain to different VPS servers as needed
- **Integrated Management**: Built-in domain setup and verification in menu system

```bash
# Setup domain-based VPN connection
sudo ./domain_manager.sh setup remote.netbill.site

# Verify domain configuration
sudo ./domain_manager.sh verify remote.netbill.site

# Use domain in router configurations
# Instead of: connect-to=192.168.1.100
# Use: connect-to=remote.netbill.site

# Or use the integrated menu system:
sudo ./menu.sh
# Then select option 9: Domain Management
```

#### **Setup Enhanced Monitoring**
```bash
# Install enhanced monitoring and reliability features
sudo ./setup_monitoring.sh

# This will install:
# ✓ Health monitoring service (runs every 5 minutes)
# ✓ Startup service (ensures services start on boot)
# ✓ Automated cron jobs for backups and monitoring
# ✓ Log rotation and cleanup
```

#### **Health Check Commands**
```bash
# Run manual health check
sudo ./health_check.sh check

# Start continuous monitoring
sudo ./health_check.sh monitor

# Setup as system service
sudo ./health_check.sh setup
```

#### **Startup Management**
```bash
# Run startup process manually
sudo ./startup.sh

# Setup startup service (runs automatically on boot)
sudo ./startup.sh setup
```

### Certificate Renewal

Certificates are valid for 10 years by default. To renew:
1. Stop OpenVPN service
2. Generate new certificates
3. Restart OpenVPN service

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review log files
3. Verify network connectivity
4. Ensure all prerequisites are met

## License

This project is provided as-is for educational and personal use.

## GitHub Deployment

This project is designed to work seamlessly with GitHub. After cloning, you can:

### Quick Start Commands
```bash
# Clone the repository
git clone https://github.com/mmkash-web/mikrotikovpn.git
cd mikrotikovpn

# One-command installation
sudo ./quick_install.sh

# Or use the deployment script for more options
sudo ./deploy.sh
```

### Available Scripts
- **`quick_install.sh`** - One-click installation (recommended for most users)
- **`deploy.sh`** - Interactive deployment with options
- **`install.sh`** - Full system installation
- **`vps_setup.sh`** - OpenVPN server setup with domain support
- **`menu.sh`** - Router management interface with domain management
- **`domain_manager.sh`** - Domain setup and verification
- **`health_check.sh`** - System health monitoring
- **`startup.sh`** - Startup and recovery management
- **`setup_monitoring.sh`** - Automated monitoring setup
- **`backup.sh`** - Backup and restore configurations
- **`monitor.sh`** - Connection monitoring and status
- **`uninstall.sh`** - Complete system removal

### GitHub Actions
This repository includes GitHub Actions for:
- Automated testing of shell scripts
- Syntax validation
- File permission checks
- Required file validation

## Git Repository Setup

### Initial Setup (First Time)
```bash
# Clone the repository
git clone https://github.com/mmkash-web/mikrotikovpn.git
cd mikrotikovpn

# Initialize git (if not already done)
git init
git add .
git commit -m "Initial commit: MikroTik VPN Management System"

# Connect to GitHub repository
git remote add origin https://github.com/mmkash-web/mikrotikovpn.git
git branch -M main
git push -u origin main
```

### Regular Updates
```bash
# Pull latest changes
git pull origin main

# Make your changes
# ... edit files ...

# Commit and push changes
git add .
git commit -m "Update: description of your changes"
git push origin main
```

### Working with Branches
```bash
# Create a new feature branch
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "Add: new feature description"

# Push branch to GitHub
git push origin feature/new-feature

# Create Pull Request on GitHub
# Then merge and delete branch
git checkout main
git pull origin main
git branch -d feature/new-feature
```

## Contributing

Feel free to submit improvements and bug fixes. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Development Setup
```bash
# Clone the repository
git clone https://github.com/mmkash-web/mikrotikovpn.git
cd mikrotikovpn

# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes and test
sudo ./quick_install.sh

# Commit and push
git add .
git commit -m "Add: description of your feature"
git push origin feature/your-feature-name

# Create a Pull Request on GitHub
```

---

## Version History

See [CHANGELOG.md](CHANGELOG.md) for a complete version history.

### Latest Version: 1.0.0
- **Initial Release**: Complete MikroTik VPN Management System
- **Domain Support**: Integrated domain management and verification
- **Enhanced Reliability**: Health monitoring and automatic recovery
- **Professional Features**: GitHub Actions, comprehensive documentation

---

**Note**: This is a production-ready implementation with enterprise-grade features. For additional security in high-risk environments, consider:
- Stronger encryption algorithms (AES-256-GCM)
- Additional firewall rules and intrusion detection
- Regular security audits and penetration testing
- Multi-factor authentication for management access
- Encrypted configuration storage 