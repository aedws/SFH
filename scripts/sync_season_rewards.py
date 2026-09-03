"""Validate/sync SeasonReward Sheet with a Web-safe locked payload (two header rows)."""
import argparse
import csv
import io
import pathlib
import re
import urllib.request
from locked_csv_payload import sync_payload, verify_payload

ROOT = pathlib.Path(__file__).resolve().parents[1]
TARGET = ROOT / "game/features/conditional_ranking/data/season_reward.csv"
PAYLOAD = TARGET.with_name("season_reward_payload.tres")
SOURCE = "res://game/features/conditional_ranking/data/season_reward.csv"
URL = "https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/gviz/tq?tqx=out:csv&headers=1&sheet=SeasonReward"
COLUMNS = ["reward_id", "ranking_id", "max_rank", "kind", "display_name", "color", "runtime_enabled", "description"]


def validate(text):
    matrix = list(csv.reader(io.StringIO(text.lstrip("\ufeff"))))
    if len(matrix) < 3 or matrix[0] != COLUMNS:
        raise ValueError("SeasonReward needs variables, Korean descriptions, and data")
    seen = set()
    active = []
    for values in matrix[2:]:
        if not values or not values[0]:
            continue
        row = dict(zip(COLUMNS, values))
        if len(values) != len(COLUMNS) or row["reward_id"] in seen:
            raise ValueError("duplicate reward or column count")
        seen.add(row["reward_id"])
        if row["runtime_enabled"].lower() not in {"true", "false"}:
            raise ValueError("runtime_enabled must be TRUE/FALSE")
        if row["runtime_enabled"].lower() == "false":
            continue
        if row["kind"] not in {"title", "aura"} or row["ranking_id"] not in {"recovered_value", "elapsed_seconds", "kills"} or int(row["max_rank"]) < 1 or not re.fullmatch(r"[0-9a-fA-F]{6}", row["color"]):
            raise ValueError("invalid cosmetic reward")
        active.append(row)
    if not active:
        raise ValueError("empty reward catalog")
    return matrix, active


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    text = TARGET.read_text(encoding="utf-8-sig") if args.check else urllib.request.urlopen(URL, timeout=30).read().decode("utf-8-sig")
    matrix, active = validate(text)
    if args.check:
        verify_payload(TARGET, PAYLOAD, SOURCE)
    else:
        with TARGET.open("w", encoding="utf-8", newline="") as output:
            csv.writer(output, lineterminator="\n").writerows(matrix)
        sync_payload(TARGET, PAYLOAD, SOURCE)
    print(f"SEASON_REWARD_DATA_OK rows={len(active)} cosmetic_only=true locked_payload=true")
