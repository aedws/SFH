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


def validate(text: str) -> list[dict[str, str]]:
    reader = csv.DictReader(io.StringIO(text.lstrip("\ufeff")))
    if reader.fieldnames != COLUMNS:
        raise ValueError("CSV 열 순서가 템플릿과 다릅니다: " + ", ".join(reader.fieldnames or []))
    rows = list(reader)
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
