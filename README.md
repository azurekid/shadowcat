![logo](/media/shadowcat.png?raw=true)

<div align="center">

Languages & Tools
=================

<img width="50" src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/powershell/powershell-original.svg" alt="PowerShell" title=PowerShell />
<br>
<br>

</div>

# ShadowCat - Windows Security Research Platform

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

## 🛠️ Tool Categories

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
# Download and run the enhanced installer
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/azurekid/shadowcat/main/BlackCat-Enhanced-Installer.ps1'))
```

### Custom Installation

```powershell
# Clone the repository
git clone https://github.com/azurekid/shadowcat.git
cd shadowcat

# Install specific categories
.\BlackCat-Enhanced-Installer.ps1 -ConfigFiles "configs\blackcat-redteam-tools.json"

# Install with specific profile level
.\BlackCat-Enhanced-Installer.ps1 -ConfigFiles "configs\blackcat-professional-profile.json" -InstallLevel professional

# Dry run to preview installation
.\BlackCat-Enhanced-Installer.ps1 -ConfigFiles "configs\blackcat-web-tools.json" -DryRun
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
├── 📄 BlackCat-Enhanced-Installer.ps1      # Main installation script
├── 📄 BlackCat-ConfigManager.ps1           # Configuration management
├── 📄 BlackCat-Modular-Guide.md            # Detailed installation guide
├── 📁 configs/                             # Tool configuration files
│   ├── shadowcat-redteam-tools.json        # Red team frameworks
│   ├── shadowcat-osint-tools.json          # OSINT and reconnaissance
│   ├── shadowcat-web-tools.json            # Web application testing
│   ├── shadowcat-mobile-tools.json         # Mobile security testing
│   ├── shadowcat-forensics-tools.json      # Digital forensics
│   ├── shadowcat-essential-tools.json      # Core utilities
│   ├── shadowcat-lite-profile.json         # Lightweight installation
│   └── shadowcat-professional-profile.json # Complete toolset
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

- **[Modular Installation Guide](BlackCat-Modular-Guide.md)**: Comprehensive setup instructions
- **[Configuration Reference](configs/)**: Details on all available tool configurations
- **[Security Guidelines](SECURITY.md)**: Security best practices and reporting

### 💬 Getting Help

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