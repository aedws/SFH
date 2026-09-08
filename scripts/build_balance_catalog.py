"""Read-only CSV projection for wiki numeric experiments; never writes gameplay data."""
import csv
import hashlib
import io
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/assets/balance-catalog.json'
TITLES = dict(zip(
    'character_catalog skill_catalog season_reward equipment_identity run_buff_balance upgrade_balance skill_investment weapon_investment item_lifecycle loot_table facility codex operation_preset recipe shop_offer training_scenario utility session_socket_rules weapon_balance'.split(),
    ['캐릭터','스킬','시즌 보상','장비 고유 기능·옵션','내부 성장','장비·모듈 강화','스킬 투자','무기 투자','아이템 생명 주기','지역 드랍 표','시설','도감','작전 프리셋','제작 레시피','상점','훈련장','소모품','런 소켓','무기 밸런스']))
LABELS = {
    'shape_x':'필수 피스 가로 0~1','shape_y':'필수 피스 세로 0~1','random_weight':'보조 시설 추첨 가중치',
    'entry_cost':'진입 비용 C','max_health_add':'최대 체력 추가','defense_add':'방어 추가',
    'movement_speed_multiplier':'이동 속도 배수','target_slot_index':'대상 슬롯 번호',
    'cooldown_seconds':'쿨타임 초','energy_cost':'AP 소모','maximum_charges':'최대 충전 횟수','charge_recovery_seconds':'충전 회복 초',
    'grade':'등급','max_rank':'최대 순위','innate_trigger_hits':'고유 기능 발동 명중 횟수','innate_fixed_damage':'고유 고정 피해',
    'innate_effect_radius':'고유 효과 반경 px','innate_maximum_targets':'고유 효과 최대 대상 수','fixed_option_value':'고정 옵션 수치 (종류별 단위)',
    'maximum_stacks':'최대 중첩 수','movement_speed_add':'이동 속도 추가 px/초','movement_speed_multiply':'이동 속도 배수',
    'weapon_damage_add':'무기 피해 추가','weapon_damage_multiply':'무기 피해 배수','fire_interval_multiply':'발사 간격 배수',
    'target_range_multiply':'사거리 배수','heal_on_apply':'적용 시 회복 HP','level':'레벨','maximum_level':'최대 레벨',
    'module_capacity_cost':'모듈 용량 코스트','credit_cost':'강화 비용 C','material_quantity':'재료 수량','player_stat_add':'스탯 추가 (스탯별 단위)',
    'player_stat_multiply':'스탯 배수','weapon_fire_interval_multiply':'무기 발사 간격 배수','weapon_target_range_multiply':'무기 사거리 배수',
    'run_investment_price':'런 투자 가격 C','grid_width':'가방 가로 칸','grid_height':'가방 세로 칸','credit_value':'크레딧 가치 C','convert_value':'환전 가치 C',
    'base_weight':'기본 추첨 가중치 (확률 아님)','minimum_quantity':'최소 수량','maximum_quantity':'최대 수량','risk_bonus':'중심 위험 추가 배수',
    'cache_weight':'자원 금고 배치 가중치','required_count':'필요 횟수','required_max_credits':'요구 최대 크레딧 C',
    'minimum_affixes':'최소 옵션 수','maximum_affixes':'최대 옵션 수','minimum_sockets':'최소 소켓 수','maximum_sockets':'최대 소켓 수',
    'quantity':'수량','price':'가격 C','performance_multiplier':'성능 배수','rotation_weight':'회전 추첨 가중치',
    'dummy_count':'더미 수','dummy_health':'더미 HP','dummy_armor':'더미 방어막','measurement_seconds':'측정 시간 초',
    'run_price':'런 가격 C','max_quantity':'최대 수량','effect_value':'효과 수치 (종류별 단위)','slot_capacity':'소켓 용량',
    'duplicate_limit':'중복 상한','modifier_value':'보정 수치 (종류별 단위)','priority':'우선순위',
    'damage':'탄환 피해','fire_interval_sec':'발사 간격 초','projectile_speed_px_sec':'탄속 px/초','target_range_px':'사거리 px',
    'projectiles_per_shot':'발사당 탄환 수','spread_angle_deg':'탄 퍼짐 각도','burst_count':'점사 발수','burst_interval_sec':'점사 간격 초',
    'critical_chance':'치명 확률 0~1','critical_multiplier':'치명 배수','pierce_count':'관통 수','pierce_damage_retention':'관통 피해 유지 비율',
    'projectile_lifetime_sec':'탄환 수명 초',
}

def build():
    datasets = []
    sources = {}
    for path in sorted((ROOT / 'game/features').rglob('*.csv')):
        text = path.read_text(encoding='utf-8-sig').replace('\r\n', '\n')
        rows = list(csv.DictReader(io.StringIO(text)))
        numeric = {}
        for key in (rows[0] if rows else {}):
            values = []
            for i, row in enumerate(rows):
                try:
                    value = float(row[key])
                    if not -1e7 <= value <= 1e7:
                        continue
                    values.append((i, value))
                except (TypeError, ValueError):
                    continue
            if values:
                numeric[key] = values
        if not numeric:
            continue
        valid_rows = sorted({i for values in numeric.values() for i, _ in values})
        labels = {}
        for i in valid_rows:
            row = rows[i]
            label = row.get('display_name') or row.get('name') or next((v for k, v in row.items() if k.endswith('_id') and v), str(i + 3))
            if row.get('level'):
                label += ' Lv.' + row['level']
            labels[str(i)] = f'{label} (CSV {i + 2}행)'
        source = path.relative_to(ROOT).as_posix()
        sources[source] = hashlib.sha256(text.encode()).hexdigest()
        datasets.append({'id': path.stem, 'title': TITLES.get(path.stem,path.stem), 'source': source, 'labels': labels,
                         'column_labels': {key: LABELS.get(key,key) for key in numeric},
                         'columns': {key: [{'id': str(i), 'value': v} for i, v in vals] for key, vals in numeric.items()}})
    assert len({d['id'] for d in datasets}) == len(datasets)
    return {'schema': 1, 'sources': sources, 'datasets': datasets,
            'version': (ROOT / 'game/features/balance_data/data_version.txt').read_text().strip()}

result = json.dumps(build(), ensure_ascii=False, indent=2) + '\n'
if '--check' in sys.argv:
    assert OUT.read_text(encoding='utf-8') == result, 'Stale balance catalog; run scripts/build_balance_catalog.py'
else:
    OUT.write_text(result, encoding='utf-8')
print('BALANCE_CATALOG_OK')
