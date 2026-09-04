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

# A fresh clone has no imported fonts or global GDScript class cache yet.
# Build those generated inputs explicitly so the smoke test does not depend on
# somebody having opened the project in the editor beforehand.
& $godotExecutable --headless --editor --path $repositoryRoot --quit
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/basic_loop_smoke_test.gd"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
& $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/equipment_fixed_identity_contract_test.gd"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
python (Join-Path $PSScriptRoot "sync_equipment_identity.py") --check
exit $LASTEXITCODE
