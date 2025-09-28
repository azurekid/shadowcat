# =============================================================================
# ShadowCat-HighPerformance-Installer.ps1
# High-performance version of ShadowCat installer with parallel processing
# =============================================================================

<#
.SYNOPSIS
    High-performance ShadowCat security toolkit installer with parallel processing

.DESCRIPTION
    This optimized installer uses parallel processing, batch operations, and caching
    to dramatically improve installation speed of security tools.

.PARAMETER ConfigFiles
    Array of configuration files to process

.PARAMETER InstallLevel
    Installation level: lite, standard, professional, or all

.PARAMETER InstallPath
    Custom installation path (default: C:\ShadowCat\SecurityTools)

.PARAMETER Online
    Fetch configurations from GitHub instead of local files

.PARAMETER DryRun
    Preview what would be installed without actually installing

.PARAMETER MaxJobs
    Maximum parallel jobs (default: CPU cores * 2, max 8)

.PARAMETER BatchSize
    Package batch size for parallel installation (default: 10)

.EXAMPLE
    # High-performance professional installation
    .\ShadowCat-HighPerformance-Installer.ps1 -ConfigFiles "shadowcat-professional-profile.json" -MaxJobs 8

    # Fast category installation with custom batch size
    .\ShadowCat-HighPerformance-Installer.ps1 -ConfigFiles "shadowcat-redteam-tools.json" -BatchSize 15

    # Parallel multi-category installation
    .\ShadowCat-HighPerformance-Installer.ps1 -ConfigFiles @("shadowcat-web-tools.json", "shadowcat-osint-tools.json") -MaxJobs 12
#>

param(
    [Parameter(Mandatory=$false)]
    [string[]]$ConfigFiles = @(),

    [Parameter(Mandatory=$false)]
    [ValidateSet("lite", "standard", "professional", "all")]
    [string]$InstallLevel = "",

    [Parameter(Mandatory=$false)]
    [string]$InstallPath = $(if ($IsLinux -or $IsMacOS) { "/tmp/ShadowCat/SecurityTools" } else { "C:\ShadowCat\SecurityTools" }),

    [Parameter(Mandatory=$false)]
    [switch]$Online,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [int]$MaxJobs = [Math]::Min([Environment]::ProcessorCount * 2, 8),

    [Parameter(Mandatory=$false)]
    [int]$BatchSize = 10
)

# Global script variables
$script:InstallPath = $InstallPath
$script:DryRun = $DryRun.IsPresent
$script:Online = $Online.IsPresent
$script:InstallLevel = if ([string]::IsNullOrEmpty($InstallLevel)) { "standard" } else { $InstallLevel }
$script:PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:StartTime = Get-Date
$script:InstalledTools = @{}
$script:SkippedTools = @{}
$script:ProcessedConfigs = @{}
$script:ToolCategories = @{}
$script:MaxParallelJobs = $MaxJobs
$script:BatchSize = $BatchSize

# Performance metrics
$script:TotalPackages = 0
$script:InstallationStats = @{
    Chocolatey = @{ Installed = 0; Failed = 0; Skipped = 0 }
    Scoop = @{ Installed = 0; Failed = 0; Skipped = 0 }
    GitHub = @{ Installed = 0; Failed = 0; Skipped = 0 }
    Python = @{ Installed = 0; Failed = 0; Skipped = 0 }
}

function Write-ShadowCatLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error", "Header", "Debug")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $colors = @{
        "Info" = "White"
        "Success" = "Green"
        "Warning" = "Yellow"
        "Error" = "Red"
        "Header" = "Cyan"
        "Debug" = "Gray"
    }

    $prefix = switch ($Level) {
        "Header" { "[ShadowCat] [>>>]" }
        "Success" { "[ShadowCat] [✓]" }
        "Warning" { "[ShadowCat] [⚠]" }
        "Error" { "[ShadowCat] [✗]" }
        "Debug" { "[ShadowCat] [DBG]" }
        default { "[ShadowCat] [i]" }
    }

    Write-Host "$timestamp $prefix $Message" -ForegroundColor $colors[$Level]
}

