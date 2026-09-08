"""Facility Sheet -> validated locked CSV + Web payload. Two header rows remain intact."""
import argparse
import csv
import io
import math
import pathlib
import urllib.request
from locked_csv_payload import sync_payload, verify_payload

ROOT = pathlib.Path(__file__).resolve().parents[1]
TARGET = ROOT / "game/features/map_generation/data/facility.csv"
PAYLOAD = TARGET.with_name("facility_payload.tres")
SOURCE = "res://game/features/map_generation/data/facility.csv"
URL = "https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/gviz/tq?tqx=out:csv&headers=1&sheet=Facility"
COLUMNS = "facility_id,display_name,encounter,risk_bonus,cache_weight,planner_note,required_regions,anchor_zone,shape_x,shape_y,entrance_axis,random_weight".split(",")

def validate(text):
    matrix = list(csv.reader(io.StringIO(text.lstrip("\ufeff"))))
    if len(matrix) < 4 or matrix[0] != COLUMNS:
        raise ValueError("Facility needs variables, descriptions and two or more facility rows")
    seen = set()
    objectives = 0
    for row in matrix[2:]:
        if len(row) != 12 or not row[0] or row[0] in seen or not row[1] or row[2] not in {"patrol", "objective"}:
            raise ValueError("Invalid facility row or duplicate ID")
        risk, weight = float(row[3]), float(row[4])
        if not math.isfinite(risk) or not math.isfinite(weight) or not 0 <= risk <= 2 or not 0 < weight <= 10:
            raise ValueError("Facility risk or placement weight outside allowed range")
        seen.add(row[0])
        objectives += row[2] == "objective"
        if not row[6] or row[7] not in {'west','east','north','south','center'} or row[10] not in {'horizontal','vertical'}:
            raise ValueError('Invalid required region, anchor or entrance axis')
        for column in [8,9,11]:
            value = float(row[column])
            if not math.isfinite(value) or not 0 <= value <= (10 if column==11 else 1):
                raise ValueError('Invalid piece dimensions or random weight')
        if row[2]=='objective' and (row[6]!='*' or float(row[11])!=0):
            raise ValueError('Objective must be globally required and excluded from filler')
    if objectives != 1:
        raise ValueError("Exactly one optional-objective type is required")
    if len(matrix)-2 > 12 or not any(r[2]=='patrol' and float(r[11])>0 for r in matrix[2:]):
        raise ValueError('At most 12 facilities and a positive filler candidate are required')
    return matrix

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--verify-live", action="store_true", help="Read/validate live rows without locking them")
    args = parser.parse_args()
    current = validate(TARGET.read_text(encoding="utf-8-sig"))
    if args.check:
        verify_payload(TARGET, PAYLOAD, SOURCE)
    else:
        matrix = validate(urllib.request.urlopen(URL, timeout=30).read().decode("utf-8-sig"))
        # gviz omits text descriptions in mostly numeric columns; never erase Korean row 2.
        matrix[1] = [value or current[1][index] for index, value in enumerate(matrix[1])]
        if not args.verify_live:
            with TARGET.open("w", encoding="utf-8", newline="") as output:
                csv.writer(output, lineterminator="\n").writerows(matrix)
            sync_payload(TARGET, PAYLOAD, SOURCE)
    print("FACILITY_DATA_OK locked_payload" if args.check else f"FACILITY_LIVE_OK validated_rows_{len(matrix)-2}")
