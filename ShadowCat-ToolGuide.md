![Mr Robot fonts](https://see.fontimg.com/api/renderfont4/g123/eyJyIjoiZnMiLCJoIjoxMjUsInciOjE1MDAsImZzIjo4MywiZmdjIjoiI0VGMDkwOSIsImJnYyI6IiMxMTAwMDAiLCJ0IjoxfQ/cyBoIGEgZCBvIHcgYyBAIHQ=/mrrobot.png)

# ShadowCat Tool Guide

<div align="center">

[![License](https://img.shields.io/github/license/azurekid/shadowcat?color=blue&style=for-the-badge)](LICENSE.md)
[![Contributors](https://img.shields.io/github/contributors/azurekid/shadowcat?style=for-the-badge)](https://github.com/azurekid/shadowcat/contributors)
[![Stars](https://img.shields.io/github/stars/azurekid/shadowcat?style=for-the-badge)](https://github.com/azurekid/shadowcat/stargazers)

**A comprehensive guide to all tools installed by the ShadowCat Security Toolkit**

*This guide details all tools available in each installation level*

</div>

---

## Installation Levels Overview

ShadowCat offers multiple installation levels to meet different needs:

1. **Lite** - Minimal toolset for basic security testing
2. **Standard** - Medium toolkit with essential security and web testing tools
3. **Professional** - Advanced toolkit with all security categories including red team, OSINT, and forensics
4. **All** - Everything available, including specialized tools

Each level includes the core base components plus additional tools as described below.

---

## Core Base (Included in All Installations)

The Core Base provides essential tools required for all security operations:

### Development Tools
- **git** - Distributed version control system
- **python3** - Python programming language interpreter
- **7zip** - File archiver with high compression ratio
- **golang** - Go programming language

### Network Utilities
- **curl** - Command line tool for transferring data
- **wget** - Network downloader

This base provides the fundamental infrastructure needed for more specialized security tools.

---

## Lite Installation

The Lite installation includes the Core Base plus these additional tools:

### Network Tools
- **nmap** - Network discovery and security auditing tool
- **putty** - SSH and Telnet client
- **ncat** - Network connectivity tool (Netcat implementation)

### Python Packages
- **python-nmap** - Python library for Nmap

This level is ideal for basic security assessments and network reconnaissance.

---

## Standard Installation

The Standard installation layers the Lite toolset on top of the core base, then adds these standard-level configurations:

- Includes: `shadowcat-core-base`, `shadowcat-lite-profile`, and the standard tool packs listed below

### Essential Security Tools
- **nmap** - Network discovery and security auditing tool
- **wireshark** - Network protocol analyzer
- **burpsuite-free** - Web vulnerability scanner
- **hashcat** - Advanced password recovery tool
- **john** - Password cracking tool
- **sqlmap** - SQL injection and database takeover tool
- **mimikatz** - Windows credential extraction tool
- **powersploit** - PowerShell post-exploitation framework
- **responder** - LLMNR, NBT-NS and MDNS poisoner
- **bloodhound** - Active Directory security tool
- **remmina** - Remote desktop client
- **gobuster** - Directory/file & DNS busting tool

### Web Testing Tools
- **zap** - OWASP Zed Attack Proxy
- **nikto** - Web server scanner
- **ffuf** - Fast web fuzzer
- **wfuzz** - Web application fuzzer
- **dirsearch** - Web path scanner
- **sublist3r** - Subdomain enumeration tool
- **whatweb** - Web scanner to identify technologies
- **wpscan** - WordPress vulnerability scanner

These tools provide a solid foundation for network penetration testing and web application security assessments.

---

## Professional Installation

The Professional installation stacks every preceding level—core base, lite, and standard—before adding the professional-specific inventory below:

- Includes: Core + lite + standard + professional configurations (with all declared dependencies)

### All Standard Level Tools
- Includes all tools from Essential Security and Web Testing configurations

### Reverse Engineering Tools
- **ida-free** - Interactive disassembler
- **ghidra** - Software reverse engineering framework
- **radare2** - Reverse engineering framework
- **binary-ninja** - Binary analysis platform

### Red Team Tools
- **metasploit** - Penetration testing framework
- **docker-desktop** - Containerization platform for C2 frameworks
- **virtualbox** - Virtualization platform
- **empire** - PowerShell post-exploitation framework
- **covenant** - .NET command and control framework
- **impacket** - Network protocol toolkit
- **crackmapexec** - Swiss army knife for Windows/Active Directory environments

### OSINT Tools
- **recon-ng** - Web reconnaissance framework
- **holehe** - Check if email is used on different sites
- **twint** - Twitter intelligence tool
- **shodan-cli** - Shodan command-line interface
- **theHarvester** - Email, subdomain and name harvester
- **osrframework** - User research through different platforms
- **maltego** - Interactive data mining tool

### Mobile Security Tools
- **adb** - Android Debug Bridge
- **scrcpy** - Android device screen mirroring
- **apktool** - Android APK analysis tool
- **jadx** - Dex to Java decompiler

### Forensics Tools
- **volatility** - Advanced memory forensics framework
- **autopsy** - Digital forensics platform
- **sleuthkit** - Collection of command line tools for digital forensics
- **exiftool** - Read, write and edit metadata in files
- **binwalk** - Firmware analysis tool
- **regripper** - Windows registry analysis tool
- **rekall** - Memory forensic framework

This comprehensive toolkit is designed for professional security analysts, penetration testers, and red team operators.

---

## All Installation

The All level installs **every** configuration shipping with ShadowCat, combining core base, lite, standard, professional, and all specialty packs (red team, OSINT, mobile, forensics, etc.).

Choose this option when you want the most complete security testing environment with no exclusions.

---

## Tool Categories

ShadowCat organizes tools into categories for easier navigation:

- **Network Scanning** - Tools for network discovery and enumeration
- **Web Scanners** - Web application security testing tools
- **Password Cracking** - Tools for credential recovery and testing
- **Exploitation** - Frameworks and tools for exploiting vulnerabilities
- **Post-Exploitation** - Tools for use after gaining initial access
- **Forensics** - Digital forensics and incident response tools
- **OSINT** - Open Source Intelligence gathering tools
- **Reverse Engineering** - Tools for analyzing binary files
- **Mobile Security** - Tools for mobile application security testing
- **Development** - Programming languages and environments
- **Infrastructure** - Supporting tools and platforms

---

## Installation and Usage

To install ShadowCat with your chosen toolset:

1. Run the ShadowCat installer script
2. Select your desired installation level
3. Review the stacked configuration list that the installer assembles for your level (lite/standard/professional automatically include lower tiers)
4. Wait for the installation to complete

Once installed, tools are accessible via:
- Windows Start Menu
- Command line
- Tool category folders in the ShadowCat installation directory

For detailed usage guides for each tool, refer to the tool's documentation.

---

## Contributing and Requesting Tools

ShadowCat is a community-driven project that welcomes contributions and suggestions for new tools.

### Requesting New Tools

Have a favorite security tool that's not included? You can request it through:

1. **GitHub Issues**: Create a new issue at the [ShadowCat Issues page](https://github.com/azurekid/shadowcat/issues) with the label "tool request"
2. **Discussions**: Start a discussion in the [GitHub Discussions](https://github.com/azurekid/shadowcat/discussions) section

When requesting a tool, please include:
- Tool name and website/repository
- Brief description of its functionality
- Which installation level it should belong to
- Why it would be valuable to the toolkit

### Contributing Tools

Want to add a tool yourself? Here's how:

1. Fork the repository
2. Create a new configuration file or add to an existing one
3. Follow the JSON schema format for tool definitions
4. Test your changes with the installer
5. Submit a pull request with a clear description

All contributions are subject to review to ensure they meet quality and security standards.

---

<div align="center">

**ShadowCat Security Toolkit**  
*Developed by the Blackcat Security Team*

</div>