# Contributing to MikroTik VPN Management System

Thank you for your interest in contributing to the MikroTik VPN Management System! This document provides guidelines and information for contributors.

## How to Contribute

### 1. Fork the Repository
1. Go to [https://github.com/mmkash-web/mikrotikovpn](https://github.com/mmkash-web/mikrotikovpn)
2. Click the "Fork" button to create your own copy

### 2. Clone Your Fork
```bash
git clone https://github.com/YOUR_USERNAME/mikrotikovpn.git
cd mikrotikovpn
```

### 3. Create a Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 4. Make Your Changes
- Follow the coding standards below
- Test your changes thoroughly
- Update documentation if needed

### 5. Commit Your Changes
```bash
git add .
git commit -m "Add: brief description of your changes"
```

### 6. Push to Your Fork
```bash
git push origin feature/your-feature-name
```

### 7. Create a Pull Request
1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Select the main branch as the target
4. Describe your changes clearly

## Coding Standards

### Shell Scripts
- Use `#!/bin/bash` shebang
- Follow [ShellCheck](https://www.shellcheck.net/) guidelines
- Use meaningful variable names
- Add proper error handling
- Include comments for complex logic

### File Naming
- Use lowercase with underscores: `script_name.sh`
- Make all scripts executable: `chmod +x script_name.sh`

### Documentation
- Update README.md for new features
- Add inline comments for complex functions
- Include usage examples

## Testing

Before submitting a pull request:

1. **Test on Ubuntu/Debian systems**
2. **Run shellcheck on your scripts:**
   ```bash
   shellcheck your_script.sh
   ```
3. **Test the installation process:**
   ```bash
   sudo ./install.sh
   ```
4. **Verify all functionality works**

## What to Contribute

### High Priority
- Bug fixes
- Security improvements
- Performance optimizations
- Better error handling

### Medium Priority
- New features
- Documentation improvements
- Code refactoring
- Additional monitoring tools

### Low Priority
- Cosmetic changes
- Minor text updates
- Additional examples

## Getting Help

If you need help or have questions:

1. **Check existing issues** for similar problems
2. **Create a new issue** with detailed information
3. **Join discussions** in existing pull requests

## Code of Conduct

- Be respectful and inclusive
- Focus on technical discussions
- Help others learn and improve
- Accept constructive feedback

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Thank You!

Your contributions help make this project better for everyone. Thank you for your time and effort! 