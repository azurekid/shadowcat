# ============================================
# Project ShadowCat - Modular Security Toolkit
# Advanced installer with dependency management and overlap prevention
# ==============================================================================
# 
# Author: Project ShadowCat Team
# Version: 2.1.0
# License: MIT License
# ==============================================================================

param(
    [string[]]$ConfigFiles = @(),
    [string]$InstallPath = "C:\ShadowCat\SecurityTools",
    [ValidateSet("lite", "standard", "professional", "all")]
    [string]$InstallLevel = "standard",
    [switch]$SkipSystemConfig,
    [switch]$SkipPowershellProfile,
    [switch]$Verbose,
    [switch]$ShowAvailableConfigs,
    [switch]$DryRun,
    [switch]$ShowDependencies,
    [switch]$Online
)

# Script-scoped variables for tracking (used across modules)
$script:PSScriptRoot = $PSScriptRoot
$script:InstallLevel = $InstallLevel
$script:DryRun = $DryRun
$script:Verbose = $Verbose
$script:Online = $Online
$script:ToolCategories = @{}
$script:ProcessedConfigs = @{}
$script:InstalledTools = @{}
$script:SkippedTools = @{}
$script:DependencyChain = @()
$script:AutoSelectProfile = $true
$script:IsIEXMode = ($null -eq $PSScriptRoot -or $PSScriptRoot -eq '')

# Set a global variable to inform module files that we're in IEX mode
# This will be used to conditionally skip Export-ModuleMember commands
$Global:ShadowCatIEXMode = $script:IsIEXMode

# Identify execution context - local script or IEX
if ($script:IsIEXMode) {
    # Running via IEX - need to handle modules differently
    Write-Host "Detected execution via Invoke-Expression (IEX)" -ForegroundColor Yellow
    $script:PSScriptRoot = [System.IO.Path]::GetTempPath()
}

# Import modules
Write-Host "Loading ShadowCat modules..." -ForegroundColor Cyan
$modulesPath = Join-Path $script:PSScriptRoot "modules"
$moduleFiles = @(
    "ShadowCat-UI.ps1",
    "ShadowCat-Config.ps1", 
    "ShadowCat-PackageManagers.ps1",
    "ShadowCat-CustomTools.ps1"
)

# Create modules directory if needed (for IEX mode)
if ($script:IsIEXMode -and -not (Test-Path $modulesPath)) {
    New-Item -Path $modulesPath -ItemType Directory -Force | Out-Null
    Write-Host "  [*] Created temporary modules directory: $modulesPath" -ForegroundColor Yellow
}

# Base URL for downloading modules
$moduleBaseUrl = "https://raw.githubusercontent.com/azurekid/shadowcat/main/modules"

