"""Google Sheets RunAsset 탭과 확정 세션 소켓 CSV를 동기화한다."""

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
    "rule_id", "item_id", "display_name", "socket_type", "slot_capacity",
    "duplicate_limit", "replacement_policy", "effect_target", "modifier_id",
    "modifier_operation", "modifier_value", "priority", "runtime_enabled", "description",
]
SOCKET_TYPES = {"rune", "core", "artifact"}
REPLACEMENT_POLICIES = {"replace_oldest", "reject"}
EFFECT_TARGETS = {"weapon", "skill", "player"}
OPERATIONS = {"add", "multiply"}


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
    type_contracts: dict[str, tuple[int, str]] = {}
    for source in reader:
        if not enabled(source["runtime_enabled"]):
            continue
        row = {column: source.get(column, "").strip() for column in COLUMNS}
        rule_id = row["rule_id"]
        if not rule_id or rule_id in seen:
            raise ValueError(f"rule_id가 비어 있거나 중복입니다: {rule_id}")
        seen.add(rule_id)
        if row["socket_type"] not in SOCKET_TYPES:
            raise ValueError(f"{rule_id}: socket_type이 올바르지 않습니다.")
        if row["replacement_policy"] not in REPLACEMENT_POLICIES:
            raise ValueError(f"{rule_id}: replacement_policy가 올바르지 않습니다.")
        if row["effect_target"] not in EFFECT_TARGETS or not row["modifier_id"]:
            raise ValueError(f"{rule_id}: 효과 대상·수정자 계약이 올바르지 않습니다.")
        if row["modifier_operation"] not in OPERATIONS:
            raise ValueError(f"{rule_id}: modifier_operation이 올바르지 않습니다.")
        try:
            capacity = int(row["slot_capacity"])
            duplicate_limit = int(row["duplicate_limit"])
            modifier_value = float(row["modifier_value"])
            int(row["priority"])
        except ValueError as error:
            raise ValueError(f"{rule_id}: 숫자 열 형식이 올바르지 않습니다.") from error
        if not row["item_id"] or not row["display_name"] or not 1 <= duplicate_limit <= capacity <= 10:
            raise ValueError(f"{rule_id}: 아이템·소켓 수·중복 상한이 올바르지 않습니다.")
        if row["modifier_operation"] == "multiply" and modifier_value <= 0:
            raise ValueError(f"{rule_id}: 곱연산 값은 0보다 커야 합니다.")
        contract = (capacity, row["replacement_policy"])
        if row["socket_type"] in type_contracts and type_contracts[row["socket_type"]] != contract:
            raise ValueError(f"{rule_id}: 동일 소켓 종류의 수량·교체 정책이 다릅니다.")
        type_contracts[row["socket_type"]] = contract
        rows.append(row)
    if not rows:
        raise ValueError("활성 세션 소켓 규칙이 없습니다.")
    return rows


def render(rows: list[dict[str, str]]) -> str:
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=COLUMNS, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue()


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    default_output = root / "game/features/session_sockets/data/session_socket_rules.csv"
    default_payload = root / "game/features/session_sockets/data/session_socket_rules_payload.tres"
    parser = argparse.ArgumentParser()
    parser.add_argument("--spreadsheet-id", default="1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM")
    parser.add_argument("--url")
    parser.add_argument("--output", type=pathlib.Path, default=default_output)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    source_path = "res://game/features/session_sockets/data/session_socket_rules.csv"
    try:
        if args.check:
            rows = validate(args.output.read_text(encoding="utf-8-sig"))
            verify_payload(args.output, default_payload, source_path)
        else:
            url = args.url or (
                "https://docs.google.com/spreadsheets/d/"
                f"{args.spreadsheet_id}/gviz/tq?"
                + urllib.parse.urlencode({"tqx": "out:csv", "headers": "1", "sheet": "RunAsset"})
            )
            with urllib.request.urlopen(url, timeout=30) as response:
                text = response.read().decode("utf-8-sig")
            rows = validate(text)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(render(rows), encoding="utf-8", newline="\n")
            sync_payload(args.output, default_payload, source_path)
        print(f"SESSION_SOCKET_RULES_OK rows={len(rows)} socket_types={len({row['socket_type'] for row in rows})}")
        return 0
    except (OSError, ValueError, csv.Error) as error:
        print(f"SESSION_SOCKET_RULES_ERROR {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
