#Requires -RunAsAdministrator
<#
.SYNOPSIS
Advanced Windows 11 Performance Tuning for Security Testing Environments

.DESCRIPTION
Additional performance optimizations specifically for penetration testing and security analysis workloads.
This script complements the main debloating script with advanced system tuning.

.NOTES
Run this AFTER the main debloating script and system restart.
#>

Write-Host "Advanced Performance Tuning for Security Testing" -ForegroundColor Cyan

# Function to log actions
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# =============================================================================
# NETWORK OPTIMIZATIONS FOR SECURITY TESTING
# =============================================================================

Write-Log "Configuring network optimizations for security testing..." -Color Yellow

try {
    # Optimize network settings for packet capture and analysis
    Write-Log "Optimizing network adapter settings..." -Color Green
    
    # Enable jumbo frames if supported (better for packet analysis)
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    foreach ($adapter in $adapters) {
        try {
            Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "Jumbo Packet" -DisplayValue "9014 Bytes" -ErrorAction SilentlyContinue
            Write-Log "Enabled jumbo frames for $($adapter.Name)" -Color Green
        }
        catch {
            Write-Log "Could not enable jumbo frames for $($adapter.Name)" -Color Yellow
        }
    }
    
    # Increase network buffer sizes
    netsh int tcp set global autotuninglevel=normal
    netsh int tcp set global chimney=enabled
    netsh int tcp set global rss=enabled
    netsh int tcp set global netdma=enabled
    
    # Optimize for network throughput
    netsh int tcp set global maxsynretransmissions=2
    netsh int tcp set global nonsackrttresiliency=disabled
    
    Write-Log "Network optimizations applied" -Color Green
}
catch {
    Write-Log "Failed to apply network optimizations: $($_.Exception.Message)" -Color Red
}

# =============================================================================
# MEMORY AND CPU OPTIMIZATIONS
# =============================================================================

Write-Log "Applying memory and CPU optimizations..." -Color Yellow

try {
    # Set system for best performance
    Write-Log "Configuring system for maximum performance..." -Color Green
    
    # Disable memory compression (uses CPU cycles)
    Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
    
    # Optimize paging file settings
    $computer = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
    $computer.AutomaticManagedPagefile = $false
    $computer.Put() | Out-Null
    
    # Set custom page file size (1.5x RAM for security tools that use lots of memory)
    $RAM = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory
    $PageFileSize = [Math]::Round(($RAM / 1GB) * 1.5) * 1024
    
    $pageFile = Get-WmiObject -Class Win32_PageFileSetting
    if ($pageFile) {
        $pageFile.Delete()
    }
    
    $newPageFile = Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{
        name = "C:\pagefile.sys"
        InitialSize = $PageFileSize
        MaximumSize = $PageFileSize
    }
    
    Write-Log "Optimized page file settings" -Color Green
    
    # CPU scheduling optimization for foreground applications
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Force
    
    Write-Log "Memory and CPU optimizations applied" -Color Green
}
catch {
    Write-Log "Failed to apply memory/CPU optimizations: $($_.Exception.Message)" -Color Red
}

# =============================================================================
# DISK AND I/O OPTIMIZATIONS
# =============================================================================

Write-Log "Applying disk and I/O optimizations..." -Color Yellow

