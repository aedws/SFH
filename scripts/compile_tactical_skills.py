"""Compile locked tactical patterns into Godot resources and discovery catalogs.

Only generated IDs in tactical_patterns.csv are replaced; hand-authored skills survive.
"""
import argparse
import csv
import io
import json
import math
import re
import urllib.parse
import urllib.request
from pathlib import Path
from locked_csv_payload import sync_payload

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "game/features/combat_skills"
BOOLEAN = {"follow_player", "anchor_on_target"}
TEXT = {"shape", "status_id", "consume_status_id"}
META = {"skill_id", "display_name", "slot", "cooldown", "energy", "description"}

def read(path):
    return list(csv.DictReader(path.open(encoding="utf-8-sig")))

def compile_catalog(rows=None, skill_overrides=None):
    rows = read(BASE / "data/tactical_patterns.csv") if rows is None else rows
    metadata = {r['skill_id']:r for r in read(BASE / 'data/skill_catalog.csv')}
    for sid, values in (skill_overrides or {}).items(): metadata[sid] = {**metadata.get(sid,{}), **values}
    ids = [row["skill_id"] for row in rows]
    if len(ids) != len(set(ids)) or len(ids) < 36:
        raise ValueError("Need 36 unique additional skill IDs")
    output = {}
    for row in rows:
        sid = row["skill_id"]
        if not re.fullmatch(r'[a-z][a-z0-9_]*', sid): raise ValueError("Invalid ID")
        meta = metadata.get(sid, {})
        charges = int(meta.get('maximum_charges','1'))
        recovery = float(meta.get('charge_recovery_seconds',row['cooldown']))
        if not 1 <= charges <= 10 or not .1 <= recovery <= 120: raise ValueError(f'{sid}: charge policy')
        tags = [tag for tag in meta.get('required_combat_tags','').split('|') if tag]
        if any(not re.fullmatch(r'[a-z][a-z0-9_]*',tag) for tag in tags): raise ValueError(f'{sid}: tags')
        rendered_tags = ', '.join('&'+json.dumps(tag) for tag in tags)
        if row['shape'] not in {'circle','ring','cone','line','chain','single','self'}: raise ValueError(f'{sid}: shape')
        for key, low, high in [('slot',0,2),('pulses',1,40),('maximum_targets',1,64)]:
            number=float(row[key])
            if not number.is_integer() or not low <= number <= high: raise ValueError(f'{sid}: {key}')
        for key, low, high in [('radius',1,2400),('interval',.1,10),('delay',0,10),('status_duration',0,30),('combo_multiplier',1,10),('buff_duration',.1,30),('speed_multiplier',.01,5),('cooldown',.1,120),('energy',0,1000),('damage',0,10000),('width',1,2400),('angle_degrees',1,360),('chain_range',1,2400),('defense_add',0,1000)]:
            if not low <= float(row[key]) <= high: raise ValueError(f'{sid}: {key}')
        if not 0 <= float(row['inner_radius']) < float(row['radius']): raise ValueError(f'{sid}: inner radius')
        for key in ('status_id','consume_status_id'):
            if row[key] not in {'','shock','slow','stun','vulnerable'}: raise ValueError(f'{sid}: {key}')
        props = []
        for key, value in row.items():
            if key in META: continue
            if key in BOOLEAN:
                if value not in {"TRUE", "FALSE"}: raise ValueError(key)
                rendered = value.lower()
            elif key in TEXT: rendered = json.dumps(value)
            else:
                if not math.isfinite(float(value)): raise ValueError(key)
                rendered = value
            props.append(f"{key} = {rendered}")
        mode = "densest" if row["anchor_on_target"] == "TRUE" else "highest_health" if row["shape"] == "single" else "direction" if row["shape"] in {"line", "cone"} else "self"
        output[BASE / f"definitions/{sid}.tres"] = '\n'.join([
            '[gd_resource type="Resource" script_class="CombatSkillDefinition" load_steps=4 format=3]', '',
            '[ext_resource type="Script" path="res://game/features/combat_skills/combat_skill_definition.gd" id="1"]',
            '[ext_resource type="Script" path="res://game/features/combat_skills/effects/tactical_pattern_effect.gd" id="2"]', '',
            '[sub_resource type="Resource" id="Effect"]', 'script = ExtResource("2")', *props, '',
            '[resource]', 'script = ExtResource("1")', f'skill_id = &"{sid}"',
            'display_name = ' + json.dumps(row['display_name'], ensure_ascii=False),
            'description = ' + json.dumps(row['description'], ensure_ascii=False),
            f'input_action = &"combat_skill_{int(row["slot"])+1}"', f'input_label = "{int(row["slot"])+1}"',
            f'targeting_mode = "{mode}"', f'targeting_range = {row["radius"]}',
            f'required_combat_tags = [{rendered_tags}]',
            f'cooldown_seconds = {row["cooldown"]}', f'energy_cost = {row["energy"]}',
            f'maximum_charges = {charges}', f'charge_recovery_seconds = {recovery:g}', 'effect = SubResource("Effect")', ''])
    for relative, kind in [("combat_skills/data/skill_catalog.csv", "catalog"), ("loadout_investment/data/skill_investment.csv", "investment")]:
        path = ROOT / "game/features" / relative
        original = read(path)
        by_id = {r.get('skill_id',r.get('item_id')):r for r in original}
        result = [row for row in original if row.get("skill_id", row.get("item_id")) not in ids]
        fields = list(original[0])
        for row in rows:
            sid = row["skill_id"]
            entry = {field:'' for field in fields}
            entry.update(by_id.get(sid, {}))
            meta = metadata.get(sid,{})
            if kind == "catalog":
                entry.update({key:meta[key] for key in fields if key in meta})
                entry.update(skill_id=sid,display_name=row['display_name'],target_slot_index=row['slot'],targeting_mode='direction' if row['shape'] in {'line','cone'} else 'cluster' if row['anchor_on_target']=='TRUE' else 'single' if row['shape']=='single' else 'self',cooldown_seconds=row['cooldown'],energy_cost=row['energy'],maximum_charges=meta.get('maximum_charges','1'),charge_recovery_seconds=meta.get('charge_recovery_seconds',row['cooldown']))
                for key,value in dict(grade='3',region_tags='global',acquisition_mode='default',runtime_enabled='TRUE',planner_note='임시 전술 스킬 · '+row['description']).items():
                    if not entry.get(key): entry[key]=value
            else:
                entry.update(item_id=sid,display_name=row['display_name'],slot_id='skill_'+row['slot'],resource_path=f'res://game/features/combat_skills/definitions/{sid}.tres')
                for key,default in dict(run_investment_price='0',default_owned='TRUE',required_unlock_id='',source_status='temporary').items():
                    source_key='investment_source_status' if key=='source_status' else key
                    entry[key]=str(meta.get(source_key,entry.get(key) or default))
            result.append(entry)
        stream = io.StringIO()
        writer = csv.DictWriter(stream, fieldnames=fields, lineterminator='\n')
        writer.writeheader(); writer.writerows(result)
        output[path] = stream.getvalue()
    return output

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--from-sheet', action='store_true', help='Lock active SkillPattern rows; Skill owns slot, AP and cooldown values.')
    parser.add_argument('--spreadsheet-id', default='1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM')
    args = parser.parse_args()
    rows = None
    skills = None
    if args.from_sheet:
        if args.check: raise ValueError('--check does not fetch or change data')
        def fetch(tab):
            url = f'https://docs.google.com/spreadsheets/d/{args.spreadsheet_id}/gviz/tq?' + urllib.parse.urlencode({'tqx':'out:csv','headers':'1','sheet':tab})
            with urllib.request.urlopen(url, timeout=30) as response:
                return list(csv.DictReader(io.StringIO(response.read().decode('utf-8-sig'))))
        skills = {r['skill_id']:r for r in fetch('Skill') if r.get('runtime_enabled','').upper()=='TRUE'}
        fields = list(read(BASE / 'data/tactical_patterns.csv')[0])
        rows = []
        for source in fetch('SkillPattern'):
            if source.get('skill_id') not in skills: continue
            row = {key:source[key] for key in fields}
            skill = skills[row['skill_id']]
            row.update(display_name=skill['display_name'], slot=skill['target_slot_index'], cooldown=skill['cooldown_seconds'], energy=skill['energy_cost'])
            for key in fields:
                if key in BOOLEAN: row[key] = row[key].upper()
                elif key not in TEXT | {'skill_id','display_name','description'}: row[key] = format(float(row[key]), '.12g')
            rows.append(row)
    outputs = compile_catalog(rows, skills)
    if rows is not None:
        stream = io.StringIO()
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]), lineterminator='\n')
        writer.writeheader(); writer.writerows(rows)
        outputs[BASE / 'data/tactical_patterns.csv'] = stream.getvalue()
    for path, text in outputs.items():
        if args.check:
            if not path.exists() or path.read_text(encoding='utf-8') != text: raise ValueError(f'Stale: {path.relative_to(ROOT)}')
        else: path.write_text(text, encoding='utf-8', newline='\n')
    if not args.check:
        for relative in ['combat_skills/data/skill_catalog', 'loadout_investment/data/skill_investment', 'character_selection/data/character_catalog']:
            source = ROOT / 'game/features' / (relative+'.csv')
            sync_payload(source, source.with_name(source.stem+'_payload.tres'), 'res://game/features/'+relative+'.csv')
    print('TACTICAL_SKILLS_COMPILED total=40 additional=36')

if __name__ == '__main__': main()
