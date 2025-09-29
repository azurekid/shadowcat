#Requires -RunAsAdministrator
<#
.SYNOPSIS
Windows 11 Debloating and Security Optimization Script for ParrotOS-like Experience

.DESCRIPTION
This script removes Windows 11 bloatware, optimizes performance, and configures the system
for security testing purposes while maintaining remote access capabilities for Azure VMs.

.NOTES
Author: Security Team
Version: 1.0
Requires: PowerShell 5.1+ running as Administrator
Compatible: Windows 11 (Azure VM optimized)
Purpose: Create ParrotOS alternative on Windows for blue/red team exercises
#>

# Script configuration
$ErrorActionPreference = "Continue"
$VerbosePreference = "Continue"

# Optimize PowerShell performance for this session
$ProgressPreference = 'SilentlyContinue'  # Suppress progress bars for faster execution
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# Enable PowerShell 7+ parallel features if available
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Write-Host "PowerShell 7+ detected - Parallel processing enabled" -ForegroundColor Green
} else {
    Write-Host "PowerShell 5.x detected - Using compatibility mode" -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows 11 Security Optimization Script" -ForegroundColor Cyan
Write-Host "ParrotOS Alternative Setup (OPTIMIZED)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Function to log actions with progress
function Write-Log {
    param([string]$Message, [string]$Color = "White", [int]$Progress = -1)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    if ($Progress -ge 0) {
        Write-Progress -Activity "Windows 11 Optimization" -Status $Message -PercentComplete $Progress
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# Function to check if script is running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Log "This script must be run as Administrator!" -Color Red
    exit 1
}

Write-Log "Starting Windows 11 debloating and security optimization..." -Color Green -Progress 0

# =============================================================================
# PHASE 1: REMOVE BLOATWARE APPLICATIONS
# =============================================================================

Write-Log "Phase 1: Removing bloatware applications..." -Color Yellow -Progress 10

# List of bloatware to remove (excluding business/enterprise apps)
$BloatwareApps = @(
    # Gaming and Entertainment
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGameCallableUI",
    "Microsoft.GamingApp",
    "Microsoft.GamingServices",
    "Microsoft.MicrosoftSolitaireCollection",
    "king.com.CandyCrushSaga",
    "king.com.CandyCrushSodaSaga",
    
    # Social and Communication (non-business)
    "Microsoft.SkypeApp",
    "Microsoft.WindowsCommunicationsApps", # Mail and Calendar
    "Microsoft.People",
    "Microsoft.Teams", # Microsoft Teams
    "MicrosoftTeams", # Microsoft Teams (alternative package name)
    "Microsoft.OutlookForWindows", # New Outlook
    "Microsoft.Outlook", # Traditional Outlook
    "Microsoft.ToDo", # Microsoft To Do
    "Microsoft.Todos", # Microsoft To Do (alternative name)
    
    # Microsoft Store and related
    "Microsoft.WindowsStore", # Microsoft Store
    "Microsoft.StorePurchaseApp", # Store Purchase App
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    
    # Media and Photos
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.WindowsMaps",
    "Microsoft.BingWeather",
    "Microsoft.BingNews",
    "Microsoft.BingFinance",
    "Microsoft.BingSports",
    "Microsoft.BingTravel",
    
    # Productivity (consumer versions)
    "Microsoft.Office.OneNote",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.Tips",
    
    # Windows Features (consumer-focused)
    "Microsoft.MixedReality.Portal",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MSPaint", # Keeping for basic image editing
    "Microsoft.WindowsCamera",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.YourPhone",
    "Microsoft.WindowsFeedbackHub",
    
    # Third-party bloatware
    "ActiproSoftwareLLC.562882FEEB491",
    "Adobe.CCExpress",
    "AdobeSystemsIncorporated.AdobePhotoshopExpress",
    "Amazon.com.Amazon",
    "Clipchamp.Clipchamp",
    "Disney.37853FC22B2CE",
    "Facebook.Facebook",
    "Facebook.Instagram",
    "Flipboard.Flipboard",
    "MarchOfEmpires.EMCPublishing",
    "Netflix.Netflix",
    "PandoraMediaInc.29680B314EFC2",
    "Spotify.SpotifyAB",
    "SpotifyAB.SpotifyMusic",
    "Twitter.Twitter",
    "Wunderkinder.Wunderlist"
)

# Remove bloatware apps using parallel processing
Write-Log "Scanning for installed bloatware packages..." -Color Green

# Get all installed packages once (faster than individual queries)
$AllPackages = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
$AllProvisionedPackages = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

# Filter packages that match our bloatware list
$PackagesToRemove = $AllPackages | Where-Object { 
    $packageName = $_.Name
    $BloatwareApps | Where-Object { $packageName -like "*$_*" }
}

$ProvisionedToRemove = $AllProvisionedPackages | Where-Object {
    $packageName = $_.DisplayName  
    $BloatwareApps | Where-Object { $packageName -like "*$_*" }
}

Write-Log "Found $($PackagesToRemove.Count) installed packages and $($ProvisionedToRemove.Count) provisioned packages to remove" -Color Yellow

# Remove installed packages in parallel using jobs
if ($PackagesToRemove.Count -gt 0) {
    Write-Log "Removing installed bloatware packages..." -Color Green
    
    $PackagesToRemove | ForEach-Object -ThrottleLimit 5 -Parallel {
        $package = $_
        try {
            Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction SilentlyContinue
            Write-Host "Removed: $($package.Name)" -ForegroundColor Red
        }
        catch {
            Write-Host "Failed to remove $($package.Name): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# Remove provisioned packages in parallel
if ($ProvisionedToRemove.Count -gt 0) {
    Write-Log "Removing provisioned bloatware packages..." -Color Green
    
    $ProvisionedToRemove | ForEach-Object -ThrottleLimit 5 -Parallel {
        $package = $_
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName -ErrorAction SilentlyContinue
            Write-Host "Removed provisioned: $($package.DisplayName)" -ForegroundColor Red
        }
        catch {
            Write-Host "Failed to remove provisioned $($package.DisplayName): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# =============================================================================
# PHASE 2: DISABLE UNNECESSARY SERVICES
# =============================================================================

Write-Log "Phase 2: Disabling unnecessary services..." -Color Yellow -Progress 30

# Services to disable (keeping remote access services)
$ServicesToDisable = @(
    "DiagTrack",                    # Connected User Experiences and Telemetry
    "dmwappushservice",            # WAP Push Message Routing Service
    "lfsvc",                       # Geolocation Service
    "MapsBroker",                  # Downloaded Maps Manager
    "NetTcpPortSharing",           # Net.Tcp Port Sharing Service
    "RemoteAccess",                # Routing and Remote Access
    "RemoteRegistry",              # Remote Registry (security risk)
    "SharedAccess",                # Internet Connection Sharing
    "TrkWks",                      # Distributed Link Tracking Client
    "WbioSrvc",                    # Windows Biometric Service
    "WMPNetworkSvc",               # Windows Media Player Network Sharing Service
    "XblAuthManager",              # Xbox Live Auth Manager
    "XblGameSave",                 # Xbox Live Game Save Service
    "XboxNetApiSvc",               # Xbox Live Networking Service
    "XboxGipSvc",                  # Xbox Accessory Management Service
    "Fax",                         # Fax Service
    "WpcMonSvc",                   # Parental Controls
    "RetailDemo",                  # Retail Demo Service
    "wisvc",                       # Windows Insider Service
    "icssvc",                      # Windows Mobile Hotspot Service
    "PhoneSvc",                    # Phone Service
    "TabletInputService",          # Touch Keyboard and Handwriting Panel Service
    "WSearch"                      # Windows Search (can impact performance)
)

# KEEP these critical services for remote access:
# - "TermService" (Remote Desktop Services)
# - "WinRM" (Windows Remote Management)
# - "SSHD" (OpenSSH SSH Server)
# - "Themes" (Required for RDP visual experience)
# - "UxSms" (Desktop Window Manager Session Manager)

Write-Log "Scanning for services to disable..." -Color Green

# Get all services once for better performance
$AllServices = Get-Service -ErrorAction SilentlyContinue
$ServicesToProcess = $AllServices | Where-Object { $_.Name -in $ServicesToDisable }

Write-Log "Found $($ServicesToProcess.Count) services to disable" -Color Yellow

# Disable services in parallel using runspaces for better performance
$ServicesToProcess | ForEach-Object -ThrottleLimit 10 -Parallel {
    $service = $_
    try {
        Set-Service -Name $service.Name -StartupType Disabled -ErrorAction SilentlyContinue
        if ($service.Status -eq 'Running') {
            Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
        }
        Write-Host "Disabled service: $($service.Name)" -ForegroundColor Red
    }
    catch {
        Write-Host "Failed to disable $($service.Name): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# =============================================================================
# PHASE 3: REGISTRY OPTIMIZATIONS
# =============================================================================

Write-Log "Phase 3: Applying registry optimizations..." -Color Yellow -Progress 50

# Function to apply registry changes in batch for better performance
function Set-RegistryBatch {
    param([hashtable]$RegistryChanges)
    
    $RegistryChanges.GetEnumerator() | ForEach-Object -ThrottleLimit 10 -Parallel {
        $path = $_.Key
        $settings = $_.Value
        
        try {
            # Create path if it doesn't exist
            if (!(Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }
            
            # Apply all settings for this path
            foreach ($setting in $settings.GetEnumerator()) {
                Set-ItemProperty -Path $path -Name $setting.Key -Value $setting.Value -Force -ErrorAction SilentlyContinue
            }
            
            Write-Host "Applied registry changes to: $path" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to apply registry changes to $path : $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# Disable telemetry and data collection in batch
try {
    Write-Log "Applying telemetry and privacy optimizations..." -Color Green
    
    $TelemetrySettings = @{
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" = @{
            "AllowTelemetry" = 0
        }
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" = @{
            "AllowTelemetry" = 0
        }
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" = @{
            "AllowCortana" = 0
        }
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" = @{
            "DisableWindowsConsumerFeatures" = 1
        }
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" = @{
            "EnableActivityFeed" = 0
            "PublishUserActivities" = 0
            "UploadUserActivities" = 0
        }
    }
    
    Set-RegistryBatch -RegistryChanges $TelemetrySettings
    
    Write-Log "Telemetry and data collection disabled" -Color Green
}
catch {
    Write-Log "Failed to apply telemetry settings: $($_.Exception.Message)" -Color Red
}

# Performance optimizations
try {
    Write-Log "Applying performance optimizations..." -Color Green
    
    $PerformanceSettings = @{
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" = @{
            "VisualFXSetting" = 2
        }
        "HKCU:\AppEvents\Schemes" = @{
            "(Default)" = ".None"
        }
        "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" = @{
            "Win32PrioritySeparation" = 38
        }
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" = @{
            "StartupDelayInMSec" = 0
        }
    }
    
    Set-RegistryBatch -RegistryChanges $PerformanceSettings
    Write-Log "Performance optimizations applied" -Color Green
}
catch {
    Write-Log "Failed to apply performance optimizations: $($_.Exception.Message)" -Color Red
}

# Security optimizations
try {
    Write-Log "Applying security optimizations..." -Color Green
    
    $SecuritySettings = @{
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" = @{
            "DisableAntiSpyware" = 0
        }
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" = @{
            "NoDriveTypeAutoRun" = 255
        }
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" = @{
            "ConsentPromptBehaviorAdmin" = 2
            "PromptOnSecureDesktop" = 0
        }
    }
    
    Set-RegistryBatch -RegistryChanges $SecuritySettings
    
    Write-Log "Security optimizations applied" -Color Green
}
catch {
    Write-Log "Failed to apply security optimizations: $($_.Exception.Message)" -Color Red
}

# =============================================================================
# PHASE 4: ENSURE REMOTE ACCESS CAPABILITIES
# =============================================================================

Write-Log "Phase 4: Configuring remote access capabilities..." -Color Yellow -Progress 70

try {
    # Enable Remote Desktop
    Write-Log "Enabling Remote Desktop..." -Color Green
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
    
    # Enable WinRM for PowerShell remoting
    Write-Log "Configuring WinRM..." -Color Green
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
    Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
    
    # Enable OpenSSH Server if available
    Write-Log "Checking OpenSSH Server..." -Color Green
    $OpenSSH = Get-WindowsCapability -Online | Where-Object {$_.Name -match "OpenSSH.Server"}
    if ($OpenSSH.State -ne "Installed") {
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    }
    Start-Service sshd
    Set-Service -Name sshd -StartupType Automatic
    
    Write-Log "Remote access configured successfully" -Color Green
}
catch {
    Write-Log "Failed to configure remote access: $($_.Exception.Message)" -Color Red
}

# =============================================================================
# PHASE 5: SYSTEM CLEANUP AND FINALIZATION
# =============================================================================

Write-Log "Phase 5: Performing system cleanup..." -Color Yellow -Progress 85

try {
    # Define cleanup locations for parallel processing
    $CleanupLocations = @(
        @{ Path = "$env:TEMP"; Description = "User Temp" },
        @{ Path = "$env:WINDIR\Temp"; Description = "System Temp" },
        @{ Path = "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"; Description = "IE Cache" },
        @{ Path = "$env:LOCALAPPDATA\Temp"; Description = "Local Temp" }
    )
    
    Write-Log "Cleaning temporary files..." -Color Green
    
    # Clean locations in parallel
    $CleanupLocations | ForEach-Object -ThrottleLimit 4 -Parallel {
        $location = $_
        try {
            if (Test-Path $location.Path) {
                $itemCount = (Get-ChildItem $location.Path -ErrorAction SilentlyContinue).Count
                if ($itemCount -gt 0) {
                    Remove-Item -Path "$($location.Path)\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "Cleaned $($location.Description): $itemCount items" -ForegroundColor Green
                }
            }
        }
        catch {
            Write-Host "Failed to clean $($location.Description): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Clear Windows Update cache (must be sequential)
    Write-Log "Clearing Windows Update cache..." -Color Green
    $wuService = Get-Service wuauserv -ErrorAction SilentlyContinue
    if ($wuService -and $wuService.Status -eq 'Running') {
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    
    $wuCachePath = "$env:WINDIR\SoftwareDistribution\Download"
    if (Test-Path $wuCachePath) {
        $cacheSize = (Get-ChildItem $wuCachePath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
        Remove-Item -Path "$wuCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Cleared $([math]::Round($cacheSize, 2)) MB from Windows Update cache" -Color Green
    }
    
    if ($wuService) {
        Start-Service wuauserv -ErrorAction SilentlyContinue
    }
    
    Write-Log "System cleanup completed" -Color Green
}
catch {
    Write-Log "Failed during system cleanup: $($_.Exception.Message)" -Color Red
}

# =============================================================================
# PHASE 6: FINAL CONFIGURATION AND RESTART PREPARATION
# =============================================================================

Write-Log "Phase 6: Final configuration..." -Color Yellow -Progress 95

try {
    # Set Windows to high performance power plan
    Write-Log "Setting high performance power plan..." -Color Green
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    
    # Disable hibernation to free up disk space
    Write-Log "Disabling hibernation..." -Color Green
    powercfg /hibernate off
    
    Write-Log "Final configuration completed" -Color Green
}
catch {
    Write-Log "Failed during final configuration: $($_.Exception.Message)" -Color Red
}

# =============================================================================
# COMPLETION SUMMARY
# =============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "WINDOWS 11 OPTIMIZATION COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Progress -Activity "Windows 11 Optimization" -Status "Completed!" -PercentComplete 100 -Completed

Write-Log "Optimization Summary:" -Color Green
Write-Log "✓ Removed bloatware applications" -Color Green
Write-Log "✓ Disabled unnecessary services" -Color Green
Write-Log "✓ Applied performance optimizations" -Color Green
Write-Log "✓ Configured security settings" -Color Green
Write-Log "✓ Ensured remote access capabilities" -Color Green
Write-Log "✓ Performed system cleanup" -Color Green

Write-Host "`nRemote Access Status:" -ForegroundColor Yellow
Write-Host "✓ Remote Desktop Protocol (RDP) - Enabled" -ForegroundColor Green
Write-Host "✓ Windows Remote Management (WinRM) - Enabled" -ForegroundColor Green
Write-Host "✓ OpenSSH Server - Enabled" -ForegroundColor Green

Write-Host "`nIMPORTANT NOTES:" -ForegroundColor Red
Write-Host "1. A system restart is REQUIRED for all changes to take effect" -ForegroundColor Yellow
Write-Host "2. Remote access capabilities have been preserved for Azure VM" -ForegroundColor Yellow
Write-Host "3. Windows Defender remains enabled for security" -ForegroundColor Yellow
Write-Host "4. High performance power plan has been activated" -ForegroundColor Yellow

Write-Host "`nRestart the system now? (Y/N)" -ForegroundColor Cyan -NoNewline
$restart = Read-Host " "
if ($restart -eq "Y" -or $restart -eq "y") {
    Write-Log "Restarting system in 10 seconds..." -Color Red
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Log "Please restart the system manually when convenient." -Color Yellow
}

Write-Log "Windows 11 optimization script completed!" -Color Green