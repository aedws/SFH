"""확정 CSV와 Web-safe Godot Resource 미러를 동기화한다."""

from __future__ import annotations

import json
import pathlib


def render_payload(csv_path: pathlib.Path, source_path: str) -> str:
    csv_text = csv_path.read_text(encoding="utf-8-sig").replace("\r\n", "\n")
    if csv_text and not csv_text.endswith("\n"):
        csv_text += "\n"
    encoded_text = json.dumps(csv_text, ensure_ascii=False)
    return (
        '[gd_resource type="Resource" script_class="EmbeddedCsvPayload" '
        'load_steps=2 format=3]\n\n'
        '[ext_resource type="Script" '
        'path="res://game/features/balance_data/embedded_csv_payload.gd" '
        'id="1_payload"]\n\n'
        '[resource]\n'
        'script = ExtResource("1_payload")\n'
        f'source_path = {json.dumps(source_path, ensure_ascii=False)}\n'
        f'csv_text = {encoded_text}\n'
    )


def sync_payload(csv_path: pathlib.Path, payload_path: pathlib.Path, source_path: str) -> None:
    payload_path.parent.mkdir(parents=True, exist_ok=True)
    payload_path.write_text(render_payload(csv_path, source_path), encoding="utf-8", newline="\n")


def verify_payload(csv_path: pathlib.Path, payload_path: pathlib.Path, source_path: str) -> None:
    expected = render_payload(csv_path, source_path)
    actual = payload_path.read_text(encoding="utf-8")
    if actual != expected:
        raise ValueError(f"Web 내장 CSV 미러가 원본과 다릅니다: {payload_path}")
