#!/usr/bin/env python3
"""Build the read-only owner decision ontology used by the protected developer wiki."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "docs" / "assets" / "owner-decision-registry.json"
CODE_MAP = ROOT / "docs" / "assets" / "code-module-map.json"
KNOWLEDGE_MAP = ROOT / "docs" / "assets" / "knowledge-map.json"
MILESTONE_WORKLINE = ROOT / "docs" / "design" / "current-milestone-workline.md"
NOTION_SNAPSHOT = ROOT / "docs" / "assets" / "notion-source-snapshot.json"
OUTPUT = ROOT / "docs" / "assets" / "project-ontology.json"
MILESTONE_ID_PATTERN = re.compile(r"^((?:BASE|P\d+)-\d+[A-Z]?)(?:\s*·\s*(.+))?$")


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


def clean_markdown_cell(value: str) -> str:
    value = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", value)
    value = value.replace("`", "").replace("**", "")
    return re.sub(r"\s+", " ", value).strip()


def milestone_work_items(path: Path) -> list[dict]:
    result: list[dict] = []
    seen: set[str] = set()
    for raw_line in path.read_text(encoding="utf-8-sig").splitlines():
        if not raw_line.lstrip().startswith("|"):
            continue
        cells = [clean_markdown_cell(cell) for cell in raw_line.strip().strip("|").split("|")]
        if len(cells) < 4:
            continue
        match = MILESTONE_ID_PATTERN.fullmatch(cells[0])
        if not match:
            continue
        milestone_id = match.group(1)
        if milestone_id in seen:
            raise ValueError(f"Duplicate milestone work item: {milestone_id}")
        seen.add(milestone_id)
        status_label = (match.group(2) or "").strip()
        if "완료" in status_label or status_label == "현행화":
            status = "implemented"
            certainty = "confirmed"
            next_action = "후속 변경에서 수락 조건과 E2E 회귀를 유지합니다."
        elif "보류" in status_label:
            status = "deferred"
            certainty = "confirmed"
            next_action = "프로젝트 오너가 재개 조건을 승인할 때까지 구현하지 않습니다."
        elif "차단" in status_label:
            status = "blocked"
            certainty = "confirmed"
            next_action = "표에 기록된 선행 조건을 해결하고 프로젝트 오너가 재개를 판단합니다."
        else:
            status = "ready"
            certainty = "provisional"
            next_action = "프로젝트 오너가 범위와 수락 조건을 확인한 뒤 착수합니다."
        work = cells[1]
        boundary = cells[2]
        player_acceptance = cells[3]
        e2e_gate = cells[4] if len(cells) >= 5 else cells[3]
        relations = [
            {"to": "document:design/current-milestone-workline", "type": "documented_by"},
            {"to": "source:git", "type": "implemented_by"},
            {"to": "source:e2e", "type": "verified_by"},
        ]
        if milestone_id.startswith("P"):
            relations.append({"to": "source:notion", "type": "informed_by"})
        result.append({
            "id": "work:milestone:" + milestone_id.lower(),
            "type": "work_item",
            "label": f"{milestone_id} · {work}",
            "milestone_id": milestone_id,
            "milestone_status": status_label or "계속 적용",
            "status": status,
            "certainty": certainty,
            "decision_owner": "authority:project-owner",
            "summary": boundary,
            "acceptance": f"{player_acceptance} · E2E: {e2e_gate}",
            "next_action": next_action,
            "route": "design/current-milestone-workline/",
            "source": "docs/design/current-milestone-workline.md",
            "kind": "milestone",
            "origin": "generated_milestone_table",
            "relations": relations,
        })
    return result


def knowledge_collections(root: dict) -> tuple[list[dict], list[dict]]:
    objects: list[dict] = []
    relations: list[dict] = []
    root_id = "collection:root:" + root["id"]
    objects.append({
        "id": root_id,
        "type": "collection",
        "label": root["label"],
        "status": "reference",
        "certainty": "derived",
        "summary": root.get("description", ""),
        "kind": "navigation",
        "origin": "knowledge_map",
    })
    for category in root.get("categories", []):
        category_id = "collection:category:" + category["id"]
        objects.append({
            "id": category_id,
            "type": "collection",
            "label": category["label"],
            "status": "reference",
            "certainty": "derived",
            "summary": category.get("description", ""),
            "kind": "navigation",
            "origin": "knowledge_map",
        })
        relations.append({"from": category_id, "to": root_id, "type": "part_of", "origin": "knowledge_map"})
        for group in category.get("groups", []):
            group_id = f"collection:group:{category['id']}/{group['id']}"
            objects.append({
                "id": group_id,
                "type": "collection",
                "label": group["label"],
                "status": "reference",
                "certainty": "derived",
                "summary": group.get("description", ""),
                "kind": "navigation",
                "origin": "knowledge_map",
            })
            relations.append({"from": group_id, "to": category_id, "type": "part_of", "origin": "knowledge_map"})
            for document in group.get("documents", []):
                source = document.get("source", "")
                if source:
                    relations.append({
                        "from": document_id(source),
                        "to": group_id,
                        "type": "part_of",
                        "origin": "knowledge_map",
                    })
    return objects, relations


def enrich_source_systems(source_systems: list[dict], notion_snapshot: dict) -> list[dict]:
    enriched: list[dict] = []
    edited_ms = int(notion_snapshot["root_last_edited_time"])
    notion_observed_at = datetime.fromtimestamp(edited_ms / 1000, timezone.utc).isoformat().replace("+00:00", "Z")
    for source in source_systems:
        item = dict(source)
        if item["id"] == "source:notion":
            item["freshness"] = {
                "state": "snapshot",
                "observed_at": notion_observed_at,
                "revision": str(notion_snapshot["root_version"]),
                "content_sha256": notion_snapshot["content_sha256"],
                "max_age_days": 7,
                "check": "작업 시작 전 공개 Master GDD를 다시 읽고 스냅샷을 검증합니다.",
            }
        elif item["id"] == "source:google-sheet":
            item["freshness"] = {
                "state": "unverified",
                "observed_at": None,
                "revision": None,
                "max_age_days": 1,
                "check": "목록·밸런스 작업 전 대상 탭을 실시간 검증하고 확정 CSV 해시와 함께 기록합니다.",
            }
        enriched.append(item)
    return enriched


def unique_relations(relations: list[dict]) -> list[dict]:
    result: list[dict] = []
    seen: set[tuple[str, str, str]] = set()
    for relation in relations:
        key = (relation["from"], relation["type"], relation["to"])
        if key in seen:
            continue
        seen.add(key)
        result.append(relation)
    return result


def digest_sources(*paths: Path) -> str:
    digest = hashlib.sha256()
    for path in paths:
        digest.update(path.relative_to(ROOT).as_posix().encode("utf-8"))
        digest.update(b"\0")
        # Git checks out text with platform-specific line endings. Hash the
        # logical UTF-8 content so Windows and Linux produce the same result.
        content = path.read_text(encoding="utf-8-sig")
        normalized = content.replace("\r\n", "\n").replace("\r", "\n")
        digest.update(normalized.encode("utf-8"))
    return digest.hexdigest()


def generate() -> dict:
    registry = load_json(REGISTRY)
    code_map = load_json(CODE_MAP)
    knowledge_map = load_json(KNOWLEDGE_MAP)
    notion_snapshot = load_json(NOTION_SNAPSHOT)

    authority = dict(registry["authority"])
    contributors = [dict(item) for item in registry.get("contributors", [])]
    object_types = [dict(item) for item in registry.get("object_types", [])]
    interfaces = [dict(item) for item in registry.get("interfaces", [])]
    source_systems = enrich_source_systems(
        [dict(item) for item in registry.get("source_systems", [])],
        notion_snapshot,
    )
    action_types = [dict(item) for item in registry.get("action_types", [])]
    lifecycle = [dict(item) for item in registry.get("lifecycle", [])]
    objects = [
        {
            **authority,
            "type": "authority",
            "status": "implemented",
            "certainty": "confirmed",
            "summary": authority["description"],
        }
    ]
    objects.extend({
        **item,
        "type": "contributor",
        "status": "active",
        "certainty": "confirmed",
        "summary": item["responsibility"],
        "kind": "governance",
    } for item in contributors)
    objects.extend({
        **item,
        "type": "source",
        "certainty": "confirmed",
        "kind": "evidence",
    } for item in source_systems)
    objects.extend({**item, "kind": "governance"} for item in registry.get("objects", []))
    generated_milestones = milestone_work_items(MILESTONE_WORKLINE)
    objects.extend(generated_milestones)

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

    collection_objects, knowledge_relations = knowledge_collections(knowledge_map["root"])
    module_objects: list[dict] = []
    derived_relations: list[dict] = list(knowledge_relations)
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

    all_objects = objects + collection_objects + module_objects + document_objects
    object_ids = {item["id"] for item in all_objects}
    if len(object_ids) != len(all_objects):
        raise ValueError("Project ontology object IDs must be unique")

    statuses = {item["id"] for item in registry.get("statuses", [])}
    governed_types = {"principle", "decision", "risk", "work_item"}
    object_type_ids = {item["id"] for item in object_types}
    unknown_object_types = sorted({item.get("type") for item in all_objects} - object_type_ids)
    if unknown_object_types:
        raise ValueError(f"Unknown ontology object types: {', '.join(unknown_object_types)}")
    interface_by_id = {item["id"]: item for item in interfaces}
    required_interfaces = {"owner_decidable", "traceable", "verifiable"}
    missing_interfaces = sorted(required_interfaces - set(interface_by_id))
    if missing_interfaces:
        raise ValueError(
            f"Project ontology is missing interfaces: {', '.join(missing_interfaces)}"
        )
    explicit_relations: list[dict] = []
    governed_records = [dict(item) for item in registry.get("objects", [])] + generated_milestones
    for item in governed_records:
        if item.get("type") in governed_types:
            if item.get("decision_owner") != authority["id"]:
                raise ValueError(f"Missing project-owner authority: {item.get('id')}")
            if item.get("status") not in statuses:
                raise ValueError(f"Unknown status for {item.get('id')}: {item.get('status')}")
            for field in interface_by_id["owner_decidable"]["required"]:
                if field not in item:
                    raise ValueError(f"Missing owner_decidable field for {item.get('id')}: {field}")
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
        if item.get("type") == "work_item":
            if not item.get("acceptance"):
                raise ValueError(f"Missing verifiable acceptance for {item.get('id')}")
            if not any(
                relation.get("type") == "verified_by"
                for relation in item.get("relations", [])
            ):
                raise ValueError(f"Missing verifiable evidence for {item.get('id')}")

    relations = unique_relations(explicit_relations + derived_relations)
    for relation in relations:
        if relation["from"] not in object_ids or relation["to"] not in object_ids:
            raise ValueError(
                f"Broken ontology relation: {relation['from']} -> {relation['to']}"
            )

    action_ids = {item["id"] for item in action_types}
    source_ids = {item["id"] for item in source_systems}
    for stage in lifecycle:
        if stage.get("action") not in action_ids:
            raise ValueError(f"Unknown lifecycle action: {stage.get('action')}")
        for evidence in stage.get("evidence", []):
            if evidence not in source_ids:
                raise ValueError(f"Unknown lifecycle evidence: {evidence}")
    for action in action_types:
        if action.get("actor") not in object_ids:
            raise ValueError(f"Unknown action actor: {action.get('actor')}")

    for item in document_objects:
        source_path = ROOT / item["source"]
        if not source_path.exists():
            raise ValueError(f"Missing ontology document source: {item['source']}")

    related_ids = {
        endpoint
        for relation in relations
        for endpoint in (relation["from"], relation["to"])
    }
    isolated_documents = sorted(
        item["id"] for item in document_objects if item["id"] not in related_ids
    )
    if isolated_documents:
        raise ValueError(
            "Knowledge-map documents are isolated from the ontology: "
            + ", ".join(isolated_documents)
        )

    freshness_by_source = {
        item["id"]: item.get("freshness", {}) for item in source_systems
    }
    if not freshness_by_source.get("source:notion", {}).get("observed_at"):
        raise ValueError("Notion source freshness snapshot is missing")
    if freshness_by_source.get("source:google-sheet", {}).get("state") != "unverified":
        raise ValueError("Google Sheet must remain visibly unverified until a live check")

    tracked = [item for item in all_objects if item["type"] in governed_types]
    status_counts = {
        status["id"]: sum(1 for item in tracked if item.get("status") == status["id"])
        for status in registry.get("statuses", [])
    }
    return {
        "schema_version": registry["schema_version"],
        "updated": registry["updated"],
        "source_sha256": digest_sources(REGISTRY, CODE_MAP, KNOWLEDGE_MAP, MILESTONE_WORKLINE, NOTION_SNAPSHOT),
        "authority": authority,
        "contributors": contributors,
        "object_types": object_types,
        "interfaces": interfaces,
        "source_systems": source_systems,
        "action_types": action_types,
        "lifecycle": lifecycle,
        "statuses": registry.get("statuses", []),
        "views": [
            {
                "id": "owner-decision",
                "label": "오너 판단",
                "audience": "developer",
                "object_types": ["decision", "risk", "work_item", "principle"],
                "read_only": True,
            },
            {
                "id": "object-explorer",
                "label": "객체 탐색",
                "audience": "developer",
                "object_types": [item["id"] for item in object_types],
                "read_only": True,
            },
            {
                "id": "lineage",
                "label": "관계·계보",
                "audience": "developer",
                "object_types": ["decision", "risk", "work_item", "module", "document", "collection", "source"],
                "read_only": True,
            },
            {
                "id": "operations",
                "label": "행동·관측",
                "audience": "developer",
                "object_types": ["source"],
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
            "collections": len(collection_objects),
            "generated_milestones": len(generated_milestones),
            "sources": len(source_systems),
            "actions": len(action_types),
            "relations": len(relations),
            "broken_relations": 0,
            "ownerless_governed_objects": 0,
            "isolated_documents": len(isolated_documents),
            "source_warnings": sum(
                1
                for item in source_systems
                if item.get("freshness", {}).get("state") == "unverified"
            ),
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
