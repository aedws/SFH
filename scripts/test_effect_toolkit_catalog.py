"""Resource labels are not contracts: follow the root's actual innate skill binding."""
from build_effect_toolkit import ROOT, build, innate_resource_block

for path in sorted((ROOT / 'game/features/equipment/definitions/weapons').glob('*.tres')):
    text = path.read_text(encoding='utf-8')
    section, block = innate_resource_block(text, str(path))
    old_id = section.split('id="')[1].rstrip('"')
    renamed = text.replace(f'"{old_id}"', '"FutureEffect_42"')
    renamed_section, renamed_block = innate_resource_block(renamed, str(path))
    assert renamed_section.endswith('id="FutureEffect_42"')
    assert block.split('\n', 1)[1] == renamed_block.split('\n', 1)[1]
    for invalid in [renamed.replace('innate_skill = ', 'unused = '),
                    renamed.replace('SubResource("FutureEffect_42")', 'SubResource("Missing")')]:
        try:
            innate_resource_block(invalid, str(path))
        except ValueError:
            pass
        else:
            raise AssertionError('Broken reference must fail explicitly')

catalog = build()
for field in catalog['fields']:
    if field['id'].startswith('weapon.innate_'):
        assert len(field['targets']) == 8
        for target in field['targets']:
            assert len(target['bindings']) == 2
print('EFFECT_TOOLKIT_RESOURCE_OK weapons_8 renamed_labels missing_reference paired_bindings')
