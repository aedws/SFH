"""Google Sheets Character 탭과 확정 캐릭터 CSV를 동기화한다."""

from __future__ import annotations

import argparse
import csv
import io
import math
import pathlib
import sys
import urllib.parse
import urllib.request

from locked_csv_payload import sync_payload, verify_payload

COLUMNS = [
    "character_id", "display_name", "entry_cost", "passive_id", "passive_name",
    "passive_description", "max_health_add", "defense_add",
    "movement_speed_multiplier", "runtime_enabled", "source_status", "planner_note",
    "skill_families", "skill_damage_multiplier", "skill_cooldown_multiplier", "skill_radius_multiplier",
    "energy_capacity_multiplier", "moving_energy_regeneration_multiplier",
]


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
        character_id = row["character_id"]
        if not character_id or character_id in seen:
            raise ValueError(f"character_id가 비어 있거나 중복입니다: {character_id}")
        seen.add(character_id)
        if not row["display_name"] or not row["passive_id"] or not row["passive_name"]:
            raise ValueError(f"{character_id}: 이름과 패시브 식별자가 필요합니다.")
        if row["source_status"] not in {"temporary", "confirmed"}:
            raise ValueError(f"{character_id}: source_status가 올바르지 않습니다.")
        try:
            entry_cost = int(row["entry_cost"])
            float(row["max_health_add"])
            float(row["defense_add"])
            speed = float(row["movement_speed_multiplier"])
        except ValueError as error:
            raise ValueError(f"{character_id}: 숫자 열 형식이 올바르지 않습니다.") from error
        if entry_cost < 0 or speed <= 0:
            raise ValueError(f"{character_id}: 비용 또는 이동 속도 배율이 올바르지 않습니다.")
        for key in ('skill_damage_multiplier','skill_cooldown_multiplier','skill_radius_multiplier',
                    'energy_capacity_multiplier', 'moving_energy_regeneration_multiplier'):
            if not math.isfinite(float(row[key])) or not 0 < float(row[key]) <= 5:
                raise ValueError(f'{character_id}: {key} 특화 배율 오류')
        rows.append(row)
    if not rows:
        raise ValueError("활성 캐릭터가 없습니다.")
    return rows


def render(rows: list[dict[str, str]]) -> str:
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=COLUMNS, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue()


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    output = root / "game/features/character_selection/data/character_catalog.csv"
    payload = root / "game/features/character_selection/data/character_catalog_payload.tres"
    source_path = "res://game/features/character_selection/data/character_catalog.csv"
    parser = argparse.ArgumentParser()
    parser.add_argument("--spreadsheet-id", default="1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM")
    parser.add_argument("--url")
    parser.add_argument("--output", type=pathlib.Path, default=output)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    try:
        if args.check:
            rows = validate(args.output.read_text(encoding="utf-8-sig"))
            verify_payload(args.output, payload, source_path)
        else:
            url = args.url or (
                "https://docs.google.com/spreadsheets/d/"
                f"{args.spreadsheet_id}/gviz/tq?"
                + urllib.parse.urlencode({"tqx": "out:csv", "headers": "1", "sheet": "Character"})
            )
            with urllib.request.urlopen(url, timeout=30) as response:
                text = response.read().decode("utf-8-sig")
            rows = validate(text)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(render(rows), encoding="utf-8", newline="\n")
            sync_payload(args.output, payload, source_path)
        print(f"CHARACTER_CATALOG_OK rows={len(rows)}")
        return 0
    except (OSError, ValueError, csv.Error) as error:
        print(f"CHARACTER_CATALOG_ERROR {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
