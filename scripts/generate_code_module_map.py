#!/usr/bin/env python3
"""Generate the wiki's code/module graph directly from the Godot sources."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
OUTPUT = ROOT / "docs" / "assets" / "code-module-map.json"

CLASS_RE = re.compile(r"(?m)^class_name\s+([A-Za-z_][A-Za-z0-9_]*)\s*$")
EXTENDS_RE = re.compile(r'(?m)^extends\s+(?:"([^"]+)"|([A-Za-z_][A-Za-z0-9_]*))\s*$')
RESOURCE_RE = re.compile(r'["\'](res://game/[^"\']+)["\']')
TOGGLE_RE = re.compile(r"(?m)^@export var ([a-z0-9_]+)_enabled:\s*bool\s*=\s*(true|false)\s*$")
DEPENDENCY_LINE_RE = re.compile(r"^\s*if\s+([a-z0-9_]+)_enabled\b(?P<body>.*):\s*$")
NEGATED_TOGGLE_RE = re.compile(r"not\s+([a-z0-9_]+)_enabled")


MODULE_LABELS = {
    "scene_assembly": "게임 조립",
    "core": "공통 계약",
    "balance_data": "밸런스 데이터",
    "boss_warning": "보스 경고",
    "character_selection": "요원 선택",
    "combat_resources": "전투 자원",
    "combat_skills": "전투 스킬",
    "conditional_ranking": "조건부 랭킹",
    "crafting": "도면 제작",
    "credits": "크레딧",
    "elite_pursuit": "엘리트 추격",
    "enemies": "적 유닛",
    "equipment": "장비 규칙",
    "equipment_upgrade": "장비 강화",
    "experience": "경험치",
    "extraction": "탈출",
    "field_loot": "필드 전리품",
    "fog_of_war": "전장의 안개",
    "growth_balance": "성장 밸런스",
    "health_recovery": "체력 회복",
    "hit_feedback": "타격 피드백",
    "hub_economy": "거점 경제",
    "hub_preparation": "거점 준비",
    "inventory": "가방 인벤토리",
    "key_mapping": "키 설정",
    "loadout_investment": "투입 비용",
    "local_save": "로컬 저장",
    "loot": "전리품",
    "loot_lifecycle": "전리품 생명 주기",
    "loot_tables": "드랍 테이블",
    "map_generation": "맵 생성",
    "meta_progression": "외부 성장",
    "minimap": "미니맵",
    "mobile_controls": "모바일 조작",
    "movement_hud": "이동 HUD",
    "operation_contract": "작전 계약",
    "operation_launch": "작전 진입",
    "operation_results": "작전 결과",
    "operation_tutorial": "작전 튜토리얼",
    "p5_hub_progression": "거점 성장 루프",
    "penalty_modifiers": "페널티 변형",
    "persistent_profile": "영구 프로필",
    "player": "플레이어",
    "presentation_settings": "화면 설정",
    "presentation_theme": "화면 테마",
    "room_encounters": "방 전투",
    "room_navigation": "방 이동",
    "run_buffs": "내부 강화",
    "run_settlement": "런 정산",
    "run_setup": "런 설정",
    "session_sockets": "세션 소켓",
    "shop_browser": "상점",
    "skill_binding": "스킬 장착",
    "smart_targeting": "자동 타게팅",
    "spawning": "적 생성",
    "start_hub": "시작 거점",
    "training_ground": "훈련장",
    "weapon_balance": "무기 밸런스",
    "weapons": "무기",
    "verification": "자동 검증",
}

DOMAIN_LABELS = {
    "system": "기반·검증",
    "operation": "작전 흐름",
    "combat": "전투",
    "world": "월드·탐색",
    "equipment": "장비·세팅",
    "economy": "파밍·경제",
    "growth": "성장",
    "presentation": "UI·입력",
    "data": "데이터",
}

MODULE_DOMAINS = {
    "scene_assembly": "system", "core": "system", "verification": "system",
    "operation_contract": "operation", "operation_launch": "operation",
    "operation_results": "operation", "operation_tutorial": "operation",
    "run_setup": "operation", "run_settlement": "operation",
    "loadout_investment": "operation", "extraction": "operation",
    "conditional_ranking": "operation", "penalty_modifiers": "operation",
    "combat_resources": "combat", "combat_skills": "combat",
    "smart_targeting": "combat", "skill_binding": "combat",
    "hit_feedback": "combat", "player": "combat", "enemies": "combat",
    "spawning": "combat", "boss_warning": "combat", "elite_pursuit": "combat",
    "room_encounters": "combat",
    "map_generation": "world", "fog_of_war": "world", "minimap": "world",
    "room_navigation": "world", "start_hub": "world", "training_ground": "world",
    "weapons": "equipment", "weapon_balance": "equipment", "equipment": "equipment",
    "inventory": "equipment", "session_sockets": "equipment",
    "equipment_upgrade": "equipment", "character_selection": "equipment",
    "loot": "economy", "loot_lifecycle": "economy", "loot_tables": "economy",
    "field_loot": "economy", "credits": "economy", "hub_economy": "economy",
    "shop_browser": "economy", "crafting": "economy", "local_save": "economy",
    "persistent_profile": "economy", "hub_preparation": "economy",
    "experience": "growth", "growth_balance": "growth", "health_recovery": "growth",
    "run_buffs": "growth", "meta_progression": "growth", "p5_hub_progression": "growth",
    "key_mapping": "presentation", "mobile_controls": "presentation",
    "movement_hud": "presentation", "presentation_settings": "presentation",
    "presentation_theme": "presentation",
    "balance_data": "data",
}


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def module_for(path: Path) -> str:
    parts = path.relative_to(GAME).parts
    if parts[0] == "features" and len(parts) > 1:
        return parts[1]
    if parts[0] == "core":
        return "core"
    if parts[0] == "scenes":
        return "scene_assembly"
    if parts[0] == "tests":
        return "verification"
    return parts[0]


def module_path(module_id: str) -> str:
    if module_id == "core":
        return "game/core"
    if module_id == "scene_assembly":
        return "game/scenes"
    if module_id == "verification":
        return "game/tests"
    return f"game/features/{module_id}"


def module_layer(module_id: str) -> str:
    if module_id == "core":
        return "contract"
    if module_id == "scene_assembly":
        return "assembly"
    if module_id == "verification":
        return "verification"
    return "feature"


def wiki_route(module_id: str) -> str:
    if module_id == "hub_preparation":
        return "features/start-hub/"
    if module_id == "shop_browser":
        return "features/hub-economy/"
    if module_id == "local_save":
        return "getting-started/run-project/"
    if module_id == "boss_warning":
        return "features/elite-pursuit/"
    candidates = [
        ROOT / "docs" / "features" / f"{module_id}.md",
        ROOT / "docs" / "architecture" / f"{module_id}.md",
    ]
    for candidate in candidates:
        if candidate.exists():
            return relative(candidate).removeprefix("docs/").removesuffix(".md") + "/"
    if module_id == "verification":
        return "quality/e2e-play-session/"
    return "architecture/module-rules/"


def generate() -> dict:
    scripts = sorted(GAME.rglob("*.gd"))
    text_by_path = {path: path.read_text(encoding="utf-8-sig") for path in scripts}
    class_by_path: dict[str, str] = {}
    source_hash = hashlib.sha256()
    for path in scripts:
        rel = relative(path)
        source_hash.update(rel.encode("utf-8"))
        source_hash.update(b"\0")
        source_hash.update(text_by_path[path].encode("utf-8"))
        match = CLASS_RE.search(text_by_path[path])
        if match:
            class_by_path["res://" + rel] = match.group(1)

    classes = []
    module_files: dict[str, list[str]] = defaultdict(list)
    module_classes: dict[str, list[str]] = defaultdict(list)
    raw_edges: dict[tuple[str, str, str], set[str]] = defaultdict(set)

    for path in scripts:
        rel = relative(path)
        text = text_by_path[path]
        module_id = module_for(path)
        module_files[module_id].append(rel)
        class_match = CLASS_RE.search(text)
        extends_match = EXTENDS_RE.search(text)
        class_name = class_match.group(1) if class_match else path.stem
        parent_path = extends_match.group(1) if extends_match else ""
        parent_name = extends_match.group(2) if extends_match else ""
        base_id = ""
        if parent_path:
            parent_name = class_by_path.get(parent_path, Path(parent_path).stem)
            base_id = "class:" + parent_name if parent_path in class_by_path else ""
        if class_match:
            module_classes[module_id].append(class_name)
            classes.append({
                "id": "class:" + class_name,
                "name": class_name,
                "module": module_id,
                "path": rel,
                "extends": parent_name or "(none)",
                "base_id": base_id,
                "inheritance": "project" if base_id else "engine",
            })
            if base_id:
                raw_edges[(module_id, module_for(ROOT / parent_path.removeprefix("res://")), "inherits")].add(rel)

        for resource_path in RESOURCE_RE.findall(text):
            target = ROOT / resource_path.removeprefix("res://")
            if not target.exists() or not str(target).lower().endswith((".gd", ".tscn", ".tres")):
                continue
            target_module = module_for(target)
            if target_module == module_id:
                continue
            edge_type = "verifies" if module_id == "verification" else "references"
            raw_edges[(module_id, target_module, edge_type)].add(rel)

    manifest_text = (GAME / "core" / "feature_manifest.gd").read_text(encoding="utf-8-sig")
    toggles = {match.group(1): match.group(2) == "true" for match in TOGGLE_RE.finditer(manifest_text)}
    for line in manifest_text.splitlines():
        match = DEPENDENCY_LINE_RE.match(line)
        if not match:
            continue
        source = match.group(1)
        for target in NEGATED_TOGGLE_RE.findall(match.group("body")):
            if source != target:
                raw_edges[(source, target, "requires")].add("game/core/feature_manifest.gd")

    module_ids = sorted(module_files, key=lambda value: (module_layer(value), value))
    incoming: dict[str, set[str]] = defaultdict(set)
    outgoing: dict[str, set[str]] = defaultdict(set)
    edges = []
    for (source, target, edge_type), evidence in sorted(raw_edges.items()):
        if source not in module_files or target not in module_files or source == target:
            continue
        incoming[target].add(source)
        outgoing[source].add(target)
        edges.append({
            "from": source,
            "to": target,
            "type": edge_type,
            "evidence_count": len(evidence),
        })

    modules = []
    for module_id in module_ids:
        domain = MODULE_DOMAINS.get(module_id, "system")
        modules.append({
            "id": module_id,
            "label": MODULE_LABELS.get(module_id, module_id.replace("_", " ")),
            "domain": domain,
            "domain_label": DOMAIN_LABELS[domain],
            "layer": module_layer(module_id),
            "path": module_path(module_id),
            "wiki_route": wiki_route(module_id),
            "enabled": toggles.get(module_id),
            "file_count": len(module_files[module_id]),
            "class_count": len(module_classes[module_id]),
            "classes": sorted(module_classes[module_id]),
            "incoming_count": len(incoming[module_id]),
            "outgoing_count": len(outgoing[module_id]),
        })

    inheritance_count = sum(1 for item in classes if item["base_id"])
    return {
        "schema_version": 2,
        "source_sha256": source_hash.hexdigest(),
        "domains": [
            {"id": domain_id, "label": label}
            for domain_id, label in DOMAIN_LABELS.items()
        ],
        "layers": [
            {"id": "contract", "label": "계약", "description": "FeatureManifest와 공통 공개 규칙"},
            {"id": "assembly", "label": "조립", "description": "Game·Hub가 활성 모듈을 연결"},
            {"id": "feature", "label": "기능", "description": "폴더 단위로 교체 가능한 플레이 기능"},
            {"id": "verification", "label": "검증", "description": "계약과 플레이 흐름을 실행 검사"},
        ],
        "summary": {
            "modules": len(modules),
            "scripts": len(scripts),
            "named_classes": len(classes),
            "relationships": len(edges),
            "project_inheritance": inheritance_count,
            "enabled_toggles": sum(1 for enabled in toggles.values() if enabled),
        },
        "modules": modules,
        "classes": sorted(classes, key=lambda item: (item["module"], item["name"])),
        "edges": edges,
    }


def serialized(data: dict) -> str:
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail if the committed graph is stale")
    args = parser.parse_args()
    expected = serialized(generate())
    if args.check:
        actual = OUTPUT.read_text(encoding="utf-8-sig") if OUTPUT.exists() else ""
        if actual != expected:
            print("CODE_MODULE_MAP_STALE run: python scripts/generate_code_module_map.py")
            return 1
        data = json.loads(actual)
        print(
            "CODE_MODULE_MAP_OK"
            f" modules={data['summary']['modules']}"
            f" classes={data['summary']['named_classes']}"
            f" edges={data['summary']['relationships']}"
        )
        return 0
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(expected, encoding="utf-8")
    print(f"WROTE {relative(OUTPUT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