# Dot-source each module file
foreach ($moduleFile in $moduleFiles) {
    $modulePath = Join-Path $modulesPath $moduleFile
    
    # For IEX mode, download the module if it doesn't exist
    if ($script:IsIEXMode -and -not (Test-Path $modulePath)) {
        $moduleUrl = "$moduleBaseUrl/$moduleFile"
        try {
            Write-Host "  [*] Downloading module: $moduleFile" -ForegroundColor Yellow
            $moduleContent = Invoke-WebRequest -Uri $moduleUrl -UseBasicParsing | Select-Object -ExpandProperty Content
            
            # Remove all Export-ModuleMember lines that cause errors in IEX mode
            $lines = $moduleContent -split "`n" | Where-Object { $_ -notmatch 'Export-ModuleMember' }
            $moduleContent = $lines -join "`n"
            
            Set-Content -Path $modulePath -Value $moduleContent -Force
            Write-Host "  [✓] Downloaded module: $moduleFile (Modified for IEX compatibility)" -ForegroundColor Green
        }
        catch {
            Write-Host "  [✗] Failed to download module: $moduleFile" -ForegroundColor Red
            Write-Host "      $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
    
    # Now dot-source the module (whether local or downloaded)
    if (Test-Path $modulePath) {
        . $modulePath
        Write-Host "  [✓] Loaded module: $moduleFile" -ForegroundColor Green
    } 
    else {
        Write-Host "  [✗] Module not found: $moduleFile" -ForegroundColor Red
        Write-Host "      Please ensure all module files exist in: $modulesPath" -ForegroundColor Yellow
        exit 1
    }
}

# Main installation function
function Show-InstallLevelMenu {
    Write-Host "`nSelect Installation Level:" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host "1. Lite        - Minimal tools (core base + lite profile)" -ForegroundColor White
    Write-Host "2. Standard    - Essential security tools (core + standard tools)" -ForegroundColor White
    Write-Host "3. Professional- Complete toolkit (all tools + advanced features)" -ForegroundColor White
    Write-Host "4. All         - Everything available (all configs)" -ForegroundColor White
    Write-Host "0. Exit" -ForegroundColor Yellow
    Write-Host ""
    
    do {
        $choice = Read-Host "Enter your choice (0-4)"
        switch ($choice) {
            "1" { return "lite" }
            "2" { return "standard" }
            "3" { return "professional" }
            "4" { return "all" }
            "0" { exit 0 }
            default { Write-Host "Invalid choice. Please select 0-4." -ForegroundColor Red }
        }
    } while ($true)
}

function Show-ConfigSelectionMenu {
    param([string]$InstallLevel)
    
    Write-Host "`nSelect Configuration Profile:" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "Note: Core Base will be automatically included" -ForegroundColor Green
    Write-Host ""
    
    $configs = @{}
    $configPath = Join-Path $PSScriptRoot "configs"
    
    if (Test-Path $configPath) {
        $configFiles = Get-ChildItem -Path $configPath -Filter "*.json"
        $index = 1
        
        # Show the profile option first if it exists for this level
        $profileName = "shadowcat-$($InstallLevel)-profile.json"
        $profileConfig = $configFiles | Where-Object { $_.Name -eq $profileName }
        
        if ($profileConfig) {
            try {
                $content = Get-Content $profileConfig.FullName -Raw | ConvertFrom-Json
                $name = if ($content.metadata.name) { $content.metadata.name } else { $profileConfig.BaseName }
                $category = if ($content.metadata.category) { $content.metadata.category } else { "Profile" }
                
                Write-Host "$index. $name (Recommended)" -ForegroundColor Green
                Write-Host "   Category: $category | Level: $InstallLevel" -ForegroundColor Gray
                $configs[$index] = $profileConfig.Name
                $index++
            }
            catch {}
        }
        
        # Now add other appropriate configs
        foreach ($configFile in $configFiles) {
            # Skip core base and the already added profile
            if ($configFile.Name -eq "shadowcat-core-base.json" -or $configFile.Name -eq $profileName) {
                continue
            }
            
            try {
                $content = Get-Content $configFile.FullName -Raw | ConvertFrom-Json
                $configLevel = if ($content.metadata.installLevel) { $content.metadata.installLevel } else { "any" }
                $name = if ($content.metadata.name) { $content.metadata.name } else { $configFile.BaseName }
                $category = if ($content.metadata.category) { $content.metadata.category } else { "Other" }
                
                # Filter configs based on install level
                $showConfig = switch ($InstallLevel) {
                    "lite" { $configLevel -eq "lite" }
                    "standard" { $configLevel -in @("lite", "standard") }
                    "professional" { $configLevel -in @("lite", "standard", "professional") }
                    "all" { $true }
                    default { $true }
                }
                
                if ($showConfig) {
                    Write-Host "$index. $name" -ForegroundColor Yellow
                    Write-Host "   Category: $category | Level: $configLevel" -ForegroundColor Gray
                    $configs[$index] = $configFile.Name
                    $index++
                }
            }
            catch {
                Write-Host "$index. $($configFile.BaseName) [INVALID JSON]" -ForegroundColor Red
                $configs[$index] = $configFile.Name
                $index++
            }
        }
    }
    
    Write-Host "0. Back to Install Level Selection" -ForegroundColor Yellow
    Write-Host ""
    
    do {
        $choice = Read-Host "Enter your choice (0-$($configs.Count))"
        if ($choice -eq "0") {
            return $null
        }
        elseif ($configs.ContainsKey([int]$choice)) {
            return @($configs[[int]$choice])
        }
        else {
            Write-Host "Invalid choice. Please select 0-$($configs.Count)." -ForegroundColor Red
        }
    } while ($true)
}

function Start-InteractiveInstallation {
    param([string[]]$ConfigFiles, [string]$InstallPath)

    # If configs are already specified via command line, skip interactive mode
    if ($ConfigFiles.Count -gt 0) {
        Start-Installation -ConfigFiles $ConfigFiles -InstallPath $InstallPath
        return
    }

    Show-ShadowCatBanner

    # Interactive menu for config selection
    Write-ShadowCatLog "No configuration files specified. Starting interactive selection..." -Level "Info"
    
    do {
        $selectedLevel = Show-InstallLevelMenu
        $script:InstallLevel = $selectedLevel
        Write-ShadowCatLog "Selected install level: $selectedLevel" -Level "Info"
        
        if ($selectedLevel -eq "all") {
            # For "all", get all available configs
            $configPath = Join-Path $PSScriptRoot "configs"
            if (Test-Path $configPath) {
                $ConfigFiles = Get-ChildItem -Path $configPath -Filter "*.json" | Select-Object -ExpandProperty Name
                Write-ShadowCatLog "Selected all available configurations: $($ConfigFiles -join ', ')" -Level "Success"
                break
            }
        } else {
            # Look for profile config specific to this level first
            $profileName = "shadowcat-$($selectedLevel)-profile.json"
            $profilePath = Join-Path $PSScriptRoot "configs" $profileName
            
            if ((Test-Path $profilePath) -and ($script:AutoSelectProfile -ne $false)) {
                # If a matching profile exists for this level, use it
                $ConfigFiles = @($profileName)
                Write-ShadowCatLog "Auto-selected profile for $selectedLevel level: $profileName" -Level "Success"
                break
            } else {
                # Otherwise show the menu
                $selectedConfigs = Show-ConfigSelectionMenu -InstallLevel $selectedLevel
                if ($selectedConfigs) {
                    $ConfigFiles = $selectedConfigs
                    Write-ShadowCatLog "Selected configuration: $($ConfigFiles -join ', ')" -Level "Success"
                    break
                }
                # If user chose "0. Back", loop continues
            }
        }
    } while ($true)

    # Now proceed with the actual installation
    Start-Installation -ConfigFiles $ConfigFiles -InstallPath $InstallPath
}

function Start-Installation {
    param([string[]]$ConfigFiles, [string]$InstallPath)

    Show-ShadowCatBanner

    # Always use online mode for IEX installations
    if ($script:IsIEXMode) {
        Write-ShadowCatLog "Running in IEX mode - using online configuration" -Level "Info"
        $script:Online = $true
    }

    if ($ShowDependencies) {
        Write-ShadowCatLog "Dependency analysis mode - showing configuration dependencies" -Level "Info"
        $resolvedConfigs = Resolve-ConfigDependencies -ConfigFiles $ConfigFiles
        return
    }

    if ($script:Online -and $ConfigFiles.Count -eq 0) {
        Write-ShadowCatLog "No config files specified. Fetching all configs with installLevel 'standard' from GitHub..." -Level "Info"
        $configsApiUrl = "https://api.github.com/repos/azurekid/shadowcat/contents/configs"
        try {
            $configsList = Invoke-WebRequest -Uri $configsApiUrl -UseBasicParsing | ConvertFrom-Json
            $standardConfigs = @()
            foreach ($item in $configsList) {
                if ($item.name -like "*.json") {
                    $rawUrl = $item.download_url
                    $configContent = Invoke-WebRequest -Uri $rawUrl -UseBasicParsing | Select-Object -ExpandProperty Content
                    $configJson = $configContent | ConvertFrom-Json
                    if ($configJson.metadata.installLevel -eq "standard") {
                        $standardConfigs += $item.name
                    }
                }
            }
            if ($standardConfigs.Count -eq 0) {
                Write-ShadowCatLog "No configs with installLevel 'standard' found online." -Level "Error"
                return
            }
            Write-ShadowCatLog "Using configs: $($standardConfigs -join ', ')" -Level "Success"
            $ConfigFiles = $standardConfigs
        } catch {
            Write-ShadowCatLog "Failed to fetch configs from GitHub: $($_.Exception.Message)" -Level "Error"
            return
        }
    } elseif ($ConfigFiles.Count -eq 0 -and -not $script:IsIEXMode) {
        # Interactive menu for config selection
        Write-ShadowCatLog "No configuration files specified. Starting interactive selection..." -Level "Info"
        
        do {
            $selectedLevel = Show-InstallLevelMenu
            $script:InstallLevel = $selectedLevel
            Write-ShadowCatLog "Selected install level: $selectedLevel" -Level "Info"
            
            if ($selectedLevel -eq "all") {
                # For "all", get all available configs
                $configPath = Join-Path $PSScriptRoot "configs"
                if (Test-Path $configPath) {
                    $ConfigFiles = Get-ChildItem -Path $configPath -Filter "*.json" | Select-Object -ExpandProperty Name
                    Write-ShadowCatLog "Selected all available configurations: $($ConfigFiles -join ', ')" -Level "Success"
                    break
                }
            } else {
                $selectedConfigs = Show-ConfigSelectionMenu -InstallLevel $selectedLevel
                if ($selectedConfigs) {
                    $ConfigFiles = $selectedConfigs
                    Write-ShadowCatLog "Selected configuration: $($ConfigFiles -join ', ')" -Level "Success"
                    break
                }
                # If user chose "0. Back", loop continues
            }
        } while ($true)
    }

    Write-ShadowCatLog "Starting ShadowCat Installation..." -Level "Header"
    Write-ShadowCatLog "Install Level: $script:InstallLevel" -Level "Info"
    Write-ShadowCatLog "Install Path: $InstallPath" -Level "Info"
    Write-ShadowCatLog "Dry Run Mode: $script:DryRun" -Level "Info"
    Write-ShadowCatLog "Online Mode: $script:Online" -Level "Info"

    # Always ensure core base config is included
    $coreBaseConfig = "shadowcat-core-base.json"
    if ($ConfigFiles -notcontains $coreBaseConfig) {
        Write-ShadowCatLog "Adding required core base configuration" -Level "Info"
        $ConfigFiles += $coreBaseConfig
    }

    # Resolve dependencies
    $resolvedConfigs = Resolve-ConfigDependencies -ConfigFiles $ConfigFiles

    if ($resolvedConfigs.Count -eq 0) {
        Write-ShadowCatLog "No valid configurations to process" -Level "Error"
        return
    }

    # Process each configuration in dependency order
    foreach ($configFile in $resolvedConfigs) {
        $config = $null
        if ($script:Online) {
            # Use just the filename as the key for processed configs in online mode
            if ($script:ProcessedConfigs.ContainsKey($configFile)) {
                $config = $script:ProcessedConfigs[$configFile]
            }
        } else {
            $localKey = Join-Path (Join-Path $script:PSScriptRoot "configs") $configFile
            if ($script:ProcessedConfigs.ContainsKey($localKey)) {
                $config = $script:ProcessedConfigs[$localKey]
            }
        }

        if ($null -eq $config) { continue }

        Write-ShadowCatLog "Processing configuration: $($config.metadata.name)" -Level "Header"

        # Install packages based on configuration
        if ($config.chocolatey) {
            Install-ChocolateyPackages -packages $config.chocolatey.packages -configName $config.metadata.name
        }

        if ($config.scoop) {
            Install-ScoopPackages -scoopConfig $config.scoop -configName $config.metadata.name
        }

        if ($config.github) {
            Install-GitHubProjects -projects $config.github.projects -basePath $InstallPath -configName $config.metadata.name
        }

        if ($config.python) {
            Install-PythonPackages -packages $config.python.packages -configName $config.metadata.name
        }
    }

    # Create categorized tool folders after installation
    New-ToolCategoryFolders -BasePath (Join-Path $InstallPath "Tools")

    # Create shortcuts to installed tools in category folders
    New-ToolShortcuts -ToolsBasePath (Join-Path $InstallPath "Tools")

    # Set custom desktop background (change URL as desired)
    $wallpaperUrl = "https://raw.githubusercontent.com/azurekid/shadowcat/main/docs/shadowcat_wallpaper.jpg"
    Set-DesktopBackground -ImageUrl $wallpaperUrl

    # Show final summary
    Show-InstallationSummary
}

# Handle command line arguments
if ($ShowAvailableConfigs) {
    # Display available configurations
    Write-Host "`nAvailable Configuration Files:" -ForegroundColor Cyan
    $configPath = Join-Path $PSScriptRoot "configs"
    if (Test-Path $configPath) {
        $configs = Get-ChildItem -Path $configPath -Filter "*.json"
        foreach ($config in $configs) {
            try {
                $content = Get-Content $config.FullName -Raw | ConvertFrom-Json
                $level = if ($content.metadata.installLevel) { $content.metadata.installLevel } else { "any" }
                $name = if ($content.metadata.name) { $content.metadata.name } else { $config.BaseName }
                $desc = if ($content.metadata.description) { $content.metadata.description } else { "No description" }
                
                Write-Host "  [$level] $($config.Name)" -NoNewline -ForegroundColor Yellow
                Write-Host " - $name : $desc" -ForegroundColor White
            }
            catch {
                Write-Host "  [ERROR] $($config.Name) - Invalid JSON format" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  No local configs found at $configPath" -ForegroundColor Yellow
        Write-Host "  Online configs can be used with -Online switch" -ForegroundColor Cyan
    }
    Write-Host ""
    exit 0
}

# Start the installation
Start-InteractiveInstallation -ConfigFiles $ConfigFiles -InstallPath $InstallPath