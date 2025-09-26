# =============================================================================
# ShadowCat-Config.ps1
# Configuration and dependency management functions
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

# Export functions - but only if not in IEX mode
if (-not (Get-Variable -Name ShadowCatIEXMode -Scope Global -ErrorAction SilentlyContinue)) {
    Export-ModuleMember -Function Import-ShadowCatConfig, Resolve-ConfigDependencies, Test-ToolInstallation
}