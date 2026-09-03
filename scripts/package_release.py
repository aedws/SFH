"""Create and verify the reproducible SFH Windows release bundle metadata."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from prune_windows_releases import prune_local


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_token(path: Path, label: str) -> str:
    value = path.read_text(encoding="utf-8").strip()
    if not value:
        raise ValueError(f"{label} is empty: {path}")
    return value


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--version-file", type=Path, required=True)
    parser.add_argument("--godot-version-file", type=Path, required=True)
    parser.add_argument("--csv-version-file", type=Path, required=True)
    parser.add_argument("--csv", type=Path, action="append", required=True)
    parser.add_argument("--commit", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    input_dir = args.input_dir.resolve()
    output_dir = args.output_dir.resolve()
    executable = input_dir / "SFH.exe"
    pack = input_dir / "SFH.pck"
    for required in (executable, pack):
        if not required.is_file() or required.stat().st_size == 0:
            raise FileNotFoundError(f"missing release file: {required}")

    version = read_token(args.version_file, "release version")
    godot_version = read_token(args.godot_version_file, "Godot version")
    csv_version = read_token(args.csv_version_file, "CSV data version")
    csv_files = [path.resolve() for path in args.csv]
    for csv_file in csv_files:
        if not csv_file.is_file():
            raise FileNotFoundError(f"missing CSV input: {csv_file}")

    metadata = {
        "schema_version": 1,
        "product": "SFH",
        "release_version": version,
        "platform": "windows-x86_64",
        "desktop_save_schema_version": 1,
        "desktop_save_location": "%APPDATA%/Godot/app_userdata/SFH/",
        "build_commit": args.commit,
        "godot_version": godot_version,
        "csv_data_version": csv_version,
        "csv_sha256": {path.name: sha256(path) for path in sorted(csv_files)},
        "built_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
    }
    metadata_path = input_dir / "BUILD-METADATA.json"
    metadata_path.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    shutil.copyfile(
        Path(__file__).resolve().parents[1] / "game/distribution/WINDOWS-README.txt",
        input_dir / "WINDOWS-README.txt",
    )

    output_dir.mkdir(parents=True, exist_ok=True)
    removed = prune_local(output_dir, version)
    if removed:
        print(f"LOCAL_WINDOWS_RETENTION removed={len(removed)} keep={version}")
    archive = output_dir / f"SFH-Windows-x64-{version}.zip"
    with ZipFile(archive, "w", ZIP_DEFLATED, compresslevel=9) as bundle:
        for path in sorted(item for item in input_dir.rglob("*") if item.is_file()):
            bundle.write(path, path.relative_to(input_dir).as_posix())

    archive_hash = sha256(archive)
    checksum = output_dir / f"{archive.name}.sha256"
    checksum.write_text(f"{archive_hash}  {archive.name}\n", encoding="ascii")

    with ZipFile(archive) as bundle:
        names = set(bundle.namelist())
        required_names = {"SFH.exe", "SFH.pck", "BUILD-METADATA.json", "WINDOWS-README.txt"}
        missing = required_names - names
        if missing:
            raise RuntimeError(f"archive verification failed, missing: {sorted(missing)}")
        archived_metadata = json.loads(bundle.read("BUILD-METADATA.json"))
        if archived_metadata != metadata:
            raise RuntimeError("archive metadata differs from generated metadata")
    if sha256(archive) != archive_hash:
        raise RuntimeError("archive checksum changed during verification")

    print(
        "RELEASE_PACKAGE_OK "
        f"archive={archive.name} sha256={archive_hash} "
        f"commit={args.commit} godot={godot_version} csv={csv_version}"
    )


if __name__ == "__main__":
    main()
