# ==============================================================================
# Project ShadowCat - Enhanced Modular Security Toolkit
# Advanced installer with dependency management and overlap prevention
# ==============================================================================
#
# Author: Project BlackCat Team
# Version: 2.0.0
# License: MIT License
# ==============================================================================

param(
    [string[]]$ConfigFiles = @(),
    [string]$InstallPath = "C:\ShadowCat\SecurityTools",
    [ValidateSet("lite", "standard", "professional", "all")]
    [string]$InstallLevel = "standard",
    [switch]$SkipSystemConfig,
    [switch]$SkipPowershellProfile,
    [switch]$Verbose = $true,
    [switch]$ShowAvailableConfigs,
    [switch]$DryRun,
    [switch]$ShowDependencies,
    [switch]$Online = $true
)

# Global variables for tracking
$Global:ToolCategories = @{}
$Global:ProcessedConfigs = @{}
$Global:InstalledTools = @{}
$Global:SkippedTools = @{}
$Global:DependencyChain = @()

# ShadowCat ASCII Art Banner
function Show-ShadowCatBanner {
    $banner = @"


    _____ _      /\_/\    _                _____      _
   / ____| |    ( o.o )  | |              / ____|    | |
  | (___ | |__   > ^ < __| | _____      _| |     ____| |_     /\_/\
   \___ \| '_ \ / _`  |/ _`  |/ _ \ \ /\ / / |    / _`  | __|   ( o.o )
   ____) | | | | (_| | (_| | (_) \ V  V /| |___| (_| | |_     > ^ <
  |_____/|_| |_|\__,_|\__,_|\___/ \_/\_/  \_____\__,_|\__|

"@
    Write-Host $banner -ForegroundColor Blue
    Write-Host "    [+] Install Level: $InstallLevel" -ForegroundColor Yellow
    Write-Host "    [+] Dependency Resolution: Enabled" -ForegroundColor Yellow
    Write-Host "    [+] Overlap Prevention: Active" -ForegroundColor Yellow
    Write-Host "    [+] Project ShadowCat - Elite Security Solutions" -ForegroundColor Yellow
    Write-Host ""
}

# logging
function Write-ShadowCatLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error", "Header", "Debug", "Dependency")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Level) {
        "Info"       { "[ShadowCat] [INFO]" }
        "Success"    { "[ShadowCat] [✓]" }
        "Warning"    { "[ShadowCat] [⚠]" }
        "Error"      { "[ShadowCat] [✗]" }
        "Header"     { "[ShadowCat] [>>>]" }
        "Debug"      { "[ShadowCat] [DBG]" }
        "Dependency" { "[ShadowCat] [DEP]" }
    }

    $color = switch ($Level) {
        "Info"       { "White" }
        "Success"    { "Green" }
        "Warning"    { "Yellow" }
        "Error"      { "Red" }
        "Header"     { "Cyan" }
        "Debug"      { "Gray" }
        "Dependency" { "Magenta" }
    }

    if ($Level -eq "Debug" -and -not $Verbose) { return }

    Write-Host "$timestamp $prefix $Message" -ForegroundColor $color
}

# Load configuration with enhanced validation
function Import-ShadowCatConfig {
    param([string]$ConfigPath)


    $fullPath = $ConfigPath
    $configContent = $null

    if ($Online) {
        # Download config from GitHub main branch
        $repoUrl = "https://raw.githubusercontent.com/azurekid/shadowcat/main/configs/$ConfigPath"
        Write-ShadowCatLog "Downloading config from GitHub: $repoUrl" -Level "Info"
        try {
            $configContent = Invoke-WebRequest -Uri $repoUrl -UseBasicParsing | Select-Object -ExpandProperty Content
        } catch {
            Write-ShadowCatLog "Failed to download config: $($_.Exception.Message)" -Level "Error"
            return $null
        }
        # Use just the filename as the key for processed configs in online mode
        $fullPath = $ConfigPath
    } else {
        if (-not [System.IO.Path]::IsPathRooted($ConfigPath)) {
            $fullPath = Join-Path (Join-Path $PSScriptRoot "configs") $ConfigPath
        }
        if (-not (Test-Path $fullPath)) {
            Write-ShadowCatLog "Configuration file not found: $ConfigPath" -Level "Error"
            return $null
        }
        $configContent = Get-Content $fullPath -Raw
    }

    # Check if already processed
    if ($Global:ProcessedConfigs.ContainsKey($fullPath)) {
        Write-ShadowCatLog "Configuration already processed: $ConfigPath" -Level "Debug"
        return $Global:ProcessedConfigs[$fullPath]
    }

    try {
        $config = $configContent | ConvertFrom-Json

        # Enhanced validation
        if (-not $config.metadata) {
            Write-ShadowCatLog "Invalid configuration - missing metadata: $ConfigPath" -Level "Error"
            return $null
        }

        # Add to processed configs
        $Global:ProcessedConfigs[$fullPath] = $config

        Write-ShadowCatLog "Loaded configuration: $($config.metadata.name)" -Level "Success"
        Write-ShadowCatLog "Install Level: $($config.metadata.installLevel) | Dependencies: $($config.metadata.dependencies.Count)" -Level "Debug"

        return $config
    }
    catch {
        Write-ShadowCatLog "Failed to parse configuration file: $($_.Exception.Message)" -Level "Error"
        return $null
    }
}

# Resolve configuration dependencies
function Resolve-ConfigDependencies {
    param([string[]]$ConfigFiles)

    Write-ShadowCatLog "Resolving configuration dependencies..." -Level "Header"

    $resolvedConfigs = @()
    $processingQueue = [System.Collections.Queue]::new()

    # Add initial configs to queue
    foreach ($configFile in $ConfigFiles) {
        $processingQueue.Enqueue($configFile)
    }

    while ($processingQueue.Count -gt 0) {
        $currentConfig = $processingQueue.Dequeue()

        # Skip if already resolved
        if ($currentConfig -in $resolvedConfigs) {
            continue
        }

        Write-ShadowCatLog "Processing dependencies for: $currentConfig" -Level "Dependency"

        $config = Import-ShadowCatConfig -ConfigPath $currentConfig
        if ($null -eq $config) {
            Write-ShadowCatLog "Skipping invalid configuration: $currentConfig" -Level "Warning"
            continue
        }

        # Check install level compatibility
        if ($config.metadata.installLevel) {
            $configLevel = $config.metadata.installLevel
            $isCompatible = switch ($InstallLevel) {
                "lite" { $configLevel -eq "lite" }
                "standard" { $configLevel -in @("lite", "standard") }
                "professional" { $configLevel -in @("lite", "standard", "professional") }
                "all" { $true }
                default { $true }
            }

            if (-not $isCompatible) {
                Write-ShadowCatLog "Skipping $currentConfig - install level $configLevel not compatible with $InstallLevel" -Level "Warning"
                continue
            }
        }

        # Process dependencies first
        if ($config.metadata.dependencies) {
            foreach ($dependency in $config.metadata.dependencies) {
                if ($dependency -notin $resolvedConfigs) {
                    Write-ShadowCatLog "Adding dependency: $dependency" -Level "Dependency"
                    $processingQueue.Enqueue($dependency)
                }
            }
        }

        # Add current config to resolved list
        $resolvedConfigs += $currentConfig
        $Global:DependencyChain += $currentConfig
    }

    Write-ShadowCatLog "Dependency resolution complete. Processing order:" -Level "Success"
    foreach ($config in $resolvedConfigs) {
        Write-ShadowCatLog "  → $config" -Level "Info"
    }

    return $resolvedConfigs
}

# Check if tool should be installed based on level and duplicates
function Test-ToolInstallation {
    param($tool, $source)

    # Check if tool has a unique ID
    $toolId = if ($tool.toolId) { $tool.toolId } else { $tool.name }

    # Check install level compatibility
    if ($tool.installLevel) {
        $toolLevel = $tool.installLevel
        $isCompatible = switch ($InstallLevel) {
            "lite" { $toolLevel -eq "lite" }
            "standard" { $toolLevel -in @("lite", "standard") }
            "professional" { $toolLevel -in @("lite", "standard", "professional") }
            "all" { $true }
            default { $true }
        }

        if (-not $isCompatible) {
            Write-ShadowCatLog "Skipping $($tool.name) - level $toolLevel not compatible with $InstallLevel" -Level "Debug"
            return $false
        }
    }

    # Track tool category for folder organization
    if ($tool.category) {
        $Global:ToolCategories[$toolId] = $tool.category
    }
    # Check for duplicates
    if ($Global:InstalledTools.ContainsKey($toolId)) {
        $existingSource = $Global:InstalledTools[$toolId]
        Write-ShadowCatLog "Tool $($tool.name) already installed from $existingSource (ID: $toolId)" -Level "Warning"
        $Global:SkippedTools[$toolId] = @{
            name = $tool.name
            source = $source
            reason = "Duplicate - already installed from $existingSource"
        }
        return $false
    }

    return $true
}

function Install-ChocolateyPackages {
    param($packages, $configName)

    if (-not $packages -or $packages.Count -eq 0) { return }

    Write-ShadowCatLog "Processing Chocolatey packages from $configName..." -Level "Header"

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-ShadowCatLog "Installing Chocolatey package manager..." -Level "Info"
        if (-not $DryRun) {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
    }

    $installedCount = 0
    $skippedCount = 0

    foreach ($package in $packages) {
        $toolId = if ($package.toolId) { $package.toolId } else { $package.name }

        if (-not (Test-ToolInstallation -tool $package -source "Chocolatey")) {
            $skippedCount++
            continue
        }

        try {
            Write-ShadowCatLog "Installing $($package.name) - $($package.description)" -Level "Info"

            if (-not $DryRun) {
                $installCmd = "choco install $($package.name) -y"
                if ($package.arguments) {
                    $installCmd += " $($package.arguments)"
                }
                Invoke-Expression $installCmd
            } else {
                Write-ShadowCatLog "[DRY RUN] Would install: $installCmd" -Level "Debug"
            }

            $Global:InstalledTools[$toolId] = "Chocolatey"
            $installedCount++
            Write-ShadowCatLog "Successfully processed $($package.name)" -Level "Success"
        }
        catch {
            Write-ShadowCatLog "Failed to install $($package.name): $($_.Exception.Message)" -Level "Error"
        }
    }

    Write-ShadowCatLog "Chocolatey summary: $installedCount installed, $skippedCount skipped" -Level "Info"
}

# Scoop installation
function Install-ScoopPackages {
    param($scoopConfig, $configName)

    if (-not $scoopConfig -or $scoopConfig.packages.Count -eq 0) { return }

    Write-ShadowCatLog "Processing Scoop packages from $configName..." -Level "Header"

    # Ensure Scoop is installed
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-ShadowCatLog "Installing Scoop package manager..." -Level "Info"
        if (-not $DryRun) {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Invoke-RestMethod get.scoop.sh | Invoke-Expression
        }
    }

    # Add required buckets
    if ($scoopConfig.buckets -and -not $DryRun) {
        foreach ($bucket in $scoopConfig.buckets) {
            try {
                Write-ShadowCatLog "Adding Scoop bucket: $bucket" -Level "Debug"
                scoop bucket add $bucket 2>$null
            }
            catch {
                Write-ShadowCatLog "Warning: Could not add bucket $bucket" -Level "Warning"
            }
        }
    }

    $installedCount = 0
    $skippedCount = 0

    foreach ($package in $scoopConfig.packages) {
        $toolId = if ($package.toolId) { $package.toolId } else { $package.name }

        if (-not (Test-ToolInstallation -tool $package -source "Scoop")) {
            $skippedCount++
            continue
        }

        try {
            Write-ShadowCatLog "Installing $($package.name) - $($package.description)" -Level "Info"

            if (-not $DryRun) {
                scoop install $package.name
            } else {
                Write-ShadowCatLog "[DRY RUN] Would install: scoop install $($package.name)" -Level "Debug"
            }

            $Global:InstalledTools[$toolId] = "Scoop"
            $installedCount++
            Write-ShadowCatLog "Successfully processed $($package.name)" -Level "Success"
        }
        catch {
            Write-ShadowCatLog "Failed to install $($package.name): $($_.Exception.Message)" -Level "Error"
        }
    }

    Write-ShadowCatLog "Scoop summary: $installedCount installed, $skippedCount skipped" -Level "Info"
}

