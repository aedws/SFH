"""Google Sheets 공개 CSV를 검증해 SFH의 확정 밸런스로 동기화한다."""

from __future__ import annotations

import argparse
import csv
import io
import math
import pathlib
import sys
import time
import urllib.parse
import urllib.request

from locked_csv_payload import sync_payload, verify_payload


COLUMNS = [
    "weapon_id", "display_name", "trait_id", "damage", "fire_interval_sec",
    "projectile_speed_px_sec", "target_range_px", "projectiles_per_shot",
    "spread_angle_deg", "burst_count", "burst_interval_sec", "critical_chance",
    "critical_multiplier", "pierce_count", "pierce_damage_retention",
    "projectile_lifetime_sec", "projectile_color_hex", "description",
]
LEGACY_COLUMNS = COLUMNS.copy()
COLUMNS += ["distance_damage_curve"]
DISTANCE_COLUMNS = COLUMNS.copy()
COLUMNS += ["attack_mode"]


def validate_distance_curve(value: str) -> list[tuple[float, float]]:
    pairs = value.split(";")
    if not 2 <= len(pairs) <= 16:
        raise ValueError("거리 곡선은 2~16점이어야 합니다.")
    points = []
    for pair in pairs:
        parts = pair.split(":")
        if len(parts) != 2:
            raise ValueError("거리:배율 형식이 필요합니다.")
        x, y = map(float, parts)
        if not math.isfinite(x) or not math.isfinite(y) or not 0 <= x <= 1 or not 0 <= y <= 3 or (points and x <= points[-1][0]):
            raise ValueError("거리 0~1 오름차순, 배율 0~3이 필요합니다.")
        points.append((x, y))
    if points[0][0] != 0 or points[-1][0] != 1:
        raise ValueError("거리 곡선 양 끝은 0과 1이어야 합니다.")
    return points
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
    missing = [column for column in LEGACY_COLUMNS if column not in rows_by_variable]
    if missing:
        raise ValueError("필수 변수가 없습니다: " + ", ".join(missing))

    maximum_columns = max(len(row) for row in matrix)
    rows_by_variable.setdefault("distance_damage_curve", ["distance_damage_curve", "설명"] + ["0:1;1:1"] * (maximum_columns - 2))
    rows_by_variable.setdefault("attack_mode", ["attack_mode", "공격 방식"] + ["projectile"] * (maximum_columns - 2))
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
    fieldnames = reader.fieldnames or []
    missing = [column for column in LEGACY_COLUMNS if column not in fieldnames]
    if missing:
        raise ValueError("필수 열이 없습니다: " + ", ".join(missing))
    if fieldnames not in (COLUMNS, DISTANCE_COLUMNS, LEGACY_COLUMNS) and "runtime_enabled" not in fieldnames:
        raise ValueError("CSV 열 순서가 템플릿과 다릅니다: " + ", ".join(fieldnames))
    rows = list(reader)
    if "runtime_enabled" in fieldnames:
        rows = [row for row in rows if _is_enabled(row.get("runtime_enabled", ""))]
    return [
        {column: row.get(column, {"distance_damage_curve": "0:1;1:1", "attack_mode": "projectile"}.get(column, "")).strip() for column in COLUMNS}
        for row in rows
    ]


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
        validate_distance_curve(row["distance_damage_curve"])
        if row["attack_mode"] not in {"projectile", "melee_arc", "melee_thrust"}:
            raise ValueError(f"{line_number}행 지원하지 않는 공격 방식입니다.")
        if row["attack_mode"] != "projectile" and (int(row["projectiles_per_shot"]) != 1 or int(row["burst_count"]) != 1 or not 0 < float(row["spread_angle_deg"]) <= 180):
            raise ValueError(f"{line_number}행 근접 공격은 1타/1회 및 0~180도 각도가 필요합니다.")
        for column in INTEGER_COLUMNS:
            int(row[column])
        for column in FLOAT_COLUMNS:
            if not math.isfinite(float(row[column])):
                raise ValueError(f"{line_number}행 {column} 값은 유한해야 합니다.")
        for column in ["damage", "fire_interval_sec", "projectile_speed_px_sec", "target_range_px", "projectile_lifetime_sec"]:
            if float(row[column]) <= 0:
                raise ValueError(f"{line_number}행 {column} 값은 양수여야 합니다.")
        if int(row["projectiles_per_shot"]) > 32 or int(row["burst_count"]) > 16 or not 0 <= int(row["pierce_count"]) <= 32:
            raise ValueError(f"{line_number}행 공격 개수 예산 초과입니다.")
        if float(row["burst_interval_sec"]) < 0 or float(row["spread_angle_deg"]) < 0 or float(row["critical_multiplier"]) < 1:
            raise ValueError(f"{line_number}행 간격/각도/치명타 배율 범위가 잘못됐습니다.")
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
    default_payload = root / "game/features/weapon_balance/data/weapon_balance_payload.tres"
    source_path = "res://game/features/weapon_balance/data/weapon_balance.csv"
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
        sync_payload(args.output, default_payload, source_path)
    elif args.output.resolve() == default_output.resolve():
        verify_payload(args.output, default_payload, source_path)
    print(f"WEAPON_BALANCE_OK rows={len(rows)} output={args.output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, csv.Error) as error:
        print(f"WEAPON_BALANCE_ERROR {error}", file=sys.stderr)
        raise SystemExit(1)
