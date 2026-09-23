"""ContainerCapacity Sheet -> validated locked CSV and Web mirror."""
import argparse
import csv
import io
import pathlib
import urllib.request
from locked_csv_payload import sync_payload, verify_payload

ROOT = pathlib.Path(__file__).resolve().parents[1]
TARGET = ROOT / 'game/features/inventory/data/container_capacity.csv'
PAYLOAD = TARGET.with_name('container_capacity_payload.tres')
SOURCE = 'res://game/features/inventory/data/container_capacity.csv'
URL = 'https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/gviz/tq?tqx=out:csv&headers=1&sheet=ContainerCapacity'
COLUMNS = 'container_id,stage,display_name,columns,rows,credit_cost,upgrade_enabled,policy_status,planner_note'.split(',')

def validate(text):
    matrix = list(csv.reader(io.StringIO(text.lstrip('\ufeff'))))
    if len(matrix) < 4 or matrix[0] != COLUMNS:
        raise ValueError('ContainerCapacity requires variables/descriptions/data')
    prior = {}
    for row in matrix[2:]:
        if len(row) != 9 or row[0] not in {'backpack', 'pouch'} or not row[2] or row[6].lower() not in {'true', 'false'} or row[7] not in {'confirmed', 'provisional', 'pending'}:
            raise ValueError('invalid capacity row')
        stage, width, height, cost = map(int, (row[1], row[3], row[4], row[5]))
        old_stage, old_height = prior.get(row[0], (-1, 0))
        if stage != old_stage + 1 or width != (12 if row[0]=='backpack' else 2) or not old_height < height <= (6 if row[0]=='backpack' else 4) or not 0 <= cost <= 10000000 or (stage==0 and cost != 0):
            raise ValueError('invalid stage, size or cost')
        if row[7]=='pending' and row[6].lower()=='true':
            raise ValueError('pending policy cannot enable purchases')
        row[6] = row[6].lower()
        prior[row[0]] = stage, height
    if set(prior) != {'backpack', 'pouch'}: raise ValueError('both containers required')
    return matrix

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--payload-only', action='store_true')
    parser.add_argument('--verify-live', action='store_true')
    args = parser.parse_args()
    text = TARGET.read_text(encoding='utf-8-sig')
    current = validate(text)
    if args.check:
        verify_payload(TARGET, PAYLOAD, SOURCE)
    elif args.payload_only:
        sync_payload(TARGET, PAYLOAD, SOURCE)
    else:
        matrix = validate(urllib.request.urlopen(URL, timeout=30).read().decode('utf-8-sig'))
        matrix[1] = [v or current[1][i] for i, v in enumerate(matrix[1])]
        if args.verify_live:
            assert matrix == current, 'live/locked capacity drift'
        else:
            with TARGET.open('w', encoding='utf-8', newline='') as output:
                csv.writer(output, lineterminator='\n').writerows(matrix)
            sync_payload(TARGET, PAYLOAD, SOURCE)
    print('CONTAINER_CAPACITY_DATA_OK locked_web_two_headers')
