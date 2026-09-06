"""Conservative change routing and verified Web artifact reuse for SFH CI.

Only an explicit documentation allowlist bypasses gameplay checks. Reuse requires
a successful same-repository PR, identical Git tree and a complete payload hash.
API errors and missing/expired evidence always fall back to rebuilding.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import time
import urllib.request
import urllib.parse
import zipfile

PROOF = "sfh-ci-proof.json"
WORKFLOW = ".github/workflows/deploy-wiki.yml"


class SafeRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        redirected = super().redirect_request(req, fp, code, msg, headers, newurl)
        if redirected and urllib.parse.urlparse(req.full_url).netloc != urllib.parse.urlparse(newurl).netloc:
            redirected.remove_header("Authorization")
        return redirected


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True).strip()


def api(path: str, raw: bool = False):
    request = urllib.request.Request("https://api.github.com/" + path, headers={
        "Authorization": "Bearer " + os.environ["GH_TOKEN"],
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    })
    with urllib.request.build_opener(SafeRedirect()).open(request, timeout=30) as response:
        body = response.read()
    return body if raw else json.loads(body)


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


def read_archive(data: bytes) -> dict[str, bytes]:
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        files = {}
        for item in archive.infolist():
            if item.is_dir():
                continue
            name = item.orig_filename
            if name.startswith("/") or ".." in name.split("/") or "\\" in name or ":" in name or name in files:
                raise ValueError("Unsafe or duplicate artifact path")
            files[name] = archive.read(item)
        return files


def candidate_run(run: dict, pr: dict, repository: str) -> bool:
    return (
        run.get("event") == "pull_request" and run.get("conclusion") == "success"
        and run.get("path") == WORKFLOW
        and run.get("head_sha") == pr["head"]["sha"]
        and run.get("head_repository", {}).get("full_name") == repository
    )


def find_reuse(repository: str, sha: str, tree: str) -> str:
    # Restrict lookup to the PR actually merged into this push, not any artifact
    # with a plausible name. The tree is independently verified in its manifest.
    for pr in api(f"repos/{repository}/commits/{sha}/pulls"):
        if not pr.get("merged_at") or pr.get("merge_commit_sha") != sha:
            continue
        if pr["base"]["ref"] != "main" or pr["head"]["repo"]["full_name"] != repository:
            continue
        runs = api(f"repos/{repository}/actions/workflows/deploy-wiki.yml/runs?event=pull_request&head_sha={pr['head']['sha']}&per_page=20")
        for run in runs["workflow_runs"]:
            if not candidate_run(run, pr, repository):
                continue
            run_id = str(run["id"])
            artifacts = api(f"repos/{repository}/actions/runs/{run_id}/artifacts")["artifacts"]
            for artifact in artifacts:
                if artifact["name"] != "game-web" or artifact["expired"]:
                    continue
                files = read_archive(api(f"repos/{repository}/actions/artifacts/{artifact['id']}/zip", raw=True))
                verify_payload(files, tree, run_id)
                return run_id
    return ""


def plan() -> None:
    event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text(encoding="utf-8"))
    kind = os.environ["GITHUB_EVENT_NAME"]
    sha = os.environ["GITHUB_SHA"]
    repository = os.environ["GITHUB_REPOSITORY"]
    tree = git("rev-parse", "HEAD^{tree}")
    base = event.get("pull_request", {}).get("base", {}).get("sha") if kind == "pull_request" else event.get("before")
    paths = []
    if base and set(base) != {"0"}:
        # Includes removals and both names of renames; unknown inputs run full CI.
        paths = git("diff", "--name-only", "--no-renames", base, "HEAD").splitlines()
    game = not documentation_only(paths) or kind == "workflow_dispatch"
    reuse = ""
    if kind == "push" and game:
        try:
            reuse = find_reuse(repository, sha, tree)
        except (KeyError, ValueError, OSError, zipfile.BadZipFile) as error:
            print(f"CI_REUSE_FALLBACK {type(error).__name__}: rebuilding with full tests")
    runner = '"ubuntu-24.04"'
    # The owner-side heartbeat issues a three-minute lease after checking online
    # status. Expired leases select hosted; a host failure after assignment still
    # requires cancellation and rerun (GitHub does not migrate queued jobs).
    trusted = kind != "pull_request" or (
        event.get("pull_request", {}).get("head", {}).get("repo", {}).get("full_name") == repository
        and event.get("sender", {}).get("login") == repository.split("/")[0]
    )
    try:
        lease = int(os.environ.get("SFH_SELF_HOSTED_READY_UNTIL", "0"))
    except ValueError:
        lease = 0
    if os.environ.get("SFH_SELF_HOSTED_ENABLED") == "true" and trusted and time.time() < lease <= time.time() + 300:
        runner = '["self-hosted","Linux","X64","sfh-build"]'
    values = {"game": str(game).lower(), "reuse_run": reuse, "tree": tree,
              "web_run": reuse or os.environ["GITHUB_RUN_ID"], "runner": runner}
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


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["plan", "attest", "verify"])
    parser.add_argument("--directory", type=Path, default=Path("game-web"))
    parser.add_argument("--run-id")
    args = parser.parse_args()
    if args.command == "plan":
        plan()
    elif args.command == "attest":
        attest(args.directory)
    else:
        files = {p.relative_to(args.directory).as_posix(): p.read_bytes() for p in args.directory.rglob("*") if p.is_file()}
        verify_payload(files, git("rev-parse", "HEAD^{tree}"), args.run_id)
        print("CI_ARTIFACT_VERIFIED tree and every file SHA-256 match")


if __name__ == "__main__":
    main()
