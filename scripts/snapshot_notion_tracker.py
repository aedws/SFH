"""Read the public task tracker; never interpret planner status as code completion."""
import argparse
import collections
import datetime as dt
import hashlib
import json
from pathlib import Path

from snapshot_notion_source import request_json, _record_value

PAGE_ID = "3d35b728-0040-81d8-8798-e99d4a8f05c2"
PAGE_URL = "https://wobbly-pawpaw-1ff.notion.site/3d35b728004081d88798e99d4a8f05c2"
COLLECTION_ID = "3d35b728-0040-8116-92be-000bcf3f55dd"
VIEW_ID = "3d35b728-0040-81b2-a8df-000c7cf37314"
STATUSES = {"결정 (미구현)", "미정 (검토필요)", "진행중", "임시 시험값", "구현완료"}


def digest(rows):
    return hashlib.sha256(json.dumps(rows, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def plain(properties, key):
    return "".join(run[0] for run in properties.get(key, []) if isinstance(run, list) and run and isinstance(run[0], str)).strip()


def fetch_snapshot():
    # Raise the result limit until the API explicitly confirms a complete set.
    for limit in (100, 500, 2000):
        payload = request_json("https://www.notion.so/api/v3/queryCollection", {
            "collectionId": COLLECTION_ID, "collectionViewId": VIEW_ID,
            "loader": {"type": "reducer", "reducers": {"collection_group_results": {"type": "results", "limit": limit}}, "searchQuery": "", "userTimeZone": "Asia/Seoul"},
        })
        result = payload["result"]["reducerResults"]["collection_group_results"]
        if result.get("hasMore") is False:
            break
    else:
        raise ValueError("tracker incomplete: hasMore did not become false")
    ids = result["blockIds"]
    if not ids or len(set(ids)) != len(ids):
        raise ValueError("empty or duplicate tracker rows")
    rows = []
    for key in ids:
        value = _record_value(payload["recordMap"]["block"][key])
        props = value.get("properties", {})
        rows.append({"id": key, "title": plain(props, "title"), "request_id": plain(props, "TrYw"),
                     "planner_status": plain(props, "[eq>"), "category": plain(props, ";Od`"),
                     "acceptance": plain(props, "RV~f"), "version": value.get("version", 0),
                     "last_edited_time": value.get("last_edited_time", 0)})
    rows.sort(key=lambda row: row["id"])
    snapshot = {"schema_version": 1, "source_url": PAGE_URL, "page_id": PAGE_ID,
                "collection_id": COLLECTION_ID, "view_id": VIEW_ID, "complete": True,
                "row_count": len(rows), "content_sha256": digest(rows), "rows": rows}
    validate(snapshot)
    return snapshot


def validate(snapshot):
    rows = snapshot["rows"]
    if snapshot["source_url"] != PAGE_URL or snapshot["page_id"] != PAGE_ID or snapshot["collection_id"] != COLLECTION_ID or snapshot["view_id"] != VIEW_ID:
        raise ValueError("tracker source identity mismatch")
    if snapshot.get("complete") is not True or not rows or len(rows) != snapshot["row_count"] or len({r["id"] for r in rows}) != len(rows):
        raise ValueError("tracker rows incomplete or duplicated")
    if digest(rows) != snapshot["content_sha256"]:
        raise ValueError("tracker hash mismatch")
    for row in rows:
        if not all(row.get(k) for k in ("title", "request_id", "acceptance", "category")) or row.get("planner_status") not in STATUSES:
            raise ValueError(f"tracker schema/status drift: {row.get('id')}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--update", action="store_true")
    parser.add_argument("--live", action="store_true")
    args = parser.parse_args()
    path = Path(__file__).resolve().parents[1] / "docs/assets/notion-tracker-snapshot.json"
    if args.update:
        snapshot = fetch_snapshot()
        snapshot["captured_at"] = dt.datetime.now(dt.timezone.utc).isoformat()
        path.write_text(json.dumps(snapshot, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    snapshot = json.loads(path.read_text(encoding="utf-8"))
    validate(snapshot)
    if args.live and fetch_snapshot()["content_sha256"] != snapshot["content_sha256"]:
        raise ValueError("tracker live drift")
    print("NOTION_TRACKER_OK", snapshot["row_count"], dict(collections.Counter(row["planner_status"] for row in snapshot["rows"])))


if __name__ == "__main__":
    main()
