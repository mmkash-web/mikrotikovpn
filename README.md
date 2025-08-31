# MikroTik VPN Management System

A comprehensive system for managing OpenVPN connections between MikroTik routers and VPS servers.

## Project Overview

This project provides a complete solution for:
- Setting up OpenVPN servers on VPS instances
- Generating MikroTik router configurations
- Managing multiple router connections through a menu system
- Monitoring and maintaining VPN connections

## Project Structure

```
project/
├── vps_setup.sh              # VPS OpenVPN server setup script
├── mikrotik_config_generator.sh  # MikroTik configuration generator
├── menu.sh                   # Main menu system
├── install.sh                # Installation script
├── uninstall.sh              # Uninstallation script
├── backup.sh                 # Backup utility
├── monitor.sh                # Connection monitoring
├── config/
│   ├── openvpn.conf          # OpenVPN server configuration
│   ├── firewall.rules        # Firewall configuration
│   └── dhcp.conf            # DHCP configuration
├── routers/
│   ├── router1.conf
│   ├── router2.conf
│   └── ...
├── logs/
│   ├── vpn.log
│   └── system.log
├── backups/
│   └── ...
├── templates/
│   ├── mikrotik_template.txt
│   └── openvpn_template.conf
└── README.md
```

## Features

- **Automated VPS Setup**: Complete OpenVPN server installation and configuration
- **Router Management**: Add, remove, and manage multiple MikroTik routers
- **Configuration Generation**: Automatic generation of router-specific configs
- **Backup System**: Backup and restore configurations
- **Monitoring**: Real-time connection monitoring
- **Security**: Built-in security best practices
- **Logging**: Comprehensive logging system

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

# Run one-click installation
sudo ./quick_install.sh
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

## Security Considerations

- All certificates are generated with 2048-bit RSA keys
- Default port 1194 (UDP) for OpenVPN
- Firewall rules included for basic security
- Unique credentials for each router
- Certificate-based authentication

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
- Application logs: `./logs/`

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
- **`vps_setup.sh`** - OpenVPN server setup only
- **`menu.sh`** - Router management interface

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

Feel free to submit improvements and bug fixes.

---

**Note**: This is a basic implementation. For production use, consider additional security measures such as:
- Stronger encryption algorithms
- Additional firewall rules
- Intrusion detection systems
- Regular security audits 