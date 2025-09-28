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

ShadowCat is a **comprehensive, modular Windows security platform** designed by and for the cybersecurity community. Built with penetration testers, red team operators, security researchers, and blue team defenders in mind, ShadowCat provides **147 professional security tools** across multiple specialized categories.

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
| **Red Team** | Command & Control, Post-Exploitation, Adversary Simulation | 23 | C2 frameworks, persistence, lateral movement |
| **OSINT** | Open Source Intelligence, Reconnaissance | 20 | Information gathering, social engineering, footprinting |
| **Web Security** | Web Application Testing, API Security | 19 | OWASP testing, SQLi, XSS, API fuzzing |
| **Mobile Security** | Android/iOS Testing, Mobile Forensics | 17 | Mobile app pentesting, device analysis |
| **Forensics** | Digital Investigation, Malware Analysis | 23 | Incident response, artifact analysis, reverse engineering |
| **Essential Tools** | Core Utilities, Networking, Debugging | 32 | Network analysis, debugging, system utilities |

---

## Quick Start

### Prerequisites
- **Windows 10/11** (Administrator privileges required)
- **PowerShell 5.1+** (PowerShell 7 recommended)
- **Internet connection** for package downloads
- **16GB+ RAM** recommended for full installation
- **50GB+ free disk space** for professional profile

### One-Click Installation

ShadowCat offers two versions of the installer:

#### Standard Installer (Modular)
```powershell
# Download and run the standard modular installer
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/azurekid/shadowcat/main/ShadowCat-Installer.ps1'))
```

#### High-Performance Installer (60-80% Faster! 🚀)
```powershell
# Download and run the high-performance parallel installer
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/azurekid/shadowcat/main/ShadowCat-HighPerformance-Installer.ps1'))
```

#### IEX-Compatible Installer (Self-contained)
```powershell
# Download and run the self-contained IEX-compatible installer
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/azurekid/shadowcat/main/ShadowCat-IEX-Installer.ps1'))
```

> **⚡ Performance Boost:** The high-performance installer uses parallel processing and batch operations to reduce installation time by **60-80%**. Professional profile (147 tools) installs in ~10-15 minutes instead of 45-60 minutes!

### Custom Installation

