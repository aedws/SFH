"""CSV compatibility and scoped confirmation application. No writes."""
import copy
import csv
import hashlib
import io
import json
from pathlib import Path
from sync_weapon_balance import validate, validate_distance_curve, LEGACY_COLUMNS
from apply_weapon_distance import prepare

root = Path(__file__).resolve().parents[1]
text = (root / 'game/features/weapon_balance/data/weapon_balance.csv').read_text(encoding='utf-8')
rows = validate(text)
for bad in ['', '0:1', '0:1;0:2;1:1', '0:1;1:4', '0:nan;1:1', '0:1;0.9:1', '0:1;;1:1']:
    try:
        validate_distance_curve(bad)
        raise AssertionError(bad)
    except ValueError:
        pass
legacy = io.StringIO()
writer = csv.DictWriter(legacy, fieldnames=LEGACY_COLUMNS, extrasaction='ignore', lineterminator='\n')
writer.writeheader()
writer.writerows(rows)
assert all(r['distance_damage_curve'] == '0:1;1:1' for r in validate(legacy.getvalue()))
catalog = json.loads((root / 'docs/assets/dps-catalog.json').read_text(encoding='utf-8'))
fingerprint = hashlib.sha256(json.dumps(catalog['sources'], ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()
record = {'status':'planner_confirmed', 'model_version':3, 'submission':{'model':'distance', 'source':fingerprint, 'input':{'weaponId':'assault_rifle', 'distanceCurve':'0:1;1:0.2', 'damage':999}}}
updated = validate(prepare(record, catalog, text))
assert updated[0]['distance_damage_curve'] == '0:1;1:0.2'
updated[0]['distance_damage_curve'] = rows[0]['distance_damage_curve']
assert updated == rows, 'Only curve column may change'
for change in [{'source':'stale'}, {'input':{'weaponId':'not_registered', 'distanceCurve':'0:1;1:1'}}, {'model':'combat'}]:
    invalid = copy.deepcopy(record)
    invalid['submission'].update(change)
    try:
        prepare(invalid, catalog, text)
        raise AssertionError(change)
    except ValueError:
        pass
print('WEAPON_DISTANCE_CSV_OK legacy / malformed / curve-only apply / stale / unknown')