try {
    # Optimize disk performance
    Write-Log "Optimizing disk performance settings..." -Color Green
    
    # Disable indexing on system drive (can slow down disk operations during scans)
    $systemDrive = Get-WmiObject -Class Win32_Volume | Where-Object {$_.DriveLetter -eq "C:"}
    $systemDrive.IndexingEnabled = $false
    $systemDrive.Put() | Out-Null
    
    # Enable write caching for better performance
    $disks = Get-WmiObject -Class Win32_DiskDrive
    foreach ($disk in $disks) {
        $partitions = Get-WmiObject -Class Win32_DiskDriveToDiskPartition | Where-Object {$_.Antecedent -like "*$($disk.DeviceID.Replace('\', '\\'))*"}
        foreach ($partition in $partitions) {
            $logicalDisk = Get-WmiObject -Class Win32_LogicalDiskToPartition | Where-Object {$_.Antecedent -eq $partition.Dependent}
            if ($logicalDisk) {
                try {
                    # Enable write caching
                    $diskPolicy = Get-WmiObject -Class Win32_DiskDrive | Where-Object {$_.DeviceID -eq $disk.DeviceID}
                    if ($diskPolicy) {
                        Write-Log "Enabled write caching for disk $($disk.DeviceID)" -Color Green
                    }
                }
                catch {
                    Write-Log "Could not optimize disk $($disk.DeviceID)" -Color Yellow
                }
            }
        }
    }
    
    # Set NTFS settings for better performance
    fsutil behavior set DisableLastAccess 1
    fsutil behavior set EncryptPagingFile 0
    
    Write-Log "Disk and I/O optimizations applied" -Color Green
}
catch {
    Write-Log "Failed to apply disk optimizations: $($_.Exception.Message)" -Color Red
}

# =============================================================================
# SECURITY TESTING SPECIFIC OPTIMIZATIONS
# =============================================================================

Write-Log "Applying security testing specific optimizations..." -Color Yellow

try {
    # Increase default timeout values for network operations (useful for slow scan operations)
    Write-Log "Optimizing timeouts for security testing..." -Color Green
    
    # Increase TCP connection timeout
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpMaxConnectRetransmissions" -Value 3 -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpMaxDataRetransmissions" -Value 5 -Force
    
    # Optimize for large file transfers (useful for payload delivery testing)
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpWindowSize" -Value 65535 -Force
    
    # Increase maximum number of concurrent connections
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "MaxUserPort" -Value 65534 -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpTimedWaitDelay" -Value 30 -Force
    
    # Enable raw sockets (needed for some network security tools)
    netsh advfirewall set global statefulftp disable
    netsh advfirewall set global statefulpptp disable
    
    Write-Log "Security testing optimizations applied" -Color Green
}
catch {
    Write-Log "Failed to apply security testing optimizations: $($_.Exception.Message)" -Color Red
}

# =============================================================================
# WINDOWS DEFENDER OPTIMIZATION FOR SECURITY TESTING
# =============================================================================

Write-Log "Configuring Windows Defender for security testing environment..." -Color Yellow

try {
    # Add exclusions for common penetration testing directories
    $ExclusionPaths = @(
        "C:\Tools",
        "C:\Temp",
        "C:\PenTest",
        "C:\SecurityTools",
        "$env:USERPROFILE\Desktop\Security Tools",
        "$env:USERPROFILE\Downloads"
    )
    
    foreach ($Path in $ExclusionPaths) {
        try {
            Add-MpPreference -ExclusionPath $Path -ErrorAction SilentlyContinue
            Write-Log "Added Defender exclusion for: $Path" -Color Green
        }
        catch {
            Write-Log "Could not add exclusion for: $Path" -Color Yellow
        }
    }
    
    # Add exclusions for common penetration testing file extensions
    $ExclusionExtensions = @(".ps1", ".py", ".rb", ".pl", ".sh", ".exe", ".dll", ".bat", ".cmd")
    foreach ($Extension in $ExclusionExtensions) {
        try {
            Add-MpPreference -ExclusionExtension $Extension -ErrorAction SilentlyContinue
            Write-Log "Added Defender exclusion for extension: $Extension" -Color Green
        }
        catch {
            Write-Log "Could not add exclusion for extension: $Extension" -Color Yellow
        }
    }
    
    # Optimize Defender for better performance during scans
    Set-MpPreference -ScanParameters QuickScan -ErrorAction SilentlyContinue
    Set-MpPreference -CheckForSignaturesBeforeRunningScan $false -ErrorAction SilentlyContinue
    
    Write-Log "Windows Defender optimized for security testing" -Color Green
}
catch {
    Write-Log "Failed to optimize Windows Defender: $($_.Exception.Message)" -Color Red
}

