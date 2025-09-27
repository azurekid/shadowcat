# ==============================================================================
# Project ShadowCat - IEX-Compatible Installer
# Self-contained version with all module code embedded for direct execution
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

# Script-scoped variables for tracking
$script:IsIEXMode = $true
$script:PSScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { [System.IO.Path]::GetTempPath() }
$script:InstallLevel = $InstallLevel
$script:DryRun = $DryRun
$script:Verbose = $Verbose
$script:Online = $Online -or $true  # Force online mode for IEX
$script:ToolCategories = @{}
$script:ProcessedConfigs = @{}
$script:InstalledTools = @{}
$script:SkippedTools = @{}
$script:DependencyChain = @()

Write-Host "ShadowCat IEX-compatible installer v2.1.0" -ForegroundColor Cyan
Write-Host "Running in direct execution mode..." -ForegroundColor Yellow

# =============================================================================
# UI Module Functions
# =============================================================================

function Show-ShadowCatBanner {
    $banner = @"


    _____ _      /\_/\    _                _____      _
   / ____| |    ( o.o )  | |              / ____|    | |
  | (___ | |__   > ^ < __| | _____      _| |     ____| |_     /\_/\
   \___ \| '_ \ / _`  |/ _`  |/ _ \ \ /\ / / |    / _`  | __|   ( o.o )
   ____) | | | | (_| | (_| | (_) \ V  V /| |___| (_| | |_     > ^ <
  |_____/|_| |_|\__,_|\__,_|\___/ \_/\_/  \_____\__,_|\__|

                    version 0.1.0-beta

"@
    Write-Host $banner -ForegroundColor Blue
    Write-Host "    [+] Install Level: $script:InstallLevel" -ForegroundColor Yellow
    Write-Host "    [+] Dependency Resolution: Enabled" -ForegroundColor Yellow
    Write-Host "    [+] Overlap Prevention: Active" -ForegroundColor Yellow
    Write-Host "    [+] Project ShadowCat - Elite Security Solutions" -ForegroundColor Yellow
    Write-Host ""
}

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

    if ($Level -eq "Debug" -and -not $script:Verbose) { return }

    Write-Host "$timestamp $prefix $Message" -ForegroundColor $color
}

function Show-InstallationSummary {
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                     Installation Summary                             ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

    Write-Host "`n📊 STATISTICS:" -ForegroundColor Cyan
    Write-Host "   Total Tools Installed: $($script:InstalledTools.Count)" -ForegroundColor Green
    Write-Host "   Tools Skipped (Duplicates): $($script:SkippedTools.Count)" -ForegroundColor Yellow
    Write-Host "   Install Level: $script:InstallLevel" -ForegroundColor White

    if ($script:InstalledTools.Count -gt 0) {
        Write-Host "`n🛠️  INSTALLED TOOLS BY SOURCE:" -ForegroundColor Cyan
        $groupedTools = $script:InstalledTools.GetEnumerator() | Group-Object Value
        foreach ($group in $groupedTools) {
            Write-Host "   $($group.Name): $($group.Count) tools" -ForegroundColor White
        }
    }

    if ($script:SkippedTools.Count -gt 0) {
        Write-Host "`n⚠️  SKIPPED TOOLS:" -ForegroundColor Yellow
        foreach ($skipped in $script:SkippedTools.GetEnumerator()) {
            Write-Host "   $($skipped.Value.name) - $($skipped.Value.reason)" -ForegroundColor Gray
        }
    }

    Write-Host "`n🎯 NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "   1. Restart PowerShell to activate ShadowCat profile" -ForegroundColor White
    Write-Host "   2. Use 'bcat' command to navigate to tools" -ForegroundColor White  
    Write-Host "   3. Check tool-specific documentation for usage" -ForegroundColor White
    Write-Host "`n   Happy Hacking with ShadowCat! 🐱‍💻`n" -ForegroundColor Yellow
}

# =============================================================================
# Config Module Functions
# =============================================================================

function Import-ShadowCatConfig {
    param([string]$ConfigPath)
    
    $fullPath = $ConfigPath
    $configContent = $null

    if ($script:Online) {
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
            $fullPath = Join-Path (Join-Path $script:PSScriptRoot "configs") $ConfigPath
        }
        if (-not (Test-Path $fullPath)) {
            Write-ShadowCatLog "Configuration file not found: $ConfigPath" -Level "Error"
            return $null
        }
        $configContent = Get-Content $fullPath -Raw
    }

    # Check if already processed
    if ($script:ProcessedConfigs.ContainsKey($fullPath)) {
        Write-ShadowCatLog "Configuration already processed: $ConfigPath" -Level "Debug"
        return $script:ProcessedConfigs[$fullPath]
    }

    try {
        $config = $configContent | ConvertFrom-Json

        # Enhanced validation
        if (-not $config.metadata) {
            Write-ShadowCatLog "Invalid configuration - missing metadata: $ConfigPath" -Level "Error"
            return $null
        }

        # Add to processed configs
        $script:ProcessedConfigs[$fullPath] = $config

        Write-ShadowCatLog "Loaded configuration: $($config.metadata.name)" -Level "Success"
        Write-ShadowCatLog "Install Level: $($config.metadata.installLevel) | Dependencies: $($config.metadata.dependencies.Count)" -Level "Debug"

        return $config
    }
    catch {
        Write-ShadowCatLog "Failed to parse configuration file: $($_.Exception.Message)" -Level "Error"
        return $null
    }
}

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
            $isCompatible = switch ($script:InstallLevel) {
                "lite" { $configLevel -eq "lite" }
                "standard" { $configLevel -in @("lite", "standard") }
                "professional" { $configLevel -in @("lite", "standard", "professional") }
                "all" { $true }
                default { $true }
            }
            
            if (-not $isCompatible) {
                Write-ShadowCatLog "Skipping $currentConfig - install level $configLevel not compatible with $($script:InstallLevel)" -Level "Warning"
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
        $script:DependencyChain += $currentConfig
    }
    
    Write-ShadowCatLog "Dependency resolution complete. Processing order:" -Level "Success"
    foreach ($config in $resolvedConfigs) {
        Write-ShadowCatLog "  → $config" -Level "Info"
    }
    
    return $resolvedConfigs
}

