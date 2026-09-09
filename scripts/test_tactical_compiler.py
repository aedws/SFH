"""Authoring metadata and future columns must not depend on CSV column positions."""
from copy import deepcopy
from compile_tactical_skills import BASE, read, compile_catalog

rows = read(BASE / 'data/tactical_patterns.csv')
outputs = compile_catalog(rows, {'arc_link': {'maximum_charges':'2','charge_recovery_seconds':'3','required_combat_tags':'electric','run_investment_price':'55','default_owned':'FALSE'}})
resource = outputs[BASE / 'definitions/arc_link.tres']
assert 'maximum_charges = 2' in resource and 'charge_recovery_seconds = 3' in resource
assert 'required_combat_tags = [&"electric"]' in resource
investment = next(text for path,text in outputs.items() if path.name=='skill_investment.csv')
assert 'arc_link.tres,55,FALSE,' in investment
for key, value in [('pulses','0'),('interval','0'),('radius','nan'),('shape','unknown'),('skill_id','../escape')]:
    invalid=deepcopy(rows); invalid[0][key]=value
    try: compile_catalog(invalid)
    except (ValueError,TypeError): pass
    else: raise AssertionError(key)
print('TACTICAL_COMPILER_OK metadata_charges_tags_investment bounded_invalid_fields')
