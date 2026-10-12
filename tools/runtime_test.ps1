param([string]$GameDirectory = 'E:\SteamLibrary\steamapps\common\Balatro',
    [ValidateSet('full', 'reopen')][string]$Scenario = 'full')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$qaMods = Join-Path $projectRoot '.local\qa-mods'
$userMods = Join-Path $env:APPDATA 'Balatro\Mods'
$qaSave = [IO.Path]::GetFullPath((Join-Path $env:APPDATA 'Balatro-JRC-QA'))
$expectedSave = [IO.Path]::GetFullPath($env:APPDATA).TrimEnd('\') + '\Balatro-JRC-QA'
if ($qaSave -ne $expectedSave) { throw 'Unexpected QA save directory' }
if (Test-Path -LiteralPath $qaSave) { Remove-Item -LiteralPath $qaSave -Recurse -Force }
New-Item -ItemType Directory -Path $qaMods -Force | Out-Null
foreach ($name in @('smods-main', 'DVPreview_v4.1.2')) {
    $target = Join-Path $qaMods $name
    if (-not (Test-Path -LiteralPath $target)) {
        Copy-Item -LiteralPath (Join-Path $userMods $name) -Destination $target -Recurse
    }
}
Copy-Item -LiteralPath (Join-Path $userMods 'quickrestart_steamodded.lua') -Destination $qaMods -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'JokerReclaimed') -Destination $qaMods -Recurse -Force
$qaTarget = Join-Path $qaMods 'JokerReclaimedQA'
New-Item -ItemType Directory -Path $qaTarget -Force | Out-Null
Copy-Item -Path (Join-Path $projectRoot 'tests\qa\*') -Destination $qaTarget -Recurse -Force
$previousMods = $env:LOVELY_MOD_DIR
$previousScenario = $env:JRC_QA_SCENARIO
try {
    $env:LOVELY_MOD_DIR = $qaMods
    $env:JRC_QA_SCENARIO = $Scenario
    $process = Start-Process -FilePath (Join-Path $GameDirectory 'Balatro.exe') -WorkingDirectory $GameDirectory -WindowStyle Hidden -PassThru
    Write-Output "QA process: $($process.Id)"
    Write-Output 'Isolated save identity: Balatro-JRC-QA'
} finally {
    $env:LOVELY_MOD_DIR = $previousMods
    $env:JRC_QA_SCENARIO = $previousScenario
}
