"""Keep only the current SFH Windows download in a local directory or Cloudflare R2."""

from __future__ import annotations

import argparse
import json
import os
import re
import urllib.parse
import urllib.request
from pathlib import Path

WINDOWS_OBJECT = re.compile(
    r"^(?:downloads/([^/]+)/)?SFH-Windows-x64-(v[^/]+)\.zip(?:\.sha256)?$"
)
COMMIT_WINDOWS_OBJECT = re.compile(
    r"^downloads/releases/([0-9a-f]{40})/(v[0-9A-Za-z._-]+)/SFH-Windows-x64-(v[0-9A-Za-z._-]+)\.zip(?:\.sha256)?$"
)


def windows_object_version(value: str) -> str | None:
    match = WINDOWS_OBJECT.fullmatch(value)
    if match is None:
        return None
    directory_version, file_version = match.groups()
    if directory_version is not None and directory_version != file_version:
        return None
    return file_version


def local_candidates(root: Path) -> list[Path]:
    root = root.resolve()
    if not root.exists():
        return []
    return sorted(
        path.resolve()
        for path in root.glob("SFH-Windows-x64-v*.zip*")
        if path.is_file() and windows_object_version(path.name) is not None
    )


def prune_local(root: Path, keep_version: str, dry_run: bool = False) -> list[Path]:
    resolved_root = root.resolve()
    removed: list[Path] = []
    for path in local_candidates(resolved_root):
        version = windows_object_version(path.name)
        if version is None or version == keep_version:
            continue
        if resolved_root not in path.parents:
            raise RuntimeError(f"refusing path outside root: {path}")
        removed.append(path)
        if not dry_run:
            path.unlink()
    return removed


def _request(url: str, token: str, method: str = "GET") -> dict:
    request = urllib.request.Request(
        url,
        method=method,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        body = response.read()
    return json.loads(body) if body else {"success": True}


def list_r2_objects(account_id: str, token: str, bucket: str, prefix: str) -> list[str]:
    base = (
        "https://api.cloudflare.com/client/v4/accounts/"
        f"{urllib.parse.quote(account_id, safe='')}/r2/buckets/"
        f"{urllib.parse.quote(bucket, safe='')}/objects"
    )
    cursor = ""
    keys: list[str] = []
    while True:
        query = {"prefix": prefix, "per_page": "1000"}
        if cursor:
            query["cursor"] = cursor
        payload = _request(f"{base}?{urllib.parse.urlencode(query)}", token)
        if not payload.get("success", False):
            raise RuntimeError(f"R2 list failed: {payload}")
        keys.extend(str(item["key"]) for item in payload.get("result", []))
        info = payload.get("result_info", {})
        if not info.get("is_truncated", False):
            return keys
        cursor = str(info.get("cursor", ""))
        if not cursor:
            raise RuntimeError("R2 list was truncated without a cursor")


def prune_r2(
    account_id: str,
    token: str,
    bucket: str,
    keep_version: str,
    prefix: str = "downloads/",
    dry_run: bool = False,
) -> list[str]:
    removed: list[str] = []
    for key in list_r2_objects(account_id, token, bucket, prefix):
        version = windows_object_version(key)
        if version is None or version == keep_version:
            continue
        if not key.startswith(prefix):
            raise RuntimeError(f"refusing object outside prefix: {key}")
        removed.append(key)
        if not dry_run:
            url = (
                "https://api.cloudflare.com/client/v4/accounts/"
                f"{urllib.parse.quote(account_id, safe='')}/r2/buckets/"
                f"{urllib.parse.quote(bucket, safe='')}/objects/"
                f"{urllib.parse.quote(key, safe='/')}"
            )
            payload = _request(url, token, method="DELETE")
            if not payload.get("success", False):
                raise RuntimeError(f"R2 delete failed for {key}: {payload}")
    return removed


def prune_commit_downloads(account_id: str, token: str, bucket: str, keep_commits: list[str],
                           keep_legacy_version: str | None = None, dry_run: bool = False) -> list[str]:
    if not keep_commits or any(not re.fullmatch(r"[0-9a-f]{40}", item) for item in keep_commits):
        raise ValueError("At least one verified commit is required")
    removed = []
    for key in list_r2_objects(account_id, token, bucket, "downloads/"):
        match = COMMIT_WINDOWS_OBJECT.fullmatch(key)
        legacy = windows_object_version(key) if key.startswith("downloads/") else None
        if match:
            commit, directory_version, file_version = match.groups()
            if commit in keep_commits or directory_version != file_version:
                continue
        elif legacy:
            if legacy == keep_legacy_version:
                continue
        else:
            continue  # Never delete arbitrary R2 data, runtime or auth records.
        removed.append(key)
        if not dry_run:
            url = ("https://api.cloudflare.com/client/v4/accounts/"
                   f"{urllib.parse.quote(account_id, safe='')}/r2/buckets/"
                   f"{urllib.parse.quote(bucket, safe='')}/objects/{urllib.parse.quote(key, safe='/')}")
            if not _request(url, token, method="DELETE").get("success", False):
                raise RuntimeError(f"R2 delete failed for {key}")
    return removed


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--keep-version")
    parser.add_argument("--keep-commit", action="append", default=[])
    parser.add_argument("--keep-legacy-version")
    parser.add_argument("--local-root", type=Path)
    parser.add_argument("--r2", action="store_true")
    parser.add_argument("--bucket", default="sfh-game-artifacts")
    parser.add_argument("--prefix", default="downloads/")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if bool(args.local_root) == bool(args.r2):
        raise SystemExit("choose exactly one of --local-root or --r2")
    if args.local_root:
        if not args.keep_version:
            raise SystemExit("--keep-version is required for local retention")
        removed = [str(path) for path in prune_local(args.local_root, args.keep_version, args.dry_run)]
        scope = str(args.local_root.resolve())
    else:
        account_id = os.environ.get("CLOUDFLARE_ACCOUNT_ID", "")
        token = os.environ.get("CLOUDFLARE_API_TOKEN", "")
        if not account_id or not token:
            raise SystemExit("CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN are required")
        if args.keep_commit:
            if args.prefix != "downloads/":
                raise ValueError("Commit retention is limited to downloads/")
            removed = prune_commit_downloads(account_id, token, args.bucket, args.keep_commit,
                                              args.keep_legacy_version, args.dry_run)
        elif args.keep_version:
            removed = prune_r2(account_id, token, args.bucket, args.keep_version, args.prefix, args.dry_run)
        else:
            raise SystemExit("A verified version or commit is required")
        scope = f"r2://{args.bucket}/{args.prefix}"
    print(
        f"WINDOWS_RETENTION_OK scope={scope} keep={args.keep_commit or args.keep_version} "
        f"removed={len(removed)} dry_run={str(args.dry_run).lower()}"
    )
    for item in removed:
        print(f"REMOVE {item}")


if __name__ == "__main__":
    main()
