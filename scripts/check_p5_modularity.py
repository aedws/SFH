from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FEATURE_ROOT = ROOT / "game" / "features" / "p5_hub_progression"
ERRORS: list[str] = []

required = (
    "utility_investment_service.gd",
    "operation_draft_service.gd",
    "bankruptcy_protection_policy.gd",
    "rotating_shop_service.gd",
    "workshop_service.gd",
    "training_service.gd",
    "codex_service.gd",
    "p5_hub_progression_service.gd",
    "p5_hub_progression_config.gd",
)
for name in required:
    if not (FEATURE_ROOT / name).is_file():
        ERRORS.append(f"Missing P5 module boundary: {name}")

config = (FEATURE_ROOT / "p5_hub_progression_config.gd").read_text(encoding="utf-8")
for flag in (
    "utility_enabled",
    "operation_draft_enabled",
    "bankruptcy_preset_enabled",
    "rotating_shop_enabled",
    "workshop_enabled",
    "training_enabled",
    "codex_enabled",
):
    if flag not in config:
        ERRORS.append(f"Missing removable submodule flag: {flag}")

for service_path in FEATURE_ROOT.glob("*_service.gd"):
    content = service_path.read_text(encoding="utf-8")
    if any(token in content for token in ("get_node(", "get_tree().current_scene", "game/scenes/game.gd")):
        ERRORS.append(f"Module reaches into scene internals: {service_path.name}")

manifest = (ROOT / "game" / "core" / "feature_manifest.gd").read_text(encoding="utf-8")
if "p5_hub_progression_enabled" not in manifest or "p5_hub_progression_config_path" not in manifest:
    ERRORS.append("FeatureManifest does not expose the P5 removal/configuration boundary.")

smoke = (ROOT / "game" / "tests" / "basic_loop_smoke_test.gd").read_text(encoding="utf-8")
if "p5_hub_progression_enabled" not in smoke or "p5_hub_progression_service" not in smoke:
    ERRORS.append("Core optional-module smoke does not remove P5 with its prerequisites.")

contract = (ROOT / "game" / "tests" / "p5_hub_progression_contract_test.gd").read_text(encoding="utf-8")
if "optional_submodules" not in contract or "P5_HUB_PROGRESSION_OK" not in contract:
    ERRORS.append("P5 contract test lacks the submodule removal gate.")

if ERRORS:
    raise SystemExit("\n".join(ERRORS))

print(
    "P5_MODULARITY_OK services_7 aggregator_1 config_flags_7 "
    "no_scene_internal_access manifest_boundary optional_removal_test"
)