# GitHub projects installation
function Install-GitHubProjects {
    param($projects, $basePath, $configName)

    if (-not $projects -or $projects.Count -eq 0) { return }

    Write-ShadowCatLog "Processing GitHub projects from $configName..." -Level "Header"

    $installedCount = 0
    $skippedCount = 0

    foreach ($project in $projects) {
        $toolId = if ($project.toolId) { $project.toolId } else { $project.name }

        if (-not (Test-ToolInstallation -tool $project -source "GitHub")) {
            $skippedCount++
            continue
        }

        try {
            $destination = Join-Path $basePath $project.destination
            Write-ShadowCatLog "Cloning $($project.name) - $($project.description)" -Level "Info"

            if (-not $DryRun) {
                if (Test-Path $destination) {
                    Write-ShadowCatLog "Directory exists, pulling latest changes for $($project.name)" -Level "Debug"
                    Push-Location $destination
                    git pull
                    Pop-Location
                }
                else {
                    New-Item -Path (Split-Path $destination) -ItemType Directory -Force | Out-Null
                    git clone $project.url $destination
                }
            } else {
                Write-ShadowCatLog "[DRY RUN] Would clone: $($project.url) to $destination" -Level "Debug"
            }

            $Global:InstalledTools[$toolId] = "GitHub"
            $installedCount++
            Write-ShadowCatLog "Successfully processed $($project.name)" -Level "Success"
        }
        catch {
            Write-ShadowCatLog "Failed to clone $($project.name): $($_.Exception.Message)" -Level "Error"
        }
    }

    Write-ShadowCatLog "GitHub summary: $installedCount installed, $skippedCount skipped" -Level "Info"
}

