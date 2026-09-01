"""Google Sheets Item 탭과 확정 전리품 생명 주기 CSV를 동기화한다."""

from __future__ import annotations

import argparse
import csv
import io
import pathlib
import sys
import urllib.parse
import urllib.request

from locked_csv_payload import sync_payload, verify_payload

COLUMNS = [
    "item_id", "display_name", "item_type", "grid_width", "grid_height",
    "linked_resource", "credit_value", "consumable", "description", "loot_family",
    "session_behavior", "extract_result", "death_result", "convert_value", "region_tags",
    "runtime_enabled",
]
PERSISTENT_RESULTS = {
    "warehouse_item": "warehouse",
    "carry_currency": "wallet",
    "permanent_unlock": "permanent_unlock",
}
SESSION_TYPES = {"rune", "core", "artifact"}


def enabled(value: str) -> bool:
    return value.strip().lower() in {"true", "1", "yes", "y", "on"}


def validate(text: str) -> list[dict[str, str]]:
    reader = csv.DictReader(io.StringIO(text.lstrip("\ufeff")))
    if reader.fieldnames is None:
        raise ValueError("CSV 헤더가 없습니다.")
    missing = [column for column in COLUMNS if column not in reader.fieldnames]
    if missing:
        raise ValueError(f"필수 열이 없습니다: {', '.join(missing)}")
    rows: list[dict[str, str]] = []
    seen: set[str] = set()
    for source in reader:
        if not enabled(source["runtime_enabled"]):
            continue
        row = {column: source.get(column, "").strip() for column in COLUMNS}
        item_id = row["item_id"]
        if not item_id or item_id in seen:
            raise ValueError(f"item_id가 비어 있거나 중복입니다: {item_id}")
        seen.add(item_id)
        tags = [tag.strip() for tag in row["region_tags"].split("|") if tag.strip()]
        if not row["display_name"] or not tags or len(tags) != len(set(tags)):
            raise ValueError(f"{item_id}: 표시 이름과 중복 없는 지역 태그가 필요합니다.")
        try:
            convert_value = int(row["convert_value"])
            int(row["grid_width"])
            int(row["grid_height"])
        except ValueError as error:
            raise ValueError(f"{item_id}: 숫자 열 형식이 올바르지 않습니다.") from error
        family = row["loot_family"]
        if family == "persistent_asset":
            if row["session_behavior"] not in PERSISTENT_RESULTS:
                raise ValueError(f"{item_id}: 영구 자산 사용 규칙이 올바르지 않습니다.")
            if (
                row["extract_result"] != PERSISTENT_RESULTS[row["session_behavior"]]
                or convert_value != 0
            ):
                raise ValueError(f"{item_id}: 영구 자산 탈출 규칙이 올바르지 않습니다.")
        elif family == "session_convertible":
            if (
                row["item_type"] not in SESSION_TYPES
                or row["session_behavior"] != "session_socket"
                or row["extract_result"] != "auto_convert"
                or row["death_result"] != "lost"
                or convert_value <= 0
            ):
                raise ValueError(f"{item_id}: 세션 증폭·환금 규칙이 올바르지 않습니다.")
        else:
            raise ValueError(f"{item_id}: 지원하지 않는 loot_family입니다: {family}")
        rows.append(row)
    if not rows:
        raise ValueError("활성 전리품 행이 없습니다.")
    return rows


def render(rows: list[dict[str, str]]) -> str:
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=COLUMNS, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue()


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    default_output = root / "game/features/loot_lifecycle/data/item_lifecycle.csv"
    default_payload = root / "game/features/loot_lifecycle/data/item_lifecycle_payload.tres"
    parser = argparse.ArgumentParser()
    parser.add_argument("--spreadsheet-id", default="1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM")
    parser.add_argument("--url")
    parser.add_argument("--output", type=pathlib.Path, default=default_output)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    source_path = "res://game/features/loot_lifecycle/data/item_lifecycle.csv"
    try:
        if args.check:
            rows = validate(args.output.read_text(encoding="utf-8-sig"))
            verify_payload(args.output, default_payload, source_path)
        else:
            url = args.url or (
                "https://docs.google.com/spreadsheets/d/"
                f"{args.spreadsheet_id}/gviz/tq?"
                + urllib.parse.urlencode({"tqx": "out:csv", "headers": "1", "sheet": "Item"})
            )
            with urllib.request.urlopen(url, timeout=30) as response:
                text = response.read().decode("utf-8-sig")
            rows = validate(text)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(render(rows), encoding="utf-8", newline="\n")
            sync_payload(args.output, default_payload, source_path)
        persistent = sum(row["loot_family"] == "persistent_asset" for row in rows)
        session = sum(row["loot_family"] == "session_convertible" for row in rows)
        print(f"ITEM_LIFECYCLE_OK rows={len(rows)} persistent={persistent} session={session}")
        return 0
    except (OSError, ValueError, csv.Error) as error:
        print(f"ITEM_LIFECYCLE_ERROR {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
