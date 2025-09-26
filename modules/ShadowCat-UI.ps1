# =============================================================================
# ShadowCat-UI.ps1
# User interface and display functions for ShadowCat Installer
# =============================================================================

function Show-ShadowCatBanner {
    $banner = @"


    _____ _      /\_/\    _                _____      _
   / ____| |    ( o.o )  | |              / ____|    | |
  | (___ | |__   > ^ < __| | _____      _| |     ____| |_     /\_/\
   \___ \| '_ \ / _`  |/ _`  |/ _ \ \ /\ / / |    / _`  | __|   ( o.o )
   ____) | | | | (_| | (_| | (_) \ V  V /| |___| (_| | |_     > ^ <
  |_____/|_| |_|\__,_|\__,_|\___/ \_/\_/  \_____\__,_|\__|

                    version 0.1.0-beta
"@
    Write-Host $banner -ForegroundColor Blue
    Write-Host "    [+] Install Level: $script:InstallLevel" -ForegroundColor Yellow
    Write-Host "    [+] Dependency Resolution: Enabled" -ForegroundColor Yellow
    Write-Host "    [+] Overlap Prevention: Active" -ForegroundColor Yellow
    Write-Host "    [+] Project ShadowCat - Elite Security Solutions" -ForegroundColor Yellow
    Write-Host ""
}

function Write-ShadowCatLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error", "Header", "Debug", "Dependency")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Level) {
        "Info"       { "[ShadowCat] [INFO]" }
        "Success"    { "[ShadowCat] [✓]" }
        "Warning"    { "[ShadowCat] [⚠]" }
        "Error"      { "[ShadowCat] [✗]" }
        "Header"     { "[ShadowCat] [>>>]" }
        "Debug"      { "[ShadowCat] [DBG]" }
        "Dependency" { "[ShadowCat] [DEP]" }
    }

    $color = switch ($Level) {
        "Info"       { "White" }
        "Success"    { "Green" }
        "Warning"    { "Yellow" }
        "Error"      { "Red" }
        "Header"     { "Cyan" }
        "Debug"      { "Gray" }
        "Dependency" { "Magenta" }
    }

    if ($Level -eq "Debug" -and -not $script:Verbose) { return }

    Write-Host "$timestamp $prefix $Message" -ForegroundColor $color
}

function Show-InstallationSummary {
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                     Installation Summary                             ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

    Write-Host "`n📊 STATISTICS:" -ForegroundColor Cyan
    Write-Host "   Total Tools Installed: $($script:InstalledTools.Count)" -ForegroundColor Green
    Write-Host "   Tools Skipped (Duplicates): $($script:SkippedTools.Count)" -ForegroundColor Yellow
    Write-Host "   Install Level: $script:InstallLevel" -ForegroundColor White

    if ($script:InstalledTools.Count -gt 0) {
        Write-Host "`n🛠️  INSTALLED TOOLS BY SOURCE:" -ForegroundColor Cyan
        $groupedTools = $script:InstalledTools.GetEnumerator() | Group-Object Value
        foreach ($group in $groupedTools) {
            Write-Host "   $($group.Name): $($group.Count) tools" -ForegroundColor White
        }
    }

    if ($script:SkippedTools.Count -gt 0) {
        Write-Host "`n⚠️  SKIPPED TOOLS:" -ForegroundColor Yellow
        foreach ($skipped in $script:SkippedTools.GetEnumerator()) {
            Write-Host "   $($skipped.Value.name) - $($skipped.Value.reason)" -ForegroundColor Gray
        }
    }

    Write-Host "`n🎯 NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "   1. Restart PowerShell to activate ShadowCat profile" -ForegroundColor White
    Write-Host "   2. Use 'bcat' command to navigate to tools" -ForegroundColor White  
    Write-Host "   3. Check tool-specific documentation for usage" -ForegroundColor White
    Write-Host "`n   Happy Hacking with ShadowCat! 🐱‍💻`n" -ForegroundColor Yellow
}

# Export functions - Note: This line will be removed when running in IEX mode
# The line below is needed only when this file is imported as a PowerShell module
if ($MyInvocation.Line -notmatch 'IEX|Invoke-Expression' -and (Get-Command -Name Export-ModuleMember -ErrorAction SilentlyContinue)) {
    # Only export if this is being loaded as a module (not via IEX)
    Export-ModuleMember -Function Show-ShadowCatBanner, Write-ShadowCatLog, Show-InstallationSummary
}