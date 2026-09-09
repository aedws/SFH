"""Validated locked Armor/ArmorSet CSV -> Godot definitions + Web payloads.

Sheet row 1 is the schema, row 2 documentation. Export reviewed rows to these
locked CSVs before running; this compiler never silently reads live values.
"""
from pathlib import Path
import csv
import io
import json
import math
import re
import sys
from locked_csv_payload import render_payload

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'game/features/equipment'
q = lambda value: json.dumps(value, ensure_ascii=False)


def rows(name):
    return list(csv.DictReader(io.StringIO((BASE / 'data' / (name + '.csv')).read_text(encoding='utf-8-sig'))))


def number(value, low=0, high=10000):
    n = float(value)
    assert math.isfinite(n) and low <= n <= high, f'Invalid armor number {value}'
    return n


def build():
    armor, effects = rows('armor_catalog'), rows('armor_set')
    sets = {}
    keys = set()
    for row in effects:
        sid, target, modifier, operation = (row[k] for k in ['set_id', 'target_kind', 'modifier_id', 'operation'])
        assert re.fullmatch(r'[a-z][a-z0-9_]*', sid)
        count = int(row['required_pieces'])
        assert 1 <= count <= 4 and row['source_status'] in ['provisional', 'confirmed']
        allowed = {'player': ['max_health', 'defense', 'movement_speed'], 'weapon': ['damage_multiply', 'fire_interval_multiply'], 'skill': ['damage_multiply', 'cooldown_multiply']}
        assert target in allowed and modifier in allowed[target]
        assert operation in ['add', 'multiply'] and (target == 'player' or operation == 'multiply')
        key = sid, count, target, modifier, operation
        assert key not in keys, f'Duplicate {key}'
        keys.add(key)
        amount = number(row['amount'], .0001 if operation == 'multiply' else 0)
        group = sets.setdefault(sid, {'name': row['display_name'], 'bonuses': {}})
        assert group['name'] == row['display_name']
        bonus = group['bonuses'].setdefault(count, {'required_pieces': count, 'player': {}, 'weapon': {}, 'skill': {}, 'description': ''})
        if target == 'player': bonus[target].setdefault(modifier, {})[operation] = amount
        else: bonus[target][modifier] = amount
        bonus['description'] = ' / '.join(filter(None, [bonus['description'], row['description']]))
    output = {}
    for sid, group in sets.items():
        output[BASE / 'definitions/armor_sets' / (sid + '.tres')] = '\n'.join([
            '[gd_resource type="Resource" script_class="ArmorSetDefinition" load_steps=2 format=3]', '',
            '[ext_resource type="Script" path="res://game/features/equipment/armor_set_definition.gd" id="1"]', '',
            '[resource]', 'script = ExtResource("1")', f'set_id = &{q(sid)}', f'display_name = {q(group["name"])}',
            'bonuses = Array[Dictionary](' + q(list(group['bonuses'].values())) + ')', ''])
    seen = set()
    for row in armor:
        aid, sid = row['armor_id'], row['set_id']
        assert re.fullmatch(r'[a-z][a-z0-9_]*', aid) and aid not in seen
        seen.add(aid)
        assert row['slot_id'] in ['head', 'body', 'hands', 'feet']
        assert not sid or sid in sets
        for key, low, high in [('maximum_level',1,100),('module_slot_limit',0,20),('module_cost_limit',0,100)]:
            assert number(row[key],low,high).is_integer()
        assert row['fixed_option_modifier'] in ['max_health','defense','movement_speed']
        assert row['fixed_option_operation'] in ['add','multiply']
        number(row['fixed_option_value'], .0001 if row['fixed_option_operation']=='multiply' else 0)
        ext = ['[ext_resource type="Script" path="res://game/features/equipment/armor_definition.gd" id="armor"]',
               '[ext_resource type="Script" path="res://game/features/equipment/stat_modifier.gd" id="stat"]',
               '[ext_resource type="Script" path="res://game/features/equipment/equipment_fixed_option.gd" id="option"]']
        if sid: ext.append(f'[ext_resource type="Resource" path="res://game/features/equipment/definitions/armor_sets/{sid}.tres" id="set"]')
        subs, references = [], []
        for stat in ['max_health','defense','movement_speed']:
            amount = number(row[stat + '_add'])
            if not amount: continue
            references.append(f'SubResource("{stat}")')
            subs.append(f'[sub_resource type="Resource" id="{stat}"]\nscript = ExtResource("stat")\nstat_id = &{q(stat)}\noperation = 0\namount = {amount}\n')
        subs.append('\n'.join(['[sub_resource type="Resource" id="fixed"]', 'script = ExtResource("option")',
            f'option_id = &{q(row["fixed_option_id"])}', f'display_name = {q(row["fixed_option_name"])}', 'target_kind = 0',
            f'modifier_id = &{q(row["fixed_option_modifier"])}', f'operation = {0 if row["fixed_option_operation"] == "add" else 1}',
            f'amount = {float(row["fixed_option_value"])}', '']))
        fields = ['[resource]', 'script = ExtResource("armor")', f'armor_id = &{q(aid)}', f'display_name = {q(row["display_name"])}', f'slot_id = &{q(row["slot_id"])}']
        fields += [f'{k} = {int(row[k])}' for k in ['maximum_level','module_slot_limit','module_cost_limit']]
        fields += ['stat_modifiers = [' + ', '.join(references) + ']', 'fixed_options = [SubResource("fixed")]']
        if sid: fields.append('armor_set = ExtResource("set")')
        description = row['description'] + f' · 고정 옵션 {row["fixed_option_name"]}: {row["fixed_option_value"]}'
        if sid: description += ' · ' + ' / '.join(f'{n}세트 {b["description"]}' for n,b in sets[sid]['bonuses'].items())
        fields += ['description = ' + q(description), '']
        output[BASE / 'definitions/armor' / (aid+'.tres')] = '\n\n'.join([f'[gd_resource type="Resource" script_class="EquipmentArmorDefinition" load_steps={1+len(ext)+len(subs)} format=3]', '\n'.join(ext), '\n'.join(subs), '\n'.join(fields)])
    # Same CSV payload mechanism used by the Web exporter; no remote runtime dependency.
    for name in ['armor_catalog','armor_set']:
        output[BASE / 'data' / (name+'_web_payload.tres')] = render_payload(BASE / 'data' / (name+'.csv'), 'res://game/features/equipment/data/'+name+'.csv')
    return output


if __name__ == '__main__':
    for path, text in build().items():
        if '--check' in sys.argv: assert path.exists() and path.read_text(encoding='utf-8') == text, f'Stale armor output: {path}'
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding='utf-8')
    print(f'ARMOR_CATALOG_OK armor={len(rows("armor_catalog"))} sets={len({r["set_id"] for r in rows("armor_set")})} effects={len(rows("armor_set"))}')
