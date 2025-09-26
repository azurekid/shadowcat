![Mr Robot fonts](https://see.fontimg.com/api/renderfont4/g123/eyJyIjoiZnMiLCJoIjoxMjUsInciOjE1MDAsImZzIjo4MywiZmdjIjoiI0VGMDkwOSIsImJnYyI6IiMxMTAwMDAiLCJ0IjoxfQ/cyBoIGEgZCBvIHcgYyBAIHQ=/mrrobot.png)

## ShadowCat - Windows Security Research Platform

<div align="center">

[![License](https://img.shields.io/github/license/azurekid/shadowcat?color=blue&style=for-the-badge)](LICENSE.md)
[![Contributors](https://img.shields.io/github/contributors/azurekid/shadowcat?style=for-the-badge)](https://github.com/azurekid/shadowcat/contributors)
[![Stars](https://img.shields.io/github/stars/azurekid/shadowcat?style=for-the-badge)](https://github.com/azurekid/shadowcat/stargazers)
[![Issues](https://img.shields.io/github/issues/azurekid/shadowcat?style=for-the-badge)](https://github.com/azurekid/shadowcat/issues)

**A community-driven Windows-based penetration testing, red teaming, and security research toolkit**

*Empowering security professionals with a comprehensive, modular toolset for ethical hacking and defensive security operations*

</div>

---

## What is ShadowCat?

ShadowCat is a **comprehensive, modular Windows security platform** designed by and for the cybersecurity community. Built with penetration testers, red team operators, security researchers, and blue team defenders in mind, ShadowCat provides **300+ professional security tools** across multiple specialized categories.

### Key Features

- **Modular Architecture**: Install only what you need with category-specific configurations
- **Automated Deployment**: One-click installation of entire security toolsets
- **Multi-Level Support**: Lite, Standard, and Professional installation profiles
- **Dependency Management**: Smart tool resolution prevents conflicts and duplicates
- **Community Driven**: Open-source project welcoming contributions from security professionals worldwide
- **Customizable**: Create and share your own tool configurations

---

## Tool Categories

ShadowCat organizes security tools into specialized categories for different use cases:

| Category | Description | Tools Count | Use Cases |
|----------|-------------|-------------|-----------|
| **Red Team** | Command & Control, Post-Exploitation, Adversary Simulation | 25+ | C2 frameworks, persistence, lateral movement |
| **OSINT** | Open Source Intelligence, Reconnaissance | 30+ | Information gathering, social engineering, footprinting |
| **Web Security** | Web Application Testing, API Security | 35+ | OWASP testing, SQLi, XSS, API fuzzing |
| **Mobile Security** | Android/iOS Testing, Mobile Forensics | 20+ | Mobile app pentesting, device analysis |
| **Forensics** | Digital Investigation, Malware Analysis | 40+ | Incident response, artifact analysis, reverse engineering |
| **Essential Tools** | Core Utilities, Networking, Debugging | 50+ | Network analysis, debugging, system utilities |

---

## Quick Start

### Prerequisites
- **Windows 10/11** (Administrator privileges required)
- **PowerShell 5.1+** (PowerShell 7 recommended)
- **Internet connection** for package downloads
- **16GB+ RAM** recommended for full installation
- **50GB+ free disk space** for professional profile

### One-Click Installation

```powershell
# Download and run the installer
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/azurekid/shadowcat/main/ShadowCat-Installer.ps1'))
```

### Custom Installation

```powershell
# Clone the repository
git clone https://github.com/azurekid/shadowcat.git
cd shadowcat

# Install specific categories
.\ShadowCat-Installer.ps1 -ConfigFiles "configs\shadowcat-redteam-tools.json"

# Install with specific profile level
.\ShadowCat-Installer.ps1 -ConfigFiles "configs\shadowcat-professional-profile.json" -InstallLevel professional

# Dry run to preview installation
.\ShadowCat-Installer.ps1 -ConfigFiles "configs\shadowcat-web-tools.json" -DryRun

# Online installation (fetch config from GitHub main branch)
.\ShadowCat-Installer.ps1 -ConfigFiles "shadowcat-core-base.json" -Online
```

---

## 📦 Installation Profiles

Choose the profile that matches your needs and system capabilities:

### Lite Profile

*Perfect for beginners and resource-constrained systems*
- **~50 essential tools**
- **~5GB disk space**
- **8GB+ RAM recommended**
- Core reconnaissance and basic testing tools

### Standard Profile

*Balanced setup for most security professionals*
- **~150 tools across all categories**
- **~25GB disk space**  
- **12GB+ RAM recommended**
- Comprehensive testing capabilities

### Professional Profile

*Complete arsenal for advanced operations*
- **300+ tools and frameworks**
- **~50GB disk space**
- **16GB+ RAM recommended**
- Full red team, forensics, and research capabilities

---

## Modular JSON Configuration System

ShadowCat's power lies in its **modular JSON-based configuration system** that allows for flexible, maintainable, and customizable tool installations. Each configuration file is a self-contained blueprint that defines tools, dependencies, and installation parameters.

### Configuration Architecture

#### **Configuration Types**
- **Category Configs**: Specialized tool collections (`shadowcat-redteam-tools.json`, `shadowcat-web-tools.json`)
- **Profile Configs**: Complete installation profiles (`shadowcat-professional-profile.json`, `shadowcat-lite-profile.json`)
- **Base Configs**: Core dependencies shared across configurations (`shadowcat-core-base.json`)

#### **JSON Structure**
```json
{
  "metadata": {
    "name": "Configuration Name",
    "version": "1.0.0",
    "description": "Detailed description of tools included",
    "author": "Author Name",
    "lastUpdated": "2024-09-26",
    "category": "RedTeam|OSINT|Web|Mobile|Forensics|Essential|Profile|Base",
    "installLevel": "lite|standard|professional",
    "dependencies": ["other-config-files.json"]
  },
  "chocolatey": {
    "packages": [
      {
        "name": "tool-name",
        "description": "Tool description",
        "category": "Tool category",
        "required": true,
        "installLevel": "lite|standard|professional", 
        "toolId": "unique-identifier",
        "arguments": "additional-install-args"
      }
    ]
  },
  "github": {
    "projects": [
      {
        "url": "https://github.com/author/repo",
        "destination": "Tools\\RepoName",
        "description": "GitHub project description",
        "category": "Tool category",
        "installLevel": "lite|standard|professional",
        "toolId": "unique-identifier"
      }
    ]
  }
}
```

### Key Configuration Features

#### ** Dependency Resolution**
- Configurations can declare dependencies on other config files
- The installer automatically resolves and merges dependency chains
- Prevents circular dependencies and ensures proper installation order
- Example: Professional profile depends on core base, essential tools, and specialized categories

#### ** Duplicate Prevention**
- Each tool has a unique `toolId` that prevents duplicate installations
- Tools referenced in multiple configs are installed only once
- Shared dependencies (Python, Git, etc.) are centralized in base configurations

#### ** Multi-Level Installation**
- **Lite**: Essential tools only (`installLevel: "lite"`)
- **Standard**: Balanced toolset (`installLevel: "standard"`) 
- **Professional**: Complete arsenal (`installLevel: "professional"`)
- **All**: Install everything regardless of level (`-InstallLevel all`)

#### ** Custom Configuration Creation**
Create your own configurations by following the JSON schema:

```powershell
# Example: Create a custom DFIR (Digital Forensics & Incident Response) config
{
  "metadata": {
    "name": "Custom DFIR Toolkit",
    "version": "1.0.0", 
    "description": "Specialized tools for digital forensics and incident response",
    "author": "Your Name",
    "category": "Custom",
    "installLevel": "standard",
    "dependencies": ["shadowcat-core-base.json"]
  },
  "chocolatey": {
    "packages": [
      {
        "name": "autopsy",
        "description": "Digital forensics platform",
        "category": "Forensics",
        "required": true,
        "installLevel": "standard",
        "toolId": "autopsy"
      }
    ]
  }
}
```

### Configuration Examples


#### **Quick Category Installation**
```powershell
# Install only OSINT tools
.\ShadowCat-Installer.ps1 -ConfigFiles "configs\shadowcat-osint-tools.json"

# Install web security tools at professional level  
.\ShadowCat-Installer.ps1 -ConfigFiles "configs\shadowcat-web-tools.json" -InstallLevel professional

# Online installation (fetch config from GitHub)
.\ShadowCat-Installer.ps1 -ConfigFiles "shadowcat-osint-tools.json" -Online
```

#### **Multi-Configuration Installation**
```powershell
# Install multiple categories simultaneously
.\ShadowCat-Installer.ps1 -ConfigFiles @(
  "configs\shadowcat-redteam-tools.json",
  "configs\shadowcat-forensics-tools.json",
  "configs\shadowcat-osint-tools.json"
)
```

#### **Profile-Based Installation**
```powershell
# Install complete professional profile (includes all dependencies)
.\ShadowCat-Installer.ps1 -ConfigFiles "configs\shadowcat-professional-profile.json"

# Lite installation for resource-constrained systems
.\ShadowCat-Installer.ps1 -ConfigFiles "configs\shadowcat-lite-profile.json"
```

### 🔍 Available Configurations

| Configuration File | Category | Tools | Dependencies | Best For |
|-------------------|----------|--------|--------------|----------|
| `shadowcat-core-base.json` | Base | Core utilities (Git, Python, Go) | None | Required by all configs |
| `shadowcat-essential-tools.json` | Essential | Network, debug, utilities | Core base | All installations |
| `shadowcat-redteam-tools.json` | Red Team | C2, post-exploitation | Core base | Offensive operations |
| `shadowcat-osint-tools.json` | OSINT | Reconnaissance, HUMINT | Core base | Information gathering |
| `shadowcat-web-tools.json` | Web Security | Web app testing, API fuzzing | Core base | Web penetration testing |
| `shadowcat-mobile-tools.json` | Mobile | Android/iOS testing | Core base | Mobile security testing |
| `shadowcat-forensics-tools.json` | Forensics | Digital investigation | Core base | Incident response |
| `shadowcat-lite-profile.json` | Profile | Essential tools only | Multiple configs | Beginners, low resources |
| `shadowcat-professional-profile.json` | Profile | Complete toolset | All category configs | Advanced users |

### Advanced Configuration Management

#### **Configuration Validation**
```powershell
# Validate configuration syntax before installation
. ./ShadowCat-ConfigManager.ps1 -Action validate -ConfigFile configs\your-config.json

# Preview what would be installed (dry run)
.\ShadowCat-Installer.ps1 -ConfigFiles "configs\shadowcat-web-tools.json" -DryRun
```

#### **Dependency Analysis & Tool Listing**
```powershell
# List all tools in a config
. ./ShadowCat-ConfigManager.ps1 -Action list -ConfigFile configs\shadowcat-redteam-tools.json

# Merge configs
. ./ShadowCat-ConfigManager.ps1 -Action merge-configs -MergeConfigs configs\one.json,configs\two.json -OutputConfig configs\merged.json
```

This modular approach ensures ShadowCat remains **maintainable**, **flexible**, and **community-friendly** while providing enterprise-grade tool management capabilities.

---

## Use Cases

### Red Team Operations

- **C2 Infrastructure**: Cobalt Strike, Metasploit, Empire, Covenant
- **Post-Exploitation**: PowerShell Empire, BloodHound, Mimikatz
- **Adversary Simulation**: Atomic Red Team, CALDERA integration
- **Persistence**: Registry manipulation, service creation, WMI

### Blue Team Defense

- **Incident Response**: Volatility, YARA, Sysmon analysis
- **Threat Hunting**: Sigma rules, threat intelligence feeds
- **Digital Forensics**: Autopsy, FTK Imager, memory analysis
- **Malware Analysis**: Remnux tools, sandboxing capabilities

### Security Research

- **Vulnerability Research**: Fuzzing frameworks, exploit development
- **Reverse Engineering**: IDA Pro alternatives, binary analysis
- **Network Analysis**: Wireshark, nmap, custom protocol analysis
- **Cryptographic Analysis**: Hash cracking, encryption testing

---

## Community & Contributions

ShadowCat thrives on community collaboration! We welcome contributions from security professionals worldwide.

### How to Contribute

1. **🐛 Report Issues**: Found a bug or have a feature request? [Open an issue](https://github.com/azurekid/shadowcat/issues)
2. **🔧 Submit Tool Configs**: Add your favorite security tools to the collection
3. **📖 Improve Documentation**: Help make ShadowCat more accessible
4. **🧪 Test & Validate**: Help ensure tools work across different Windows versions
5. **💡 Share Use Cases**: Document how you use ShadowCat in your security work

### Contribution Guidelines

- All tools must serve legitimate security testing purposes
- Follow responsible disclosure for any vulnerabilities found
- Ensure new tools don't conflict with existing ones
- Test configurations thoroughly before submitting
- Document tool usage and installation requirements

---

## Project Structure

```
shadowcat/
├── 📄 ShadowCat-Installer.ps1              # Main installation script
├── 📄 ShadowCat-ConfigManager.ps1          # Configuration management
├── 📄 shadowcat-Modular-Guide.md            # Detailed installation guide
├── 📁 configs/                             # Tool configuration files
│   ├── shadowcat-redteam-tools.json         # Red team frameworks
│   ├── shadowcat-osint-tools.json           # OSINT and reconnaissance
│   ├── shadowcat-web-tools.json             # Web application testing
│   ├── shadowcat-mobile-tools.json          # Mobile security testing
│   ├── shadowcat-forensics-tools.json       # Digital forensics
│   ├── shadowcat-essential-tools.json       # Core utilities
│   ├── shadowcat-lite-profile.json          # Lightweight installation
│   └── shadowcat-professional-profile.json  # Complete toolset
├── 📁 docs/                                # Documentation folder
│   └── ShadowCat-ConfigManager.md          # Config manager documentation
└── 📄 README.md                            # This file
```

---

## ⚠️ Ethical Use & Legal Disclaimer

**ShadowCat is designed exclusively for legitimate security testing and research purposes.**

### Authorized Uses
- Penetration testing with proper authorization
- Security research in controlled environments  
- Educational purposes and skill development
- Red team exercises with organizational approval
- Vulnerability assessments with client consent

### Prohibited Uses
- Unauthorized access to systems or networks
- Malicious attacks against third-party systems
- Any illegal or unethical activities
- Violation of local, national, or international laws

**Users are solely responsible for ensuring compliance with all applicable laws and regulations.**

---

## Support & Troubleshooting

### Documentation

- **[Modular Installation Guide](shadowcat-Modular-Guide.md)**: Comprehensive setup instructions
- **[Configuration Reference](configs/)**: Details on all available tool configurations
- **[Security Guidelines](SECURITY.md)**: Security best practices and reporting

### Getting Help

- **GitHub Issues**: [Report bugs or request features](https://github.com/azurekid/shadowcat/issues)
- **Discussions**: [Community Q&A and tool discussions](https://github.com/azurekid/shadowcat/discussions)
- **Wiki**: [Additional documentation and tutorials](https://github.com/azurekid/shadowcat/wiki)

### Common Issues

- **Antivirus Detection**: Some security tools may trigger AV alerts - this is expected
- **UAC Prompts**: Administrator privileges required for most security tools
- **Network Restrictions**: Corporate firewalls may block tool downloads
- **Disk Space**: Ensure sufficient space before running professional profiles

---

## License

This project is licensed under the **MIT License** - see the [LICENSE.md](LICENSE.md) file for details.

### Third-Party Tools
Individual security tools included in ShadowCat retain their original licenses. Users must comply with all applicable licenses when using these tools.

---

## Acknowledgments

Tools included in ShadowCat exists thanks to the incredible work of the cybersecurity community:

- **Tool Developers**: The creators of the 300+ security tools integrated into ShadowCat
- **Contributors**: Community members who submit configurations, bug reports, and improvements  
- **Security Community**: The broader infosec community whose feedback shapes ShadowCat's direction
- **Open Source Projects**: The foundational open-source tools that make security testing accessible

---

<div align="center">

**⭐ Star this repository if ShadowCat helps your security work!**

*Built by the security community, for the security community*

[🐛 Report Bug](https://github.com/azurekid/shadowcat/issues) • [💡 Request Feature](https://github.com/azurekid/shadowcat/issues) • [🤝 Contribute](CONTRIBUTING.md) • [💬 Discuss](https://github.com/azurekid/shadowcat/discussions)

</div>