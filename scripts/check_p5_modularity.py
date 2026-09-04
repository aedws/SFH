from __future__ import annotations

import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FEATURE_ROOT = ROOT / "game" / "features" / "p5_hub_progression"
DATA_ROOT = FEATURE_ROOT / "data"
ERRORS: list[str] = []


def read_rows(path: Path, required: set[str], id_column: str, description_row: bool = True) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        headers = set(reader.fieldnames or [])
        missing = required - headers
        if missing:
            ERRORS.append(f"{path.name}: missing columns {sorted(missing)}")
        if description_row:
            next(reader, None)
        rows = [row for row in reader if row.get(id_column, "").strip()]
    identifiers = [row[id_column].strip() for row in rows]
    duplicates = sorted({value for value in identifiers if identifiers.count(value) > 1})
    if duplicates:
        ERRORS.append(f"{path.name}: duplicate {id_column} {duplicates}")
    return rows


required_files = (
    "utility_investment_service.gd", "operation_draft_service.gd",
    "bankruptcy_protection_policy.gd", "rotating_shop_service.gd",
    "workshop_service.gd", "training_service.gd", "codex_service.gd",
    "p5_hub_action_presenter.gd", "p5_hub_progression_service.gd",
    "p5_hub_progression_config.gd", "p5_catalog_table.gd",
    "item_quality_definition.gd", "item_quality_catalog.gd",
    "shop_item_quality_policy.gd", "shop_inventory_delivery_service.gd",
    "shop_rotation_policy.gd", "shop_rotation_state.gd",
    "shop_reroll_transaction_service.gd",
)
for name in required_files:
    if not (FEATURE_ROOT / name).is_file():
        ERRORS.append(f"Missing P5 module boundary: {name}")

config = (FEATURE_ROOT / "p5_hub_progression_config.gd").read_text(encoding="utf-8")
for flag in (
    "utility_enabled", "operation_draft_enabled", "bankruptcy_preset_enabled",
    "rotating_shop_enabled", "workshop_enabled", "training_enabled", "codex_enabled",
):
    if flag not in config:
        ERRORS.append(f"Missing removable submodule flag: {flag}")
if "if not bool(contract[0])" not in config or "continue" not in config:
    ERRORS.append("Disabled submodules do not conditionally skip missing CSV validation.")
for stem in ("utility", "operation_preset", "shop_offer", "recipe", "training_scenario", "codex"):
    if f"{stem}_csv_payload" not in config:
        ERRORS.append(f"Missing Web-safe P5 payload boundary: {stem}_csv_payload")
if "shop_quality_catalog" not in config:
    ERRORS.append("P5 config does not expose the replaceable item-quality catalogue.")
if "shop_rotation_policy" not in config:
    ERRORS.append("P5 config does not expose the replaceable shop-rotation policy.")
if not (FEATURE_ROOT / "configs" / "default_item_quality_catalog.tres").is_file():
    ERRORS.append("Missing default item-quality Resource catalogue.")
if not (FEATURE_ROOT / "configs" / "default_shop_rotation_policy.tres").is_file():
    ERRORS.append("Missing default shop-rotation Resource policy.")

sync_script = ROOT / "scripts" / "sync_p5_catalogs.py"
if not sync_script.is_file():
    ERRORS.append("Missing P5 CSV payload synchronization gate.")
for stem in ("utility", "operation_preset", "shop_offer", "recipe", "training_scenario", "codex"):
    if not (DATA_ROOT / f"{stem}_payload.tres").is_file():
        ERRORS.append(f"Missing Web-safe P5 payload resource: {stem}_payload.tres")

aggregator = (FEATURE_ROOT / "p5_hub_progression_service.gd").read_text(encoding="utf-8")
if "preload(" in aggregator:
    ERRORS.append("P5 aggregator statically preloads removable submodules.")
for public_method in ("set_utility_quantity", "use_utility", "record_training_hit", "get_codex_entry", "perform_hub_action"):
    if f"func {public_method}" not in aggregator:
        ERRORS.append(f"P5 facade missing public method: {public_method}")

for service_path in FEATURE_ROOT.glob("*_service.gd"):
    content = service_path.read_text(encoding="utf-8")
    if any(token in content for token in ("get_node(", "get_tree().current_scene", "game/scenes/game.gd")):
        ERRORS.append(f"Module reaches into scene internals: {service_path.name}")

manifest = (ROOT / "game" / "core" / "feature_manifest.gd").read_text(encoding="utf-8")
if "p5_hub_progression_enabled" not in manifest or "p5_hub_progression_config_path" not in manifest:
    ERRORS.append("FeatureManifest does not expose the P5 removal/configuration boundary.")

contract = (ROOT / "game" / "tests" / "p5_hub_progression_contract_test.gd").read_text(encoding="utf-8")
if "res://removed/" not in contract or "CSV 필수 열·중복 ID 차단" not in contract:
    ERRORS.append("P5 contract lacks missing-file and malformed-schema removal gates.")
if re.search(r'p5\.get\("(?:utility|shop|workshop|training|codex)', contract):
    ERRORS.append("P5 contract bypasses the public facade to access internals.")

game = (ROOT / "game" / "scenes" / "game.gd").read_text(encoding="utf-8")
for forbidden in ('&"assault_blueprint_recipe"', '&"single_target"', 'call(&"purchase_shop_offer"', 'call(&"craft_recipe"'):
    if forbidden in game:
        ERRORS.append(f"Game assembly owns a P5 domain decision: {forbidden}")
