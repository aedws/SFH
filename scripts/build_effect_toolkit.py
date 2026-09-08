"""Code-grounded authoring catalog. Read-only: never modifies gameplay values."""
import csv
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/assets/effect-toolkit.json'


def build():
    sources, fields = {}, {}

    def read(path):
        text = (ROOT / path).read_text(encoding='utf-8-sig').replace('\r\n', '\n')
        sources[path] = hashlib.sha256(text.encode()).hexdigest()
        return text

    def add(kind, key, label, unit, bounds, target, binding, effect, choices=None):
        fid = kind + '.' + key
        field = fields.setdefault(fid, dict(id=fid, kind=kind, label=label, unit=unit,
            minimum=bounds[0], maximum=bounds[1], integer=bounds[2], choices=choices,
            effect=effect, targets=[]))
        field['targets'].append(dict(**target, bindings=[binding]))

    def resource(kind, path, identity, name, section, key, label, unit, bounds, effect):
        text = read(path)
        blocks = re.split(r'(?m)^\[', text)
        block = next(b for b in blocks if b.startswith(section + ']'))
        match = re.search(r'^' + re.escape(key) + r' = (-?[\d.]+)$', block, re.M)
        if not match:
            raise ValueError(f'Missing resource field {path} [{section}] {key}')
        value = float(match[1])
        add(kind, key if section == 'resource' else section.split('id="')[-1].rstrip('"') + '.' + key,
            label, unit, bounds, dict(id=identity, name=name, current=value),
            dict(type='resource', path=path, section=section, field=key), effect)

    skill_root = 'game/features/combat_skills/'
    for identity, name, effect_section in [('blink','점멸','BlinkEffect'),('arc_dash','아크 질주','ArcDashEffect'),
                                         ('magnetic_field','원형 자기장','MagneticFieldEffect'),('speed_boost','기동 가속','SpeedBoostEffect')]:
        path = skill_root + 'definitions/' + identity + '.tres'
        for key,label,unit,lo,hi,integer in [('cooldown_seconds','재사용 대기시간','초',.1,120,False),
                ('energy_cost','AP 소모','AP',0,1000,False),('maximum_charges','최대 충전','회',1,10,True),
                ('charge_recovery_seconds','충전 회복 시간','초',.1,120,False)]:
            resource('skill',path,identity,name,'resource',key,label,unit,(lo,hi,integer),'스킬 입력 / 충전 1회 소비')
        if identity in ['blink','arc_dash']:
            rows=[(effect_section,'distance','이동 거리','px',32,1200,False),('PathDamagePolicy','damage','경로 피해','피해',0,10000,False),
                  ('PathDamagePolicy','half_width','경로 반폭','px',1,240,False),('PathDamagePolicy','maximum_targets','최대 피격 대상','명',1,64,True)]
            mechanism='이동 방향 경로 / 벽에 막힘 / 한 발동에서 대상당 1회'
        elif identity=='magnetic_field':
            rows=[(effect_section,'radius','원형 반경','px',32,1000,False),(effect_section,'tick_damage','틱당 피해','피해',0,10000,False),
                  (effect_section,'duration_seconds','지속 시간','초',.1,8,False),(effect_section,'tick_interval_seconds','피해 간격','초',.1,2,False)]
            mechanism='플레이어를 따라가는 원형 지속 피해 / 최초 틱 포함 / 성장 보정은 기존 스킬 계약'
        else:
            rows=[(effect_section,'speed_multiplier','이동 속도 배율','배',1.01,5,False),(effect_section,'duration_seconds','지속 시간','초',.1,60,False)]
            mechanism='본인 이동 속도 / 재사용 시 기존 버프 교체 / 종료 시 원복'
        for section,key,label,unit,lo,hi,integer in rows:
            resource('skill',path,identity,name,f'sub_resource type="Resource" id="{section}"',key,label,unit,(lo,hi,integer),mechanism)

    def table(kind,path,id_key,columns,predicate=lambda r:True):
        for row in csv.DictReader(read(path).splitlines()):
            if not predicate(row): continue
            for key,label,unit,lo,hi,integer,choices in columns:
                if row.get(key,'')=='': continue
                value = row[key] if choices else float(row[key])
                add(kind,key,label,unit,(lo,hi,integer),dict(id=row[id_key],name=row['display_name'],current=value),
                    dict(type='csv',path=path,selector={id_key:row[id_key]},field=key),
                    '해당 정의의 기존 전투/스탯 계약. ID·설명만 바꿔 새 행동을 생성하지 않습니다.',choices)
    table('weapon','game/features/weapon_balance/data/weapon_balance.csv','weapon_id',[
        ('damage','탄환 기본 피해','피해',0,10000,False,None),('fire_interval_sec','발사 간격','초',.05,60,False,None),
        ('target_range_px','탐지 사거리','px',32,3000,False,None),('critical_chance','치명 확률','0~1',0,1,False,None),
        ('critical_multiplier','치명 배율','배',1,10,False,None),('burst_count','점사 발수','발',1,32,True,None),
        ('projectiles_per_shot','발사당 탄환','발',1,32,True,None),('pierce_count','추가 관통 수','명',0,32,True,None)])
    table('weapon','game/features/equipment/data/equipment_identity.csv','definition_id',[
        ('innate_trigger_hits','고유 기능 발동 명중 수','회',1,100,True,None),('innate_fixed_damage','고유 고정 피해','피해',.01,10000,False,None),
        ('innate_effect_kind','명중 고유 효과','종류',0,0,False,['single_target','electric_area']),
        ('innate_effect_radius','고유 효과 반경','px',0,1000,False,None),('innate_maximum_targets','고유 최대 대상','명',1,32,True,None)],lambda r:r['equipment_kind']=='weapon')
    table('character','game/features/character_selection/data/character_catalog.csv','character_id',[
        ('max_health_add','패시브 최대 체력 가산','HP',0,10000,False,None),('defense_add','패시브 방어 가산','방어',0,1000,False,None),
        ('movement_speed_multiplier','패시브 이동 속도 배율','배',.1,5,False,None)])
    # Identity CSV is an audited mirror; .tres is the actual runtime definition.
    identity_keys = {'innate_trigger_hits':'trigger_every_hits','innate_fixed_damage':'fixed_damage',
                     'innate_effect_kind':'effect_kind','innate_effect_radius':'effect_radius',
                     'innate_maximum_targets':'maximum_targets'}
    for csv_key, resource_key in identity_keys.items():
        field = fields['weapon.' + csv_key]
        field['effect'] = '탄환 명중 횟수마다 발동 / 고정 피해는 내·외부 레벨과 독립 / CSV와 런타임 Resource를 함께 변경'
        for target in field['targets']:
            path = f"game/features/equipment/definitions/weapons/{target['id']}.tres"
            text = read(path)
            block = next(b for b in re.split(r'(?m)^\[',text) if b.startswith('sub_resource type="Resource" id="InnateSkill"]'))
            match = re.search(r'^'+resource_key+r' = ([\d.]+)$',block,re.M)
            defaults = read('game/features/equipment/weapon_innate_skill_definition.gd')
            if match:
                actual = float(match[1])
            else:
                default = re.search(r'var '+resource_key+r': [\w]+ = ([\w.]+)',defaults)[1]
                actual = 0 if default=='EffectKind.SINGLE_TARGET' else float(default)
            expected = ['single_target','electric_area'].index(target['current']) if csv_key=='innate_effect_kind' else target['current']
            assert actual == expected, f'Identity CSV / resource conflict: {path} {csv_key}'
            binding = dict(type='resource',path=path,section='sub_resource type="Resource" id="InnateSkill"',field=resource_key)
            if csv_key=='innate_effect_kind': binding['enum_values'] = {'single_target':0,'electric_area':1}
            target['bindings'].append(binding)
    for identity,name,section,label,unit in [('ballistic_core','탄도 연산 코어','DamageModifier','기본 피해 가산','피해'),
            ('vitality_matrix','생체 강화 매트릭스','HealthModifier','최대 체력 가산','HP'),
            ('mobility_chip','기동 보조 칩','SpeedModifier','이동 속도 가산','px/초'),
            ('armor_plate','복합 장갑판','DefenseModifier','방어 가산','방어')]:
        resource('module',f'game/features/equipment/definitions/modules/{identity}.tres',identity,name,
            f'sub_resource type="Resource" id="{section}"','amount',label,unit,(0,10000,False),
            '장착한 동안 가산 / 해제 시 제거 / 강화 추가분은 Upgrade 별도 / candidate ID는 구현된 특수 효과가 아님')
    # Includes runtime mechanism code in freshness: behavioral changes must invalidate drafts too.
    for path in ['game/features/weapons/weapon_innate_skill_system.gd','game/features/combat_skills/effects/path_damage_policy.gd',
                 'game/features/combat_skills/effects/persistent_magnetic_field.gd','game/features/character_selection/character_definition.gd',
                 'game/features/equipment/stat_modifier.gd']:
        read(path)
    fingerprint=hashlib.sha256(json.dumps(sources,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    return dict(schema=1,version=(ROOT/'game/features/balance_data/data_version.txt').read_text().strip(),
        fingerprint=fingerprint,sources=sources,fields=list(fields.values()))


if __name__=='__main__':
    result=json.dumps(build(),ensure_ascii=False,indent=2)+'\n'
    if '--check' in sys.argv:
        assert OUT.read_text(encoding='utf-8')==result,'Stale effect toolkit; run scripts/build_effect_toolkit.py'
    else: OUT.write_text(result,encoding='utf-8')
    print('EFFECT_TOOLKIT_CATALOG_OK')