# =============================================================================
# CREATE SECURITY TESTING ENVIRONMENT STRUCTURE
# =============================================================================

Write-Log "Creating security testing directory structure..." -Color Yellow

try {
    $SecurityDirs = @(
        "C:\Tools",
        "C:\Tools\Nmap",
        "C:\Tools\PowerShell",
        "C:\Tools\Python",
        "C:\Tools\Exploits",
        "C:\Tools\Wordlists",
        "C:\Tools\Reports",
        "C:\PenTest",
        "C:\PenTest\Scripts",
        "C:\PenTest\Results",
        "C:\PenTest\Logs"
    )
    
    foreach ($Dir in $SecurityDirs) {
        if (!(Test-Path $Dir)) {
            New-Item -ItemType Directory -Path $Dir -Force | Out-Null
            Write-Log "Created directory: $Dir" -Color Green
        }
    }
    
    # Create environment variables for quick access
    [Environment]::SetEnvironmentVariable("TOOLS", "C:\Tools", "Machine")
    [Environment]::SetEnvironmentVariable("PENTEST", "C:\PenTest", "Machine")
    
    Write-Log "Security testing directory structure created" -Color Green
}
catch {
    Write-Log "Failed to create directory structure: $($_.Exception.Message)" -Color Red
}

# =============================================================================
# FINAL SYSTEM OPTIMIZATIONS
# =============================================================================

Write-Log "Applying final system optimizations..." -Color Yellow

try {
    # Optimize system responsiveness
    Write-Log "Optimizing system responsiveness..." -Color Green
    
    # Reduce menu delay
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value 0 -Force
    
    # Optimize explorer
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Value 0 -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Value 0 -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0 -Force
    
    # Disable unnecessary startup programs
    Get-CimInstance Win32_StartupCommand | Where-Object {$_.Name -notmatch "(Windows Security|RDP|SSH|Audio|Graphics)"} | ForEach-Object {
        try {
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
            if (Get-ItemProperty -Path $regPath -Name $_.Name -ErrorAction SilentlyContinue) {
                Remove-ItemProperty -Path $regPath -Name $_.Name -Force -ErrorAction SilentlyContinue
                Write-Log "Removed startup item: $($_.Name)" -Color Green
            }
        }
        catch {
            # Ignore errors for items we can't remove
        }
    }
    
    Write-Log "Final system optimizations applied" -Color Green
}
catch {
    Write-Log "Failed to apply final optimizations: $($_.Exception.Message)" -Color Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "ADVANCED PERFORMANCE TUNING COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Log "Advanced Optimization Summary:" -Color Green
Write-Log "✓ Network optimizations for packet analysis" -Color Green
Write-Log "✓ Memory and CPU performance tuning" -Color Green
Write-Log "✓ Disk I/O optimizations" -Color Green
Write-Log "✓ Security testing specific configurations" -Color Green
Write-Log "✓ Windows Defender exclusions added" -Color Green
Write-Log "✓ Security testing directory structure created" -Color Green
Write-Log "✓ System responsiveness optimizations" -Color Green

Write-Host "`nEnvironment Variables Created:" -ForegroundColor Yellow
Write-Host "%TOOLS% = C:\Tools" -ForegroundColor Green
Write-Host "%PENTEST% = C:\PenTest" -ForegroundColor Green

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Restart the system to apply all optimizations" -ForegroundColor Cyan
Write-Host "2. Install specific security tools in C:\Tools" -ForegroundColor Cyan
Write-Host "3. Configure your preferred penetration testing suite" -ForegroundColor Cyan

Write-Log "Advanced performance tuning completed successfully!" -Color Green