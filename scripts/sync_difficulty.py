"""Difficulty Sheet -> validated locked CSV + Web payload; never changes a running contract."""
import argparse
import csv
import io
import math
import pathlib
import urllib.request
from locked_csv_payload import sync_payload, verify_payload

ROOT = pathlib.Path(__file__).resolve().parents[1]
TARGET = ROOT / 'game/features/operation_contract/data/difficulty.csv'
PAYLOAD = TARGET.with_name('difficulty_payload.tres')
SOURCE = 'res://game/features/operation_contract/data/difficulty.csv'
URL = 'https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/gviz/tq?tqx=out:csv&headers=1&sheet=Difficulty'
COLUMNS = 'level,difficulty_id,display_name,entry_cost_multiplier,health_multiplier,damage_multiplier,armor_multiplier,speed_multiplier,reward_multiplier,high_grade_drop_multiplier,polygon_ratio,loot_band,planner_note'.split(',')

def validate(text):
    matrix = list(csv.reader(io.StringIO(text.lstrip('\ufeff'))))
    if len(matrix) != 12 or matrix[0] != COLUMNS:
        raise ValueError('Difficulty needs two headers and exactly ten levels')
    previous = None
    for level, row in enumerate(matrix[2:], 1):
        expected = {1:'standard', 5:'veteran', 10:'nightmare'}.get(level, f'level_{level:02d}')
        if len(row) != 13 or row[0] != str(level) or row[1] != expected or not row[2] or row[11] not in {'standard','veteran','nightmare'}:
            raise ValueError('Difficulty ID/order/band invalid')
        if row[11] != ('standard' if level<5 else 'veteran' if level<10 else 'nightmare'):
            raise ValueError('Legacy loot band is fixed to level')
        values = list(map(float, row[3:11]))
        for index, value in enumerate(values):
            if not math.isfinite(value) or not (0 if index==7 else 1) <= value <= (0.6 if index==7 else 1.5 if index==4 else 10):
                raise ValueError('Difficulty outside safe bounds')
            if previous and (value < previous[index] or (index==0 and value==previous[0])):
                raise ValueError('Entry cost must strictly rise; risks must never fall')
        previous = values
    return matrix

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--verify-live', action='store_true')
    args = parser.parse_args()
    current = validate(TARGET.read_text(encoding='utf-8-sig'))
    if args.check:
        verify_payload(TARGET, PAYLOAD, SOURCE)
    else:
        matrix = validate(urllib.request.urlopen(URL, timeout=30).read().decode('utf-8-sig'))
        matrix[1] = [v or current[1][i] for i,v in enumerate(matrix[1])]
        if not args.verify_live:
            with TARGET.open('w', encoding='utf-8', newline='') as output:
                csv.writer(output, lineterminator='\n').writerows(matrix)
            sync_payload(TARGET, PAYLOAD, SOURCE)
    print('DIFFICULTY_DATA_OK ten_levels')