function Test-ToolInstallation {
    param($tool, $source)
    
    # Check if tool has a unique ID
    $toolId = if ($tool.toolId) { $tool.toolId } else { $tool.name }
    
    # Track tool category for folder organization
    if ($tool.category) {
        $script:ToolCategories[$toolId] = $tool.category
    }
    
    # Check install level compatibility
    if ($tool.installLevel) {
        $toolLevel = $tool.installLevel
        $isCompatible = switch ($script:InstallLevel) {
            "lite" { $toolLevel -eq "lite" }
            "standard" { $toolLevel -in @("lite", "standard") }
            "professional" { $toolLevel -in @("lite", "standard", "professional") }
            "all" { $true }
            default { $true }
        }
        
        if (-not $isCompatible) {
            Write-ShadowCatLog "Skipping $($tool.name) - level $toolLevel not compatible with $($script:InstallLevel)" -Level "Debug"
            return $false
        }
    }
    
    # Check for duplicates
    if ($script:InstalledTools.ContainsKey($toolId)) {
        $existingSource = $script:InstalledTools[$toolId]
        Write-ShadowCatLog "Tool $($tool.name) already installed from $existingSource (ID: $toolId)" -Level "Warning"
        $script:SkippedTools[$toolId] = @{
            name = $tool.name
            source = $source
            reason = "Duplicate - already installed from $existingSource"
        }
        return $false
    }
    
    return $true
}

# =============================================================================
# Package Manager Module Functions
# =============================================================================

