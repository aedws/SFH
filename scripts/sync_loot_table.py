"""Google Sheets LootTable 탭과 확정 지역·난이도 드랍 CSV를 동기화한다."""

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
    "entry_id", "region_id", "difficulty_id", "map_size", "source_type", "item_id",
    "grade", "base_weight", "minimum_quantity", "maximum_quantity", "boss_only",
    "runtime_enabled", "planner_note",
]
REGIONS = {"ruined_city", "industrial_district", "research_complex"}
DIFFICULTIES = {"any", "standard", "veteran", "nightmare"}
MAP_SIZES = {"any", "small", "medium", "large"}
SOURCE_TYPES = {"enemy", "room_reward", "vault", "boss"}


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
        entry_id = row["entry_id"]
        if not entry_id or entry_id in seen:
            raise ValueError(f"entry_id가 비어 있거나 중복입니다: {entry_id}")
        seen.add(entry_id)
        if row["region_id"] not in REGIONS:
            raise ValueError(f"{entry_id}: region_id가 올바르지 않습니다.")
        if row["difficulty_id"] not in DIFFICULTIES:
            raise ValueError(f"{entry_id}: difficulty_id가 올바르지 않습니다.")
        if row["map_size"] not in MAP_SIZES:
            raise ValueError(f"{entry_id}: map_size가 올바르지 않습니다.")
        if row["source_type"] not in SOURCE_TYPES:
            raise ValueError(f"{entry_id}: source_type이 올바르지 않습니다.")
        try:
            grade = int(row["grade"])
            weight = float(row["base_weight"])
            minimum = int(row["minimum_quantity"])
            maximum = int(row["maximum_quantity"])
        except ValueError as error:
            raise ValueError(f"{entry_id}: 숫자 열 형식이 올바르지 않습니다.") from error
        if not row["item_id"] or not 1 <= grade <= 5 or weight <= 0 or minimum < 1 or maximum < minimum:
            raise ValueError(f"{entry_id}: 아이템·등급·가중치·수량 계약이 올바르지 않습니다.")
        if enabled(row["boss_only"]) and row["source_type"] != "boss":
            raise ValueError(f"{entry_id}: boss_only 행은 boss 출처여야 합니다.")
        rows.append(row)
    if not rows:
        raise ValueError("활성 드랍 테이블 행이 없습니다.")
    return rows


def render(rows: list[dict[str, str]]) -> str:
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=COLUMNS, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue()


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    default_output = root / "game/features/loot_tables/data/loot_table.csv"
    default_payload = root / "game/features/loot_tables/data/loot_table_payload.tres"
    parser = argparse.ArgumentParser()
    parser.add_argument("--spreadsheet-id", default="1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM")
    parser.add_argument("--url")
    parser.add_argument("--output", type=pathlib.Path, default=default_output)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    source_path = "res://game/features/loot_tables/data/loot_table.csv"
    try:
        if args.check:
            rows = validate(args.output.read_text(encoding="utf-8-sig"))
            verify_payload(args.output, default_payload, source_path)
        else:
            url = args.url or (
                "https://docs.google.com/spreadsheets/d/"
                f"{args.spreadsheet_id}/gviz/tq?"
                + urllib.parse.urlencode({"tqx": "out:csv", "headers": "1", "sheet": "LootTable"})
            )
            with urllib.request.urlopen(url, timeout=30) as response:
                text = response.read().decode("utf-8-sig")
            rows = validate(text)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(render(rows), encoding="utf-8", newline="\n")
            sync_payload(args.output, default_payload, source_path)
        regions = len({row["region_id"] for row in rows})
        print(f"LOOT_TABLE_OK rows={len(rows)} regions={regions} deterministic=true")
        return 0
    except (OSError, ValueError, csv.Error) as error:
        print(f"LOOT_TABLE_ERROR {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
