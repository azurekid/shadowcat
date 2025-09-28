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
    [string]$InstallPath = "C:\ShadowCat\SecurityTools",

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

🚀 ███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗ ██████╗ █████╗ ████████╗
   ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔══██╗╚══██╔══╝
   ███████╗███████║███████║██║  ██║██║   ██║██║ █╗ ██║██║     ███████║   ██║
   ╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║███╗██║██║     ██╔══██║   ██║
   ███████║██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝╚██████╗██║  ██║   ██║
   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝  ╚═════╝╚═╝  ╚═╝   ╚═╝

                    🔥 HIGH-PERFORMANCE INSTALLER 🔥
                     Parallel • Optimized • Blazing Fast

"@ -ForegroundColor Red

    Write-Host "⚡ Performance Configuration:" -ForegroundColor Cyan
    Write-Host "   • Max Parallel Jobs: $MaxJobs" -ForegroundColor Yellow
    Write-Host "   • Batch Size: $BatchSize" -ForegroundColor Yellow
    Write-Host "   • CPU Cores: $([Environment]::ProcessorCount)" -ForegroundColor Yellow
    Write-Host "   • Install Path: $InstallPath" -ForegroundColor Yellow
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

    # Load required modules
    Import-Module "$script:PSScriptRoot\modules\ShadowCat-PerformanceOptimizations.ps1" -Force
    Import-Module "$script:PSScriptRoot\modules\ShadowCat-Config.ps1" -Force

    # Initialize performance mode
    Initialize-PerformanceMode -InstallPath $script:InstallPath

    # Create install directory
    if (-not (Test-Path $script:InstallPath)) {
        New-Item -Path $script:InstallPath -ItemType Directory -Force | Out-Null
    }

    Write-ShadowCatLog "Environment initialized successfully" -Level "Success"
}

function Install-ConfigurationsParallel {
    param([array]$ConfigFiles)

    Write-ShadowCatLog "Processing $($ConfigFiles.Count) configurations in parallel..." -Level "Header"

    # Load and merge all configurations first
    $allChocolateyPackages = @()
    $allScoopPackages = @()
    $allGitHubProjects = @()
    $allPythonPackages = @()

    foreach ($configFile in $ConfigFiles) {
        $config = Get-ProcessedConfig -ConfigFile $configFile -InstallLevel $InstallLevel -Online $script:Online

        if ($config) {
            if ($config.chocolatey -and $config.chocolatey.packages) {
                $allChocolateyPackages += $config.chocolatey.packages
            }
            if ($config.scoop -and $config.scoop.packages) {
                $allScoopPackages += $config.scoop.packages
            }
            if ($config.github -and $config.github.projects) {
                $allGitHubProjects += $config.github.projects
            }
            if ($config.python -and $config.python.packages) {
                $allPythonPackages += $config.python.packages
            }
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
        Write-ShadowCatLog "No configuration files specified. Available options:" -Level "Info"
        Write-Host "   • shadowcat-professional-profile.json (147 tools)" -ForegroundColor Yellow
        Write-Host "   • shadowcat-redteam-tools.json (23 tools)" -ForegroundColor Yellow
        Write-Host "   • shadowcat-web-tools.json (19 tools)" -ForegroundColor Yellow
        Write-Host "   • shadowcat-osint-tools.json (20 tools)" -ForegroundColor Yellow
        Write-Host ""

        $selection = Read-Host "Enter configuration file name or press Enter for professional profile"
        if ([string]::IsNullOrWhiteSpace($selection)) {
            $ConfigFiles = @("shadowcat-professional-profile.json")
        } else {
            $ConfigFiles = @($selection)
        }
    }

    Write-ShadowCatLog "Starting high-performance installation..." -Level "Header"
    Write-ShadowCatLog "Target configurations: $($ConfigFiles -join ', ')" -Level "Info"

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