function Install-ChocolateyPackages {
    param($packages, $configName)
    
    if (-not $packages -or $packages.Count -eq 0) { return }
    
    Write-ShadowCatLog "Processing Chocolatey packages from $configName..." -Level "Header"
    
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-ShadowCatLog "Installing Chocolatey package manager..." -Level "Info"
        if (-not $script:DryRun) {
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
            
            if (-not $script:DryRun) {
                # Check if package is already installed
                $chocoList = choco list --local-only $($package.name) -r
                $isInstalled = $chocoList -match "^$($package.name)\|"
                
                if ($isInstalled) {
                    Write-ShadowCatLog "$($package.name) is already installed, skipping." -Level "Info"
                } else {
                    # First check if package exists in repository
                    $searchResult = choco search $($package.name) --exact -r
                    if (-not $searchResult) {
                        # Package not found in default repository
                        Write-ShadowCatLog "Package $($package.name) not found in default Chocolatey repository." -Level "Warning"
                        
                        # Handle specific package alternatives
                        switch ($package.name) {
                            "john" {
                                Write-ShadowCatLog "Trying alternative: john-jumbo instead of john" -Level "Info"
                                $installCmd = "choco install john-jumbo -y"
                            }
                            "netcat" {
                                Write-ShadowCatLog "Trying alternative: netcat-win32 instead of netcat" -Level "Info"
                                $installCmd = "choco install netcat-win32 -y"
                            }
                            default {
                                Write-ShadowCatLog "Skipping installation of $($package.name) - package not found." -Level "Warning"
                                $script:SkippedTools[$toolId] = @{
                                    name = $package.name
                                    source = $source
                                    reason = "Package not found in repository"
                                }
                                continue
                            }
                        }
                    } else {
                        $installCmd = "choco install $($package.name) -y"
                        if ($package.arguments) {
                            $installCmd += " $($package.arguments)"
                        }
                    }
                    
                    # Execute the install command
                    try {
                        $output = Invoke-Expression $installCmd
                        
                        # Check if installation was successful
                        if ($output -match "0/\d+ packages failed" -or $output -match "installed 1/1") {
                            Write-ShadowCatLog "$($package.name) installed successfully." -Level "Success"
                        } else {
                            Write-ShadowCatLog "Installation of $($package.name) may have failed. Check logs for details." -Level "Warning"
                        }
                    } catch {
                        Write-ShadowCatLog "Error during installation of $($package.name): $($_.Exception.Message)" -Level "Error"
                    }
                }
            } else {
                Write-ShadowCatLog "[DRY RUN] Would install: choco install $($package.name) -y" -Level "Debug"
            }
            
            $script:InstalledTools[$toolId] = "Chocolatey"
            $installedCount++
            Write-ShadowCatLog "Successfully processed $($package.name)" -Level "Success"
        }
        catch {
            Write-ShadowCatLog "Failed to install $($package.name): $($_.Exception.Message)" -Level "Error"
        }
    }
    
    Write-ShadowCatLog "Chocolatey summary: $installedCount installed, $skippedCount skipped" -Level "Info"
}

