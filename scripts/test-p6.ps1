$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$godotCommand = Get-Command "godot_console" -ErrorAction SilentlyContinue
$godotExecutable = $null
if ($godotCommand) {
    $godotExecutable = $godotCommand.Source
} else {
    $wingetPackages = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    $godotExecutable = Get-ChildItem -LiteralPath $wingetPackages -Directory -Filter "GodotEngine.GodotEngine_*" -ErrorAction SilentlyContinue |
        ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Recurse -Filter "Godot_v*_console.exe" -ErrorAction SilentlyContinue } |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $godotExecutable) { throw "Godot console executable not found." }
& $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/ranking_provider_contract_test.gd"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/ranking_season_contract_test.gd"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
