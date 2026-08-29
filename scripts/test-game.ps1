$ErrorActionPreference = "Stop"

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$godotCommand = Get-Command "godot_console" -ErrorAction SilentlyContinue
$godotExecutable = $null

if ($godotCommand) {
    $godotExecutable = $godotCommand.Source
}
else {
    $wingetPackages = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    $godotExecutable = Get-ChildItem -LiteralPath $wingetPackages -Directory -Filter "GodotEngine.GodotEngine_*" -ErrorAction SilentlyContinue |
        ForEach-Object {
            Get-ChildItem -LiteralPath $_.FullName -File -Filter "Godot*_console.exe" -ErrorAction SilentlyContinue
        } |
        Select-Object -First 1 -ExpandProperty FullName
}

if (-not $godotExecutable) {
    throw "Godot 콘솔 실행 파일을 찾지 못했습니다. Godot 4.7.2 설치를 확인하세요."
}

& $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/basic_loop_smoke_test.gd"
exit $LASTEXITCODE