function Install-ScoopPackages {
    param($scoopConfig, $configName)
    
    if (-not $scoopConfig -or $scoopConfig.packages.Count -eq 0) { return }
    
    Write-ShadowCatLog "Processing Scoop packages from $configName..." -Level "Header"
    
    # Ensure Scoop is installed
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-ShadowCatLog "Installing Scoop package manager..." -Level "Info"
        if (-not $script:DryRun) {
            try {
                # Always use admin installation mode for consistency and reliability
                Write-ShadowCatLog "Using Scoop admin installation mode..." -Level "Info"
                
                # Special handling for admin installation following official guidelines
                # https://github.com/ScoopInstaller/Install#for-admin
                
                # Set variables for admin installation
                $env:SCOOP = "C:\ProgramData\scoop"
                [environment]::setEnvironmentVariable('SCOOP', $env:SCOOP, 'Machine')
                
                # Allow admin installations by setting the required environment variable
                $env:SCOOP_ALLOW_ADMIN = "1"
                [environment]::setEnvironmentVariable('SCOOP_ALLOW_ADMIN', '1', 'Machine')
                
                # Create Scoop directory if it doesn't exist
                if (-not (Test-Path $env:SCOOP)) {
                    New-Item -Path $env:SCOOP -ItemType Directory -Force | Out-Null
                }
                
                # Use the official admin installer with -RunAsAdmin parameter
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                Invoke-Expression "& {$(Invoke-RestMethod -Uri get.scoop.sh)} -RunAsAdmin"
                
                # Add the app directory to PATH to ensure scoop commands work immediately
                $env:PATH = "$env:SCOOP\shims;$env:PATH"
            }
            catch {
                Write-ShadowCatLog "Failed to install Scoop: $($_.Exception.Message)" -Level "Error"
                Write-ShadowCatLog "You may need to install Scoop manually. Visit https://scoop.sh for instructions." -Level "Warning"
            }
        }
    }
    
    # Add required buckets
    if ($scoopConfig.buckets -and -not $script:DryRun) {
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
            
            if (-not $script:DryRun) {
                scoop install $package.name
            } else {
                Write-ShadowCatLog "[DRY RUN] Would install: scoop install $($package.name)" -Level "Debug"
            }
            
            $script:InstalledTools[$toolId] = "Scoop"
            $installedCount++
            Write-ShadowCatLog "Successfully processed $($package.name)" -Level "Success"
        }
        catch {
            Write-ShadowCatLog "Failed to install $($package.name): $($_.Exception.Message)" -Level "Error"
        }
    }
    
    Write-ShadowCatLog "Scoop summary: $installedCount installed, $skippedCount skipped" -Level "Info"
}

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
            
            if (-not $script:DryRun) {
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
            
            $script:InstalledTools[$toolId] = "GitHub"
            $installedCount++
            Write-ShadowCatLog "Successfully processed $($project.name)" -Level "Success"
        }
        catch {
            Write-ShadowCatLog "Failed to clone $($project.name): $($_.Exception.Message)" -Level "Error"
        }
    }
    
    Write-ShadowCatLog "GitHub summary: $installedCount installed, $skippedCount skipped" -Level "Info"
}

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
            
            if (-not $script:DryRun) {
                python -m pip install $package.name
            } else {
                Write-ShadowCatLog "[DRY RUN] Would install: python -m pip install $($package.name)" -Level "Debug"
            }
            
            $script:InstalledTools[$toolId] = "Python pip"
            $installedCount++
            Write-ShadowCatLog "Successfully processed $($package.name)" -Level "Success"
        }
        catch {
            Write-ShadowCatLog "Failed to install $($package.name): $($_.Exception.Message)" -Level "Error"
        }
    }
    
    Write-ShadowCatLog "Python summary: $installedCount installed, $skippedCount skipped" -Level "Info"
}

# =============================================================================
# Custom Tools Module Functions
# =============================================================================

function New-ToolCategoryFolders {
    param([string]$BasePath)
    Write-ShadowCatLog "Creating categorized tool folders..." -Level "Header"
    $categories = $script:ToolCategories.Values | Select-Object -Unique
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

# =============================================================================
# Main Installation Function
# =============================================================================

function Start-Installation {
    param([string[]]$ConfigFiles, [string]$InstallPath)

    Show-ShadowCatBanner

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
    } elseif ($ConfigFiles.Count -eq 0) {
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
    $wallpaperUrl = "https://raw.githubusercontent.com/azurekid/shadowcat/main/media/shadowcat_wallpaper.jpg"
    Set-DesktopBackground -ImageUrl $wallpaperUrl

    # Show final summary
    Show-InstallationSummary
}

# =============================================================================
# Handle command line arguments
# =============================================================================

if ($ShowAvailableConfigs) {
    # Display available configurations
    Write-Host "`nAvailable Configuration Files:" -ForegroundColor Cyan
    $configPath = Join-Path $script:PSScriptRoot "configs"
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