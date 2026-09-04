"""Public SFH Notion page metadata -> reviewable, deterministic wiki snapshot."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import pathlib
import sys
import urllib.request

PAGE_ID = "3ce5b728-0040-81bf-a94f-e42e4ed48767"
PAGE_URL = "https://wobbly-pawpaw-1ff.notion.site/Master-GDD-2026-09-02-04-14-00-3ce5b728004081bfa94fe42e4ed48767"
ENDPOINT = "https://www.notion.so/api/v3/loadCachedPageChunk"


def _record_value(record: object) -> dict:
    value = record if isinstance(record, dict) else {}
    while isinstance(value.get("value"), dict):
        value = value["value"]
    return value


def _plain_title(properties: object) -> str:
    title = (properties if isinstance(properties, dict) else {}).get("title", [])
    output: list[str] = []
    if isinstance(title, list):
        for run in title:
            if isinstance(run, list) and run and isinstance(run[0], str):
                output.append(run[0])
    return "".join(output).strip()


def _checked(properties: object) -> bool | None:
    """Decode Notion rich-text checkbox values, never Python string truthiness.

    Missing means unknown/not applicable, not confirmed. Unknown encodings fail
    the snapshot refresh so upstream format drift cannot silently report done.
    """
    if not isinstance(properties, dict) or "checked" not in properties:
        return None
    value = properties["checked"]
    if isinstance(value, list) and len(value) == 1 and isinstance(value[0], list) and value[0]:
        value = value[0][0]
    if isinstance(value, bool):
        return value
    if isinstance(value, str) and value in ("Yes", "No"):
        return value == "Yes"
    raise ValueError(f"unknown Notion checkbox encoding: {value!r}")


def fetch_snapshot() -> dict:
    body = json.dumps({
        "pageId": PAGE_ID, "limit": 100, "cursor": {"stack": []},
        "chunkNumber": 0, "verticalColumns": False,
    }).encode("utf-8")
    request = urllib.request.Request(
        ENDPOINT, data=body, headers={"Content-Type": "application/json"}, method="POST"
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = json.load(response)
    raw_blocks = payload.get("recordMap", {}).get("block", {})
    blocks: list[dict] = []
    for block_id, record in raw_blocks.items():
        value = _record_value(record)
        if not value:
            continue
        properties = value.get("properties", {})
        blocks.append({
            "id": block_id,
            "type": value.get("type", "unknown"),
            "version": int(value.get("version", 0) or 0),
            "title": _plain_title(properties),
            "checked": _checked(properties),
            "last_edited_time": int(value.get("last_edited_time", 0) or 0),
        })
    blocks.sort(key=lambda item: item["id"])
    root = next((block for block in blocks if block["id"] == PAGE_ID), None)
    canonical = json.dumps(blocks, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return {
        "schema_version": 1,
        "source_url": PAGE_URL,
        "page_id": PAGE_ID,
        "root_version": int((root or {}).get("version", 0)),
        "root_last_edited_time": int((root or {}).get("last_edited_time", 0)),
        "block_count": len(blocks),
        "content_sha256": hashlib.sha256(canonical.encode("utf-8")).hexdigest(),
        "blocks": blocks,
    }


def validate(snapshot: dict) -> None:
    required = {"source_url", "page_id", "root_version", "root_last_edited_time", "block_count", "content_sha256", "blocks"}
    missing = sorted(required - snapshot.keys())
    if missing:
        raise ValueError("missing fields: " + ", ".join(missing))
    blocks = snapshot["blocks"]
    if snapshot["source_url"] != PAGE_URL:
        raise ValueError("source URL mismatch")
    if snapshot["page_id"] != PAGE_ID or not isinstance(blocks, list) or len(blocks) != snapshot["block_count"]:
        raise ValueError("page or block count mismatch")
    canonical = json.dumps(blocks, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    expected = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    if snapshot["content_sha256"] != expected:
        raise ValueError("content hash mismatch")
    if not any(block.get("id") == PAGE_ID for block in blocks):
        raise ValueError("root block missing")
    if any(block.get("checked") is not None and not isinstance(block["checked"], bool) for block in blocks):
        raise ValueError("checkbox must be boolean or null")


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    output = root / "docs/assets/notion-source-snapshot.json"
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=pathlib.Path, default=output)
    parser.add_argument("--update", action="store_true")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--live", action="store_true")
    args = parser.parse_args()
    try:
        if args.update:
            snapshot = fetch_snapshot()
            snapshot["captured_at"] = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(snapshot, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        committed = json.loads(args.output.read_text(encoding="utf-8"))
        validate(committed)
        if args.live:
            current = fetch_snapshot()
            state = "current" if current["content_sha256"] == committed["content_sha256"] else "drift"
            print(f"NOTION_SOURCE_LIVE state={state} committed={committed['content_sha256'][:12]} live={current['content_sha256'][:12]}")
            return 2 if state == "drift" else 0
        print(f"NOTION_SOURCE_OK version={committed['root_version']} blocks={committed['block_count']} sha256={committed['content_sha256'][:12]}")
        return 0
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"NOTION_SOURCE_ERROR {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