function Show-PerformanceBanner {
    Clear-Host
    Write-Host @"

 ███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗ ██████╗ █████╗ ████████╗
 ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔══██╗╚══██╔══╝
 ███████╗███████║███████║██║  ██║██║   ██║██║ █╗ ██║██║     ███████║   ██║
 ╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║███╗██║██║     ██╔══██║   ██║
 ███████║██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝╚██████╗██║  ██║   ██║
 ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝  ╚═════╝╚═╝  ╚═╝   ╚═╝

"@ -ForegroundColor Red

    Write-Host "                    � HIGH-PERFORMANCE INSTALLER �" -ForegroundColor Cyan
    Write-Host "                     Parallel • Optimized • Blazing Fast" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔥 Performance Configuration:" -ForegroundColor Cyan
    Write-Host "   • Max Parallel Jobs: $MaxJobs" -ForegroundColor White
    Write-Host "   • Batch Size: $BatchSize" -ForegroundColor White
    Write-Host "   • CPU Cores: $([Environment]::ProcessorCount)" -ForegroundColor White
    Write-Host "   • Install Path: $InstallPath" -ForegroundColor White
    Write-Host ""
}

function Test-ToolInstallation {
    param($tool, $source)

    # Quick check - if we already processed this tool, don't check again
    $toolId = if ($tool.toolId) { $tool.toolId } else { $tool.name }
    if ($script:InstalledTools.ContainsKey($toolId)) {
        return $false
    }

    return $true  # Simplified for performance - let package managers handle duplicates
}

function Initialize-HighPerformanceEnvironment {
    Write-ShadowCatLog "Initializing high-performance environment..." -Level "Header"

    # Load required modules (dot-source them)
    $modulesPath = Join-Path $script:PSScriptRoot "modules"
    $moduleFiles = @(
        "ShadowCat-UI.ps1",
        "ShadowCat-Config.ps1",
        "ShadowCat-PackageManagers.ps1",
        "ShadowCat-PerformanceOptimizations.ps1"
    )

    foreach ($moduleFile in $moduleFiles) {
        $modulePath = Join-Path $modulesPath $moduleFile
        if (Test-Path $modulePath) {
            . $modulePath
            Write-ShadowCatLog "Loaded module: $moduleFile" -Level "Debug"
            
            # Verify key functions are loaded
            if ($moduleFile -eq "ShadowCat-Config.ps1") {
                if (Get-Command "Resolve-ConfigDependencies" -ErrorAction SilentlyContinue) {
                    Write-ShadowCatLog "✓ Resolve-ConfigDependencies function loaded" -Level "Debug"
                } else {
                    Write-ShadowCatLog "✗ Resolve-ConfigDependencies function NOT loaded" -Level "Error"
                }
            }
        } else {
            Write-ShadowCatLog "Module not found: $moduleFile" -Level "Error"
            throw "Required module missing: $moduleFile"
        }
    }

    # Initialize performance mode
    Initialize-PerformanceMode -InstallPath $script:InstallPath

    # Create install directory
    if (-not (Test-Path $script:InstallPath)) {
        New-Item -Path $script:InstallPath -ItemType Directory -Force | Out-Null
    }

    Write-ShadowCatLog "Environment initialized successfully" -Level "Success"
}

function Load-Configuration {
    param([string]$ConfigFile)
    
    $configPath = $null
    if ($script:Online) {
        # Online mode - fetch from GitHub
        $configUrl = "https://raw.githubusercontent.com/azurekid/shadowcat/main/configs/$ConfigFile"
        try {
            $configContent = Invoke-WebRequest -Uri $configUrl -UseBasicParsing | Select-Object -ExpandProperty Content
            $config = $configContent | ConvertFrom-Json
            Write-ShadowCatLog "Downloaded configuration: $ConfigFile" -Level "Info"
            return $config
        }
        catch {
            Write-ShadowCatLog "Failed to download configuration: $ConfigFile" -Level "Error"
            return $null
        }
    } else {
        # Local mode
        $configPath = Join-Path (Join-Path $script:PSScriptRoot "configs") $ConfigFile
        if (Test-Path $configPath) {
            try {
                $config = Get-Content $configPath -Raw | ConvertFrom-Json
                Write-ShadowCatLog "Loaded local configuration: $ConfigFile" -Level "Info"
                return $config
            }
            catch {
                Write-ShadowCatLog "Failed to load configuration: $ConfigFile" -Level "Error"
                return $null
            }
        } else {
            Write-ShadowCatLog "Configuration file not found: $ConfigFile" -Level "Error"
            return $null
        }
    }
}

