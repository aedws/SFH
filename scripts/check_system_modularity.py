from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
FEATURES = GAME / "features"
ERRORS: list[str] = []


def text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig")


feature_dirs = sorted(path for path in FEATURES.iterdir() if path.is_dir())
feature_ids = {path.name for path in feature_dirs}
class_owners: dict[str, list[str]] = defaultdict(list)
dependency_graph: dict[str, set[str]] = {feature_id: set() for feature_id in feature_ids}
dependency_pattern = re.compile(r"res://game/features/([^/]+)/")

for script in GAME.rglob("*.gd"):
    source = text(script)
    match = re.search(r"^class_name\s+(\w+)", source, re.MULTILINE)
    if match:
        class_owners[match.group(1)].append(script.relative_to(ROOT).as_posix())

for name, owners in class_owners.items():
    if len(owners) > 1:
        ERRORS.append(f"Duplicate class_name {name}: {owners}")

for feature_dir in feature_dirs:
    owned_files = [
        path for path in feature_dir.rglob("*")
        if path.suffix in {".gd", ".tscn", ".tres"}
    ]
    if not owned_files:
        ERRORS.append(f"Empty feature boundary: {feature_dir.name}")
        continue
    for path in owned_files:
        source = text(path)
        for target in dependency_pattern.findall(source):
            if target not in feature_ids:
                ERRORS.append(f"Unknown feature dependency {feature_dir.name} -> {target}: {path}")
            elif target != feature_dir.name:
                dependency_graph[feature_dir.name].add(target)


def find_cycle() -> list[str]:
    visiting: set[str] = set()
    visited: set[str] = set()
    stack: list[str] = []

    def visit(node: str) -> list[str]:
        if node in visiting:
            start = stack.index(node)
            return stack[start:] + [node]
        if node in visited:
            return []
        visiting.add(node)
        stack.append(node)
        for target in sorted(dependency_graph[node]):
            cycle = visit(target)
            if cycle:
                return cycle
        stack.pop()
        visiting.remove(node)
        visited.add(node)
        return []

    for feature_id in sorted(feature_ids):
        cycle = visit(feature_id)
        if cycle:
            return cycle
    return []


cycle = find_cycle()
if cycle:
    ERRORS.append(f"Feature dependency cycle: {' -> '.join(cycle)}")

for path in FEATURES.rglob("*.gd"):
    if path.name.endswith(("service.gd", "policy.gd", "provider.gd", "registry.gd")):
        source = text(path)
        for forbidden in ("get_tree().current_scene", "res://game/scenes/", "get_node("):
            if forbidden in source:
                ERRORS.append(f"Domain boundary reaches scene internals ({forbidden}): {path.relative_to(ROOT)}")

scene_references = []
for path in FEATURES.rglob("*.gd"):
    if "res://game/scenes/" in text(path):
        scene_references.append(path.relative_to(ROOT).as_posix())
allowed_scene_routers = {"game/features/mobile_controls/control_mode_entry.gd"}
unexpected_scene_references = sorted(set(scene_references) - allowed_scene_routers)
if unexpected_scene_references:
    ERRORS.append(f"Feature-to-scene references outside entry router: {unexpected_scene_references}")

manifest_path = GAME / "core" / "feature_manifest.gd"
manifest = text(manifest_path)
enabled_flags = re.findall(r"@export var (\w+_enabled): bool", manifest)
enabled_module_body = manifest.split("func enabled_module_ids()", 1)[1].split(
    "func validation_errors()", 1
)[0]
for flag in enabled_flags:
    if f"if {flag}" not in enabled_module_body:
        ERRORS.append(f"Feature flag missing from enabled_module_ids(): {flag}")

resource_paths = set(re.findall(r'"(res://game/features/[^"\n]+\.(?:tres|tscn|gd))"', manifest))
for resource_path in sorted(resource_paths):
    local_path = ROOT / resource_path.removeprefix("res://")
    if not local_path.is_file():
        ERRORS.append(f"Manifest resource does not exist: {resource_path}")

required_workshop_boundaries = {
    "blueprint_registry.gd",
    "workshop_recipe_provider.gd",
    "workshop_unlock_service.gd",
    "workshop_roll_policy.gd",
    "workshop_craft_transaction_service.gd",
}
workshop_root = FEATURES / "p5_hub_progression"
for filename in sorted(required_workshop_boundaries):
    if not (workshop_root / filename).is_file():
        ERRORS.append(f"Workshop boundary missing: {filename}")

required_training_boundaries = {
    "combat_telemetry_collector.gd",
    "training_scenario_definition.gd",
    "training_dummy_spawner.gd",
    "training_scenario_reset_service.gd",
    "training_ground_service.gd",
    "training_telemetry_service.gd",
    "training_telemetry_presenter.gd",
    "training_loadout_snapshot.gd",
    "training_loadout_service.gd",
    "training_loadout_presenter.gd",
}
training_root = FEATURES / "training_ground"
for filename in sorted(required_training_boundaries):
    if not (training_root / filename).is_file():
        ERRORS.append(f"Training ground boundary missing: {filename}")
training_source = "\n".join(
    text(path) for path in training_root.glob("*.gd") if path.is_file()
)
for forbidden in (
    "res://game/features/spawning/",
    "res://game/features/loot/",
    "res://game/features/room_encounters/",
):
    if forbidden in training_source:
        ERRORS.append(f"Training ground leaks into operation runtime: {forbidden}")

training_contract = ROOT / "game" / "tests" / "training_ground_scenario_contract_test.gd"
training_e2e = ROOT / "game" / "tests" / "training_ground_gameplay_e2e_test.gd"
if not training_contract.is_file() or "spawn_budget_isolated" not in text(training_contract):
    ERRORS.append("P8 training ground lacks scenario/reset/spawn-isolation coverage.")
if not training_e2e.is_file() or "single_attack_telemetry" not in text(training_e2e):
    ERRORS.append("P8 training ground lacks real hub attack telemetry E2E coverage.")
if "final_snapshot" not in text(training_contract):
    ERRORS.append("P8 telemetry lacks fixed-window final snapshot coverage.")
for marker in ("isolated_skill_runtime", "free_loadout_restore"):
    if marker not in text(training_e2e):
        ERRORS.append(f"P8 free-loadout E2E marker missing: {marker}")

workflow = text(ROOT / ".github" / "workflows" / "deploy-wiki.yml")
if "check_system_modularity.py" not in workflow:
    ERRORS.append("System modularity audit is not enforced by CI.")

if ERRORS:
    raise SystemExit("\n".join(ERRORS))

edge_count = sum(len(targets) for targets in dependency_graph.values())
print(
    "SYSTEM_MODULARITY_OK "
    f"features={len(feature_ids)} classes={len(class_owners)} dependencies={edge_count} "
    f"cycles=0 service_scene_reach=0 manifest_flags={len(enabled_flags)} "
    "workshop_boundaries=5 training_boundaries=10 ci_gate=1"
)
