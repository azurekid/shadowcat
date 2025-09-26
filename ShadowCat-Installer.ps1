# ==============================================================================
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
        # Only show this warning for non-IEX mode
        Write-ShadowCatLog "No configuration files specified. Use -ShowAvailableConfigs to see options." -Level "Warning"
        return
    }

    Write-ShadowCatLog "Starting ShadowCat Installation..." -Level "Header"
    Write-ShadowCatLog "Install Level: $script:InstallLevel" -Level "Info"
    Write-ShadowCatLog "Install Path: $InstallPath" -Level "Info"
    Write-ShadowCatLog "Dry Run Mode: $script:DryRun" -Level "Info"
    Write-ShadowCatLog "Online Mode: $script:Online" -Level "Info"

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
Start-Installation -ConfigFiles $ConfigFiles -InstallPath $InstallPath