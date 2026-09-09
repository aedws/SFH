"""Weapon/Armor Sheet의 고정 정체성 열을 검증해 잠금 CSV로 동기화한다."""

from __future__ import annotations

import argparse
import csv
import io
import pathlib
import sys
import urllib.request


COLUMNS = [
    "equipment_kind", "definition_id", "display_name", "innate_skill_id",
    "innate_skill_name", "innate_trigger_hits", "innate_fixed_damage",
    "innate_effect_kind", "innate_effect_radius", "innate_maximum_targets",
    "fixed_option_id", "fixed_option_name", "fixed_option_modifier",
    "fixed_option_operation", "fixed_option_value", "scaling_policy", "source_status",
]


def _download(url: str) -> str:
    request = urllib.request.Request(url, headers={"User-Agent": "SFH-equipment-identity-sync/1.0"})
    with urllib.request.urlopen(request, timeout=15) as response:
        return response.read().decode("utf-8-sig")


def _rows(text: str, kind: str) -> list[dict[str, str]]:
    source = list(csv.DictReader(io.StringIO(text.lstrip("\ufeff"))))
    result: list[dict[str, str]] = []
    id_column = "weapon_id" if kind == "weapon" else "armor_id"
    for index, row in enumerate(source):
        definition_id = (row.get(id_column) or "").strip()
        # Shared workbook row 2 is Korean column documentation, not an equipment record.
        if index == 0 and not definition_id.isascii():
            continue
        if not definition_id:
            continue
        result.append({
            "equipment_kind": kind,
            "definition_id": definition_id,
            "display_name": (row.get("display_name") or "").strip(),
            "innate_skill_id": (row.get("innate_skill_id") or "").strip() if kind == "weapon" else "",
            "innate_skill_name": (row.get("innate_skill_name") or "").strip() if kind == "weapon" else "",
            "innate_trigger_hits": (row.get("innate_trigger_hits") or "").strip() if kind == "weapon" else "",
            "innate_fixed_damage": (row.get("innate_fixed_damage") or "").strip() if kind == "weapon" else "",
            "innate_effect_kind": (row.get("innate_effect_kind") or "single_target").strip() if kind == "weapon" else "",
            "innate_effect_radius": (row.get("innate_effect_radius") or "0").strip() if kind == "weapon" else "",
            "innate_maximum_targets": (row.get("innate_maximum_targets") or "1").strip() if kind == "weapon" else "",
            "fixed_option_id": (row.get("fixed_option_id") or "").strip(),
            "fixed_option_name": (row.get("fixed_option_name") or "").strip(),
            "fixed_option_modifier": (row.get("fixed_option_modifier") or "").strip(),
            "fixed_option_operation": (row.get("fixed_option_operation") or "").strip(),
            "fixed_option_value": (row.get("fixed_option_value") or "").strip(),
            "scaling_policy": "fixed_identity",
            "source_status": (row.get("source_status") or "provisional").strip(),
        })
    return result


def validate(rows: list[dict[str, str]]) -> None:
    if not rows:
        raise ValueError("장비 정체성 데이터가 비어 있습니다.")
    seen: set[str] = set()
    for index, row in enumerate(rows, start=2):
        key = f"{row['equipment_kind']}:{row['definition_id']}"
        if key in seen or not row["definition_id"]:
            raise ValueError(f"{index}행 장비 ID가 비어 있거나 중복입니다: {key}")
        seen.add(key)
        if row["equipment_kind"] not in {"weapon", "armor"}:
            raise ValueError(f"{index}행 장비 종류가 잘못됐습니다.")
        if not all(row[column] for column in [
            "display_name", "fixed_option_id", "fixed_option_name",
            "fixed_option_modifier", "fixed_option_operation", "fixed_option_value",
        ]):
            raise ValueError(f"{index}행 고정 옵션 필드가 비어 있습니다.")
        if row["fixed_option_operation"] not in {"add", "multiply"}:
            raise ValueError(f"{index}행 연산은 add 또는 multiply여야 합니다.")
        float(row["fixed_option_value"])
        if row["equipment_kind"] == "weapon":
            if not all(row[column] for column in [
                "innate_skill_id", "innate_skill_name", "innate_trigger_hits", "innate_fixed_damage",
                "innate_effect_kind", "innate_effect_radius", "innate_maximum_targets",
            ]):
                raise ValueError(f"{index}행 무기 고유 스킬 필드가 비어 있습니다.")
            if int(row["innate_trigger_hits"]) < 1 or float(row["innate_fixed_damage"]) <= 0:
                raise ValueError(f"{index}행 무기 고유 스킬 수치가 잘못됐습니다.")
            if row["innate_effect_kind"] not in {"single_target", "electric_area"}:
                raise ValueError(f"{index}행 무기 고유 효과 종류가 잘못됐습니다.")
            radius = float(row["innate_effect_radius"])
            maximum_targets = int(row["innate_maximum_targets"])
            if maximum_targets < 1 or maximum_targets > 32:
                raise ValueError(f"{index}행 무기 고유 효과 대상 수가 잘못됐습니다.")
            if row["innate_effect_kind"] == "electric_area" and radius <= 0:
                raise ValueError(f"{index}행 전기 광역 효과 반경이 잘못됐습니다.")
        if row["scaling_policy"] != "fixed_identity":
            raise ValueError(f"{index}행 스케일 정책이 fixed_identity가 아닙니다.")


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    output = root / "game/features/equipment/data/equipment_identity.csv"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--weapon-url")
    parser.add_argument("--armor-url")
    parser.add_argument("--output", type=pathlib.Path, default=output)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    if args.check:
        with args.output.open(encoding="utf-8-sig", newline="") as file:
            rows = list(csv.DictReader(file))
        if not rows or list(rows[0].keys()) != COLUMNS:
            raise ValueError("잠금 CSV 열 순서가 계약과 다릅니다.")
    elif args.weapon_url and args.armor_url:
        rows = _rows(_download(args.weapon_url), "weapon") + _rows(_download(args.armor_url), "armor")
    else:
        parser.error("--check 또는 --weapon-url/--armor-url 쌍이 필요합니다.")

    validate(rows)
    if not args.check:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("w", encoding="utf-8", newline="") as file:
            writer = csv.DictWriter(file, fieldnames=COLUMNS, lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)
    print(f"EQUIPMENT_IDENTITY_OK rows={len(rows)} output={args.output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, csv.Error) as error:
        print(f"EQUIPMENT_IDENTITY_ERROR {error}", file=sys.stderr)
        raise SystemExit(1)
