"""Run-scoped, hash-verified handoff on ONE trusted self-hosted runner.

The sibling of GITHUB_WORKSPACE survives checkout cleaning and is mounted in
Godot containers as well as host jobs. This is transport, not a backup/cache.
Never reuse another run/attempt, fall back to GitHub artifacts, or accept links.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import tempfile

from ci_budget import git

SURFACES = {"game-web", "wiki-site", "windows"}
STORE = ".sfh-build-store"


def no_links(path: Path) -> None:
    for part in (path, *path.parents):
        if part.is_symlink():
            raise ValueError(f"Symlink is not a build transport path: {part}")


def hashes(directory: Path) -> dict:
    no_links(directory)
    if not directory.is_dir():
        raise ValueError(f"Missing payload directory: {directory}")
    result = {}
    for path in sorted(directory.rglob("*")):
        no_links(path)
        if path.is_dir():
            continue
        if not path.is_file():
            raise ValueError("Only regular build files are allowed")
        digest = hashlib.sha256()
        with path.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(chunk)
        result[path.relative_to(directory).as_posix()] = {
            "sha256": digest.hexdigest(), "size": path.stat().st_size,
        }
    if not result:
        raise ValueError("Empty build payload")
    return result


def context() -> dict:
    values = {key: os.environ[key] for key in (
        "GITHUB_REPOSITORY", "GITHUB_RUN_ID", "GITHUB_RUN_ATTEMPT", "GITHUB_SHA",
    )}
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", values["GITHUB_REPOSITORY"]):
        raise ValueError("Invalid repository")
    if not all(re.fullmatch(r"[1-9][0-9]*", values[key]) for key in ("GITHUB_RUN_ID", "GITHUB_RUN_ATTEMPT")):
        raise ValueError("Invalid run identity")
    if not re.fullmatch(r"[0-9a-f]{40}", values["GITHUB_SHA"]) or git("rev-parse", "HEAD") != values["GITHUB_SHA"]:
        raise ValueError("Checkout differs from workflow commit")
    return {"schema": 1, **values, "tree": git("rev-parse", "HEAD^{tree}")}


def run_root(identity: dict) -> Path:
    workspace = Path(os.environ["GITHUB_WORKSPACE"]).absolute()
    no_links(workspace)
    repository = hashlib.sha256(identity["GITHUB_REPOSITORY"].encode()).hexdigest()[:24]
    root = workspace.parent / STORE / repository / identity["GITHUB_RUN_ID"] / identity["GITHUB_RUN_ATTEMPT"]
    no_links(root)
    return root


def bundle(root: Path, surface: str) -> Path:
    if surface not in SURFACES:
        raise ValueError("Unknown build surface")
    target = root / surface
    no_links(target)
    return target


def publish(root: Path, identity: dict, surface: str, source: Path) -> None:
    target = bundle(root, surface)
    if target.exists():
        raise ValueError("Run payload already exists; rerun the entire workflow")
    expected = hashes(source)
    root.mkdir(parents=True, exist_ok=True)
    staging = Path(tempfile.mkdtemp(prefix="staging-", dir=root))
    try:
        shutil.copytree(source, staging / "payload")
        if hashes(staging / "payload") != expected:
            raise ValueError("Build changed during publishing")
        proof = {"identity": identity, "surface": surface, "files": expected}
        (staging / "manifest.json").write_text(json.dumps(proof, indent=2) + "\n", encoding="utf-8")
        staging.rename(target)
    finally:
        if staging.exists():
            shutil.rmtree(staging)
    print(f"CI_TRANSFER_PUBLISHED surface={surface} files={len(expected)}")


def retrieve(root: Path, identity: dict, surface: str, destination: Path) -> None:
    target = bundle(root, surface)
    no_links(target / "manifest.json")
    proof = json.loads((target / "manifest.json").read_text(encoding="utf-8"))
    if proof.get("identity") != identity or proof.get("surface") != surface:
        raise ValueError("Build identity mismatch; rerun the entire workflow")
    if proof.get("files") != hashes(target / "payload"):
        raise ValueError("Build payload missing, injected or tampered")
    no_links(destination.absolute())
    if destination.exists():
        raise ValueError("Refusing to overwrite destination")
    shutil.copytree(target / "payload", destination)
    if hashes(destination) != proof["files"]:
        raise ValueError("Build changed during retrieval")
    print(f"CI_TRANSFER_VERIFIED surface={surface} commit={identity['GITHUB_SHA']} files={len(proof['files'])}")


def clean(root: Path) -> None:
    # Exact run/attempt only. Never remove sibling runs, checkout, auth or R2.
    no_links(root)
    if root.exists():
        for path in root.rglob("*"):
            no_links(path)
        shutil.rmtree(root)
    print("CI_TRANSFER_CLEANED current_run_attempt_only=true")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["publish", "retrieve", "clean"])
    parser.add_argument("--surface", choices=sorted(SURFACES))
    parser.add_argument("--directory", type=Path)
    args = parser.parse_args()
    identity = context()
    root = run_root(identity)
    if args.command == "clean":
        clean(root)
    else:
        if not args.surface or not args.directory:
            parser.error("--surface and --directory are required")
        {"publish": publish, "retrieve": retrieve}[args.command](root, identity, args.surface, args.directory)


if __name__ == "__main__":
    main()