# Python packages installation
function Install-PythonPackages {
    param($packages, $configName)

    if (-not $packages -or $packages.Count -eq 0) { return }

    Write-ShadowCatLog "Processing Python packages from $configName..." -Level "Header"

    $installedCount = 0
    $skippedCount = 0

    foreach ($package in $packages) {
        $toolId = if ($package.toolId) { $package.toolId } else { "python-$($package.name)" }

        if (-not (Test-ToolInstallation -tool $package -source "Python pip")) {
            $skippedCount++
            continue
        }

        try {
            Write-ShadowCatLog "Installing Python package: $($package.name) - $($package.description)" -Level "Info"

            if (-not $DryRun) {
                python -m pip install $package.name
            } else {
                Write-ShadowCatLog "[DRY RUN] Would install: python -m pip install $($package.name)" -Level "Debug"
            }

            $Global:InstalledTools[$toolId] = "Python pip"
            $installedCount++
            Write-ShadowCatLog "Successfully processed $($package.name)" -Level "Success"
        }
        catch {
            Write-ShadowCatLog "Failed to install $($package.name): $($_.Exception.Message)" -Level "Error"
        }
    }

    Write-ShadowCatLog "Python summary: $installedCount installed, $skippedCount skipped" -Level "Info"
}

# Show installation summary
function New-ToolCategoryFolders {
    param([string]$BasePath)
    Write-ShadowCatLog "Creating categorized tool folders..." -Level "Header"
    $categories = $Global:ToolCategories.Values | Select-Object -Unique
    foreach ($cat in $categories) {
        $catFolder = Join-Path $BasePath $cat
        if (-not (Test-Path $catFolder)) {
            New-Item -Path $catFolder -ItemType Directory -Force | Out-Null
            Write-ShadowCatLog "Created folder: $catFolder" -Level "Success"
        }
    }
}

