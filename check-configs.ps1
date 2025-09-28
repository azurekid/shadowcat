# Get config files for each installation level
$configPath = Join-Path (Get-Location).Path "configs"
$configFiles = Get-ChildItem -Path $configPath -Filter "*.json"

function Get-ConfigsForLevel {
    param([string]$Level)
    
    $results = @()
    
    foreach ($configFile in $configFiles) {
        # Skip core base
        if ($configFile.Name -eq "shadowcat-core-base.json") {
            continue
        }
        
        try {
            $content = Get-Content $configFile.FullName -Raw | ConvertFrom-Json
            $configLevel = if ($content.metadata.installLevel) { $content.metadata.installLevel } else { "any" }
            
            if ($configLevel -eq $Level) {
                $results += $configFile.Name
            }
        }
        catch {
            # Skip invalid JSON
        }
    }
    
    return $results
}

# Show results for each level
Write-Host "`nConfigurations for Lite level:" -ForegroundColor Cyan
$liteConfigs = Get-ConfigsForLevel -Level "lite"
$liteConfigs | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }

Write-Host "`nConfigurations for Standard level:" -ForegroundColor Cyan
$standardConfigs = Get-ConfigsForLevel -Level "standard"
$standardConfigs | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }

Write-Host "`nConfigurations for Professional level:" -ForegroundColor Cyan
$proConfigs = Get-ConfigsForLevel -Level "professional"
$proConfigs | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }

Write-Host "`nProfiles available:" -ForegroundColor Cyan
$profiles = $configFiles | Where-Object { $_.Name -like "*-profile.json" }
$profiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor White }