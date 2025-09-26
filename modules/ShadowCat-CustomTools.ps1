# =============================================================================
# ShadowCat-CustomTools.ps1
# Custom tool functions (wallpaper, folder organization)
# =============================================================================

function New-ToolCategoryFolders {
    param([string]$BasePath)
    Write-ShadowCatLog "Creating categorized tool folders..." -Level "Header"
    $categories = $script:ToolCategories.Values | Select-Object -Unique
    foreach ($cat in $categories) {
        $catFolder = Join-Path $BasePath $cat
        if (-not (Test-Path $catFolder)) {
            New-Item -Path $catFolder -ItemType Directory -Force | Out-Null
            Write-ShadowCatLog "Created folder: $catFolder" -Level "Success"
        }
    }
}

function Set-DesktopBackground {
    param([string]$ImageUrl)
    Write-ShadowCatLog "Setting custom desktop background..." -Level "Header"
    $wallpaperPath = "$env:TEMP\shadowcat_wallpaper.jpg"
    try {
        Invoke-WebRequest -Uri $ImageUrl -OutFile $wallpaperPath -UseBasicParsing
        # Set registry key for wallpaper
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper -Value $wallpaperPath
        # Refresh desktop to apply wallpaper
        rundll32.exe user32.dll,UpdatePerUserSystemParameters 1, True
        Write-ShadowCatLog "Desktop background set successfully." -Level "Success"
    } catch {
        Write-ShadowCatLog "Failed to set desktop background: $($_.Exception.Message)" -Level "Error"
    }
}

# Export functions - Note: This line will be removed when running in IEX mode
# The line below is needed only when this file is imported as a PowerShell module
if ($MyInvocation.Line -notmatch 'IEX|Invoke-Expression' -and (Get-Command -Name Export-ModuleMember -ErrorAction SilentlyContinue)) {
    # Only export if this is being loaded as a module (not via IEX)
    Export-ModuleMember -Function New-ToolCategoryFolders, Set-DesktopBackground
}