function Set-DesktopBackground {
    param([string]$ImageUrl)
    Write-ShadowCatLog "Setting custom desktop background..." -Level "Header"
    $wallpaperPath = "$env:TEMP\shadowcat_wallpaper.jpg"
    try {
        Invoke-WebRequest -Uri $ImageUrl -OutFile $wallpaperPath -UseBasicParsing
        # Set registry key for wallpaper
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper -Value $wallpaperPath
        # Refresh desktop to apply wallpaper
        rundll32.exe user32.dll,UpdatePerUserSystemParameters 1, True
        Write-ShadowCatLog "Desktop background set successfully." -Level "Success"
    } catch {
        Write-ShadowCatLog "Failed to set desktop background: $($_.Exception.Message)" -Level "Error"
    }
}

function Show-InstallationSummary {
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                     Installation Summary                             ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

    Write-Host "`n📊 STATISTICS:" -ForegroundColor Cyan
    Write-Host "   Total Tools Installed: $($Global:InstalledTools.Count)" -ForegroundColor Green
    Write-Host "   Tools Skipped (Duplicates): $($Global:SkippedTools.Count)" -ForegroundColor Yellow
    Write-Host "   Install Level: $InstallLevel" -ForegroundColor White

    if ($Global:InstalledTools.Count -gt 0) {
        Write-Host "`n🛠️  INSTALLED TOOLS BY SOURCE:" -ForegroundColor Cyan
        $groupedTools = $Global:InstalledTools.GetEnumerator() | Group-Object Value
        foreach ($group in $groupedTools) {
            Write-Host "   $($group.Name): $($group.Count) tools" -ForegroundColor White
        }
    }

    if ($Global:SkippedTools.Count -gt 0) {
        Write-Host "`n⚠️  SKIPPED TOOLS:" -ForegroundColor Yellow
        foreach ($skipped in $Global:SkippedTools.GetEnumerator()) {
            Write-Host "   $($skipped.Value.name) - $($skipped.Value.reason)" -ForegroundColor Gray
        }
    }

    Write-Host "`n🎯 NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "   1. Restart PowerShell to activate ShadowCat profile" -ForegroundColor White
    Write-Host "   2. Use 'bcat' command to navigate to tools" -ForegroundColor White  
    Write-Host "   3. Check tool-specific documentation for usage" -ForegroundColor White
    Write-Host "`n   Happy Hacking with ShadowCat! 🐱‍💻`n" -ForegroundColor Yellow
}

