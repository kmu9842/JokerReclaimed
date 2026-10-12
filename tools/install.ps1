param([string]$ModsDirectory = (Join-Path $env:APPDATA 'Balatro\Mods'))
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$source = Join-Path $projectRoot 'JokerReclaimed'
$destination = Join-Path $ModsDirectory 'JokerReclaimed'
if (-not (Test-Path -LiteralPath (Join-Path $source 'JokerReclaimed.json'))) { throw 'Missing mod metadata' }
$preservedConfig = $null
if (Test-Path -LiteralPath $destination) {
    $backupRoot = Join-Path $projectRoot '.local\install-backups'
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    $backup = Join-Path $backupRoot ('JokerReclaimed-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Copy-Item -LiteralPath $destination -Destination $backup -Recurse
    $configPath = Join-Path $destination 'config.lua'
    if (Test-Path -LiteralPath $configPath) { $preservedConfig = [IO.File]::ReadAllText($configPath) }
    Write-Output "Previous installation backed up: $backup"
}
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Get-ChildItem -LiteralPath $source -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $destination -Recurse -Force
}
if ($null -ne $preservedConfig) {
    # Retain user preferences while dropping the option removed in 1.0.2.
    $retiredOption = '(?:\[\s*["'']enable_cheats["'']\s*\]|\benable_cheats)\s*=\s*(?:true|false)\s*[,;]?'
    $preservedConfig = [regex]::Replace($preservedConfig, $retiredOption, '')
    [IO.File]::WriteAllText((Join-Path $destination 'config.lua'), $preservedConfig, [Text.UTF8Encoding]::new($false))
}
$verified = 0
Get-ChildItem -LiteralPath $source -File -Recurse | ForEach-Object {
    $relative = $_.FullName.Substring($source.Length).TrimStart('\')
    if ($relative -eq 'config.lua' -and $null -ne $preservedConfig) { return }
    $installed = Join-Path $destination $relative
    if ((Get-FileHash -LiteralPath $_.FullName).Hash -ne (Get-FileHash -LiteralPath $installed).Hash) {
        throw "Installed file differs: $relative"
    }
    $verified++
}
Write-Output "Installed and hash-verified $verified files: $destination"
Write-Output 'Restart Balatro to load the mod. Persistent wallet files were not changed.'
