$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$featureRoot = Join-Path $repositoryRoot "game\features\p5_hub_progression"
$errors = [System.Collections.Generic.List[string]]::new()
$required = @(
    "utility_investment_service.gd",
    "operation_draft_service.gd",
    "bankruptcy_protection_policy.gd",
    "rotating_shop_service.gd",
    "workshop_service.gd",
    "training_service.gd",
    "codex_service.gd",
    "p5_hub_progression_service.gd",
    "p5_hub_progression_config.gd"
)
foreach ($name in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $featureRoot $name))) {
        $errors.Add("Missing P5 module boundary: $name")
    }
}
$config = Get-Content -LiteralPath (Join-Path $featureRoot "p5_hub_progression_config.gd") -Raw -Encoding UTF8
foreach ($flag in @("utility_enabled", "operation_draft_enabled", "bankruptcy_preset_enabled", "rotating_shop_enabled", "workshop_enabled", "training_enabled", "codex_enabled")) {
    if ($config -notmatch [regex]::Escape($flag)) {
        $errors.Add("Missing removable submodule flag: $flag")
    }
}
Get-ChildItem -LiteralPath $featureRoot -Filter "*_service.gd" | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    if ($content -match 'get_node\(|get_tree\(\)\.current_scene|game/scenes/game\.gd') {
        $errors.Add("Module reaches into scene internals: $($_.Name)")
    }
}
$manifest = Get-Content -LiteralPath (Join-Path $repositoryRoot "game\core\feature_manifest.gd") -Raw -Encoding UTF8
if ($manifest -notmatch 'p5_hub_progression_enabled' -or $manifest -notmatch 'p5_hub_progression_config_path') {
    $errors.Add("FeatureManifest does not expose the P5 removal/configuration boundary.")
}
$smoke = Get-Content -LiteralPath (Join-Path $repositoryRoot "game\tests\basic_loop_smoke_test.gd") -Raw -Encoding UTF8
if ($smoke -notmatch 'p5_hub_progression_enabled' -or $smoke -notmatch 'p5_hub_progression_service') {
    $errors.Add("Core optional-module smoke does not remove P5 with its prerequisites.")
}
$contract = Get-Content -LiteralPath (Join-Path $repositoryRoot "game\tests\p5_hub_progression_contract_test.gd") -Raw -Encoding UTF8
if ($contract -notmatch 'optional_submodules' -or $contract -notmatch 'P5_HUB_PROGRESSION_OK') {
    $errors.Add("P5 contract test lacks the submodule removal gate.")
}
if ($errors.Count -gt 0) {
    throw ($errors -join [Environment]::NewLine)
}
Write-Output "P5_MODULARITY_OK services_7 aggregator_1 config_flags_7 no_scene_internal_access manifest_boundary optional_removal_test"
