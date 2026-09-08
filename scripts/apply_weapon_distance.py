"""Validate a planner distance confirmation; apply only with explicit owner approval."""
from __future__ import annotations
import argparse
import csv
import hashlib
import io
import json
from pathlib import Path
from sync_weapon_balance import validate, validate_distance_curve
from locked_csv_payload import sync_payload

ROOT = Path(__file__).resolve().parents[1]


def prepare(record: dict, catalog: dict, text: str) -> str:
    submission = record.get('submission', {})
    if record.get('status') != 'planner_confirmed' or submission.get('model') != 'distance' or record.get('model_version') != 3:
        raise ValueError('거리 곡선 기획 확정 v3 파일이 필요합니다.')
    fingerprint = hashlib.sha256(json.dumps(catalog['sources'], ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()
    if submission.get('source') != fingerprint:
        raise ValueError('원본이 변경된 확정안입니다. 현재 값으로 다시 검토하세요.')
    path = 'game/features/weapon_balance/data/weapon_balance.csv'
    if hashlib.sha256(text.replace('\r\n', '\n').encode()).hexdigest() != catalog['sources'][path]:
        raise ValueError('현재 CSV와 검토 카탈로그가 다릅니다.')
    trial = submission['input']
    curve = trial['distanceCurve']
    validate_distance_curve(curve)
    rows = validate(text)
    match = [row for row in rows if row['weapon_id'] == trial['weaponId']]
    if len(match) != 1:
        raise ValueError('확정 CSV의 기존 무기만 적용할 수 있습니다. 신규 무기는 등록 절차가 필요합니다.')
    match[0]['distance_damage_curve'] = curve
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=list(rows[0]), lineterminator='\n')
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('record', type=Path)
    parser.add_argument('--approve-and-apply', action='store_true', help='오너 검토 후에만 사용. 곡선 외 시험 수치는 적용하지 않음')
    args = parser.parse_args()
    path = ROOT / 'game/features/weapon_balance/data/weapon_balance.csv'
    record = json.loads(args.record.read_text(encoding='utf-8'))
    result = prepare(record, json.loads((ROOT / 'docs/assets/dps-catalog.json').read_text(encoding='utf-8')), path.read_text(encoding='utf-8'))
    if args.approve_and_apply:
        path.write_text(result, encoding='utf-8', newline='\n')
        sync_payload(path, path.with_name('weapon_balance_payload.tres'), 'res://game/features/weapon_balance/data/weapon_balance.csv')
    print('DISTANCE_APPLY_OK' if args.approve_and_apply else 'DISTANCE_PREVIEW_OK no writes')
    print('기존 무기의 곡선만 적용합니다. 비교용 장착·피해·명중률은 적용하지 않습니다. Sheet 동일 곡선 반영, 카탈로그 재생성, 테스트와 배포가 필요합니다.')


if __name__ == '__main__':
    main()
