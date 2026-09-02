"""Weapon·Skill Sheet의 런 투자 열을 확정 CSV와 Web 미러로 동기화한다."""

from __future__ import annotations

import argparse
import csv
import io
import pathlib
import sys
import urllib.parse
import urllib.request

from locked_csv_payload import sync_payload, verify_payload

OUTPUT_COLUMNS = [
    "item_id", "display_name", "slot_id", "resource_path",
    "run_investment_price", "default_owned", "required_unlock_id", "source_status",
]


def enabled(value: str) -> bool:
    return value.strip().lower() in {"true", "1", "yes", "y", "on"}


def extract(source_text: str, kind: str) -> list[dict[str, str]]:
    reader = csv.DictReader(io.StringIO(source_text.lstrip("\ufeff")))
    if reader.fieldnames is None:
        raise ValueError(f"{kind} Sheet 헤더가 없습니다.")
    id_column = "weapon_id" if kind == "weapon" else "skill_id"
    slot_column = "allowed_slots" if kind == "weapon" else "target_slot_index"
    required = {
        id_column, "display_name", slot_column, "runtime_enabled", "run_investment_price",
        "default_owned", "required_unlock_id", "investment_source_status",
    }
    missing = sorted(required - set(reader.fieldnames))
    if missing:
        raise ValueError(f"{kind} Sheet 필수 열 누락: {', '.join(missing)}")
    rows: list[dict[str, str]] = []
    for source in reader:
        if not enabled(source.get("runtime_enabled", "")):
            continue
        item_id = source[id_column].strip()
        slot_id = source[slot_column].strip() if kind == "weapon" else f"skill_{int(source[slot_column])}"
        base = (
            "res://game/features/equipment/definitions/weapons"
            if kind == "weapon" else "res://game/features/combat_skills/definitions"
        )
        rows.append({
            "item_id": item_id,
            "display_name": source["display_name"].strip(),
            "slot_id": slot_id,
            "resource_path": f"{base}/{item_id}.tres",
            "run_investment_price": source["run_investment_price"].strip(),
            "default_owned": "TRUE" if enabled(source["default_owned"]) else "FALSE",
            "required_unlock_id": source["required_unlock_id"].strip(),
            "source_status": source["investment_source_status"].strip(),
        })
    return validate_rows(rows, kind)


def validate_rows(rows: list[dict[str, str]], kind: str) -> list[dict[str, str]]:
    if not rows:
        raise ValueError(f"활성 {kind} 투자 항목이 없습니다.")
    seen: set[str] = set()
    for row in rows:
        if row["item_id"] in seen or not row["item_id"]:
            raise ValueError(f"{kind} item_id가 비어 있거나 중복입니다: {row['item_id']}")
        seen.add(row["item_id"])
        price = int(row["run_investment_price"])
        if price < 0 or row["source_status"] not in {"temporary", "confirmed"}:
            raise ValueError(f"{row['item_id']}: 가격 또는 근거 상태가 올바르지 않습니다.")
        if not enabled(row["default_owned"]) and not row["required_unlock_id"]:
            raise ValueError(f"{row['item_id']}: 비기본 항목에는 required_unlock_id가 필요합니다.")
        if kind == "weapon" and row["slot_id"] not in {"main", "secondary"}:
            raise ValueError(f"{row['item_id']}: 무기 슬롯이 올바르지 않습니다.")
    return rows


def read_locked(path: pathlib.Path, kind: str) -> list[dict[str, str]]:
    reader = csv.DictReader(io.StringIO(path.read_text(encoding="utf-8-sig")))
    if reader.fieldnames != OUTPUT_COLUMNS:
        raise ValueError(f"{kind} 확정 CSV 열 순서가 다릅니다.")
    return validate_rows([{key: value.strip() for key, value in row.items()} for row in reader], kind)


def render(rows: list[dict[str, str]]) -> str:
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=OUTPUT_COLUMNS, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue()


def download(spreadsheet_id: str, sheet: str) -> str:
    query = urllib.parse.urlencode({"tqx": "out:csv", "headers": "1", "sheet": sheet})
    url = f"https://docs.google.com/spreadsheets/d/{spreadsheet_id}/gviz/tq?{query}"
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read().decode("utf-8-sig")


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    data = root / "game/features/loadout_investment/data"
    paths = {
        "weapon": data / "weapon_investment.csv",
        "skill": data / "skill_investment.csv",
    }
    payloads = {kind: path.with_name(path.stem + "_payload.tres") for kind, path in paths.items()}
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spreadsheet-id", default="1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    counts: dict[str, int] = {}
    for kind, sheet in (("weapon", "Weapon"), ("skill", "Skill")):
        source_path = f"res://game/features/loadout_investment/data/{kind}_investment.csv"
        if args.check:
            rows = read_locked(paths[kind], kind)
            verify_payload(paths[kind], payloads[kind], source_path)
        else:
            rows = extract(download(args.spreadsheet_id, sheet), kind)
            paths[kind].write_text(render(rows), encoding="utf-8", newline="\n")
            sync_payload(paths[kind], payloads[kind], source_path)
        counts[kind] = len(rows)
    print(f"LOADOUT_INVESTMENT_OK weapons={counts['weapon']} skills={counts['skill']} locked_payloads=true")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, csv.Error) as error:
        print(f"LOADOUT_INVESTMENT_ERROR {error}", file=sys.stderr)
        raise SystemExit(1)