```powershell
# Clone the repository
git clone https://github.com/azurekid/shadowcat.git
cd shadowcat

# Standard installation
.\ShadowCat-Installer.ps1 -ConfigFiles "configs\shadowcat-redteam-tools.json"

# High-performance installation (60-80% faster)
.\ShadowCat-HighPerformance-Installer.ps1 -ConfigFiles "configs\shadowcat-redteam-tools.json" -MaxJobs 12

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
- **~12 essential tools**
- **~5GB disk space**
- **8GB+ RAM recommended**
- Core reconnaissance and basic testing tools
- Includes: `shadowcat-core-base` + lite toolset

### Standard Profile

*Balanced setup for most security professionals*
- **~40 tools across core categories**
- **~25GB disk space**  
- **12GB+ RAM recommended**
- Comprehensive testing capabilities
- Includes: Core + lite + standard toolsets

### Professional Profile

*Complete arsenal for advanced operations*
- **147 tools and frameworks**
- **~50GB disk space**
- **16GB+ RAM recommended**
- Full red team, forensics, and research capabilities
- Includes: Core + lite + standard + professional toolsets

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
- **Lite**: Core base + lite toolset (`installLevel: "lite"`)
- **Standard**: Core base + lite + standard toolsets (`installLevel: "standard"`)
- **Professional**: Core base + lite + standard + professional toolsets (`installLevel: "professional"`)
- **All**: Installs every available configuration (`-InstallLevel all`)

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
| `shadowcat-core-base.json` | Base | 8 tools | None | Required by all configs |
| `shadowcat-essential-tools.json` | Essential | 32 tools | Core base | All installations |
| `shadowcat-redteam-tools.json` | Red Team | 23 tools | Core base | Offensive operations |
| `shadowcat-osint-tools.json` | OSINT | 20 tools | Core base | Information gathering |
| `shadowcat-web-tools.json` | Web Security | 19 tools | Core base | Web penetration testing |
| `shadowcat-mobile-tools.json` | Mobile | 17 tools | Core base | Mobile security testing |
| `shadowcat-forensics-tools.json` | Forensics | 23 tools | Core base | Incident response |
| `shadowcat-lite-profile.json` | Profile | 4 tools | Multiple configs | Beginners, low resources |
| `shadowcat-professional-profile.json` | Profile | 5 tools | All category configs | Advanced users |

### 📊 Tool Distribution by Package Manager

ShadowCat's 147 unique tools are distributed across multiple package managers for optimal compatibility and functionality:

| Package Manager | Tools Count | Percentage | Examples |
|----------------|-------------|------------|----------|
| **GitHub Projects** | 69 tools | 47% | Specialized security tools, research projects, custom frameworks |
| **Chocolatey** | 37 tools | 25% | Windows applications, commercial tools, GUI applications |
| **Scoop** | 26 tools | 18% | Command-line utilities, portable applications, developer tools |  
| **Python** | 15 tools | 10% | Python libraries, security frameworks, analysis tools |

#### **Package Manager Benefits**

- **GitHub Projects**: Latest security research tools, community-driven projects, customizable frameworks
- **Chocolatey**: Stable Windows applications, automated updates, enterprise compatibility  
- **Scoop**: Lightweight installations, no admin rights needed, minimal system impact
- **Python**: Cross-platform libraries, extensive analysis capabilities, machine learning integration

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

## Modular Architecture

ShadowCat has been redesigned with a modular architecture for improved maintainability, flexibility, and performance. The installer is now split into specialized modules that handle different aspects of the installation process.

### Module Structure

| Module File | Description | Responsibility |
|-------------|-------------|----------------|
| `UI.ps1` | User interface functions | Handles all console output, progress bars, and user interaction |
| `Config.ps1` | Configuration processing | Manages JSON config loading, validation, and dependency resolution |
| `PackageManagers.ps1` | Package installation | Handles Chocolatey, Scoop, and other package managers |
| `CustomTools.ps1` | Custom tool installation | Manages GitHub repositories, Python packages, and custom installations |

### Installation Options

ShadowCat offers multiple installation methods to accommodate different environments:

1. **Standard Installation**: Uses the modular `ShadowCat-Installer.ps1` script which loads separate module files
2. **High-Performance Installation**: Uses the optimized `ShadowCat-HighPerformance-Installer.ps1` script with parallel processing (60-80% faster)
3. **IEX-Compatible Installation**: Uses the self-contained `ShadowCat-IEX-Installer.ps1` script that works in environments where module loading is restricted
4. **Local Installation**: Clones the repository and runs the installer locally
5. **Online Installation**: Fetches configuration files directly from GitHub using the `-Online` parameter

For maximum speed, use the high-performance installer which can complete professional profile installation (147 tools) in just 10-15 minutes!

For more detailed information, see the [BlackCat-Modular-Guide.md](BlackCat-Modular-Guide.md) file.

### Tool Organization

ShadowCat organizes installed tools in a structured directory layout for easy access:

```
C:\ShadowCat\SecurityTools\
├── Tools\
│   ├── Web Testing\        # Contains shortcuts to web testing tools
│   │   ├── gobuster.lnk
│   │   ├── ffuf.lnk
│   │   └── sqlmap.lnk
│   ├── Reconnaissance\     # Contains shortcuts to recon tools
│   │   ├── subfinder.lnk
│   │   └── amass.lnk
│   └── [Other Categories]\
└── [GitHub Projects]\      # Direct clones of GitHub repositories
```

**How it works:**
- **Package Manager Tools** (Chocolatey/Scoop): Shortcuts are created in category folders pointing to the actual executables
- **GitHub Projects**: Shortcuts created to open project directories or run executable files found within projects
- **Python Packages**: Shortcuts created to run Python modules with `python -m module_name`
- **Category Folders**: Only created for categories that have successfully installed tools

This approach provides both **organized access** through shortcuts and **direct access** to full project repositories.

---

## 📈 ShadowCat by the Numbers

### Total Toolkit Statistics

- **🎯 Total Unique Tools**: 147 professional security tools
- **📦 Package Managers**: 4 different installation methods (GitHub, Chocolatey, Scoop, Python)
- **📁 Configuration Files**: 9 modular JSON configurations
- **🏷️ Tool Categories**: 60+ specialized security categories
- **💾 Storage Requirements**: 5GB (lite) to 50GB (professional)
- **🧠 Memory Requirements**: 8GB (lite) to 16GB+ (professional)

### Top Tool Categories

| Category | Tool Count | Primary Focus |
|----------|------------|---------------|
| Active Directory | 9 tools | Enterprise security, domain attacks |
| Web Testing | 5 tools | Application security, OWASP testing |
| Dynamic Analysis | 4 tools | Runtime analysis, mobile testing |
| Command & Control | 4 tools | C2 frameworks, post-exploitation |
| Social Media Intelligence | 4 tools | OSINT, social engineering |
| Email Intelligence | 4 tools | Email analysis, breach hunting |
| File Analysis | 4 tools | Digital forensics, malware analysis |
| APK Analysis | 4 tools | Android security testing |

### Installation Profile Breakdown

| Profile | Unique Tools | Disk Space | RAM | Best For |
|---------|-------------|------------|-----|----------|
| **Core Base** | 8 tools | ~1GB | 4GB+ | Foundation requirements |
| **Lite** | ~12 tools | ~5GB | 8GB+ | Beginners, limited resources |
| **Standard** | ~40 tools | ~25GB | 12GB+ | Most security professionals |
| **Professional** | 147 tools | ~50GB | 16GB+ | Advanced operations |

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
├── 📄 ShadowCat-Installer.ps1              # Main modular installation script
├── 📄 ShadowCat-IEX-Installer.ps1          # Self-contained IEX-compatible installer
├── 📄 ShadowCat-ConfigManager.ps1          # Configuration management
├── 📄 BlackCat-Modular-Guide.md            # Detailed installation guide
├── 📁 modules/                             # Modular components
│   ├── UI.ps1                              # User interface functions
│   ├── Config.ps1                          # Configuration handling
│   ├── PackageManagers.ps1                 # Package manager operations
│   └── CustomTools.ps1                     # Custom tool installations
├── 📁 configs/                             # Tool configuration files
│   ├── shadowcat-redteam-tools.json        # Red team frameworks
│   ├── shadowcat-osint-tools.json          # OSINT and reconnaissance
│   ├── shadowcat-web-tools.json            # Web application testing
│   ├── shadowcat-mobile-tools.json         # Mobile security testing
│   ├── shadowcat-forensics-tools.json      # Digital forensics
│   ├── shadowcat-essential-tools.json      # Core utilities
│   ├── shadowcat-core-base.json            # Core base requirements
│   ├── shadowcat-lite-profile.json         # Lightweight installation
│   └── shadowcat-professional-profile.json # Complete toolset
├── 📁 docs/                                # Documentation folder
│   └── BlackCat-ConfigManager.md           # Config manager documentation
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

- **Tool Developers**: The creators of the 147+ security tools integrated into ShadowCat
- **Contributors**: Community members who submit configurations, bug reports, and improvements  
- **Security Community**: The broader infosec community whose feedback shapes ShadowCat's direction
- **Open Source Projects**: The foundational open-source tools that make security testing accessible

---

<div align="center">

**⭐ Star this repository if ShadowCat helps your security work!**

*Built by the security community, for the security community*

[🐛 Report Bug](https://github.com/azurekid/shadowcat/issues) • [💡 Request Feature](https://github.com/azurekid/shadowcat/issues) • [🤝 Contribute](CONTRIBUTING.md) • [💬 Discuss](https://github.com/azurekid/shadowcat/discussions)

</div>