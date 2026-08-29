"""Google Sheets 공개 CSV를 검증해 SFH의 확정 밸런스로 동기화한다."""

from __future__ import annotations

import argparse
import csv
import io
import pathlib
import sys
import time
import urllib.parse
import urllib.request


COLUMNS = [
    "weapon_id", "display_name", "trait_id", "damage", "fire_interval_sec",
    "projectile_speed_px_sec", "target_range_px", "projectiles_per_shot",
    "spread_angle_deg", "burst_count", "burst_interval_sec", "critical_chance",
    "critical_multiplier", "pierce_count", "pierce_damage_retention",
    "projectile_lifetime_sec", "projectile_color_hex", "description",
]
INTEGER_COLUMNS = {"projectiles_per_shot", "burst_count", "pierce_count"}
FLOAT_COLUMNS = {
    "damage", "fire_interval_sec", "projectile_speed_px_sec", "target_range_px",
    "spread_angle_deg", "burst_interval_sec", "critical_chance",
    "critical_multiplier", "pierce_damage_retention", "projectile_lifetime_sec",
}


def _is_enabled(value: str) -> bool:
    return value.strip().lower() in {"true", "1", "yes", "y", "on"}


def _read_transposed_rows(matrix: list[list[str]]) -> list[dict[str, str]]:
    rows_by_variable: dict[str, list[str]] = {}
    for row in matrix:
        if not row or not row[0].strip():
            continue
        variable_name = row[0].strip()
        if variable_name in rows_by_variable:
            raise ValueError(f"변수명이 중복됩니다: {variable_name}")
        rows_by_variable[variable_name] = row
    missing = [column for column in COLUMNS if column not in rows_by_variable]
    if missing:
        raise ValueError("필수 변수가 없습니다: " + ", ".join(missing))

    maximum_columns = max(len(row) for row in matrix)
    runtime_row = rows_by_variable.get("runtime_enabled")
    rows: list[dict[str, str]] = []
    for column_index in range(2, maximum_columns):
        weapon_id_row = rows_by_variable["weapon_id"]
        weapon_id = weapon_id_row[column_index].strip() if column_index < len(weapon_id_row) else ""
        if not weapon_id:
            continue
        if runtime_row is not None:
            enabled = runtime_row[column_index] if column_index < len(runtime_row) else ""
            if not _is_enabled(enabled):
                continue
        rows.append({
            column: (
                rows_by_variable[column][column_index].strip()
                if column_index < len(rows_by_variable[column]) else ""
            )
            for column in COLUMNS
        })
    return rows


def _normalize_rows(text: str) -> list[dict[str, str]]:
    matrix = list(csv.reader(io.StringIO(text.lstrip("\ufeff"))))
    matrix = [row for row in matrix if any(cell.strip() for cell in row)]
    if not matrix:
        raise ValueError("CSV가 비어 있습니다.")
    if len(matrix[0]) >= 3 and matrix[0][0].strip() == "weapon_id" and matrix[0][1].strip() != "display_name":
        return _read_transposed_rows(matrix)

    reader = csv.DictReader(io.StringIO(text.lstrip("\ufeff")))
    if reader.fieldnames != COLUMNS:
        raise ValueError("CSV 열 순서가 템플릿과 다릅니다: " + ", ".join(reader.fieldnames or []))
    return list(reader)


def validate(text: str) -> list[dict[str, str]]:
    rows = _normalize_rows(text)
    if not rows:
        raise ValueError("무기 데이터 행이 없습니다.")
    seen: set[str] = set()
    for line_number, row in enumerate(rows, start=2):
        weapon_id = row["weapon_id"].strip()
        if not weapon_id or weapon_id in seen:
            raise ValueError(f"{line_number}행 weapon_id가 비어 있거나 중복입니다.")
        seen.add(weapon_id)
        for column in INTEGER_COLUMNS:
            int(row[column])
        for column in FLOAT_COLUMNS:
            float(row[column])
        if int(row["projectiles_per_shot"]) < 1 or int(row["burst_count"]) < 1:
            raise ValueError(f"{line_number}행 발사체 수와 버스트 수는 1 이상이어야 합니다.")
        chance = float(row["critical_chance"])
        retention = float(row["pierce_damage_retention"])
        if not 0.0 <= chance <= 1.0 or not 0.0 < retention <= 1.0:
            raise ValueError(f"{line_number}행 확률 또는 관통 유지율 범위가 잘못됐습니다.")
    return rows


def download(url: str) -> str:
    separator = "&" if "?" in url else "?"
    request_url = f"{url}{separator}sfh_cache={int(time.time())}"
    request = urllib.request.Request(request_url, headers={"User-Agent": "SFH-balance-sync/1.0"})
    with urllib.request.urlopen(request, timeout=15) as response:
        return response.read().decode("utf-8-sig")


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    default_output = root / "game/features/weapon_balance/data/weapon_balance.csv"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", help="Google Sheets의 파일 > 공유 > 웹에 게시 CSV URL")
    parser.add_argument("--output", type=pathlib.Path, default=default_output)
    parser.add_argument("--check", action="store_true", help="현재 확정 CSV만 검사")
    args = parser.parse_args()

    if args.check:
        text = args.output.read_text(encoding="utf-8-sig")
    elif args.url:
        parsed = urllib.parse.urlparse(args.url)
        if parsed.scheme != "https" or parsed.hostname != "docs.google.com":
            raise ValueError("https Google Sheets 공개 CSV URL이 필요합니다.")
        text = download(args.url)
    else:
        parser.error("--url 또는 --check 중 하나가 필요합니다.")

    rows = validate(text)
    if not args.check:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("w", encoding="utf-8", newline="") as output_file:
            writer = csv.DictWriter(output_file, fieldnames=COLUMNS, lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)
    print(f"WEAPON_BALANCE_OK rows={len(rows)} output={args.output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, csv.Error) as error:
        print(f"WEAPON_BALANCE_ERROR {error}", file=sys.stderr)
        raise SystemExit(1)
