"""Validate the existing SFH Worker identity before any candidate is promoted."""
import json
import os
from pathlib import Path
import re
import sys


def rollback_identity(state: dict) -> dict:
    commit = state.get("build_commit", "")
    version = state.get("release_version", "")
    downloads = state.get("download_prefix", "downloads")
    if (state.get("service") != "sfh-game" or state.get("status") != "ok"
        or not re.fullmatch(r"[0-9a-f]{40}", commit)
        or not re.fullmatch(r"v[0-9A-Za-z._-]+", version)
        or state.get("release_prefix") != f"game/releases/{commit}"
        or downloads not in {"downloads", f"downloads/releases/{commit}"}):
        raise ValueError("Unsafe or unrecognized active release; do not deploy")
    return {"PREVIOUS_GAME_COMMIT": commit, "PREVIOUS_RELEASE_VERSION": version,
            "PREVIOUS_DOWNLOAD_PREFIX": downloads}


if __name__ == "__main__":
    values = rollback_identity(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")))
    if values["PREVIOUS_GAME_COMMIT"] == os.environ.get("GITHUB_SHA"):
        raise SystemExit("This commit is already live; refusing to overwrite active candidate files. Use a new recovery/fix commit.")
    with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as stream:
        for key, value in values.items():
            stream.write(f"{key}={value}\n")
    print("RELEASE_ROLLBACK_IDENTITY_OK commit=" + values["PREVIOUS_GAME_COMMIT"])
