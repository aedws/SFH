"""Fail closed when a new runtime UI source escapes the all-surface review register."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
data = json.loads((ROOT / "game/tests/support/game_ui_audit_sources.json").read_text(encoding="utf-8"))
pattern = re.compile(r"extends (?:Control|CanvasLayer|\w*Container|\w*Dialog|\w*Button|\w*Label)|\b(?:Label|RichTextLabel|Button|OptionButton|CheckBox|TabContainer|ProgressBar)\.new\(|draw_string\(")
found = {p.relative_to(ROOT).as_posix() for p in (ROOT / "game/features").rglob("*.gd") if pattern.search(p.read_text(encoding="utf-8-sig"))}
registered = set(data["sources"])
assert found == registered, f"UI review register changed: new={sorted(found-registered)} stale={sorted(registered-found)}"
for source in data["sources"] + data["scene_and_world_review"]:
    assert (ROOT / source).is_file(), f"Missing reviewed source: {source}"
assert (ROOT / "docs/quality/game-ui-rematch.md").is_file()
print(f"GAME_UI_AUDIT_OK runtime_sources={len(found)} scene_world_entries={len(data['scene_and_world_review'])}")
