# Test the HTML dashboard generation
$script:InstallLevel = "lite"
$script:PSScriptRoot = (Get-Location).Path
$script:ProcessedConfigs = @{}
$script:InstalledTools = @{}
$script:ToolCategories = @{}

# Load modules
. ./modules/ShadowCat-UI.ps1
. ./modules/ShadowCat-Config.ps1
. ./modules/ShadowCat-PackageManagers.ps1
. ./modules/ShadowCat-CustomTools.ps1

# Load a sample config to test with
# Load and test with essential tools config which has better tool name matches
$configPath = Join-Path $PSScriptRoot "configs/shadowcat-essential-tools.json"
$coreConfigPath = Join-Path $PSScriptRoot "configs/shadowcat-core-base.json"

if ((Test-Path $configPath) -and (Test-Path $coreConfigPath)) {
    $configContent = Get-Content $configPath -Raw | ConvertFrom-Json
    $coreConfigContent = Get-Content $coreConfigPath -Raw | ConvertFrom-Json
    $script:ProcessedConfigs[$configPath] = $configContent
    $script:ProcessedConfigs[$coreConfigPath] = $coreConfigContent
    
    Write-Host "Testing HTML dashboard generation..." -ForegroundColor Cyan
    
    # Test the dashboard function with both core and essential tools
    New-ToolDashboard -InstallPath "/tmp/ShadowCat/SecurityTools" -ConfigFiles @("shadowcat-core-base.json", "shadowcat-essential-tools.json") -InstallLevel "standard"
    
    Write-Host "Dashboard test completed!" -ForegroundColor Green
} else {
    Write-Host "Config files not found: $configPath or $coreConfigPath" -ForegroundColor Red
}