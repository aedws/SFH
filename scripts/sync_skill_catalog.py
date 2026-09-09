"""Google Sheets Skill 탭과 확정 스킬 카탈로그 CSV를 동기화한다."""

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
    "skill_id", "display_name", "target_slot_index", "targeting_mode",
    "required_combat_tags", "cooldown_seconds", "energy_cost", "maximum_charges",
    "charge_recovery_seconds", "grade", "region_tags", "acquisition_mode",
    "runtime_enabled", "planner_note",
]
TARGETING_MODES = {"direction", "self", "single", "cluster", "highest_health", "nearest", "elite", "densest"}
ACQUISITION_MODES = {"default", "field_loot", "shop", "blueprint"}


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
        if not enabled(source.get("runtime_enabled", "")):
            continue
        row = {column: source.get(column, "").strip() for column in COLUMNS}
        skill_id = row["skill_id"]
        if not skill_id or skill_id in seen:
            raise ValueError(f"skill_id가 비어 있거나 중복입니다: {skill_id}")
        seen.add(skill_id)
        if row["targeting_mode"] not in TARGETING_MODES:
            raise ValueError(f"{skill_id}: targeting_mode가 올바르지 않습니다.")
        if row["acquisition_mode"] not in ACQUISITION_MODES:
            raise ValueError(f"{skill_id}: acquisition_mode가 올바르지 않습니다.")
        try:
            slot = int(row["target_slot_index"])
            cooldown = float(row["cooldown_seconds"])
            energy = float(row["energy_cost"])
            charges = int(row["maximum_charges"])
            recovery = float(row["charge_recovery_seconds"])
            grade = int(row["grade"])
        except ValueError as error:
            raise ValueError(f"{skill_id}: 숫자 열 형식이 올바르지 않습니다.") from error
        if not row["display_name"] or not 0 <= slot <= 9:
            raise ValueError(f"{skill_id}: 표시명·슬롯 계약이 올바르지 않습니다.")
        if cooldown < 0 or energy < 0 or charges < 1 or recovery < 0 or not 1 <= grade <= 5:
            raise ValueError(f"{skill_id}: 전투 자원·등급 계약이 올바르지 않습니다.")
        rows.append(row)
    if not rows:
        raise ValueError("활성 스킬 행이 없습니다.")
    return rows


def render(rows: list[dict[str, str]]) -> str:
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=COLUMNS, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue()


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    default_output = root / "game/features/combat_skills/data/skill_catalog.csv"
    default_payload = root / "game/features/combat_skills/data/skill_catalog_payload.tres"
    parser = argparse.ArgumentParser()
    parser.add_argument("--spreadsheet-id", default="1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM")
    parser.add_argument("--url")
    parser.add_argument("--output", type=pathlib.Path, default=default_output)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    source_path = "res://game/features/combat_skills/data/skill_catalog.csv"
    try:
        if args.check:
            rows = validate(args.output.read_text(encoding="utf-8-sig"))
            verify_payload(args.output, default_payload, source_path)
        else:
            url = args.url or (
                "https://docs.google.com/spreadsheets/d/"
                f"{args.spreadsheet_id}/gviz/tq?"
                + urllib.parse.urlencode({"tqx": "out:csv", "headers": "1", "sheet": "Skill"})
            )
            with urllib.request.urlopen(url, timeout=30) as response:
                source_text = response.read().decode("utf-8-sig")
            rows = validate(source_text)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(render(rows), encoding="utf-8", newline="\n")
            sync_payload(args.output, default_payload, source_path)
        field_skills = sum(row["acquisition_mode"] == "field_loot" for row in rows)
        print(f"SKILL_CATALOG_OK rows={len(rows)} field_loot={field_skills} deterministic=true")
        return 0
    except (OSError, ValueError, csv.Error) as error:
        print(f"SKILL_CATALOG_ERROR {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
