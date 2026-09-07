"""Gameplay tables must stay raw CSV, never Godot Translation resources."""
from pathlib import Path
import configparser


def validate(root: Path) -> int:
    tables = sorted((root / "game/features").glob("*/data/*.csv"))
    assert tables, "No gameplay tables found"
    for table in tables:
        policy = configparser.ConfigParser()
        policy.read(str(table) + ".import", encoding="utf-8")
        assert policy.get("remap", "importer", fallback="") == '"keep"', (
            f"{table.relative_to(root)} needs versioned importer=keep; "
            "translation imports can break serialized config dependencies"
        )
    return len(tables)


if __name__ == "__main__":
    print(f"BALANCE_CSV_IMPORT_OK {validate(Path(__file__).resolve().parents[1])} raw_tables")
