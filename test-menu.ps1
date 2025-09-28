# Load only necessary functions without running the installer
$script:InstallLevel = "standard"
$script:PSScriptRoot = (Get-Location).Path

# Source only the function we need
function Show-ConfigSelectionMenu {
    param([string]$InstallLevel)
    
    Write-Host "`nSelect Configuration Profile for $InstallLevel level:" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Note: Core Base will be automatically included" -ForegroundColor Green
    Write-Host "Showing only $InstallLevel-specific configurations" -ForegroundColor Yellow
    Write-Host ""
    
    $configs = @{}
    $configPath = Join-Path $PSScriptRoot "configs"
    
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
                    "standard" { $configLevel -eq "standard" }
                    "professional" { $configLevel -eq "professional" }
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
    
    # Return the list of available configs for inspection
    return $configs
}

# Test the menu options for different levels
Write-Host "`n[TESTING LITE MENU]" -ForegroundColor Magenta
$liteConfigs = Show-ConfigSelectionMenu -InstallLevel "lite"
Write-Host "Available lite configs: $($liteConfigs.Values -join ', ')" -ForegroundColor Green

Write-Host "`n[TESTING STANDARD MENU]" -ForegroundColor Magenta
$standardConfigs = Show-ConfigSelectionMenu -InstallLevel "standard"
Write-Host "Available standard configs: $($standardConfigs.Values -join ', ')" -ForegroundColor Green

Write-Host "`n[TESTING PROFESSIONAL MENU]" -ForegroundColor Magenta
$proConfigs = Show-ConfigSelectionMenu -InstallLevel "professional"
Write-Host "Available professional configs: $($proConfigs.Values -join ', ')" -ForegroundColor Green