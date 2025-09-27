# =============================================================================
# ShadowCat-PackageManagers.ps1
# Package manager installation and management functions
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
                # Check if running as admin
                $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                
                # Set environment variables regardless of admin status
                $env:SCOOP = Join-Path $env:USERPROFILE "scoop"
                [environment]::setEnvironmentVariable('SCOOP', $env:SCOOP, 'User')
                
                if ($isAdmin) {
                    Write-ShadowCatLog "Running as admin. Using special Scoop installation method..." -Level "Warning"
                    
                    # Special handling for admin installation
                    $env:SCOOP_GLOBAL = "C:\ProgramData\scoop"
                    [environment]::setEnvironmentVariable('SCOOP_GLOBAL', $env:SCOOP_GLOBAL, 'Machine')
                    
                    # Create user scoop directory if it doesn't exist
                    if (-not (Test-Path $env:SCOOP)) {
                        New-Item -Path $env:SCOOP -ItemType Directory -Force | Out-Null
                    }
                    
                    # Download and modify the scoop installer to work with admin privileges
                    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                    $scoopInstaller = (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
                    # This modification bypasses the admin check in the installer
                    $scoopInstaller = $scoopInstaller -replace 'if\s*\(\s*\$\(get_config\s+NO_PROXY\s*\)\s*-eq\s*\$true\)', 'if ($true)'
                    Invoke-Expression $scoopInstaller
                }
                else {
                    # Standard non-admin installation
                    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                    Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression
                }
                
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

# Export functions - Note: This line will be removed when running in IEX mode
# The line below is needed only when this file is imported as a PowerShell module
if ($MyInvocation.Line -notmatch 'IEX|Invoke-Expression' -and (Get-Command -Name Export-ModuleMember -ErrorAction SilentlyContinue)) {
    # Only export if this is being loaded as a module (not via IEX)
    Export-ModuleMember -Function Install-ChocolateyPackages, Install-ScoopPackages, Install-GitHubProjects, Install-PythonPackages
}