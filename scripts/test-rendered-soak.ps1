param(
    [ValidateSet('medium', 'large')][string]$Tier = 'medium',
    [ValidateRange(5, 3600)][int]$Seconds = 600,
    [string]$OutputDirectory = ''
)
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$command = Get-Command godot_console -ErrorAction SilentlyContinue
$executable = if ($command) { $command.Source } else {
    Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Directory -Filter 'GodotEngine.GodotEngine_*' |
        ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -File -Filter 'Godot*_console.exe' } |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $executable) { throw 'Godot console not found' }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path ([IO.Path]::GetTempPath()) ('sfh-soak-' + [guid]::NewGuid().ToString('N')) }
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$logPath = Join-Path $OutputDirectory ($Tier + '.log')
$resultPath = Join-Path $OutputDirectory ($Tier + '-result.json')
if ((Test-Path -LiteralPath $resultPath) -or (Test-Path -LiteralPath $logPath)) { throw 'Choose a fresh output directory; prior evidence must not be overwritten' }
$commit = & git -C $repositoryRoot rev-parse HEAD
Write-Output "RENDERED_SOAK_START tier=$Tier seconds=$Seconds source_commit=$commit output=$OutputDirectory"
# No headless, time-scale, movie fixed-time or personal save paths. A visible game window is intentional.
& $executable --path $repositoryRoot --script 'res://game/tests/rendered_soak_test.gd' --log-file $logPath -- "--tier=$Tier" "--seconds=$Seconds" "--output=$OutputDirectory"
$status = $LASTEXITCODE
$log = Get-Content -LiteralPath $logPath -Raw
if ($status -ne 0 -or $log -match 'SCRIPT ERROR:|(?m)^ERROR:|RENDERED_SOAK_FAILED' -or $log -notmatch 'RENDERED_SOAK_OK' -or -not (Test-Path -LiteralPath $resultPath)) { throw "Rendered soak failed: $logPath" }
$result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
if ($result.wall_seconds -lt $Seconds -or $result.game_seconds -lt ($Seconds * 0.9) -or $result.frames_drawn -lt 30 -or $result.display_server -eq 'headless' -or $result.failures.Count -gt 0) { throw 'Incomplete/invalid rendered evidence' }
Write-Output "RENDERED_SOAK_VERIFIED source_commit=$commit tier=$Tier output=$OutputDirectory (coverage, not human acceptance or GPU minimum-spec certification)"
