"""Conservative CI routing: Git stores source, the private runner builds it.

Only an explicit documentation allowlist bypasses gameplay checks. Every game
push runs full tests; no GitHub artifact availability can waive required checks.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

PROOF = "sfh-ci-proof.json"
WORKFLOW = ".github/workflows/deploy-wiki.yml"


def git(*args: str) -> str:
    # A container runs as root over a runner-owned checkout. Trust this exact
    # working directory for this invocation, never every repository globally.
    return subprocess.check_output(
        ["git", "-c", f"safe.directory={Path.cwd().as_posix()}", *args], text=True
    ).strip()


def documentation_only(paths: list[str]) -> bool:
    return bool(paths) and all(
        path.startswith("docs/") or path in {
            "README.md", "AGENTS.md", ".gitignore", "mkdocs.yml", "requirements-docs.txt",
        } for path in paths
    )


def payload_hashes(files: dict[str, bytes]) -> dict[str, str]:
    return {name: hashlib.sha256(value).hexdigest()
            for name, value in sorted(files.items()) if name != PROOF}


def verify_payload(files: dict[str, bytes], tree: str, run_id: str) -> dict:
    proof = json.loads(files[PROOF])
    if proof.get("schema") != 1 or proof.get("tree") != tree or str(proof.get("run_id")) != run_id:
        raise ValueError("Artifact provenance mismatch")
    if proof.get("files") != payload_hashes(files):
        raise ValueError("Artifact file hashes mismatch")
    if any(not files.get(name) for name in ("index.html", "index.wasm", "index.pck")):
        raise ValueError("Incomplete Web artifact")
    return proof


def plan() -> None:
    event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text(encoding="utf-8"))
    kind = os.environ["GITHUB_EVENT_NAME"]
    repository = os.environ["GITHUB_REPOSITORY"]
    tree = git("rev-parse", "HEAD^{tree}")
    base = event.get("pull_request", {}).get("base", {}).get("sha") if kind == "pull_request" else event.get("before")
    paths = []
    if base and set(base) != {"0"}:
        # Includes removals and both names of renames; unknown inputs run full CI.
        paths = git("diff", "--name-only", "--no-renames", base, "HEAD").splitlines()
    game = not documentation_only(paths) or kind == "workflow_dispatch"
    # Manual-only self-hosting. Offline hosts queue work; never buy hosted minutes.
    # The workflow rejects untrusted PRs before checkout; repeat the boundary here.
    trusted = kind != "pull_request" or (
        event.get("pull_request", {}).get("head", {}).get("repo", {}).get("full_name") == repository
        and event.get("sender", {}).get("login") == repository.split("/")[0]
    )
    if not trusted:
        raise ValueError("Untrusted PR cannot run on the private self-hosted runner")
    runner = '["self-hosted","Linux","X64","sfh-build"]'
    values = {"game": str(game).lower(), "tree": tree, "runner": runner}
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as stream:
        for key, value in values.items():
            stream.write(f"{key}={value}\n")
    print("CI_PLAN " + json.dumps(values))


def attest(directory: Path) -> None:
    files = {p.relative_to(directory).as_posix(): p.read_bytes() for p in directory.rglob("*") if p.is_file()}
    proof = {"schema": 1, "tree": git("rev-parse", "HEAD^{tree}"),
             "commit": git("rev-parse", "HEAD"), "run_id": os.environ["GITHUB_RUN_ID"],
             "files": payload_hashes(files)}
    (directory / PROOF).write_text(json.dumps(proof, indent=2) + "\n", encoding="utf-8")


def require_checks(needs: dict, event: str) -> None:
    if needs["plan"]["result"] != "success":
        raise ValueError("Change classification failed")
    outputs = needs["plan"]["outputs"]
    if outputs["game"] == "false":
        return
    if outputs["game"] != "true":
        raise ValueError("Unknown change classification")
    if not all(
        needs[j]["result"] == "success" for j in ("export-game", "e2e")
    ):
        raise ValueError("Required gameplay checks did not succeed")
    if event != "pull_request" and needs["package-windows"]["result"] != "success":
        raise ValueError("Required Windows packaging did not succeed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["plan", "attest", "verify", "gate"])
    parser.add_argument("--directory", type=Path, default=Path("game-web"))
    parser.add_argument("--run-id")
    args = parser.parse_args()
    if args.command == "plan":
        plan()
    elif args.command == "gate":
        require_checks(json.loads(os.environ["NEEDS_JSON"]), os.environ["GITHUB_EVENT_NAME"])
        print("CI_GATE_OK required checks succeeded; no cross-run reuse")
    elif args.command == "attest":
        attest(args.directory)
    else:
        files = {p.relative_to(args.directory).as_posix(): p.read_bytes() for p in args.directory.rglob("*") if p.is_file()}
        verify_payload(files, git("rev-parse", "HEAD^{tree}"), args.run_id)
        print("CI_ARTIFACT_VERIFIED tree and every file SHA-256 match")


if __name__ == "__main__":
    main()