function Install-ConfigurationsParallel {
    param([array]$ConfigFiles)

    Write-ShadowCatLog "Processing $($ConfigFiles.Count) configurations in parallel..." -Level "Header"

    # Always ensure core base config is included
    $coreBaseConfig = "shadowcat-core-base.json"
    if ($ConfigFiles -notcontains $coreBaseConfig) {
        Write-ShadowCatLog "Adding required core base configuration" -Level "Info"
        $ConfigFiles += $coreBaseConfig
    }

    # Load all configurations
    $allChocolateyPackages = @()
    $allScoopPackages = @()
    $allGitHubProjects = @()
    $allPythonPackages = @()

    foreach ($configFile in $ConfigFiles) {
        $config = Load-Configuration -ConfigFile $configFile

        if ($null -eq $config) { continue }

        Write-ShadowCatLog "Processing configuration: $($config.metadata.name)" -Level "Info"

        # Filter packages based on install level
        if ($config.chocolatey -and $config.chocolatey.packages) {
            $filteredPackages = $config.chocolatey.packages | Where-Object {
                $_.installLevel -eq $null -or $_.installLevel -eq $script:InstallLevel -or 
                ($script:InstallLevel -eq "standard" -and $_.installLevel -in @("lite", "standard")) -or
                ($script:InstallLevel -eq "professional" -and $_.installLevel -in @("lite", "standard", "professional")) -or
                ($script:InstallLevel -eq "all")
            }
            $allChocolateyPackages += $filteredPackages
        }
        if ($config.scoop -and $config.scoop.packages) {
            $filteredPackages = $config.scoop.packages | Where-Object {
                $_.installLevel -eq $null -or $_.installLevel -eq $script:InstallLevel -or 
                ($script:InstallLevel -eq "standard" -and $_.installLevel -in @("lite", "standard")) -or
                ($script:InstallLevel -eq "professional" -and $_.installLevel -in @("lite", "standard", "professional")) -or
                ($script:InstallLevel -eq "all")
            }
            $allScoopPackages += $filteredPackages
        }
        if ($config.github -and $config.github.projects) {
            $filteredPackages = $config.github.projects | Where-Object {
                $_.installLevel -eq $null -or $_.installLevel -eq $script:InstallLevel -or 
                ($script:InstallLevel -eq "standard" -and $_.installLevel -in @("lite", "standard")) -or
                ($script:InstallLevel -eq "professional" -and $_.installLevel -in @("lite", "standard", "professional")) -or
                ($script:InstallLevel -eq "all")
            }
            $allGitHubProjects += $filteredPackages
        }
        if ($config.python -and $config.python.packages) {
            $filteredPackages = $config.python.packages | Where-Object {
                $_.installLevel -eq $null -or $_.installLevel -eq $script:InstallLevel -or 
                ($script:InstallLevel -eq "standard" -and $_.installLevel -in @("lite", "standard")) -or
                ($script:InstallLevel -eq "professional" -and $_.installLevel -in @("lite", "standard", "professional")) -or
                ($script:InstallLevel -eq "all")
            }
            $allPythonPackages += $filteredPackages
        }
    }

    # Update total package count for metrics
    $script:TotalPackages = $allChocolateyPackages.Count + $allScoopPackages.Count + $allGitHubProjects.Count + $allPythonPackages.Count
    Write-ShadowCatLog "Total packages to process: $script:TotalPackages" -Level "Info"

    # Launch parallel installation jobs for each package manager
    $jobs = @()

    if ($allChocolateyPackages.Count -gt 0) {
        Write-ShadowCatLog "Starting Chocolatey batch installation ($($allChocolateyPackages.Count) packages)..." -Level "Info"
        $jobs += Start-Job -Name "ChocolateyInstaller" -ScriptBlock {
            param($packages, $installPath, $dryRun, $batchSize)
            # Install chocolatey packages in batches
            Install-ChocolateyPackagesParallel -packages $packages -configName "BatchedConfigs"
        } -ArgumentList $allChocolateyPackages, $script:InstallPath, $script:DryRun, $script:BatchSize
    }

    if ($allScoopPackages.Count -gt 0) {
        Write-ShadowCatLog "Starting Scoop batch installation ($($allScoopPackages.Count) packages)..." -Level "Info"
        $scoopConfig = @{ packages = $allScoopPackages; buckets = @("main", "extras") }
        $jobs += Start-Job -Name "ScoopInstaller" -ScriptBlock {
            param($scoopConfig, $installPath, $dryRun, $batchSize)
            Install-ScoopPackagesParallel -scoopConfig $scoopConfig -configName "BatchedConfigs"
        } -ArgumentList $scoopConfig, $script:InstallPath, $script:DryRun, $script:BatchSize
    }

    if ($allGitHubProjects.Count -gt 0) {
        Write-ShadowCatLog "Starting GitHub parallel cloning ($($allGitHubProjects.Count) repositories)..." -Level "Info"
        $jobs += Start-Job -Name "GitHubInstaller" -ScriptBlock {
            param($projects, $installPath, $dryRun, $maxJobs)
            $destination = Join-Path $installPath "GitHub-Projects"
            if (-not (Test-Path $destination)) { New-Item -Path $destination -ItemType Directory -Force | Out-Null }
            Install-GitHubProjectsParallel -packages $projects -configName "BatchedConfigs" -destination $destination
        } -ArgumentList $allGitHubProjects, $script:InstallPath, $script:DryRun, $script:MaxParallelJobs
    }

    if ($allPythonPackages.Count -gt 0) {
        Write-ShadowCatLog "Starting Python batch installation ($($allPythonPackages.Count) packages)..." -Level "Info"
        $jobs += Start-Job -Name "PythonInstaller" -ScriptBlock {
            param($packages, $installPath, $dryRun)
            Install-PythonPackagesParallel -packages $packages -configName "BatchedConfigs"
        } -ArgumentList $allPythonPackages, $script:InstallPath, $script:DryRun
    }

    # Monitor job progress
    if ($jobs.Count -gt 0) {
        Write-ShadowCatLog "Running $($jobs.Count) parallel installation jobs..." -Level "Info"

        # Wait for all jobs with progress monitoring
        $completed = 0
        $totalJobs = $jobs.Count

        while ($completed -lt $totalJobs) {
            $runningJobs = $jobs | Where-Object { $_.State -eq 'Running' }
            $finishedJobs = $jobs | Where-Object { $_.State -eq 'Completed' -or $_.State -eq 'Failed' }

            foreach ($job in $finishedJobs) {
                if ($job.State -eq 'Completed') {
                    Write-ShadowCatLog "✓ Job '$($job.Name)' completed successfully" -Level "Success"
                } else {
                    Write-ShadowCatLog "✗ Job '$($job.Name)' failed" -Level "Error"
                    $errorMessage = Receive-Job $job -ErrorAction SilentlyContinue
                    if ($errorMessage) {
                        Write-ShadowCatLog "Error details: $errorMessage" -Level "Error"
                    }
                }
                Remove-Job $job
                $completed++
            }

            # Update progress
            $progress = [math]::Round(($completed / $totalJobs) * 100)
            Write-Progress -Activity "High-Performance Installation" -Status "Jobs: $completed of $totalJobs completed" -PercentComplete $progress

            # Remove processed jobs
            $jobs = $jobs | Where-Object { $_.State -eq 'Running' }

            Start-Sleep -Milliseconds 500
        }

        Write-Progress -Activity "High-Performance Installation" -Completed
    }

    Write-ShadowCatLog "All parallel installation jobs completed" -Level "Success"
}

