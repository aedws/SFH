"""Verify the selected CC0 bytes, provenance and both export notices."""
from pathlib import Path
import hashlib
import re

root = Path(__file__).resolve().parents[1]
audio = root / 'game/assets/audio'
source = (audio / 'SOURCE.md').read_text(encoding='utf-8')
rows = re.findall(r'\| (\w+\.ogg) \|[^\n]+\| ([0-9a-f]{64}) \|', source)
assert len(rows) == 6, 'Six file hashes must be recorded'
actual = {path.name: path for path in audio.rglob('*.ogg')}
assert set(actual) == {name for name, _ in rows}, 'Unrecorded or missing audio file'
for name, expected in rows:
    assert hashlib.sha256(actual[name].read_bytes()).hexdigest() == expected, name
    assert actual[name].stat().st_size < 200_000, name
for folder in ('kenney_scifi', 'kenney_impact'):
    license_text = (audio / folder / 'LICENSE.txt').read_text(encoding='utf-8-sig')
    assert 'CC0' in license_text and 'creativecommons.org/publicdomain/zero/1.0/' in license_text
presets = (root / 'export_presets.cfg').read_text(encoding='utf-8')
filters = re.findall(r'^include_filter="([^"]+)"', presets, re.M)
assert len(filters) == 2
for value in filters:
    assert 'game/assets/audio/*/LICENSE.txt' in value and 'game/assets/audio/SOURCE.md' in value
print(f'COMBAT_AUDIO_ASSETS_OK files=6 bytes={sum(p.stat().st_size for p in actual.values())} CC0_sha256 exports=2')
