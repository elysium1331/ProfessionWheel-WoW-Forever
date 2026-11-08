# Installs the built ProfessionWheel zip into the local WoW Forever AddOns folder.
# Developer convenience for this repository; it is not shipped in the release zip.
#
#   Double-click Install-ProfessionWheel.cmd, or:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\install.ps1 [-WowPath "D:\Games\World of Warcraft"]
#
# Finds the game via Battle.net's install records, the Windows uninstall registry,
# and common folders. Touches only <WoW>\_forever_\Interface\AddOns\Elysium_ProfessionWheel.
# An existing ProfessionWheel folder is copied to .\backups\ first.
param([string]$WowPath)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Addon = 'Elysium_ProfessionWheel'
$LegacyFolders = @()
$Flavor = '_forever_'

function Get-Version {
    $line = Select-String -Path (Join-Path $Root "$Addon.toc") -Pattern '^## Version:\s*(.+?)\s*$' | Select-Object -First 1
    if (-not $line) { throw "No '## Version:' in $Addon.toc" }
    $line.Matches[0].Groups[1].Value
}

function Get-Candidates {
    $list = New-Object System.Collections.Generic.List[string]
    if ($WowPath) { $list.Add($WowPath) }
    # Battle.net agent database stores install paths as plain text.
    $db = Join-Path $env:ProgramData 'Battle.net\Agent\product.db'
    if (Test-Path $db) {
        $text = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($db))
        foreach ($m in [regex]::Matches($text, '[A-Za-z]:[\\/][^\x00-\x1f"<>|]*?World of Warcraft')) { $list.Add($m.Value) }
    }
    foreach ($key in 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                     'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*') {
        Get-ItemProperty $key -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like '*World of Warcraft*' -and $_.InstallLocation } |
            ForEach-Object { $list.Add($_.InstallLocation) }
    }
    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        foreach ($sub in 'Blizzard\World of Warcraft', 'Program Files (x86)\World of Warcraft',
                         'Program Files\World of Warcraft', 'Games\World of Warcraft', 'World of Warcraft') {
            $list.Add((Join-Path $drive.Root $sub))
        }
    }
    $list | ForEach-Object { $_.TrimEnd('\', '/') -replace '/', '\' } | Select-Object -Unique
}

$version = Get-Version
$zip = Join-Path $Root "dist\$Addon-$version.zip"
if (-not (Test-Path $zip)) {
    Write-Host "Building $Addon $version ..."
    & python (Join-Path $Root 'scripts\package.py')
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $zip)) { throw "Build failed; run: python scripts\package.py" }
}

$wow = Get-Candidates | Where-Object { Test-Path (Join-Path $_ $Flavor) -PathType Container } | Select-Object -First 1
if (-not $wow) {
    throw "Could not find a WoW Forever install (a '$Flavor' folder). Re-run with -WowPath ""<folder containing $Flavor>""."
}
$addons = Join-Path $wow "$Flavor\Interface\AddOns"
if (-not (Test-Path $addons)) {
    New-Item -ItemType Directory -Path $addons | Out-Null   # the game or CurseForge app would create this
    Write-Host "Created $addons"
}

if (Get-Process -Name Wow -ErrorAction SilentlyContinue) {
    Write-Host "Note: WoW is running. Type /reload in game to load the new files (restart the game if a TOC change does not show up)."
}

foreach ($legacy in $LegacyFolders) {
    $old = Join-Path $addons $legacy
    if (Test-Path (Join-Path $old "$legacy.toc")) {
        $backup = Join-Path $Root ("backups\$legacy-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
        New-Item -ItemType Directory -Path (Split-Path $backup) -Force | Out-Null
        Copy-Item $old $backup -Recurse
        Remove-Item $old -Recurse -Force
        Write-Host "Removed old folder name $legacy (backup: $backup)"
    }
}

$target = Join-Path $addons $Addon
if (Test-Path $target) {
    $backup = Join-Path $Root ("backups\$Addon-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path (Split-Path $backup) -Force | Out-Null
    Copy-Item $target $backup -Recurse
    Remove-Item $target -Recurse -Force
    Write-Host "Backed up previous install to $backup"
}

Expand-Archive -Path $zip -DestinationPath $addons
if (-not (Test-Path (Join-Path $target "$Addon.toc"))) { throw "Install check failed: $Addon.toc not found in $target" }
Write-Host "Installed $Addon $version into $target"