function Show-InstallLevelMenu {
    Write-Host "`nSelect Installation Level:" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host "1. Lite        - Minimal tools (core base + lite)" -ForegroundColor White
    Write-Host "2. Standard    - Medium toolkit (core + lite + standard)" -ForegroundColor White
    Write-Host "3. Professional- Advanced toolkit (core + lite + standard + professional)" -ForegroundColor White
    Write-Host "4. All         - Everything available (all config options)" -ForegroundColor White
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
    
    Write-Host "`nSelect Tool Configurations for $($InstallLevel.ToUpper()) Level:" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "Note: Core Base will be automatically included" -ForegroundColor Green
    Write-Host ""
    
    $configs = @{}
    $configPath = Join-Path $script:PSScriptRoot "configs"
    
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

function Show-PerformanceReport {
    $endTime = Get-Date
    $duration = $endTime - $script:StartTime
    $totalInstalled = ($script:InstallationStats.Values | ForEach-Object { $_.Installed } | Measure-Object -Sum).Sum
    $totalFailed = ($script:InstallationStats.Values | ForEach-Object { $_.Failed } | Measure-Object -Sum).Sum

    Write-Host ""
    Write-ShadowCatLog "🎯 HIGH-PERFORMANCE INSTALLATION COMPLETE! 🎯" -Level "Header"
    Write-Host ""
    Write-Host "⏱️  Performance Metrics:" -ForegroundColor Cyan
    Write-Host "   • Total Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor Yellow
    Write-Host "   • Packages Processed: $script:TotalPackages" -ForegroundColor Yellow
    Write-Host "   • Average Speed: $([math]::Round($script:TotalPackages / $duration.TotalMinutes, 1)) packages/min" -ForegroundColor Yellow
    Write-Host "   • Parallel Jobs Used: $script:MaxParallelJobs" -ForegroundColor Yellow
    Write-Host "   • Batch Size: $script:BatchSize" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📊 Installation Results:" -ForegroundColor Cyan
    Write-Host "   • ✅ Successfully Installed: $totalInstalled" -ForegroundColor Green
    Write-Host "   • ❌ Failed: $totalFailed" -ForegroundColor Red
    Write-Host "   • Success Rate: $([math]::Round(($totalInstalled / ($totalInstalled + $totalFailed)) * 100, 1))%" -ForegroundColor $(if ($totalFailed -eq 0) { "Green" } else { "Yellow" })
    Write-Host ""

    if ($totalInstalled -gt 0) {
        Write-Host "🔧 Package Manager Breakdown:" -ForegroundColor Cyan
        foreach ($manager in $script:InstallationStats.Keys) {
            $stats = $script:InstallationStats[$manager]
            if ($stats.Installed -gt 0) {
                Write-Host "   • $manager`: $($stats.Installed) installed" -ForegroundColor White
            }
        }
    }

    Write-Host ""
    Write-ShadowCatLog "Installation completed in $($duration.ToString('mm\:ss')) - $([math]::Round($script:TotalPackages / $duration.TotalMinutes, 1)) packages/min!" -Level "Success"
    Write-Host ""
}

# Main execution
try {
    Show-PerformanceBanner

    # Interactive mode if no config files specified
    if ($ConfigFiles.Count -eq 0) {
        Write-ShadowCatLog "No configuration files specified. Starting interactive selection..." -Level "Info"
        
        do {
            $selectedLevel = Show-InstallLevelMenu
            $script:InstallLevel = $selectedLevel
            Write-ShadowCatLog "Selected install level: $selectedLevel" -Level "Info"
            
            if ($selectedLevel -eq "all") {
                # For "all", get all available configs
                $configPath = Join-Path $script:PSScriptRoot "configs"
                if (Test-Path $configPath) {
                    $ConfigFiles = Get-ChildItem -Path $configPath -Filter "*.json" | Select-Object -ExpandProperty Name
                    Write-ShadowCatLog "Selected all available configurations: $($ConfigFiles -join ', ')" -Level "Success"
                    break
                }
            } else {
                # For other levels, look for profile config specific to this level first
                $profileName = "shadowcat-$($selectedLevel)-profile.json"
                $profilePath = Join-Path $script:PSScriptRoot "configs" $profileName
                
                if (Test-Path $profilePath) {
                    # If a matching profile exists for this level, use it
                    $ConfigFiles = @($profileName)
                    Write-ShadowCatLog "Auto-selected profile for $selectedLevel level: $profileName" -Level "Success"
                    break
                } else {
                    # Show the menu with configs specific to this level
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
    }

    Write-ShadowCatLog "Starting high-performance installation..." -Level "Header"
    Write-ShadowCatLog "Target configurations: $($ConfigFiles -join ', ')" -Level "Info"
    Write-ShadowCatLog "Install level: $script:InstallLevel" -Level "Info"

    # Initialize environment
    Initialize-HighPerformanceEnvironment

    # Run parallel installation
    Install-ConfigurationsParallel -ConfigFiles $ConfigFiles

    # Show performance report
    Show-PerformanceReport

} catch {
    Write-ShadowCatLog "Critical error during installation: $($_.Exception.Message)" -Level "Error"
    Write-ShadowCatLog "Stack trace: $($_.ScriptStackTrace)" -Level "Debug"
    exit 1
}