# Main installation function
function Start-Installation {
    param([string[]]$ConfigFiles, [string]$InstallPath)

    Show-ShadowCatBanner

    if ($ShowDependencies) {
        Write-ShadowCatLog "Dependency analysis mode - showing configuration dependencies" -Level "Info"
        $resolvedConfigs = Resolve-ConfigDependencies -ConfigFiles $ConfigFiles
        return
    }

    if ($Online -and $ConfigFiles.Count -eq 0) {
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
    } elseif ($ConfigFiles.Count -eq 0) {
        Write-ShadowCatLog "No configuration files specified. Use -ShowAvailableConfigs to see options." -Level "Warning"
        return
    }

    Write-ShadowCatLog "Starting ShadowCat Installation..." -Level "Header"
    Write-ShadowCatLog "Install Level: $InstallLevel" -Level "Info"
    Write-ShadowCatLog "Install Path: $InstallPath" -Level "Info"
    Write-ShadowCatLog "Dry Run Mode: $DryRun" -Level "Info"

    # Resolve dependencies
    $resolvedConfigs = Resolve-ConfigDependencies -ConfigFiles $ConfigFiles

    if ($resolvedConfigs.Count -eq 0) {
        Write-ShadowCatLog "No valid configurations to process" -Level "Error"
        return
    }

    # Process each configuration in dependency order
    foreach ($configFile in $resolvedConfigs) {
        $config = $null
        if ($Online) {
            # Use just the filename as the key for processed configs in online mode
            if ($Global:ProcessedConfigs.ContainsKey($configFile)) {
                $config = $Global:ProcessedConfigs[$configFile]
            }
        } else {
            $localKey = Join-Path (Join-Path $PSScriptRoot "configs") $configFile
            if ($Global:ProcessedConfigs.ContainsKey($localKey)) {
                $config = $Global:ProcessedConfigs[$localKey]
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
    # Use the existing function from the original script
    exit 0
}

# Start the installation
Start-Installation -ConfigFiles $ConfigFiles -InstallPath $InstallPath