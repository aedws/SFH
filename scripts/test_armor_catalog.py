"""Compiler failure cases; invalid Sheet data must never generate partial assets."""
import copy
from unittest.mock import patch
import sync_armor_catalog as compiler

original = {name: compiler.rows(name) for name in ['armor_catalog', 'armor_set']}
compiler.build()
cases = [
    ('armor_catalog', 2, 'armor_id', '../outside'),
    ('armor_catalog', 2, 'set_id', 'missing'),
    ('armor_catalog', 2, 'slot_id', 'unknown'),
    ('armor_catalog', 2, 'maximum_level', '1.5'),
    ('armor_catalog', 2, 'max_health_add', 'nan'),
    ('armor_set', 0, 'target_kind', 'eval'),
    ('armor_set', 0, 'amount', '0'),
    ('armor_set', 0, 'required_pieces', '5'),
    ('armor_set', 0, 'modifier_id', 'unknown'),
    ('armor_set', 0, 'source_status', 'maybe'),
]
for name, index, key, value in cases:
    data = copy.deepcopy(original)
    data[name][index][key] = value
    with patch.object(compiler, 'rows', side_effect=lambda name: data[name]):
        try: compiler.build()
        except (AssertionError, ValueError): pass
        else: raise AssertionError(f'Accepted invalid input {name} {key} {value}')
for name in original:
    data = copy.deepcopy(original)
    data[name].append(data[name][0].copy())
    with patch.object(compiler, 'rows', side_effect=lambda name: data[name]):
        try: compiler.build()
        except AssertionError: pass
        else: raise AssertionError('Accepted duplicate ' + name)
print('ARMOR_COMPILER_TEST_OK invalid_12 no_partial_writes')
