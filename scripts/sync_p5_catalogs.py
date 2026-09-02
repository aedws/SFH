from __future__ import annotations

import argparse
from pathlib import Path

from locked_csv_payload import sync_payload, verify_payload


CATALOG_NAMES = (
    "utility",
    "operation_preset",
    "shop_offer",
    "recipe",
    "training_scenario",
    "codex",
)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Keep P5 hub CSV data and Web-safe embedded mirrors synchronized."
    )
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    data_root = root / "game/features/p5_hub_progression/data"
    for name in CATALOG_NAMES:
        csv_path = data_root / f"{name}.csv"
        payload_path = data_root / f"{name}_payload.tres"
        source_path = f"res://game/features/p5_hub_progression/data/{name}.csv"
        if args.check:
            verify_payload(csv_path, payload_path, source_path)
        else:
            sync_payload(csv_path, payload_path, source_path)

    print(f"P5_CATALOG_PAYLOADS_OK catalogs={len(CATALOG_NAMES)} mode={'check' if args.check else 'sync'}")


if __name__ == "__main__":
    main()
