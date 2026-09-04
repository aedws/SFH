#!/usr/bin/env python3
"""Build the read-only owner decision ontology used by the protected developer wiki."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "docs" / "assets" / "owner-decision-registry.json"
CODE_MAP = ROOT / "docs" / "assets" / "code-module-map.json"
KNOWLEDGE_MAP = ROOT / "docs" / "assets" / "knowledge-map.json"
OUTPUT = ROOT / "docs" / "assets" / "project-ontology.json"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def document_id(source: str) -> str:
    return "document:" + source.removesuffix(".md")


def collect_documents(node: object) -> list[dict]:
    result: list[dict] = []
    if isinstance(node, dict):
        documents = node.get("documents", [])
        if isinstance(documents, list):
            result.extend(item for item in documents if isinstance(item, dict))
        for key, value in node.items():
            if key != "documents":
                result.extend(collect_documents(value))
    elif isinstance(node, list):
        for value in node:
            result.extend(collect_documents(value))
    return result


def digest_sources(*paths: Path) -> str:
    digest = hashlib.sha256()
    for path in paths:
        digest.update(path.relative_to(ROOT).as_posix().encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
    return digest.hexdigest()


def generate() -> dict:
    registry = load_json(REGISTRY)
    code_map = load_json(CODE_MAP)
    knowledge_map = load_json(KNOWLEDGE_MAP)

    authority = dict(registry["authority"])
    contributors = [dict(item) for item in registry.get("contributors", [])]
    objects = [
        {
            **authority,
            "type": "authority",
            "status": "implemented",
            "certainty": "confirmed",
            "summary": authority["description"],
        }
    ]
    objects.extend({**item, "kind": "governance"} for item in registry.get("objects", []))

    documents = collect_documents(knowledge_map.get("root", {}))
    document_objects: list[dict] = []
    route_by_source: dict[str, str] = {}
    for item in documents:
        source = item.get("source", "")
        route = item.get("route", "")
        if not source:
            continue
        route_by_source[source.removesuffix(".md")] = route
        document_objects.append({
            "id": document_id(source),
            "type": "document",
            "label": item.get("label", source),
            "status": "reference",
            "certainty": "derived",
            "summary": item.get("summary", ""),
            "route": route,
            "source": "docs/" + source,
            "kind": "evidence",
        })

    module_objects: list[dict] = []
    derived_relations: list[dict] = []
    for module in code_map.get("modules", []):
        module_id = "module:" + module["id"]
        module_objects.append({
            "id": module_id,
            "type": "module",
            "label": module["label"],
            "status": "enabled" if module.get("enabled") is not False else "disabled",
            "certainty": "derived",
            "summary": f"{module['domain_label']} · {module['layer']} · 파일 {module['file_count']}개",
            "route": f"architecture/code-module-map/?module={module['id']}",
            "documentation_route": module["wiki_route"],
            "source": module["path"],
            "kind": "implementation",
            "metrics": {
                "files": module["file_count"],
                "classes": module["class_count"],
                "incoming": module["incoming_count"],
                "outgoing": module["outgoing_count"],
            },
        })
        route_key = module["wiki_route"].rstrip("/")
        for source_key, route in route_by_source.items():
            if route.rstrip("/") == route_key:
                derived_relations.append({
                    "from": module_id,
                    "to": "document:" + source_key,
                    "type": "documented_by",
                    "origin": "generated",
                })
                break

    all_objects = objects + module_objects + document_objects
    object_ids = {item["id"] for item in all_objects}
    if len(object_ids) != len(all_objects):
        raise ValueError("Project ontology object IDs must be unique")

    statuses = {item["id"] for item in registry.get("statuses", [])}
    governed_types = {"principle", "decision", "risk", "work_item"}
    explicit_relations: list[dict] = []
    for item in registry.get("objects", []):
        if item.get("type") in governed_types:
            if item.get("decision_owner") != authority["id"]:
                raise ValueError(f"Missing project-owner authority: {item.get('id')}")
            if item.get("status") not in statuses:
                raise ValueError(f"Unknown status for {item.get('id')}: {item.get('status')}")
            explicit_relations.append({
                "from": authority["id"],
                "to": item["id"],
                "type": "decides",
                "origin": "registry",
            })
        for relation in item.get("relations", []):
            explicit_relations.append({
                "from": item["id"],
                "to": relation["to"],
                "type": relation["type"],
                "origin": "registry",
            })

    relations = explicit_relations + derived_relations
    for relation in relations:
        if relation["from"] not in object_ids or relation["to"] not in object_ids:
            raise ValueError(
                f"Broken ontology relation: {relation['from']} -> {relation['to']}"
            )

    for item in document_objects:
        source_path = ROOT / item["source"]
        if not source_path.exists():
            raise ValueError(f"Missing ontology document source: {item['source']}")

    tracked = [item for item in objects if item["type"] != "authority"]
    status_counts = {
        status["id"]: sum(1 for item in tracked if item.get("status") == status["id"])
        for status in registry.get("statuses", [])
    }
    return {
        "schema_version": 1,
        "updated": registry["updated"],
        "source_sha256": digest_sources(REGISTRY, CODE_MAP, KNOWLEDGE_MAP),
        "authority": authority,
        "contributors": contributors,
        "statuses": registry.get("statuses", []),
        "views": [
            {
                "id": "owner-decision",
                "label": "오너 판단",
                "audience": "developer",
                "object_types": ["decision", "risk", "work_item", "principle"],
                "read_only": True,
            }
        ],
        "summary": {
            "tracked": len(tracked),
            "owner_decisions": status_counts.get("needs_decision", 0),
            "blocked": status_counts.get("blocked", 0),
            "ready": status_counts.get("ready", 0),
            "implemented": status_counts.get("implemented", 0),
            "modules": len(module_objects),
            "documents": len(document_objects),
            "relations": len(relations),
        },
        "objects": all_objects,
        "relations": relations,
    }


def serialized(data: dict) -> str:
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    expected = serialized(generate())
    if args.check:
        actual = OUTPUT.read_text(encoding="utf-8-sig") if OUTPUT.exists() else ""
        if actual != expected:
            print("PROJECT_ONTOLOGY_STALE run: python scripts/generate_project_ontology.py")
            return 1
        data = json.loads(actual)
        print(
            "PROJECT_ONTOLOGY_OK"
            f" tracked={data['summary']['tracked']}"
            f" objects={len(data['objects'])}"
            f" relations={data['summary']['relations']}"
        )
        return 0
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(expected, encoding="utf-8")
    print(f"WROTE {OUTPUT.relative_to(ROOT).as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
