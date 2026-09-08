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

$rematchOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/game_ui_rematch_test.gd" 2>&1
$rematchCode = $LASTEXITCODE
$rematchOutput | Write-Output
if ($rematchCode -ne 0 -or ($rematchOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($rematchOutput -join "`n") -notmatch 'GAME_UI_REMATCH_OK') { exit 1 }
$galleryOutput = & $godotExecutable --headless --path $repositoryRoot 'res://game/tests/game_ui_review.tscn' 2>&1
$galleryCode = $LASTEXITCODE
$galleryOutput | Write-Output
if ($galleryCode -ne 0 -or ($galleryOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or @($galleryOutput | Select-String 'UI_REVIEW_FRAME ').Count -ne 29) { exit 1 }
& $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/training_ground_gameplay_e2e_test.gd"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/e2e_play_session_test.gd"
exit $LASTEXITCODE
