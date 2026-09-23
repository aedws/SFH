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
& $csvPolicyPython (Join-Path $PSScriptRoot 'test_gdscript_dependencies.py')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $csvPolicyPython (Join-Path $PSScriptRoot 'check_game_ui_audit.py')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $csvPolicyPython (Join-Path $PSScriptRoot 'test_combat_audio_assets.py')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $csvPolicyPython (Join-Path $PSScriptRoot 'test_run_flow_summary.py')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# A fresh clone has no imported fonts or global GDScript class cache yet.
& $csvPolicyPython (Join-Path $PSScriptRoot 'sync_difficulty.py') --check
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $csvPolicyPython (Join-Path $PSScriptRoot 'sync_container_capacity.py') --check
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $csvPolicyPython (Join-Path $PSScriptRoot 'compile_tactical_skills.py') --check
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $csvPolicyPython (Join-Path $PSScriptRoot 'test_tactical_compiler.py')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
# Build those generated inputs explicitly so the smoke test does not depend on
# somebody having opened the project in the editor beforehand.
& $godotExecutable --headless --editor --path $repositoryRoot --quit
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

# Same provenance gate as CI: presentation source changes also refresh catalog evidence.
$dpsOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://scripts/export_dps_catalog.gd" -- --check 2>&1
$dpsStatus = $LASTEXITCODE
$dpsOutput | Write-Output
if ($dpsStatus -ne 0 -or ($dpsOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($dpsOutput -join "`n") -notmatch 'DPS_CATALOG_OK') { throw 'DPS catalog provenance differs from runtime.' }
$compoundOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/compound_difficulty_contract_test.gd" 2>&1
$compoundStatus = $LASTEXITCODE
$compoundOutput | Write-Output
if ($compoundStatus -ne 0 -or ($compoundOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($compoundOutput -join "`n") -notmatch 'COMPOUND_DIFFICULTY_OK') { throw 'Compound difficulty contract failed.' }
$tacticalOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/tactical_skill_catalog_test.gd" 2>&1
$tacticalStatus = $LASTEXITCODE
$tacticalOutput | Write-Output
if ($tacticalStatus -ne 0 -or ($tacticalOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($tacticalOutput -join "`n") -notmatch 'TACTICAL_SKILL_CATALOG_PASS') { throw 'Tactical skill contract failed.' }

$armorOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/armor_set_contract_test.gd" 2>&1
$armorStatus = $LASTEXITCODE
$armorOutput | Write-Output
if ($armorStatus -ne 0 -or ($armorOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($armorOutput -join "`n") -notmatch 'ARMOR_SET_OK') { throw 'Armor set contract failed.' }

$arsenalOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/weapon_arsenal_contract_test.gd" 2>&1
$arsenalStatus = $LASTEXITCODE
$arsenalOutput | Write-Output
if ($arsenalStatus -ne 0 -or ($arsenalOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($arsenalOutput -join "`n") -notmatch 'WEAPON_ARSENAL_OK') { throw 'Weapon arsenal contract failed.' }

$inventoryReserveOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/inventory_reserve_contract_test.gd" 2>&1
$inventoryReserveStatus = $LASTEXITCODE
$inventoryReserveOutput | Write-Output
if ($inventoryReserveStatus -ne 0 -or ($inventoryReserveOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($inventoryReserveOutput -join "`n") -notmatch 'INVENTORY_RESERVE_OK') { throw 'Lossless inventory reserve contract failed.' }

$inventoryPouchOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/inventory_pouch_contract_test.gd" 2>&1
$inventoryPouchStatus = $LASTEXITCODE
$inventoryPouchOutput | Write-Output
if ($inventoryPouchStatus -ne 0 -or ($inventoryPouchOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($inventoryPouchOutput -join "`n") -notmatch 'INVENTORY_POUCH_OK') { throw 'Protected pouch and capacity contract failed.' }

$inventoryViewOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/inventory_presentation_contract_test.gd" 2>&1
$inventoryViewStatus = $LASTEXITCODE
$inventoryViewOutput | Write-Output
if ($inventoryViewStatus -ne 0 -or ($inventoryViewOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($inventoryViewOutput -join "`n") -notmatch 'INVENTORY_PRESENTATION_OK') { throw 'Inventory presentation contract failed.' }

$equipmentScreenOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/equipment_screen_contract_test.gd" 2>&1
$equipmentScreenStatus = $LASTEXITCODE
$equipmentScreenOutput | Write-Output
if ($equipmentScreenStatus -ne 0 -or ($equipmentScreenOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($equipmentScreenOutput -join "`n") -notmatch 'EQUIPMENT_SCREEN_OK') { throw 'Equipment screen contract failed.' }

$mobileEntryOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/mobile_control_entry_contract_test.gd" 2>&1
$mobileEntryCode = $LASTEXITCODE
$mobileEntryOutput | Write-Output
if ($mobileEntryCode -ne 0 -or ($mobileEntryOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($mobileEntryOutput -join "`n") -notmatch 'MOBILE_CONTROL_ENTRY_OK') { throw 'Mobile entry and HUD reserved-region contract failed.' }

$fogOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/roguelike_fog_contract_test.gd" 2>&1
$fogStatus = $LASTEXITCODE
$fogOutput | Write-Output
if ($fogStatus -ne 0 -or ($fogOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($fogOutput -join "`n") -notmatch 'ROGUELIKE_FOG_OK') { throw 'Roguelike fog contract failed.' }
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
$combatFxOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/combat_fx_contract_test.gd" 2>&1
$combatFxStatus = $LASTEXITCODE
$combatFxOutput | Write-Output
if ($combatFxStatus -ne 0 -or ($combatFxOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($combatFxOutput -join "`n") -notmatch 'COMBAT_FX_OK') { throw 'Combat FX contract failed.' }
$feedbackOutput | ForEach-Object { Write-Output $_ }
if ($feedbackStatus -ne 0 -or ($feedbackOutput -match 'SCRIPT ERROR:|^ERROR:') -or -not ($feedbackOutput -match 'FRAME_FEEDBACK_OK')) { exit 1 }
& $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/smart_targeting_center_contract_test.gd"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/circular_coverage_contract_test.gd"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
foreach ($contractCase in @(@('run_pressure_contract_test', 'RUN_PRESSURE_OK'), @('socket_target_selection_contract_test', 'SOCKET_TARGET_SELECTION_OK'), @('vanguard_resource_contract_test', 'VANGUARD_RESOURCE_OK'), @('run_flow_contract_test', 'RUN_FLOW_OK'), @('training_live_catalog_contract_test', 'TRAINING_LIVE_CATALOG_OK'), @('combat_audio_contract_test', 'COMBAT_AUDIO_OK'), @('extraction_decay_contract_test', 'EXTRACTION_DECAY_OK'), @('enemy_attack_telegraph_contract_test', 'ENEMY_TELEGRAPH_OK'), @('equipped_rune_settlement_contract_test', 'EQUIPPED_RUNE_SETTLEMENT_OK'), @('realtime_inventory_contract_test', 'REALTIME_INVENTORY_OK'))) {
    $contractOutput = & $godotExecutable --headless --path $repositoryRoot --script "res://game/tests/$($contractCase[0]).gd" 2>&1
    $contractStatus = $LASTEXITCODE
    $contractOutput | Write-Output
    if ($contractStatus -ne 0 -or ($contractOutput -join "`n") -match 'SCRIPT ERROR:|ERROR:' -or ($contractOutput -join "`n") -notmatch $contractCase[1]) { throw "Contract failed: $($contractCase[0])" }
}
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
