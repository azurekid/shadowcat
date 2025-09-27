# ShadowCat Modular Installation Guide

This guide provides detailed information about ShadowCat's modular architecture, installation options, and customization capabilities.

## Modular Architecture Overview

ShadowCat has been redesigned with a modular architecture that separates functionality into specialized components:

1. **Main Installer Script**: `ShadowCat-Installer.ps1` - Orchestrates the installation process
2. **Module Files**: Specialized PowerShell modules that handle specific aspects of installation
3. **Configuration Files**: JSON files defining tools, dependencies, and installation parameters
4. **IEX-Compatible Installer**: Self-contained version for environments with module loading restrictions

## Installation Methods

### Method 1: Standard Modular Installation

The standard installation uses the modular architecture where components are loaded from separate files.

```powershell
# Online installation using Invoke-Expression
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/azurekid/shadowcat/main/ShadowCat-Installer.ps1'))

# Local installation after cloning the repository
.\ShadowCat-Installer.ps1
```

This method loads the following modules during execution:
- `modules/UI.ps1`: User interface functions
- `modules/Config.ps1`: Configuration processing
- `modules/PackageManagers.ps1`: Package manager operations
- `modules/CustomTools.ps1`: Custom tool installations

### Method 2: IEX-Compatible Installation

For environments with restricted module loading capabilities, the IEX-compatible installer includes all modules in a single file.

```powershell
# IEX-compatible installation using Invoke-Expression
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/azurekid/shadowcat/main/ShadowCat-IEX-Installer.ps1'))
```

Benefits of the IEX-compatible installer:
- Works in environments with module loading restrictions
- No need to download additional module files
- Self-contained in a single script file
- Functionally identical to the modular version

### Method 3: Local Installation with Custom Options

```powershell
# Clone the repository
git clone https://github.com/azurekid/shadowcat.git
cd shadowcat

# Install with custom options
.\ShadowCat-Installer.ps1 -ConfigFiles "configs\blackcat-redteam-tools.json" -InstallLevel professional -Online
```

## Installation Parameters

Both installer versions support the same parameters:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-ConfigFiles` | JSON configuration files to use | `"configs\blackcat-osint-tools.json"` |
| `-InstallLevel` | Installation level (lite, standard, professional, all) | `-InstallLevel professional` |
| `-DryRun` | Preview without installing | `-DryRun` |
| `-Online` | Fetch configs from GitHub | `-Online` |
| `-Verbose` | Show detailed output | `-Verbose` |
| `-Force` | Force installation even if checks fail | `-Force` |
| `-NoExit` | Keep console open after completion | `-NoExit` |
| `-NoSplash` | Skip splash screen | `-NoSplash` |
| `-InstallPath` | Custom installation directory | `-InstallPath "D:\Tools"` |

## Tool Organization

ShadowCat creates an organized directory structure for easy tool access:

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

### How Tool Organization Works

- **Package Manager Tools** (Chocolatey/Scoop): Windows shortcuts (.lnk files) are created in category folders pointing to the actual executables in package manager directories
- **GitHub Projects**: Shortcuts created to open project directories in Explorer, or run executable files/Python scripts found within projects
- **Python Packages**: Shortcuts created to run Python modules using `python -m module_name`
- **Category Folders**: Only created for categories that have successfully installed tools
- **Shortcut Creation**: Happens automatically after successful tool installation

## Module Structure Details

### UI Module

The UI module handles all user interface elements, including:
- Console output formatting
- Progress bars and spinners
- Colored text and banners
- User prompts and confirmation dialogs

### Config Module

The Config module manages all configuration-related functions:
- Loading JSON configuration files
- Validating configuration syntax
- Resolving dependencies between configurations
- Preventing duplicate tool installations

### PackageManagers Module

The PackageManagers module handles package manager operations:
- Chocolatey package installation
- Scoop package installation
- NuGet package management
- Python pip packages
- Verification of package installations

### CustomTools Module

The CustomTools module manages custom tool installations:
- GitHub repository cloning
- Custom script execution
- Python virtual environments
- File and directory operations
- Tool shortcut creation
- Special tool configurations

## Development and Customization

### Creating Custom Modules

You can extend ShadowCat by creating custom modules:

1. Create a new PowerShell script file in the `modules` directory
2. Define your functions with the naming convention `YourModuleName-FunctionName`
3. Use `Export-ModuleMember -Function YourModuleName-*` to export functions
4. Import your module in the main installer script

### Creating Custom Configurations

Create your own tool configurations by following the JSON schema:

```json
{
  "metadata": {
    "name": "My Custom Tools",
    "version": "1.0.0",
    "description": "My personal security toolkit",
    "author": "Your Name",
    "category": "Custom",
    "installLevel": "standard",
    "dependencies": ["blackcat-core-base.json"]
  },
  "chocolatey": {
    "packages": [
      {
        "name": "tool-name",
        "description": "Tool description",
        "category": "Tool category",
        "required": true,
        "arguments": ""
      }
    ]
  }
}
```

## Troubleshooting

### Common Issues

1. **Module Loading Errors**
   - Use the IEX-compatible installer instead of the modular version
   - Check PowerShell execution policy (`Get-ExecutionPolicy`)
   - Ensure PowerShell 5.1+ is installed

2. **Configuration Errors**
   - Validate your JSON configuration files
   - Check for circular dependencies
   - Ensure toolIds are unique

3. **Package Installation Failures**
   - Check internet connectivity
   - Ensure Chocolatey is properly installed
   - Verify administrative privileges

4. **Shortcut Creation Issues**
   - Ensure Windows Script Host is enabled
   - Check that category folders exist
   - Verify tool executables are accessible

### Debugging

For detailed debugging information:

```powershell
# Enable verbose output
.\ShadowCat-Installer.ps1 -Verbose

# Check module loading
Import-Module -Name .\modules\UI.ps1 -Verbose
```

## Contributing to ShadowCat

We welcome contributions to ShadowCat's modular architecture:

1. **Module Improvements**: Enhance existing modules with new features
2. **New Modules**: Create specialized modules for additional functionality
3. **Configuration Files**: Create and share tool configurations
4. **Documentation**: Improve guides and examples
5. **Testing**: Help ensure modules work across different environments

For more information on contributing, see the [CONTRIBUTING.md](CONTRIBUTING.md) file.