if 'enemy.has_signal(&"damaged")' not in game or "record_training_hit" not in game:
    ERRORS.append("Real enemy damage is not bridged to training telemetry.")

quality_policy = (FEATURE_ROOT / "shop_item_quality_policy.gd").read_text(encoding="utf-8")
for forbidden in ("QUALITY_LABELS", "QUALITY_OPTIONS", "QUALITY_SOCKETS"):
    if forbidden in quality_policy:
        ERRORS.append(f"Quality tuning remains hardcoded in policy: {forbidden}")
descriptor_path = ROOT / "game" / "core" / "item_quality_descriptor.gd"
if not descriptor_path.is_file():
    ERRORS.append("Missing canonical item-quality payload descriptor.")
for relative in (
    "game/features/equipment/equipment_item_state.gd",
    "game/features/equipment/equipment_module_instance.gd",
    "game/features/equipment/equipment_system.gd",
    "game/features/equipment/equipment_module_ui_presenter.gd",
):
    if "item_quality_descriptor.gd" not in (ROOT / relative).read_text(encoding="utf-8"):
        ERRORS.append(f"Equipment quality consumer bypasses canonical descriptor: {relative}")

quality_test = ROOT / "game" / "tests" / "shop_quality_inventory_contract_test.gd"
removal_test = ROOT / "game" / "tests" / "shop_delivery_modularity_contract_test.gd"
workflow = (ROOT / ".github" / "workflows" / "deploy-wiki.yml").read_text(encoding="utf-8")
if not quality_test.is_file() or "rollback_consistency" not in quality_test.read_text(encoding="utf-8"):
    ERRORS.append("Quality contract lacks rollback consistency coverage.")
if not removal_test.is_file() or "delivery_off" not in removal_test.read_text(encoding="utf-8"):
    ERRORS.append("Shop delivery lacks a standalone removal contract.")
for required_gate in (
    "shop_quality_inventory_contract_test.gd",
    "shop_delivery_modularity_contract_test.gd",
    "check-code-module-map.ps1",
):
    if required_gate not in workflow:
        ERRORS.append(f"Required quality/wiki CI gate missing: {required_gate}")

read_rows(DATA_ROOT / "utility.csv", {"utility_id", "display_name", "utility_type", "run_price", "runtime_enabled"}, "utility_id")
presets = read_rows(DATA_ROOT / "operation_preset.csv", {"preset_id", "character_id", "main_weapon_id", "secondary_weapon_id", "skill_ids", "tier_id", "region_id", "difficulty_id", "runtime_enabled"}, "preset_id")
read_rows(DATA_ROOT / "shop_offer.csv", {"offer_id", "quality", "target_id", "quantity", "price", "runtime_enabled"}, "offer_id")
recipes = read_rows(DATA_ROOT / "recipe.csv", {"recipe_id", "blueprint_id", "result_id", "materials", "runtime_enabled"}, "recipe_id")
read_rows(DATA_ROOT / "training_scenario.csv", {"scenario_id", "dummy_mode", "measurement_seconds", "runtime_enabled"}, "scenario_id")
codex = read_rows(DATA_ROOT / "codex.csv", {"entry_id", "source_id", "region_hint", "required_count", "runtime_enabled"}, "entry_id")

items = {row["item_id"] for row in read_rows(ROOT / "game/features/loot_lifecycle/data/item_lifecycle.csv", {"item_id"}, "item_id")}
weapons = {row["weapon_id"] for row in read_rows(ROOT / "game/features/weapon_balance/data/weapon_balance.csv", {"weapon_id"}, "weapon_id", False)}
skills = {row["skill_id"] for row in read_rows(ROOT / "game/features/combat_skills/data/skill_catalog.csv", {"skill_id"}, "skill_id", False)}
characters = {row["character_id"] for row in read_rows(ROOT / "game/features/character_selection/data/character_catalog.csv", {"character_id"}, "character_id", False)}
contract_text = (ROOT / "game/features/operation_contract/configs/default_operation_contracts.tres").read_text(encoding="utf-8")
regions = set(re.findall(r'"region_id": &"([^"]+)"', contract_text))

for recipe in recipes:
    if recipe["blueprint_id"] not in items:
        ERRORS.append(f"recipe unknown blueprint: {recipe['blueprint_id']}")
for entry in codex:
    if entry["source_id"] not in items:
        ERRORS.append(f"codex unknown source: {entry['source_id']}")
    if entry["region_hint"] not in regions:
        ERRORS.append(f"codex unknown region: {entry['region_hint']}")
for preset in presets:
    for weapon in (preset["main_weapon_id"], preset["secondary_weapon_id"]):
        if weapon not in weapons:
            ERRORS.append(f"preset unknown weapon: {weapon}")
    for skill in preset["skill_ids"].split("|"):
        if skill and skill not in skills:
            ERRORS.append(f"preset unknown skill: {skill}")
    if preset["character_id"] not in characters:
        ERRORS.append(f"preset unknown character: {preset['character_id']}")
    if preset["region_id"] not in regions:
        ERRORS.append(f"preset unknown region: {preset['region_id']}")

if ERRORS:
    raise SystemExit("\n".join(ERRORS))

print("P5_MODULARITY_OK lazy_submodules conditional_paths web_payloads facade_only schema_unique_fk canonical_ids presenter_boundary real_training_bridge transaction_guards item_quality_resource payload_descriptor rotation_policy_state_debit ci_quality_gate delivery_removal_gate rollback_compensation")
