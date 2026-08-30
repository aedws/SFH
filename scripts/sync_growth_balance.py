"""SFH Google Sheets의 RunBuff/Upgrade 탭을 확정 CSV로 검증·동기화한다."""

from __future__ import annotations

import argparse
import csv
import io
import pathlib
import sys
import time
import urllib.parse
import urllib.request


SCHEMAS = {
    "run_buff": [
        "buff_id", "display_name", "maximum_stacks", "meta_target",
        "max_health_add", "defense_add", "movement_speed_add",
        "movement_speed_multiply", "weapon_damage_add", "weapon_damage_multiply",
        "fire_interval_multiply", "target_range_multiply", "heal_on_apply",
        "runtime_enabled", "description",
    ],
    "upgrade": [
        "target_kind", "target_id", "level", "maximum_level",
        "module_capacity_cost", "credit_cost", "material_quantity", "player_stat_id",
        "player_stat_add", "player_stat_multiply", "weapon_damage_add",
        "weapon_damage_multiply", "weapon_fire_interval_multiply",
        "weapon_target_range_multiply", "runtime_enabled", "display_name", "description",
    ],
}


def _is_enabled(value: str) -> bool:
    return value.strip().lower() in {"true", "1", "yes", "y", "on"}


def download(url: str) -> str:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != "https" or parsed.hostname != "docs.google.com":
        raise ValueError("https Google Sheets 공개 CSV URL이 필요합니다.")
    separator = "&" if "?" in url else "?"
    request = urllib.request.Request(
        f"{url}{separator}sfh_cache={int(time.time())}",
        headers={"User-Agent": "SFH-growth-balance-sync/1.0"},
    )
    with urllib.request.urlopen(request, timeout=15) as response:
        return response.read().decode("utf-8-sig")


def validate(text: str, schema_name: str) -> list[dict[str, str]]:
    reader = csv.DictReader(io.StringIO(text.lstrip("\ufeff")))
    columns = SCHEMAS[schema_name]
    fieldnames = reader.fieldnames or []
    missing = [column for column in columns if column not in fieldnames]
    if missing:
        raise ValueError(f"{schema_name} 필수 열이 없습니다: {', '.join(missing)}")
    rows = [
        {column: row.get(column, "").strip() for column in columns}
        for row in reader
        if _is_enabled(row.get("runtime_enabled", ""))
    ]
    if not rows:
        raise ValueError(f"{schema_name} 런타임 데이터가 없습니다.")
    key_names = ["buff_id"] if schema_name == "run_buff" else ["target_kind", "target_id", "level"]
    seen: set[tuple[str, ...]] = set()
    for line_number, row in enumerate(rows, start=3):
        key = tuple(row[name] for name in key_names)
        if any(not value for value in key) or key in seen:
            raise ValueError(f"{line_number}행 키가 비어 있거나 중복입니다: {key}")
        seen.add(key)
        if schema_name == "run_buff":
            if int(row["maximum_stacks"]) < 1:
                raise ValueError(f"{line_number}행 maximum_stacks는 1 이상이어야 합니다.")
            if row["meta_target"] not in {"character", "weapon", "armor"}:
                raise ValueError(f"{line_number}행 meta_target이 잘못됐습니다.")
        else:
            if row["target_kind"] not in {"weapon", "armor", "module"}:
                raise ValueError(f"{line_number}행 target_kind가 잘못됐습니다.")
            if int(row["level"]) < 1 or int(row["maximum_level"]) < int(row["level"]):
                raise ValueError(f"{line_number}행 레벨 범위가 잘못됐습니다.")
            for name in ("module_capacity_cost", "credit_cost", "material_quantity"):
                if int(row[name]) < 0:
                    raise ValueError(f"{line_number}행 {name}은 음수일 수 없습니다.")
    return rows


def write_rows(path: pathlib.Path, columns: list[str], rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=columns, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    data_dir = root / "game/features/growth_balance/data"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-buff-url")
    parser.add_argument("--upgrade-url")
    parser.add_argument("--spreadsheet-id")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    targets = {
        "run_buff": data_dir / "run_buff_balance.csv",
        "upgrade": data_dir / "upgrade_balance.csv",
    }
    if args.check:
        texts = {name: path.read_text(encoding="utf-8-sig") for name, path in targets.items()}
    elif args.spreadsheet_id:
        base_url = (
            f"https://docs.google.com/spreadsheets/d/{args.spreadsheet_id}"
            "/gviz/tq?tqx=out:csv&headers=1"
        )
        texts = {
            "run_buff": download(f"{base_url}&sheet=RunBuff"),
            "upgrade": download(f"{base_url}&sheet=Upgrade"),
        }
    elif args.run_buff_url and args.upgrade_url:
        texts = {
            "run_buff": download(args.run_buff_url),
            "upgrade": download(args.upgrade_url),
        }
    else:
        parser.error("--check, --spreadsheet-id 또는 두 탭 URL이 필요합니다.")
    counts: dict[str, int] = {}
    normalized: dict[str, list[dict[str, str]]] = {}
    for name, text in texts.items():
        normalized[name] = validate(text, name)
        counts[name] = len(normalized[name])
    if not args.check:
        for name, rows in normalized.items():
            write_rows(targets[name], SCHEMAS[name], rows)
    print(
        "GROWTH_BALANCE_OK "
        f"run_buff_rows={counts['run_buff']} upgrade_rows={counts['upgrade']}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, csv.Error) as error:
        print(f"GROWTH_BALANCE_ERROR {error}", file=sys.stderr)
        raise SystemExit(1)
