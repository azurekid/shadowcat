# =============================================================================
# ShadowCat-PerformanceOptimizations.ps1
# High-performance installation optimizations for ShadowCat
# =============================================================================

# Performance configuration
$script:MaxParallelJobs = [Math]::Min([Environment]::ProcessorCount * 2, 8)
$script:EnableCaching = $true
$tempPath = if ($env:TEMP) { $env:TEMP } else { "/tmp" }
$script:CacheDir = Join-Path $tempPath "ShadowCat-Cache"
$script:BatchSize = 10

function Initialize-PerformanceMode {
    param([string]$InstallPath)
    
    Write-ShadowCatLog "🚀 Initializing Performance Mode..." -Level "Header"
    Write-ShadowCatLog "Max Parallel Jobs: $script:MaxParallelJobs" -Level "Info"
    
    # Create cache directory
    if ($script:EnableCaching -and -not (Test-Path $script:CacheDir)) {
        New-Item -Path $script:CacheDir -ItemType Directory -Force | Out-Null
    }
    
    # Pre-configure package managers for batch operations
    Initialize-PackageManagersParallel
}

function Initialize-PackageManagersParallel {
    Write-ShadowCatLog "Initializing package managers in parallel..." -Level "Info"
    
    $jobs = @()
    
    # Chocolatey initialization
    $jobs += Start-Job -Name "ChocolateyInit" -ScriptBlock {
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        # Pre-warm chocolatey
        choco --version | Out-Null
    }
    
    # Scoop initialization
    $jobs += Start-Job -Name "ScoopInit" -ScriptBlock {
        if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Invoke-RestMethod get.scoop.sh | Invoke-Expression
        }
        # Pre-warm scoop
        scoop --version | Out-Null
    }
    
    # Python initialization
    $jobs += Start-Job -Name "PythonInit" -ScriptBlock {
        if (Get-Command python -ErrorAction SilentlyContinue) {
            # Upgrade pip to latest version
            python -m pip install --upgrade pip --quiet
        }
    }
    
    # Wait for all initialization jobs
    $jobs | Wait-Job | ForEach-Object { 
        $result = Receive-Job $_
        Remove-Job $_
    }
    
    Write-ShadowCatLog "Package managers initialized successfully" -Level "Success"
}

function Install-ChocolateyPackagesParallel {
    param($packages, $configName)
    
    if (-not $packages -or $packages.Count -eq 0) { return }
    
    Write-ShadowCatLog "🍫 Installing $($packages.Count) Chocolatey packages in parallel..." -Level "Header"
    
    # Filter packages that need installation
    $packagesToInstall = @()
    foreach ($package in $packages) {
        if (Test-ToolInstallation -tool $package -source "Chocolatey") {
            $packagesToInstall += $package
        }
    }
    
    if ($packagesToInstall.Count -eq 0) {
        Write-ShadowCatLog "All Chocolatey packages already installed" -Level "Info"
        return
    }
    
    # Batch installation using chocolatey's multiple package feature
    $batches = Split-Array $packagesToInstall $script:BatchSize
    $jobs = @()
    
    foreach ($batch in $batches) {
        $packageNames = ($batch | ForEach-Object { $_.name }) -join ' '
        
        $jobs += Start-Job -Name "ChocoBatch_$($batch[0].name)" -ScriptBlock {
            param($packageList, $dryRun)
            
            if ($dryRun) {
                return @{
                    Success = $packageList
                    Failed = @()
                    Output = "[DRY RUN] Would install: $packageList"
                }
            }
            
            try {
                # Install multiple packages at once
                $output = choco install $packageList.Split(' ') -y --ignore-checksums 2>&1
                $outputString = $output | Out-String
                
                $success = @()
                $failed = @()
                
                # Parse results
                foreach ($pkg in $packageList.Split(' ')) {
                    if ($outputString -match "$pkg.*installed successfully" -or $outputString -match "already installed") {
                        $success += $pkg
                    } else {
                        $failed += $pkg
                    }
                }
                
                return @{
                    Success = $success
                    Failed = $failed
                    Output = $outputString
                }
            } catch {
                return @{
                    Success = @()
                    Failed = $packageList.Split(' ')
                    Output = $_.Exception.Message
                }
            }
        } -ArgumentList $packageNames, $script:DryRun
    }
    
    # Wait for all batches and process results
    $totalInstalled = 0
    $totalFailed = 0
    
    $jobs | Wait-Job | ForEach-Object {
        $result = Receive-Job $_
        $totalInstalled += $result.Success.Count
        $totalFailed += $result.Failed.Count
        
        foreach ($pkg in $result.Success) {
            $script:InstalledTools[$pkg] = "Chocolatey"
        }
        
        foreach ($pkg in $result.Failed) {
            $script:SkippedTools[$pkg] = @{
                name = $pkg
                source = "Chocolatey"
                reason = "Installation failed"
            }
        }
        
        Remove-Job $_
    }
    
    Write-ShadowCatLog "Chocolatey batch installation completed: $totalInstalled installed, $totalFailed failed" -Level "Info"
}

