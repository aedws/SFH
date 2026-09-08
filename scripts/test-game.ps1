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

# Validate before Godot can auto-import gameplay tables as translations.
$csvPolicyPython = Join-Path $repositoryRoot '.venv/Scripts/python.exe'
if (-not (Test-Path -LiteralPath $csvPolicyPython)) { $csvPolicyPython = 'python' }
& $csvPolicyPython (Join-Path $PSScriptRoot 'test_balance_csv_imports.py')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# A fresh clone has no imported fonts or global GDScript class cache yet.
# Build those generated inputs explicitly so the smoke test does not depend on
# somebody having opened the project in the editor beforehand.
& $godotExecutable --headless --editor --path $repositoryRoot --quit
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$playerUiOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/player_facing_ui_contract_test.gd" 2>&1
$playerUiStatus = $LASTEXITCODE
$playerUiOutput | Write-Output
if ($playerUiStatus -ne 0 -or ($playerUiOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($playerUiOutput -join "`n") -notmatch 'PLAYER_FACING_UI_OK') { throw 'Player-facing UI contract failed.' }
$floorOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/floor_render_contract_test.gd" 2>&1
$floorOutput | ForEach-Object { Write-Output $_ }
if ($LASTEXITCODE -ne 0 -or ($floorOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($floorOutput -join "`n") -notmatch 'FLOOR_RENDER_OK') { throw 'Floor rendering contract failed.' }
$healthOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/kit_only_health_contract_test.gd" 2>&1
$healthOutput | Write-Output
if ($LASTEXITCODE -ne 0 -or ($healthOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($healthOutput -join "`n") -notmatch 'KIT_ONLY_HEALTH_OK') { throw 'Kit-only health contract failed.' }
$policyOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/provisional_policy_contract_test.gd" 2>&1
$policyStatus = $LASTEXITCODE
$partialOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/partial_completion_contract_test.gd" 2>&1
$partialStatus = $LASTEXITCODE
$partialOutput | ForEach-Object { Write-Output $_ }
if ($partialStatus -ne 0 -or ($partialOutput -match 'SCRIPT ERROR:|^ERROR:') -or -not ($partialOutput -match 'PARTIAL_COMPLETION_OK')) { exit 1 }
$funOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/fun_qa_affordance_test.gd" 2>&1
$funStatus = $LASTEXITCODE
$attachmentOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/weapon_attachment_rack_test.gd" 2>&1
$attachmentStatus = $LASTEXITCODE
$socketOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/module_socket_workspace_test.gd" 2>&1
$socketStatus = $LASTEXITCODE
$socketOutput | ForEach-Object { Write-Output $_ }
if ($socketStatus -ne 0 -or ($socketOutput -match 'SCRIPT ERROR:|^ERROR:') -or -not ($socketOutput -match 'MODULE_SOCKET_WORKSPACE_OK')) { exit 1 }
$attachmentOutput | ForEach-Object { Write-Output $_ }
if ($attachmentStatus -ne 0 -or ($attachmentOutput -match 'SCRIPT ERROR:|^ERROR:') -or -not ($attachmentOutput -match 'WEAPON_ATTACHMENT_RACK_OK')) { exit 1 }
$funOutput | ForEach-Object { Write-Output $_ }
if ($funStatus -ne 0 -or ($funOutput -match 'SCRIPT ERROR:|^ERROR:') -or -not ($funOutput -match 'FUN_QA_AFFORDANCE_OK')) { exit 1 }
$policyOutput | ForEach-Object { Write-Output $_ }
if ($policyStatus -ne 0 -or ($policyOutput -match 'SCRIPT ERROR:|^ERROR:') -or -not ($policyOutput -match 'PROVISIONAL_POLICY_OK')) { exit 1 }
$feedbackOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/frame_feedback_contract_test.gd" 2>&1
$feedbackStatus = $LASTEXITCODE
$feedbackOutput | ForEach-Object { Write-Output $_ }
if ($feedbackStatus -ne 0 -or ($feedbackOutput -match 'SCRIPT ERROR:|^ERROR:') -or -not ($feedbackOutput -match 'FRAME_FEEDBACK_OK')) { exit 1 }
& $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/smart_targeting_center_contract_test.gd"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/circular_coverage_contract_test.gd"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/training_loadout_restore_contract_test.gd"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$optionalOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/training_optional_matrix_test.gd" 2>&1
$optionalStatus = $LASTEXITCODE
$optionalOutput | ForEach-Object { Write-Output $_ }
if ($optionalStatus -ne 0 -or ($optionalOutput -match 'SCRIPT ERROR:|^ERROR:') -or -not ($optionalOutput -match 'TRAINING_OPTIONAL_MATRIX_OK')) { exit 1 }
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
