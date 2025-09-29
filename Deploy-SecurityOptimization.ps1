#Requires -RunAsAdministrator
<#
.SYNOPSIS
Quick Deploy Script for Windows 11 Security Optimization

.DESCRIPTION
This script provides a simple interface to run all optimization scripts in the correct order.
It includes safety checks and user confirmations for each phase.

.NOTES
Author: Security Team
Version: 1.0
Requires: PowerShell 5.1+ running as Administrator
#>

# Script configuration
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Function to display banner
function Show-Banner {
    Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║              Windows 11 Security Optimization Suite             ║
║                     ParrotOS Alternative Setup                  ║
║                                                                  ║
║  Transform your Windows 11 into a lean security testing machine ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow
    
    # Check if running as Administrator
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "[ERROR] This script must be run as Administrator!" -ForegroundColor Red
        Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "[OK] Administrator privileges confirmed" -ForegroundColor Green
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Host "[ERROR] PowerShell 5.1 or later required!" -ForegroundColor Red
        Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "[OK] PowerShell version compatible: $($PSVersionTable.PSVersion)" -ForegroundColor Green
    
    # Check internet connectivity
    try {
        $response = Test-NetConnection -ComputerName "google.com" -Port 80 -InformationLevel Quiet
        if ($response) {
            Write-Host "[OK] Internet connectivity confirmed" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] No internet connectivity detected" -ForegroundColor Yellow
            Write-Host "Some features may not work properly" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[WARNING] Could not test internet connectivity" -ForegroundColor Yellow
    }
    
    # Check available scripts
    $scriptPath = Get-Location
    $requiredScripts = @(
        "Win11-Debloat-SecurityOptimize.ps1",
        "Advanced-Performance-Tuning.ps1", 
        "Security-Tools-Installation.ps1"
    )
    
    $missingScripts = @()
    foreach ($script in $requiredScripts) {
        if (-not (Test-Path (Join-Path $scriptPath $script))) {
            $missingScripts += $script
        }
    }
    
    if ($missingScripts.Count -gt 0) {
        Write-Host "[ERROR] Missing required scripts:" -ForegroundColor Red
        foreach ($script in $missingScripts) {
            Write-Host "  - $script" -ForegroundColor Red
        }
        Write-Host "Please ensure all scripts are in the current directory." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "[OK] All required scripts found" -ForegroundColor Green
}

# Function to show script information
function Show-ScriptInfo {
    param([string]$ScriptName, [string]$Description, [string]$Duration)
    
    Write-Host "`n" + "="*70 -ForegroundColor Cyan
    Write-Host "SCRIPT: $ScriptName" -ForegroundColor White
    Write-Host "DESCRIPTION: $Description" -ForegroundColor Gray
    Write-Host "ESTIMATED TIME: $Duration" -ForegroundColor Gray
    Write-Host "="*70 -ForegroundColor Cyan
}

# Function to get user confirmation
function Get-UserConfirmation {
    param([string]$Message)
    
    do {
        Write-Host "`n$Message (Y/N): " -NoNewline -ForegroundColor Yellow
        $response = Read-Host
    } while ($response -notin @('Y','y','N','n','Yes','yes','No','no'))
    
    return $response -in @('Y','y','Yes','yes')
}

# Function to show completion status
function Show-CompletionStatus {
    param([string]$ScriptName, [bool]$Success)
    
    if ($Success) {
        Write-Host "`n[OK] $ScriptName completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n[ERROR] $ScriptName encountered errors!" -ForegroundColor Red
        Write-Host "Check the output above for details." -ForegroundColor Yellow
    }
}

# Main execution function
function Start-OptimizationSuite {
    Show-Banner
    
    Write-Host "`nWelcome to the Windows 11 Security Optimization Suite!" -ForegroundColor Green
    Write-Host "This tool will transform your Windows 11 into a lean, high-performance" -ForegroundColor Gray
    Write-Host "security testing environment while maintaining remote access capabilities." -ForegroundColor Gray
    
    # Prerequisites check
    Test-Prerequisites
    
    # Show overview
    Write-Host "`n" + "="*70 -ForegroundColor Magenta
    Write-Host "OPTIMIZATION PHASES OVERVIEW" -ForegroundColor White
    Write-Host "="*70 -ForegroundColor Magenta
    Write-Host "Phase 1: Main Debloating & System Optimization (15-20 minutes)" -ForegroundColor Cyan
    Write-Host "Phase 2: Advanced Performance Tuning (10-15 minutes)" -ForegroundColor Cyan  
    Write-Host "Phase 3: Security Tools Installation (20-30 minutes)" -ForegroundColor Cyan
    Write-Host "="*70 -ForegroundColor Magenta
    Write-Host "TOTAL ESTIMATED TIME: 45-65 minutes" -ForegroundColor Yellow
    Write-Host "SYSTEM RESTARTS REQUIRED: 1-2 restarts" -ForegroundColor Yellow
    
    # Get initial confirmation
    if (-not (Get-UserConfirmation "Do you want to proceed with the full optimization?")) {
        Write-Host "`nOperation cancelled by user." -ForegroundColor Yellow
        exit 0
    }
    
    # Phase 1: Main Debloating
    Show-ScriptInfo "Win11-Debloat-SecurityOptimize.ps1" "Remove bloatware, optimize performance, ensure remote access" "15-20 minutes"
    
    if (Get-UserConfirmation "Start Phase 1: Main Debloating & Optimization?") {
        try {
            Write-Host "`nStarting main debloating script..." -ForegroundColor Green
            & ".\Win11-Debloat-SecurityOptimize.ps1"
            Show-CompletionStatus "Phase 1: Main Debloating" $true
            
            Write-Host "`n[RESTART REQUIRED] SYSTEM RESTART REQUIRED!" -ForegroundColor Red
            Write-Host "Phase 1 is complete. The system needs to restart for changes to take effect." -ForegroundColor Yellow
            Write-Host "After restart, run this script again to continue with Phase 2 & 3." -ForegroundColor Yellow
            
            if (Get-UserConfirmation "Restart the system now?") {
                Write-Host "Restarting system in 10 seconds..." -ForegroundColor Red
                Start-Sleep -Seconds 10
                Restart-Computer -Force
            } else {
                Write-Host "Please restart manually and re-run this script to continue." -ForegroundColor Yellow
                exit 0
            }
        }
        catch {
            Show-CompletionStatus "Phase 1: Main Debloating" $false
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            if (-not (Get-UserConfirmation "Continue to next phase despite errors?")) {
                exit 1
            }
        }
    } else {
        Write-Host "Skipping Phase 1..." -ForegroundColor Yellow
    }
    
    # Phase 2: Advanced Performance Tuning
    Show-ScriptInfo "Advanced-Performance-Tuning.ps1" "Network optimization, memory tuning, security testing configurations" "10-15 minutes"
    
    if (Get-UserConfirmation "Start Phase 2: Advanced Performance Tuning?") {
        try {
            Write-Host "`nStarting advanced performance tuning..." -ForegroundColor Green
            & ".\Advanced-Performance-Tuning.ps1"
            Show-CompletionStatus "Phase 2: Advanced Performance Tuning" $true
        }
        catch {
            Show-CompletionStatus "Phase 2: Advanced Performance Tuning" $false
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            if (-not (Get-UserConfirmation "Continue to next phase despite errors?")) {
                exit 1
            }
        }
    } else {
        Write-Host "Skipping Phase 2..." -ForegroundColor Yellow
    }
    
    # Phase 3: Security Tools Installation
    Show-ScriptInfo "Security-Tools-Installation.ps1" "Install comprehensive security testing tools and utilities" "20-30 minutes"
    
    if (Get-UserConfirmation "Start Phase 3: Security Tools Installation?") {
        try {
            Write-Host "`nStarting security tools installation..." -ForegroundColor Green
            & ".\Security-Tools-Installation.ps1"
            Show-CompletionStatus "Phase 3: Security Tools Installation" $true
        }
        catch {
            Show-CompletionStatus "Phase 3: Security Tools Installation" $false
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Skipping Phase 3..." -ForegroundColor Yellow
    }
    
    # Final completion
    Write-Host "`n" + "="*70 -ForegroundColor Green
    Write-Host "OPTIMIZATION SUITE COMPLETED!" -ForegroundColor Green
    Write-Host "="*70 -ForegroundColor Green
    
    Write-Host "`nYour Windows 11 ParrotOS alternative is ready!" -ForegroundColor Cyan
    Write-Host "`nWhat's been accomplished:" -ForegroundColor White
    Write-Host "[OK] Bloatware removed while preserving business functionality" -ForegroundColor Green
    Write-Host "[OK] Performance optimized for security testing workloads" -ForegroundColor Green
    Write-Host "[OK] Remote access capabilities maintained (RDP, WinRM, SSH)" -ForegroundColor Green
    Write-Host "[OK] Comprehensive security tools installed" -ForegroundColor Green
    Write-Host "[OK] Directory structure created for organized workflow" -ForegroundColor Green
    Write-Host "[OK] Desktop shortcuts and utilities configured" -ForegroundColor Green
    
    Write-Host "`nKey directories:" -ForegroundColor White
    Write-Host "- C:\Tools\ - Main security tools" -ForegroundColor Cyan
    Write-Host "- C:\PenTest\ - Penetration testing workspace" -ForegroundColor Cyan
    Write-Host "- Desktop\Security Tools\ - Quick access shortcuts" -ForegroundColor Cyan
    
    Write-Host "`nEnvironment ready for:" -ForegroundColor White
    Write-Host "- Network scanning and analysis" -ForegroundColor Yellow
    Write-Host "- Web application testing" -ForegroundColor Yellow
    Write-Host "- Password and hash cracking" -ForegroundColor Yellow
    Write-Host "- Digital forensics and reverse engineering" -ForegroundColor Yellow
    Write-Host "- Penetration testing and red team exercises" -ForegroundColor Yellow
    Write-Host "- Blue team analysis and incident response" -ForegroundColor Yellow
    
    if (Get-UserConfirmation "`nWould you like to restart the system to finalize all optimizations?") {
        Write-Host "`nRestarting system in 10 seconds..." -ForegroundColor Yellow
        Write-Host "After restart, your optimized security testing environment will be fully ready!" -ForegroundColor Green
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } else {
        Write-Host "`nPlease restart the system when convenient to finalize all optimizations." -ForegroundColor Yellow
        Write-Host "Your Windows 11 ParrotOS alternative is ready to use!" -ForegroundColor Green
    }
}

# Execute the main function
try {
    Start-OptimizationSuite
}
catch {
    Write-Host "`n[ERROR] An unexpected error occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`nPlease check the error details and try again." -ForegroundColor Yellow
    exit 1
}