function Install-ScoopPackagesParallel {
    param($scoopConfig, $configName)
    
    if (-not $scoopConfig -or -not $scoopConfig.packages -or $scoopConfig.packages.Count -eq 0) { return }
    
    Write-ShadowCatLog "🪣 Installing $($scoopConfig.packages.Count) Scoop packages in parallel..." -Level "Header"
    
    # Add buckets first (sequential for dependency reasons)
    if ($scoopConfig.buckets) {
        foreach ($bucket in $scoopConfig.buckets) {
            if ($bucket -ne "main") {
                $bucketExists = scoop bucket list | Where-Object { $_ -match $bucket }
                if (-not $bucketExists) {
                    Write-ShadowCatLog "Adding Scoop bucket: $bucket" -Level "Info"
                    if (-not $script:DryRun) {
                        scoop bucket add $bucket 2>&1 | Out-Null
                    }
                }
            }
        }
    }
    
    # Filter packages that need installation
    $packagesToInstall = @()
    foreach ($package in $scoopConfig.packages) {
        if (Test-ToolInstallation -tool $package -source "Scoop") {
            $packagesToInstall += $package
        }
    }
    
    if ($packagesToInstall.Count -eq 0) {
        Write-ShadowCatLog "All Scoop packages already installed" -Level "Info"
        return
    }
    
    # Install packages in parallel batches
    $batches = Split-Array $packagesToInstall $script:BatchSize
    $jobs = @()
    
    foreach ($batch in $batches) {
        $jobs += Start-Job -Name "ScoopBatch_$($batch[0].name)" -ScriptBlock {
            param($packages, $dryRun)
            
            $results = @{
                Success = @()
                Failed = @()
            }
            
            foreach ($pkg in $packages) {
                if ($dryRun) {
                    $results.Success += $pkg.name
                    continue
                }
                
                try {
                    $output = scoop install $pkg.name 2>&1 | Out-String
                    if ($output -match "was installed successfully" -or $output -match "already installed") {
                        $results.Success += $pkg.name
                    } else {
                        $results.Failed += $pkg.name
                    }
                } catch {
                    $results.Failed += $pkg.name
                }
            }
            
            return $results
        } -ArgumentList $batch, $script:DryRun
    }
    
    # Process results
    $totalInstalled = 0
    $totalFailed = 0
    
    $jobs | Wait-Job | ForEach-Object {
        $result = Receive-Job $_
        $totalInstalled += $result.Success.Count
        $totalFailed += $result.Failed.Count
        
        foreach ($pkg in $result.Success) {
            $script:InstalledTools[$pkg] = "Scoop"
        }
        
        foreach ($pkg in $result.Failed) {
            $script:SkippedTools[$pkg] = @{
                name = $pkg
                source = "Scoop"
                reason = "Installation failed"
            }
        }
        
        Remove-Job $_
    }
    
    Write-ShadowCatLog "Scoop batch installation completed: $totalInstalled installed, $totalFailed failed" -Level "Info"
}

