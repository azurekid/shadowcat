# Test script to check config filtering logic

$script:InstallLevel = "standard"
$script:PSScriptRoot = (Get-Location).Path

# Define the filter function based on our updated logic
function Test-ConfigFiltering {
    param(
        [string]$ConfigLevel,
        [string]$InstallLevel
    )
    
    switch ($InstallLevel) {
        "lite" { return $ConfigLevel -eq "lite" }
        "standard" { return $ConfigLevel -in @("lite", "standard") }
        "professional" { return $ConfigLevel -in @("lite", "standard", "professional") }
        "all" { return $true }
        default { return $true }
    }
}

# Test each level with a range of config levels
function Test-FilteringLogic {
    Write-Host "`n[TESTING FILTERING LOGIC]" -ForegroundColor Magenta
    
    $installLevels = @("lite", "standard", "professional", "all")
    $configLevels = @("lite", "standard", "professional", "other")
    
    foreach ($installLevel in $installLevels) {
        Write-Host "`nInstallation Level: $installLevel" -ForegroundColor Cyan
        
        foreach ($configLevel in $configLevels) {
            $result = Test-ConfigFiltering -ConfigLevel $configLevel -InstallLevel $installLevel
            $status = if ($result) { "✓ INCLUDED" } else { "✗ EXCLUDED" }
            $color = if ($result) { "Green" } else { "Red" }
            Write-Host "  Config Level '$configLevel': $status" -ForegroundColor $color
        }
    }
}

# Gather actual configs from the filesystem and test which would be shown
function Test-ActualConfigs {
    Write-Host "`n[TESTING ACTUAL CONFIG FILES]" -ForegroundColor Magenta
    
    $configPath = Join-Path $PSScriptRoot "configs"
    $configFiles = Get-ChildItem -Path $configPath -Filter "*.json"
    
    $installLevels = @("lite", "standard", "professional", "all")
    
    foreach ($installLevel in $installLevels) {
        Write-Host "`nInstallation Level: $installLevel" -ForegroundColor Cyan
        $includedConfigs = @()
        
        foreach ($configFile in $configFiles) {
            try {
                $content = Get-Content $configFile.FullName -Raw | ConvertFrom-Json
                $configLevel = if ($content.metadata.installLevel) { $content.metadata.installLevel } else { "any" }
                
                $result = Test-ConfigFiltering -ConfigLevel $configLevel -InstallLevel $installLevel
                if ($result) {
                    $includedConfigs += $configFile.Name
                }
            } catch {
                # Skip invalid JSON
            }
        }
        
        Write-Host "  Included configs ($($includedConfigs.Count)):" -ForegroundColor Yellow
        $includedConfigs | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }
    }
}

# Run the tests
Test-FilteringLogic
Test-ActualConfigs