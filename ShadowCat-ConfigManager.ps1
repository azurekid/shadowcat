# ==============================================================================
# ShadowCat Configuration Manager
# Tool for managing ShadowCat JSON configuration files
# ==============================================================================
#
# This script provides utilities for managing, validating, and maintaining
# ShadowCat security toolkit configuration files.
#
# Author: Project BlackCat Team
# Version: 1.0.0
# License: MIT License
# ==============================================================================

param(
    [ValidateSet("list", "validate", "add-tool", "remove-tool", "create-config", "merge-configs")]
    [string]$Action,
    [string]$ConfigFile,
    [string]$ToolName,
    [string]$ToolSource,
    [string]$OutputConfig,
    [string[]]$MergeConfigs
)

# ShadowCat branding
function Write-ShadowCatHeader {
    Write-Host @"


    _____ _      /\_/\    _                _____      _
   / ____| |    ( o.o )  | |              / ____|    | |
  | (___ | |__   > ^ < __| | _____      _| |     ____| |_     /\_/\
   \___ \| '_ \ / _`  |/ _`  |/ _ \ \ /\ / / |    / _`  | __|   ( o.o )
   ____) | | | | (_| | (_| | (_) \ V  V /| |___| (_| | |_     > ^ <
  |_____/|_| |_|\__,_|\__,_|\___/ \_/\_/  \_____\__,_|\__|

                          /\_/\
                         ( o.o )
                          > ^ <
                          (   )~

"@ -ForegroundColor Red
}

# Get configuration directory
function Get-ConfigDirectory {
    $configDir = Join-Path $PSScriptRoot "configs"
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }
    return $configDir
}

# List all configuration files
function Show-ConfigurationList {
    Write-ShadowCatHeader
    Write-Host "[ShadowCat] Scanning configuration files..." -ForegroundColor Yellow

    $configDir = Get-ConfigDirectory
    $configs = Get-ChildItem $configDir -Filter "ShadowCat-*.json"

    if ($configs.Count -eq 0) {
        Write-Host "[ShadowCat] No configuration files found" -ForegroundColor Red
        return
    }

    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    ShadowCat Configuration Files                      ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

    foreach ($config in $configs) {
        try {
            $configData = Get-Content $config.FullName | ConvertFrom-Json

            # Count tools
            $toolCount = 0
            if ($configData.chocolatey.packages) { $toolCount += $configData.chocolatey.packages.Count }
            if ($configData.scoop.packages) { $toolCount += $configData.scoop.packages.Count }
            if ($configData.github.projects) { $toolCount += $configData.github.projects.Count }
            if ($configData.python.packages) { $toolCount += $configData.python.packages.Count }

            Write-Host "`n📦 " -NoNewline -ForegroundColor Yellow
            Write-Host $config.Name -ForegroundColor White -NoNewline
            Write-Host " ($toolCount tools)" -ForegroundColor Gray
            Write-Host "   Category: " -NoNewline -ForegroundColor Gray
            Write-Host $configData.metadata.category -ForegroundColor Magenta
            Write-Host "   Description: " -NoNewline -ForegroundColor Gray
            Write-Host $configData.metadata.description -ForegroundColor White
            Write-Host "   Last Updated: " -NoNewline -ForegroundColor Gray
            Write-Host $configData.metadata.lastUpdated -ForegroundColor Green
        }
        catch {
            Write-Host "`n " -NoNewline -ForegroundColor Red
            Write-Host $config.Name -ForegroundColor White
            Write-Host "   [Error parsing configuration]" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Validate configuration file
function Test-ConfigurationFile {
    param([string]$ConfigPath)

    Write-Host "[ShadowCat] Validating configuration: $ConfigPath" -ForegroundColor Yellow

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "[ShadowCat] Configuration file not found" -ForegroundColor Red
        return $false
    }

    try {
        $config = Get-Content $ConfigPath | ConvertFrom-Json

        # Validate metadata
        if (-not $config.metadata) {
            Write-Host "[ShadowCat] Missing metadata section" -ForegroundColor Red
            return $false
        }

        $requiredFields = @("name", "version", "description", "author", "category")
        foreach ($field in $requiredFields) {
            if (-not $config.metadata.$field) {
                Write-Host "[ShadowCat] Missing metadata field: $field" -ForegroundColor Red
                return $false
            }
        }

        # Validate tool sections
        $validSections = @("chocolatey", "scoop", "github", "python")
        $hasTools = $false

        foreach ($section in $validSections) {
            if ($config.$section) {
                $hasTools = $true

                # Validate chocolatey section
                if ($section -eq "chocolatey" -and $config.chocolatey.packages) {
                    foreach ($package in $config.chocolatey.packages) {
                        if (-not $package.name -or -not $package.description) {
                            Write-Host "[ShadowCat] Chocolatey package missing name or description" -ForegroundColor Yellow
                        }
                    }
                }

                # Validate scoop section
                if ($section -eq "scoop" -and $config.scoop.packages) {
                    foreach ($package in $config.scoop.packages) {
                        if (-not $package.name -or -not $package.description) {
                            Write-Host "[ShadowCat] Scoop package missing name or description" -ForegroundColor Yellow
                        }
                    }
                }

                # Validate github section
                if ($section -eq "github" -and $config.github.projects) {
                    foreach ($project in $config.github.projects) {
                        if (-not $project.name -or -not $project.url -or -not $project.destination) {
                            Write-Host "[ShadowCat] GitHub project missing required fields" -ForegroundColor Yellow
                        }
                    }
                }

                # Validate python section
                if ($section -eq "python" -and $config.python.packages) {
                    foreach ($package in $config.python.packages) {
                        if (-not $package.name -or -not $package.description) {
                            Write-Host "[ShadowCat] Python package missing name or description" -ForegroundColor Yellow
                        }
                    }
                }
            }
        }

        if (-not $hasTools) {
            Write-Host "[ShadowCat] No tools defined in configuration" -ForegroundColor Yellow
        }

        Write-Host "[ShadowCat] Configuration validation passed" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[ShadowCat] JSON parsing error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Create new configuration template
function New-ConfigurationTemplate {
    param([string]$ConfigName)

    Write-Host "[ShadowCat] Creating new configuration template..." -ForegroundColor Yellow

    $template = @{
        metadata = @{
            name = "ShadowCat Security Toolkit - $ConfigName"
            version = "1.0.0"
            description = "Custom security tools configuration"
            author = "Project ShadowCat"
            lastUpdated = (Get-Date -Format "yyyy-MM-dd")
            category = $ConfigName
        }
        chocolatey = @{
            packages = @()
        }
        scoop = @{
            buckets = @("main", "extras")
            packages = @()
        }
        github = @{
            projects = @()
        }
        python = @{
            packages = @()
        }
    }

    $configDir = Get-ConfigDirectory
    $fileName = "ShadowCat-$($ConfigName.ToLower())-tools.json"
    $filePath = Join-Path $configDir $fileName

    if (Test-Path $filePath) {
        Write-Host "[ShadowCat] Configuration file already exists: $fileName" -ForegroundColor Yellow
        $overwrite = Read-Host "Overwrite existing file? (y/n)"
        if ($overwrite -ne "y") {
            Write-Host "[ShadowCat] Operation cancelled" -ForegroundColor Yellow
            return
        }
    }

    try {
        $template | ConvertTo-Json -Depth 4 | Out-File $filePath -Encoding UTF8
        Write-Host "[ShadowCat] Configuration template created: $filePath" -ForegroundColor Green
        Write-Host "[ShadowCat] Edit the file to add your tools and run validation when ready" -ForegroundColor Cyan
    }
    catch {
        Write-Host "[ShadowCat] Failed to create configuration: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Merge multiple configuration files
function Merge-ConfigurationFiles {
    param([string[]]$ConfigFiles, [string]$OutputFile)

    Write-Host "[ShadowCat] Merging configuration files..." -ForegroundColor Yellow

    if ($ConfigFiles.Count -lt 2) {
        Write-Host "[ShadowCat] At least 2 configuration files required for merging" -ForegroundColor Red
        return
    }

    $mergedConfig = @{
        metadata = @{
            name = "ShadowCat Security Toolkit - Merged Configuration"
            version = "1.0.0"
            description = "Merged configuration from multiple sources"
            author = "Project BlackCat"
            lastUpdated = (Get-Date -Format "yyyy-MM-dd")
            category = "Merged"
        }
        chocolatey = @{ packages = @() }
        scoop = @{ buckets = @(); packages = @() }
        github = @{ projects = @() }
        python = @{ packages = @() }
    }

    $allBuckets = @()

    foreach ($configFile in $ConfigFiles) {
        $configPath = $configFile
        if (-not [System.IO.Path]::IsPathRooted($configFile)) {
            $configPath = Join-Path (Get-ConfigDirectory) $configFile
        }

        if (-not (Test-Path $configPath)) {
            Write-Host "[ShadowCat] Configuration file not found: $configFile" -ForegroundColor Yellow
            continue
        }

        try {
            $config = Get-Content $configPath | ConvertFrom-Json
            Write-Host "[ShadowCat] Processing: $($config.metadata.name)" -ForegroundColor Cyan

            # Merge packages
            if ($config.chocolatey.packages) {
                $mergedConfig.chocolatey.packages += $config.chocolatey.packages
            }

            if ($config.scoop) {
                if ($config.scoop.buckets) {
                    $allBuckets += $config.scoop.buckets
                }
                if ($config.scoop.packages) {
                    $mergedConfig.scoop.packages += $config.scoop.packages
                }
            }

            if ($config.github.projects) {
                $mergedConfig.github.projects += $config.github.projects
            }

            if ($config.python.packages) {
                $mergedConfig.python.packages += $config.python.packages
            }
        }
        catch {
            Write-Host "[ShadowCat] Error processing $configFile`: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Remove duplicate buckets
    $mergedConfig.scoop.buckets = $allBuckets | Sort-Object | Get-Unique

    # Save merged configuration
    try {
        $outputPath = $OutputFile
        if (-not [System.IO.Path]::IsPathRooted($OutputFile)) {
            $outputPath = Join-Path (Get-ConfigDirectory) $OutputFile
        }

        $mergedConfig | ConvertTo-Json -Depth 4 | Out-File $outputPath -Encoding UTF8
        Write-Host "[ShadowCat] Merged configuration saved: $outputPath" -ForegroundColor Green

        # Show summary
        $totalTools = 0
        $totalTools += $mergedConfig.chocolatey.packages.Count
        $totalTools += $mergedConfig.scoop.packages.Count
        $totalTools += $mergedConfig.github.projects.Count
        $totalTools += $mergedConfig.python.packages.Count

        Write-Host "[ShadowCat] Merged $totalTools tools from $($ConfigFiles.Count) configurations" -ForegroundColor Cyan
    }
    catch {
        Write-Host "[ShadowCat] Failed to save merged configuration: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Show usage information
function Show-Usage {
    Write-ShadowCatHeader

    Write-Host @"
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                    ShadowCat Configuration Manager                     ║
    ║                            Usage Guide                                ║
    ╚═══════════════════════════════════════════════════════════════════════╝

    📋 AVAILABLE ACTIONS:

    list                    - List all configuration files
    validate               - Validate a configuration file
    create-config          - Create new configuration template
    merge-configs          - Merge multiple configurations

    💡 USAGE EXAMPLES:

    # List all configurations
    .\ShadowCat-ConfigManager.ps1 -Action list

    # Validate a configuration
    .\ShadowCat-ConfigManager.ps1 -Action validate -ConfigFile "ShadowCat-web-tools.json"

    # Create new configuration template
    .\ShadowCat-ConfigManager.ps1 -Action create-config -ConfigFile "wireless"

    # Merge configurations
    .\ShadowCat-ConfigManager.ps1 -Action merge-configs `
        -MergeConfigs "shadowcat-essential-tools.json","shadowcat-web-tools.json" `
        -OutputConfig "shadowcat-pentesting-suite.json"

     CONFIGURATION MANAGEMENT:

    - All configuration files are stored in the 'configs' directory
    - Configuration files follow the naming pattern: shadowcat-[category]-tools.json
    - Each configuration includes metadata, tool definitions, and installation parameters
    - Use validation before deploying configurations to avoid installation issues

     SUPPORT:

    Project BlackCat Security Toolkit

"@ -ForegroundColor White
}

# Main execution logic
if (-not $Action) {
    Show-Usage
    exit 0
}

Write-ShadowCatHeader

switch ($Action) {
    "list" {
        Show-ConfigurationList
    }
    "validate" {
        if (-not $ConfigFile) {
            Write-Host "[ShadowCat] ConfigFile parameter required for validation" -ForegroundColor Red
            exit 1
        }

        $configPath = $ConfigFile
        if (-not [System.IO.Path]::IsPathRooted($ConfigFile)) {
            $configPath = Join-Path (Get-ConfigDirectory) $ConfigFile
        }

        Test-ConfigurationFile -ConfigPath $configPath
    }
    "create-config" {
        if (-not $ConfigFile) {
            Write-Host "[ShadowCat] ConfigFile parameter required (category name)" -ForegroundColor Red
            exit 1
        }
        New-ConfigurationTemplate -ConfigName $ConfigFile
    }
    "merge-configs" {
        if (-not $MergeConfigs -or $MergeConfigs.Count -lt 2) {
            Write-Host "[ShadowCat] MergeConfigs parameter required (at least 2 files)" -ForegroundColor Red
            exit 1
        }
        if (-not $OutputConfig) {
            Write-Host "[ShadowCat] OutputConfig parameter required" -ForegroundColor Red
            exit 1
        }
        Merge-ConfigurationFiles -ConfigFiles $MergeConfigs -OutputFile $OutputConfig
    }
    default {
        Write-Host "[ShadowCat] Unknown action: $Action" -ForegroundColor Red
        Show-Usage
        exit 1
    }
}