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
        modules.append({
            "id": module_id,
            "label": module_id.replace("_", " "),
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
        "schema_version": 1,
        "source_sha256": source_hash.hexdigest(),
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
