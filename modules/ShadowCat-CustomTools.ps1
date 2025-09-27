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
}

function New-ToolDashboard {
    param(
        [string]$InstallPath,
        [string[]]$ConfigFiles,
        [string]$InstallLevel
    )
    
    Write-ShadowCatLog "Generating HTML tool dashboard..." -Level "Header"
    
    # Create a comprehensive tool documentation mapping
    $toolDocumentationMap = @{
        # Network Tools
        "nmap" = "https://nmap.org/docs.html"
        "wireshark" = "https://www.wireshark.org/docs/"
        "putty" = "https://www.chiark.greenend.org.uk/~sgtatham/putty/docs.html"
        "ncat" = "https://nmap.org/ncat/guide/"
        "masscan" = "https://github.com/robertdavidgraham/masscan"
        "zmap" = "https://zmap.io/documentation.html"
        
        # Web Testing Tools
        "zap" = "https://www.zaproxy.org/docs/"
        "burpsuite-free" = "https://portswigger.net/burp/documentation"
        "nikto" = "https://github.com/sullo/nikto/wiki"
        "ffuf" = "https://github.com/ffuf/ffuf"
        "wfuzz" = "https://wfuzz.readthedocs.io/"
        "dirsearch" = "https://github.com/maurosoria/dirsearch"
        "sublist3r" = "https://github.com/aboul3la/Sublist3r"
        "whatweb" = "https://github.com/urbanadventurer/WhatWeb"
        "wpscan" = "https://wpscan.com/documentation/"
        "gobuster" = "https://github.com/OJ/gobuster"
        
        # Password/Hash Tools
        "hashcat" = "https://hashcat.net/wiki/"
        "john" = "https://www.openwall.com/john/doc/"
        "hydra" = "https://github.com/vanhauser-thc/thc-hydra"
        
        # Exploitation Tools
        "metasploit" = "https://docs.rapid7.com/metasploit/"
        "sqlmap" = "https://sqlmap.org/doc/"
        "mimikatz" = "https://github.com/gentilkiwi/mimikatz/wiki"
        "powersploit" = "https://github.com/PowerShellMafia/PowerSploit"
        "responder" = "https://github.com/lgandx/Responder"
        "bloodhound" = "https://bloodhound.readthedocs.io/"
        "crackmapexec" = "https://www.crackmapexec.wiki/"
        "impacket" = "https://github.com/SecureAuthCorp/impacket"
        
        # Reverse Engineering
        "ida-free" = "https://hex-rays.com/ida-free/"
        "ghidra" = "https://ghidra-sre.org/CheatSheet.html"
        "radare2" = "https://book.rada.re/"
        "binary-ninja" = "https://docs.binary.ninja/"
        "x64dbg" = "https://x64dbg.readthedocs.io/"
        
        # OSINT Tools
        "recon-ng" = "https://github.com/lanmaster53/recon-ng/wiki"
        "holehe" = "https://github.com/megadose/holehe"
        "twint" = "https://github.com/twintproject/twint"
        "shodan-cli" = "https://cli.shodan.io/"
        "theHarvester" = "https://github.com/laramies/theHarvester"
        "maltego" = "https://docs.maltego.com/"
        "osrframework" = "https://github.com/i3visio/osrframework"
        "spiderfoot" = "https://www.spiderfoot.net/documentation/"
        
        # Mobile Security
        "adb" = "https://developer.android.com/studio/command-line/adb"
        "scrcpy" = "https://github.com/Genymobile/scrcpy"
        "apktool" = "https://ibotpeaches.github.io/Apktool/"
        "jadx" = "https://github.com/skylot/jadx"
        "frida" = "https://frida.re/docs/"
        
        # Forensics Tools
        "volatility" = "https://volatilityfoundation.org/documentation/"
        "autopsy" = "https://www.autopsy.com/documentation/"
        "sleuthkit" = "https://www.sleuthkit.org/sleuthkit/docs.php"
        "exiftool" = "https://exiftool.org/documentation.html"
        "binwalk" = "https://github.com/ReFirmLabs/binwalk"
        "regripper" = "https://github.com/keydet89/RegRipper3.0"
        "rekall" = "http://www.rekall-forensic.com/documentation-1"
        "bulk_extractor" = "https://github.com/simsong/bulk_extractor"
        
        # Development Tools
        "git" = "https://git-scm.com/docs"
        "python3" = "https://docs.python.org/3/"
        "golang" = "https://golang.org/doc/"
        "nodejs" = "https://nodejs.org/en/docs/"
        "7zip" = "https://www.7-zip.org/faq.html"
        
        # Infrastructure
        "docker-desktop" = "https://docs.docker.com/"
        "virtualbox" = "https://www.virtualbox.org/wiki/Documentation"
        "vmware-workstation" = "https://docs.vmware.com/en/VMware-Workstation-Pro/"
        "vagrant" = "https://www.vagrantup.com/docs"
        
        # Network Utilities
        "curl" = "https://curl.se/docs/"
        "wget" = "https://www.gnu.org/software/wget/manual/"
        "remmina" = "https://remmina.org/how-to/"
        
        # C2 Frameworks
        "empire" = "https://bc-security.gitbook.io/empire-wiki/"
        "covenant" = "https://github.com/cobbr/Covenant/wiki"
        "cobalt-strike" = "https://www.cobaltstrike.com/help"
        "sliver" = "https://sliver.sh/docs"
        
        # Python Libraries
        "python-nmap" = "https://python-nmap.readthedocs.io/"
        "requests" = "https://requests.readthedocs.io/"
        "scapy" = "https://scapy.readthedocs.io/"
        "pwntools" = "https://docs.pwntools.com/"
    }
    
    # Create Reports directory if it doesn't exist
    $reportsPath = Join-Path $InstallPath "Reports"
    if (-not (Test-Path $reportsPath)) {
        New-Item -Path $reportsPath -ItemType Directory -Force | Out-Null
    }
    
    $dashboardPath = Join-Path $reportsPath "ShadowCat-Dashboard.html"
    
    # Collect all tools from processed configurations
    $allTools = @()
    $configSummary = @()
    
    foreach ($configFile in $ConfigFiles) {
        $config = $null
        if ($script:Online) {
            if ($script:ProcessedConfigs.ContainsKey($configFile)) {
                $config = $script:ProcessedConfigs[$configFile]
            }
        } else {
            $localKey = Join-Path (Join-Path $script:PSScriptRoot "configs") $configFile
            if ($script:ProcessedConfigs.ContainsKey($localKey)) {
                $config = $script:ProcessedConfigs[$localKey]
            }
        }
        
        if ($null -eq $config) { continue }
        
        $configSummary += @{
            Name = $config.metadata.name
            Category = $config.metadata.category
            Description = $config.metadata.description
            Level = $config.metadata.installLevel
        }
        
        # Extract tools from different package managers
        if ($config.chocolatey -and $config.chocolatey.packages) {
            foreach ($tool in $config.chocolatey.packages) {
                $allTools += @{
                    Name = $tool.name
                    Description = $tool.description
                    Category = $tool.category
                    PackageManager = "Chocolatey"
                    Level = if ($tool.installLevel) { $tool.installLevel } else { $config.metadata.installLevel }
                    Required = $tool.required
                    ToolId = $tool.toolId
                }
            }
        }
        
        if ($config.scoop -and $config.scoop.packages) {
            foreach ($tool in $config.scoop.packages) {
                $allTools += @{
                    Name = $tool.name
                    Description = $tool.description
                    Category = $tool.category
                    PackageManager = "Scoop"
                    Level = if ($tool.installLevel) { $tool.installLevel } else { $config.metadata.installLevel }
                    Required = $tool.required
                    ToolId = $tool.toolId
                }
            }
        }
        
        if ($config.python -and $config.python.packages) {
            foreach ($tool in $config.python.packages) {
                $allTools += @{
                    Name = $tool.name
                    Description = $tool.description
                    Category = $tool.category
                    PackageManager = "Python"
                    Level = if ($tool.installLevel) { $tool.installLevel } else { $config.metadata.installLevel }
                    Required = $tool.required
                    ToolId = $tool.toolId
                }
            }
        }
        
        if ($config.github -and $config.github.projects) {
            foreach ($tool in $config.github.projects) {
                $toolName = Split-Path $tool.url -Leaf
                $allTools += @{
                    Name = $toolName
                    Description = $tool.description
                    Category = $tool.category
                    PackageManager = "GitHub"
                    Level = if ($tool.installLevel) { $tool.installLevel } else { $config.metadata.installLevel }
                    Required = $tool.required
                    ToolId = $tool.toolId
                    Url = $tool.url
                }
            }
        }
    }
    
    # Generate HTML content
    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ShadowCat Tool Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
            color: #ffffff;
            line-height: 1.6;
        }
        
        .header {
            background: linear-gradient(135deg, #EF0909 0%, #8b0000 100%);
            padding: 2rem;
            text-align: center;
            box-shadow: 0 4px 20px rgba(239, 9, 9, 0.3);
        }
        
        .header h1 {
            font-size: 3rem;
            margin-bottom: 0.5rem;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }
        
        .header .subtitle {
            font-size: 1.2rem;
            opacity: 0.9;
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            padding: 2rem;
            background: rgba(255,255,255,0.05);
        }
        
        .stat-card {
            background: rgba(255,255,255,0.1);
            padding: 1.5rem;
            border-radius: 10px;
            text-align: center;
            border: 1px solid rgba(239, 9, 9, 0.3);
        }
        
        .stat-card h3 {
            font-size: 2rem;
            color: #EF0909;
            margin-bottom: 0.5rem;
        }
        
        .controls {
            padding: 2rem;
            background: rgba(255,255,255,0.05);
            display: flex;
            flex-wrap: wrap;
            gap: 1rem;
            align-items: center;
        }
        
        .search-box {
            flex: 1;
            min-width: 300px;
            padding: 0.8rem;
            border: 2px solid rgba(239, 9, 9, 0.5);
            border-radius: 5px;
            background: rgba(255,255,255,0.1);
            color: white;
            font-size: 1rem;
        }
        
        .search-box::placeholder {
            color: rgba(255,255,255,0.7);
        }
        
        .filter-buttons {
            display: flex;
            gap: 0.5rem;
            flex-wrap: wrap;
        }
        
        .filter-btn {
            padding: 0.5rem 1rem;
            border: 2px solid #EF0909;
            background: transparent;
            color: white;
            border-radius: 5px;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .filter-btn:hover, .filter-btn.active {
            background: #EF0909;
            transform: translateY(-2px);
        }
        
        .tools-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 1.5rem;
            padding: 2rem;
        }
        
        .tool-card {
            background: rgba(255,255,255,0.1);
            border-radius: 10px;
            padding: 1.5rem;
            border: 1px solid rgba(239, 9, 9, 0.3);
            transition: all 0.3s ease;
            position: relative;
        }
        
        .tool-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 30px rgba(239, 9, 9, 0.2);
            border-color: #EF0909;
        }
        
        .tool-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 1rem;
        }
        
        .tool-name {
            font-size: 1.3rem;
            font-weight: bold;
            color: #EF0909;
        }
        
        .tool-manager {
            background: rgba(239, 9, 9, 0.2);
            padding: 0.3rem 0.8rem;
            border-radius: 15px;
            font-size: 0.8rem;
            color: #EF0909;
            border: 1px solid rgba(239, 9, 9, 0.5);
        }
        
        .tool-description {
            margin-bottom: 1rem;
            opacity: 0.9;
        }
        
        .tool-meta {
            display: flex;
            flex-wrap: wrap;
            gap: 0.5rem;
            font-size: 0.9rem;
        }
        
        .meta-tag {
            background: rgba(255,255,255,0.2);
            padding: 0.3rem 0.8rem;
            border-radius: 15px;
            border: 1px solid rgba(255,255,255,0.3);
        }
        
        .level-lite { border-color: #4CAF50; color: #4CAF50; }
        .level-standard { border-color: #FF9800; color: #FF9800; }
        .level-professional { border-color: #9C27B0; color: #9C27B0; }
        .level-core { border-color: #2196F3; color: #2196F3; }
        
        .config-summary {
            padding: 2rem;
            background: rgba(255,255,255,0.05);
        }
        
        .config-summary h2 {
            color: #EF0909;
            margin-bottom: 1rem;
            font-size: 1.8rem;
        }
        
        .config-list {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 1rem;
        }
        
        .config-item {
            background: rgba(255,255,255,0.1);
            padding: 1rem;
            border-radius: 8px;
            border-left: 4px solid #EF0909;
        }
        
        .config-item h3 {
            color: #EF0909;
            margin-bottom: 0.5rem;
        }
        
        .tool-links {
            margin-top: 1rem;
            display: flex;
            gap: 1rem;
            flex-wrap: wrap;
        }
        
        .doc-link, .github-link {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 1rem;
            background: rgba(239, 9, 9, 0.1);
            border: 1px solid rgba(239, 9, 9, 0.3);
            border-radius: 20px;
            color: #EF0909;
            text-decoration: none;
            font-size: 0.9rem;
            transition: all 0.3s ease;
        }
        
        .doc-link:hover, .github-link:hover {
            background: rgba(239, 9, 9, 0.2);
            border-color: #EF0909;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(239, 9, 9, 0.2);
        }
        
        .doc-link {
            border-color: rgba(76, 175, 80, 0.5);
            color: #4CAF50;
            background: rgba(76, 175, 80, 0.1);
        }
        
        .doc-link:hover {
            background: rgba(76, 175, 80, 0.2);
            border-color: #4CAF50;
            box-shadow: 0 4px 12px rgba(76, 175, 80, 0.2);
        }
        
        .footer {
            text-align: center;
            padding: 2rem;
            background: rgba(0,0,0,0.3);
            margin-top: 2rem;
        }
        
        @media (max-width: 768px) {
            .header h1 { font-size: 2rem; }
            .tools-grid { grid-template-columns: 1fr; }
            .controls { flex-direction: column; align-items: stretch; }
            .search-box { min-width: unset; }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🐱‍💻 ShadowCat Tool Dashboard</h1>
        <div class="subtitle">Security Toolkit - $InstallLevel Level Installation</div>
        <div class="subtitle">Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</div>
    </div>
    
    <div class="stats">
        <div class="stat-card">
            <h3 id="total-tools">$($allTools.Count)</h3>
            <p>Total Tools</p>
        </div>
        <div class="stat-card">
            <h3 id="categories-count">$(@($allTools | Select-Object -Property Category -Unique).Count)</h3>
            <p>Categories</p>
        </div>
        <div class="stat-card">
            <h3 id="configs-count">$($configSummary.Count)</h3>
            <p>Configurations</p>
        </div>
        <div class="stat-card">
            <h3>$InstallLevel</h3>
            <p>Install Level</p>
        </div>
    </div>
    
    <div class="controls">
        <input type="text" class="search-box" id="search" placeholder="Search tools by name or description...">
        <div class="filter-buttons">
            <button class="filter-btn active" data-filter="all">All</button>
            <button class="filter-btn" data-filter="Chocolatey">Chocolatey</button>
            <button class="filter-btn" data-filter="Scoop">Scoop</button>
            <button class="filter-btn" data-filter="Python">Python</button>
            <button class="filter-btn" data-filter="GitHub">GitHub</button>
        </div>
    </div>
    
    <div class="tools-grid" id="tools-grid">
"@

    # Add tool cards to HTML
    foreach ($tool in $allTools) {
        $levelClass = "level-$($tool.Level)"
        $requiredBadge = if ($tool.Required -eq $true) { "Required" } else { "Optional" }
        
        # Get documentation link for this tool
        $docLink = ""
        $toolName = $tool.Name -replace '^[^/]+/', ''  # Remove bucket prefix if present
        if ($toolDocumentationMap.ContainsKey($toolName)) {
            $docUrl = $toolDocumentationMap[$toolName]
            $docLink = "<a href=`"$docUrl`" target=`"_blank`" class=`"doc-link`" title=`"View documentation for $toolName`">📚 Documentation</a>"
        } elseif ($toolDocumentationMap.ContainsKey($tool.Name)) {
            $docUrl = $toolDocumentationMap[$tool.Name]
            $docLink = "<a href=`"$docUrl`" target=`"_blank`" class=`"doc-link`" title=`"View documentation for $($tool.Name)`">📚 Documentation</a>"
        }
        
        # GitHub link for GitHub tools
        $githubLink = ""
        if ($tool.Url) { 
            $githubLink = "<a href=`"$($tool.Url)`" target=`"_blank`" class=`"github-link`" title=`"View source on GitHub`">🔗 Source Code</a>" 
        }
        
        # Combine links
        $toolLinks = ""
        if ($docLink -and $githubLink) {
            $toolLinks = "<div class=`"tool-links`">$docLink $githubLink</div>"
        } elseif ($docLink) {
            $toolLinks = "<div class=`"tool-links`">$docLink</div>"
        } elseif ($githubLink) {
            $toolLinks = "<div class=`"tool-links`">$githubLink</div>"
        }
        
        $htmlContent += @"
        <div class="tool-card" data-manager="$($tool.PackageManager)" data-category="$($tool.Category)" data-level="$($tool.Level)">
            <div class="tool-header">
                <div class="tool-name">$($tool.Name)</div>
                <div class="tool-manager">$($tool.PackageManager)</div>
            </div>
            <div class="tool-description">$($tool.Description)</div>
            <div class="tool-meta">
                <span class="meta-tag">$($tool.Category)</span>
                <span class="meta-tag $levelClass">$($tool.Level)</span>
                <span class="meta-tag">$requiredBadge</span>
            </div>
            $toolLinks
        </div>
"@
    }

    $htmlContent += @"
    </div>
    
    <div class="config-summary">
        <h2>📋 Installed Configurations</h2>
        <div class="config-list">
"@

    foreach ($config in $configSummary) {
        $htmlContent += @"
            <div class="config-item">
                <h3>$($config.Name)</h3>
                <p><strong>Category:</strong> $($config.Category)</p>
                <p><strong>Level:</strong> $($config.Level)</p>
                <p>$($config.Description)</p>
            </div>
"@
    }

    $htmlContent += @"
        </div>
    </div>
    
    <div class="footer">
        <p>ShadowCat Security Toolkit - Generated by ShadowCat Installer</p>
        <p>Dashboard saved to: $dashboardPath</p>
    </div>
    
    <script>
        // Search functionality
        const searchBox = document.getElementById('search');
        const toolsGrid = document.getElementById('tools-grid');
        const filterButtons = document.querySelectorAll('.filter-btn');
        const toolCards = document.querySelectorAll('.tool-card');
        
        let currentFilter = 'all';
        
        searchBox.addEventListener('input', filterTools);
        
        filterButtons.forEach(btn => {
            btn.addEventListener('click', () => {
                // Get all filter buttons (including dynamically added ones)
                const allFilterButtons = document.querySelectorAll('.filter-btn');
                // Toggle functionality: if clicking active button, deselect it
                if (btn.classList.contains('active')) {
                    allFilterButtons.forEach(b => b.classList.remove('active'));
                    currentFilter = 'all';
                } else {
                    allFilterButtons.forEach(b => b.classList.remove('active'));
                    btn.classList.add('active');
                    currentFilter = btn.dataset.filter;
                }
                filterTools();
            });
        });
        
        function filterTools() {
            const searchTerm = searchBox.value.toLowerCase();
            let visibleCount = 0;
            
            toolCards.forEach(card => {
                const name = card.querySelector('.tool-name').textContent.toLowerCase();
                const description = card.querySelector('.tool-description').textContent.toLowerCase();
                const manager = card.dataset.manager;
                
                const matchesSearch = name.includes(searchTerm) || description.includes(searchTerm);
                const matchesFilter = currentFilter === 'all' || manager === currentFilter;
                
                if (matchesSearch && matchesFilter) {
                    card.style.display = 'block';
                    visibleCount++;
                } else {
                    card.style.display = 'none';
                }
            });
            
            document.getElementById('total-tools').textContent = visibleCount;
        }
        
        // Category filter functionality
        const categories = [...new Set([...toolCards].map(card => card.dataset.category))];
        
        // Add category filter buttons
        categories.forEach(category => {
            const btn = document.createElement('button');
            btn.className = 'filter-btn';
            btn.textContent = category;
            btn.dataset.filter = category;
            btn.addEventListener('click', () => {
                // Get all filter buttons (including dynamically added ones)
                const allFilterButtons = document.querySelectorAll('.filter-btn');
                // Toggle functionality: if clicking active button, deselect it
                if (btn.classList.contains('active')) {
                    allFilterButtons.forEach(b => b.classList.remove('active'));
                    currentFilter = 'all';
                } else {
                    allFilterButtons.forEach(b => b.classList.remove('active'));
                    btn.classList.add('active');
                    currentFilter = category;
                }
                filterToolsByCategory();
            });
            document.querySelector('.filter-buttons').appendChild(btn);
        });
        
        function filterToolsByCategory() {
            const searchTerm = searchBox.value.toLowerCase();
            let visibleCount = 0;
            
            toolCards.forEach(card => {
                const name = card.querySelector('.tool-name').textContent.toLowerCase();
                const description = card.querySelector('.tool-description').textContent.toLowerCase();
                const category = card.dataset.category;
                
                const matchesSearch = name.includes(searchTerm) || description.includes(searchTerm);
                const matchesFilter = currentFilter === 'all' || category === currentFilter;
                
                if (matchesSearch && matchesFilter) {
                    card.style.display = 'block';
                    visibleCount++;
                } else {
                    card.style.display = 'none';
                }
            });
            
            document.getElementById('total-tools').textContent = visibleCount;
        }
    </script>
</body>
</html>
"@

    # Write HTML to file
    try {
        Set-Content -Path $dashboardPath -Value $htmlContent -Encoding UTF8
        Write-ShadowCatLog "HTML dashboard created: $dashboardPath" -Level "Success"
        
        # Try to open the dashboard in the default browser
        try {
            Start-Process $dashboardPath
            Write-ShadowCatLog "Dashboard opened in default browser" -Level "Success"
        } catch {
            Write-ShadowCatLog "Dashboard created but could not open automatically. Open manually: $dashboardPath" -Level "Warning"
        }
    } catch {
        Write-ShadowCatLog "Failed to create HTML dashboard: $($_.Exception.Message)" -Level "Error"
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
if ((Get-Command -Name Export-ModuleMember -ErrorAction SilentlyContinue) -and $MyInvocation.MyCommand.ModuleName) {
    # Only export if this is being loaded as a module
    Export-ModuleMember -Function New-ToolCategoryFolders, New-ToolShortcuts, New-ToolDashboard, Set-DesktopBackground
}