function Install-GitHubProjectsParallel {
    param($packages, $configName, $destination)
    
    if (-not $packages -or $packages.Count -eq 0) { return }
    
    Write-ShadowCatLog "🐙 Cloning $($packages.Count) GitHub projects in parallel..." -Level "Header"
    
    # Filter projects that need cloning
    $projectsToClone = @()
    foreach ($package in $packages) {
        $projectPath = Join-Path $destination (Split-Path $package.url -Leaf)
        if (-not (Test-Path $projectPath)) {
            $projectsToClone += $package
        }
    }
    
    if ($projectsToClone.Count -eq 0) {
        Write-ShadowCatLog "All GitHub projects already cloned" -Level "Info"
        return
    }
    
    # Clone projects in parallel
    $jobs = @()
    $semaphore = New-Object System.Threading.Semaphore($script:MaxParallelJobs, $script:MaxParallelJobs)
    
    foreach ($project in $projectsToClone) {
        $jobs += Start-Job -Name "GitClone_$(Split-Path $project.url -Leaf)" -ScriptBlock {
            param($url, $destination, $dryRun, $semaphoreHandle)
            
            # Acquire semaphore to limit concurrent operations
            $null = $semaphoreHandle.WaitOne()
            
            try {
                $projectName = Split-Path $url -Leaf
                $projectPath = Join-Path $destination $projectName
                
                if ($dryRun) {
                    return @{
                        Success = $true
                        ProjectName = $projectName
                        Output = "[DRY RUN] Would clone: $url to $projectPath"
                    }
                }
                
                # Shallow clone for speed
                $gitOutput = git clone --depth 1 --single-branch $url $projectPath 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    return @{
                        Success = $true
                        ProjectName = $projectName
                        Output = "Successfully cloned $projectName"
                    }
                } else {
                    return @{
                        Success = $false
                        ProjectName = $projectName
                        Output = "Failed to clone: $gitOutput"
                    }
                }
            } catch {
                return @{
                    Success = $false
                    ProjectName = (Split-Path $url -Leaf)
                    Output = $_.Exception.Message
                }
            } finally {
                # Release semaphore
                $semaphoreHandle.Release() | Out-Null
            }
        } -ArgumentList $project.url, $destination, $script:DryRun, $semaphore
    }
    
    # Process results with progress tracking
    $completed = 0
    $totalJobs = $jobs.Count
    
    while ($completed -lt $totalJobs) {
        $finishedJobs = $jobs | Where-Object { $_.State -eq 'Completed' -or $_.State -eq 'Failed' }
        
        foreach ($job in $finishedJobs) {
            if ($job.State -eq 'Completed') {
                $result = Receive-Job $job
                if ($result.Success) {
                    $script:InstalledTools[$result.ProjectName] = "GitHub"
                    Write-ShadowCatLog "✓ $($result.ProjectName)" -Level "Success"
                } else {
                    $script:SkippedTools[$result.ProjectName] = @{
                        name = $result.ProjectName
                        source = "GitHub"
                        reason = $result.Output
                    }
                    Write-ShadowCatLog "✗ $($result.ProjectName): $($result.Output)" -Level "Error"
                }
            }
            
            Remove-Job $job
            $completed++
        }
        
        # Update progress
        $progress = [math]::Round(($completed / $totalJobs) * 100)
        Write-Progress -Activity "Cloning GitHub Projects" -Status "$completed of $totalJobs completed" -PercentComplete $progress
        
        # Remove processed jobs from array
        $jobs = $jobs | Where-Object { $_.State -ne 'Completed' -and $_.State -ne 'Failed' }
        
        Start-Sleep -Milliseconds 100
    }
    
    Write-Progress -Activity "Cloning GitHub Projects" -Completed
    $semaphore.Dispose()
    
    Write-ShadowCatLog "GitHub parallel cloning completed" -Level "Success"
}

function Install-PythonPackagesParallel {
    param($packages, $configName)
    
    if (-not $packages -or $packages.Count -eq 0) { return }
    
    Write-ShadowCatLog "🐍 Installing $($packages.Count) Python packages in parallel..." -Level "Header"
    
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-ShadowCatLog "Python not found. Skipping Python packages." -Level "Warning"
        return
    }
    
    # Filter packages that need installation
    $packagesToInstall = @()
    foreach ($package in $packages) {
        if (Test-ToolInstallation -tool $package -source "Python") {
            $packagesToInstall += $package
        }
    }
    
    if ($packagesToInstall.Count -eq 0) {
        Write-ShadowCatLog "All Python packages already installed" -Level "Info"
        return
    }
    
    # Install packages using pip batch installation
    $packageNames = ($packagesToInstall | ForEach-Object { $_.name }) -join ' '
    
    Write-ShadowCatLog "Installing Python packages: $packageNames" -Level "Info"
    
    if (-not $script:DryRun) {
        try {
            # Use pip's ability to install multiple packages at once
            $output = python -m pip install $packageNames.Split(' ') --quiet 2>&1
            
            # Mark all as installed (pip will skip already installed packages)
            foreach ($pkg in $packagesToInstall) {
                $script:InstalledTools[$pkg.name] = "Python"
            }
            
            Write-ShadowCatLog "Python batch installation completed successfully" -Level "Success"
        } catch {
            Write-ShadowCatLog "Python batch installation failed: $($_.Exception.Message)" -Level "Error"
            foreach ($pkg in $packagesToInstall) {
                $script:SkippedTools[$pkg.name] = @{
                    name = $pkg.name
                    source = "Python"
                    reason = "Batch installation failed"
                }
            }
        }
    } else {
        foreach ($pkg in $packagesToInstall) {
            $script:InstalledTools[$pkg.name] = "Python"
        }
        Write-ShadowCatLog "[DRY RUN] Would install Python packages: $packageNames" -Level "Debug"
    }
}

function Split-Array {
    param($array, $batchSize)
    
    $batches = @()
    for ($i = 0; $i -lt $array.Count; $i += $batchSize) {
        $endIndex = [Math]::Min($i + $batchSize - 1, $array.Count - 1)
        $batches += ,$array[$i..$endIndex]
    }
    return $batches
}

function Get-PerformanceMetrics {
    return @{
        MaxParallelJobs = $script:MaxParallelJobs
        CacheEnabled = $script:EnableCaching
        CacheDirectory = $script:CacheDir
        BatchSize = $script:BatchSize
        ProcessorCount = [Environment]::ProcessorCount
    }
}

# Export functions for the performance-optimized installer  
# Export-ModuleMember -Function Initialize-PerformanceMode, Install-ChocolateyPackagesParallel, Install-ScoopPackagesParallel, Install-GitHubProjectsParallel, Install-PythonPackagesParallel, Get-PerformanceMetrics