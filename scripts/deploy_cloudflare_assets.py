"""Upload verified SFH build artifacts to immutable Cloudflare R2 keys."""

from __future__ import annotations

import argparse
import hashlib
import json
import mimetypes
import os
import re
import subprocess
import tempfile
import zipfile
from pathlib import Path


WRANGLER_VERSION = "4.127.1"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def content_type(path: Path) -> str:
    overrides = {
        ".html": "text/html; charset=utf-8",
        ".js": "text/javascript; charset=utf-8",
        ".json": "application/json; charset=utf-8",
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
        ".sha256": "text/plain; charset=utf-8",
        ".zip": "application/zip",
    }
    return overrides.get(path.suffix.lower(), mimetypes.guess_type(path.name)[0] or "application/octet-stream")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bucket", default="sfh-game-artifacts")
    parser.add_argument("--runtime-prefix", default="game/releases")
    parser.add_argument("--download-prefix", default="downloads")
    parser.add_argument("--game-dir", type=Path, required=True)
    parser.add_argument("--windows-dir", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def normalized_prefix(value: str, label: str) -> str:
    prefix = value.strip("/")
    if not prefix or "//" in prefix or any(part in {".", ".."} for part in prefix.split("/")):
        raise ValueError(f"invalid {label}: {value}")
    return prefix


def add_entry(entries: list[dict[str, str]], source: Path, key: str, cache_control: str) -> None:
    if not source.is_file() or source.stat().st_size == 0:
        raise FileNotFoundError(f"missing deploy artifact: {source}")
    entries.append(
        {
            "source": str(source.resolve()),
            "key": key,
            "content_type": content_type(source),
            "cache_control": cache_control,
            "sha256": sha256(source),
            "size": str(source.stat().st_size),
        }
    )


def verify_release(game_dir: Path, windows_dir: Path, commit: str, version: str) -> None:
    if not re.fullmatch(r"[0-9a-f]{40}", commit) or not re.fullmatch(r"v[0-9A-Za-z._-]+", version):
        raise ValueError("Invalid release identity")
    proof = json.loads((game_dir / "sfh-ci-proof.json").read_text(encoding="utf-8"))
    if proof.get("commit") != commit:
        raise ValueError("Web commit differs from release")
    archive = windows_dir / f"SFH-Windows-x64-{version}.zip"
    checksum = archive.with_suffix(".zip.sha256").read_text(encoding="utf-8").split()
    if checksum != [sha256(archive), archive.name]:
        raise ValueError("Windows checksum differs from packaged release")
    with zipfile.ZipFile(archive) as bundle:
        metadata = json.loads(bundle.read("BUILD-METADATA.json"))
        if metadata.get("build_commit") != commit or metadata.get("release_version") != version:
            raise ValueError("Windows metadata differs from Web release")


def verify_remote(bucket: str, entries: list[dict]) -> None:
    # Before changing live Worker vars, read back every candidate object from R2.
    # This is an integrity gate, not a claim of browser gameplay E2E.
    with tempfile.TemporaryDirectory(prefix="sfh-r2-verify-") as directory:
        target = Path(directory) / "object"
        for entry in entries:
            subprocess.run(["wrangler", "r2", "object", "get", f"{bucket}/{entry['key']}",
                            "--remote", "--file", str(target)], check=True)
            if str(target.stat().st_size) != str(entry["size"]) or sha256(target) != entry["sha256"]:
                raise ValueError(f"R2 candidate integrity mismatch: {entry['key']}")
            target.unlink()
    print(f"CLOUDFLARE_CANDIDATE_VERIFIED objects={len(entries)}")


def main() -> None:
    args = parse_args()
    game_dir = args.game_dir.resolve()
    windows_dir = args.windows_dir.resolve()
    verify_release(game_dir, windows_dir, args.commit, args.version)
    required_game = [game_dir / name for name in ("index.html", "index.wasm", "index.pck")]
    for path in required_game:
        if not path.is_file():
            raise FileNotFoundError(f"missing required Web export: {path}")

    entries: list[dict[str, str]] = []
    runtime_prefix = normalized_prefix(args.runtime_prefix, "runtime prefix")
    download_prefix = normalized_prefix(args.download_prefix, "download prefix")
    if runtime_prefix == download_prefix or runtime_prefix.startswith(f"{download_prefix}/") or download_prefix.startswith(f"{runtime_prefix}/"):
        raise ValueError("runtime and download prefixes must be disjoint")
    game_prefix = f"{runtime_prefix}/{args.commit}"
    for path in sorted(item for item in game_dir.rglob("*") if item.is_file()):
        relative = path.relative_to(game_dir).as_posix()
        add_entry(entries, path, f"{game_prefix}/{relative}", "public, max-age=31536000, immutable")

    # The public version URL stays stable; the Worker selects this commit's
    # directory atomically with Web. Never overwrite the active Windows ZIP.
    release_download_prefix = f"{download_prefix}/releases/{args.commit}"
    archive_name = f"SFH-Windows-x64-{args.version}.zip"
    for name in (archive_name, f"{archive_name}.sha256"):
        add_entry(
            entries,
            windows_dir / name,
            f"{release_download_prefix}/{args.version}/{name}",
            "public, max-age=31536000, immutable",
        )

    manifest = {
        "schema_version": 1,
        "bucket": args.bucket,
        "release_version": args.version,
        "build_commit": args.commit,
        "game_prefix": game_prefix,
        "download_prefix": release_download_prefix,
        "wrangler_version": WRANGLER_VERSION,
        "objects": [{key: value for key, value in entry.items() if key != "source"} for entry in entries],
    }
    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    args.manifest.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    if args.dry_run:
        print(f"CLOUDFLARE_ASSET_PLAN_OK objects={len(entries)} prefix={game_prefix}")
        return
    if not os.environ.get("CLOUDFLARE_API_TOKEN") or not os.environ.get("CLOUDFLARE_ACCOUNT_ID"):
        raise RuntimeError("Cloudflare credentials are required for remote upload")

    for entry in entries:
        command = [
            "wrangler",
            "r2",
            "object",
            "put",
            f"{args.bucket}/{entry['key']}",
            "--file",
            entry["source"],
            "--content-type",
            entry["content_type"],
            "--cache-control",
            entry["cache_control"],
            "--remote",
        ]
        subprocess.run(command, check=True)
    verify_remote(args.bucket, entries)
    subprocess.run(
        [
            "wrangler",
            "r2",
            "object",
            "put",
            f"{args.bucket}/{game_prefix}/asset-manifest.json",
            "--file",
            str(args.manifest.resolve()),
            "--content-type",
            "application/json; charset=utf-8",
            "--cache-control",
            "public, max-age=31536000, immutable",
            "--remote",
        ],
        check=True,
    )
    print(f"CLOUDFLARE_ASSET_UPLOAD_OK objects={len(entries) + 1} prefix={game_prefix}")


if __name__ == "__main__":
    main()
