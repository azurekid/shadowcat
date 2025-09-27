# =============================================================================
# ShadowCat-CustomTools.ps1
# Custom tool functions (wallpaper, folder organization)
# =============================================================================

function New-ToolCategoryFolders {
    param([string]$BasePath)
    Write-ShadowCatLog "Creating categorized tool folders..." -Level "Header"

    # Only create folders for categories that have successfully installed tools
    $installedCategories = @{}
    foreach ($toolId in $script:InstalledTools.Keys) {
        if ($script:ToolCategories.ContainsKey($toolId)) {
            $category = $script:ToolCategories[$toolId]
            $installedCategories[$category] = $true
        }
    }

    foreach ($cat in $installedCategories.Keys) {
        $catFolder = Join-Path $BasePath $cat
        if (-not (Test-Path $catFolder)) {
            New-Item -Path $catFolder -ItemType Directory -Force | Out-Null
            Write-ShadowCatLog "Created folder: $catFolder" -Level "Success"
        }
    }

    if ($installedCategories.Count -eq 0) {
        Write-ShadowCatLog "No tool categories to create folders for" -Level "Info"
    }
}

function New-ToolShortcuts {
    param([string]$ToolsBasePath)
    Write-ShadowCatLog "Creating tool shortcuts in category folders..." -Level "Header"

    $shortcutsCreated = 0
    foreach ($toolId in $script:InstalledTools.Keys) {
        $toolSource = $script:InstalledTools[$toolId]
        $toolCategory = $script:ToolCategories[$toolId]

        if (-not $toolCategory) { continue }

        $categoryFolder = Join-Path $ToolsBasePath $toolCategory
        if (-not (Test-Path $categoryFolder)) { continue }

        $toolName = $toolId -replace '^[^/]+/', ''  # Remove bucket prefix for display name
        if ([string]::IsNullOrEmpty($toolName)) {
            $toolName = $toolId  # Fallback if no bucket prefix
        }
        $shortcutPath = Join-Path $categoryFolder "$toolName.lnk"

        # Skip if shortcut already exists
        if (Test-Path $shortcutPath) { continue }

        try {
            $targetPath = $null
            $workingDirectory = $null

            switch ($toolSource) {
                "Chocolatey" {
                    # For Chocolatey, try to find the executable in common locations
                    $chocoPath = "C:\ProgramData\chocolatey\bin\$toolName.exe"
                    if (Test-Path $chocoPath) {
                        $targetPath = $chocoPath
                        $workingDirectory = "C:\ProgramData\chocolatey\bin"
                    } else {
                        # Try .cmd or .bat files
                        $chocoCmdPath = "C:\ProgramData\chocolatey\bin\$toolName.cmd"
                        if (Test-Path $chocoCmdPath) {
                            $targetPath = $chocoCmdPath
                            $workingDirectory = "C:\ProgramData\chocolatey\bin"
                        }
                    }
                }
                "Scoop" {
                    # For Scoop, the executable should be in the scoop shims
                    $scoopPath = "C:\ProgramData\scoop\shims\$toolName.exe"
                    if (Test-Path $scoopPath) {
                        $targetPath = $scoopPath
                        $workingDirectory = "C:\ProgramData\scoop\shims"
                    } else {
                        # Try .cmd or .bat files
                        $scoopCmdPath = "C:\ProgramData\scoop\shims\$toolName.cmd"
                        if (Test-Path $scoopCmdPath) {
                            $targetPath = $scoopCmdPath
                            $workingDirectory = "C:\ProgramData\scoop\shims"
                        }
                    }
                }
                "GitHub" {
                    # For GitHub projects, create a shortcut to the project directory
                    # First try to find common executable files in the project
                    $projectPath = Join-Path $ToolsBasePath $toolName
                    if (Test-Path $projectPath) {
                        # Look for common executable files
                        $exeFiles = Get-ChildItem -Path $projectPath -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                        if ($exeFiles) {
                            $targetPath = $exeFiles.FullName
                            $workingDirectory = $exeFiles.DirectoryName
                        } else {
                            # Look for Python scripts
                            $pyFiles = Get-ChildItem -Path $projectPath -Filter "*.py" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^(main|run|app|cli|tool)\.py$" } | Select-Object -First 1
                            if ($pyFiles) {
                                $targetPath = "python.exe"
                                $workingDirectory = $pyFiles.DirectoryName
                                # Add arguments to run the Python script
                                $arguments = $pyFiles.FullName
                            } else {
                                # No executable found, create shortcut to open the directory in Explorer
                                $targetPath = "explorer.exe"
                                $arguments = $projectPath
                                $workingDirectory = $projectPath
                            }
                        }
                    }
                }
                "Python pip" {
                    # For Python packages, create shortcuts that run the module
                    $pythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
                    if ($pythonExe) {
                        $targetPath = $pythonExe
                        $workingDirectory = $env:USERPROFILE
                        # Extract the actual package name (remove python- prefix if present)
                        $pythonModule = $toolName -replace '^python-', ''
                        $arguments = "-m $pythonModule"
                    }
                }
            }

            if ($targetPath -and (Test-Path $targetPath)) {
                # Create Windows shortcut
                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut($shortcutPath)
                $shortcut.TargetPath = $targetPath
                if ($arguments) {
                    $shortcut.Arguments = $arguments
                }
                if ($workingDirectory) {
                    $shortcut.WorkingDirectory = $workingDirectory
                }
                $shortcut.Description = "ShadowCat Tool: $toolName"
                $shortcut.Save()

                $shortcutsCreated++
                Write-ShadowCatLog "Created shortcut: $toolName.lnk in $toolCategory" -Level "Success"
            } elseif ($toolSource -eq "GitHub" -and $targetPath -eq "explorer.exe") {
                # Special case for GitHub projects that open in Explorer
                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut($shortcutPath)
                $shortcut.TargetPath = $targetPath
                $shortcut.Arguments = $arguments
                $shortcut.WorkingDirectory = $workingDirectory
                $shortcut.Description = "ShadowCat Tool: $toolName (Open Directory)"
                $shortcut.Save()

                $shortcutsCreated++
                Write-ShadowCatLog "Created shortcut: $toolName.lnk in $toolCategory (opens directory)" -Level "Success"
            }
        }
        catch {
            Write-ShadowCatLog "Failed to create shortcut for $toolName`: $($_.Exception.Message)" -Level "Warning"
        }
    }

    Write-ShadowCatLog "Created $shortcutsCreated tool shortcuts" -Level "Info"
}function Set-DesktopBackground {
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
if ((Get-Command -Name Export-ModuleMember -ErrorAction SilentlyContinue) -and $MyInvocation.MyCommand.ModuleName) {
    # Only export if this is being loaded as a module
    Export-ModuleMember -Function New-ToolCategoryFolders, New-ToolShortcuts, Set-DesktopBackground
}