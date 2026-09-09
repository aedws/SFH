"""Release identity and candidate integrity before live Worker promotion."""
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import deploy_cloudflare_assets as assets
from release_state import rollback_identity


class ReleaseTests(unittest.TestCase):
    def test_web_windows_identity_and_checksum(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            commit, version = "a" * 40, "v0.1.0"
            (root / "sfh-ci-proof.json").write_text(json.dumps({"commit": commit}))
            archive = root / f"SFH-Windows-x64-{version}.zip"
            with zipfile.ZipFile(archive, "w") as bundle:
                bundle.writestr("BUILD-METADATA.json", json.dumps({"build_commit": commit, "release_version": version}))
            checksum = root / (archive.name + ".sha256")
            checksum.write_text(f"{assets.sha256(archive)}  {archive.name}\n")
            assets.verify_release(root, root, commit, version)
            with self.assertRaises(ValueError):
                assets.verify_release(root, root, "b" * 40, version)
            checksum.write_text("0" * 64 + "  " + archive.name)
            with self.assertRaisesRegex(ValueError, "checksum"):
                assets.verify_release(root, root, commit, version)

    def test_remote_candidate_readback_rejects_mismatched_content(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "source"
            source.write_bytes(b"verified candidate")
            entries = [{"key": "game/releases/commit/index.pck", "size": source.stat().st_size,
                        "sha256": assets.sha256(source)}]
            def download(command, **kwargs):
                Path(command[-1]).write_bytes(source.read_bytes())
            with patch.object(assets.subprocess, "run", side_effect=download):
                assets.verify_remote("bucket", entries)
                entries[0]["sha256"] = "0" * 64
                with self.assertRaisesRegex(ValueError, "integrity mismatch"):
                    assets.verify_remote("bucket", entries)

    def test_capture_is_strict_and_supports_legacy_rollback(self):
        commit = "a" * 40
        state = {"service": "sfh-game", "status": "ok", "build_commit": commit,
                 "release_version": "v0.1.0", "release_prefix": f"game/releases/{commit}",
                 "download_prefix": "downloads"}
        self.assertEqual(rollback_identity(state)["PREVIOUS_GAME_COMMIT"], commit)
        self.assertEqual(rollback_identity({**state, "download_prefix": f"downloads/releases/{commit}"})
                         ["PREVIOUS_DOWNLOAD_PREFIX"], f"downloads/releases/{commit}")
        for key, value in (("build_commit", "HEAD"), ("release_prefix", "other/data"),
                           ("download_prefix", "unrelated-prefix"), ("service", "other-project"),
                           ("release_version", "v1\nINJECTED=true")):
            with self.subTest(key=key), self.assertRaises(ValueError):
                rollback_identity({**state, key: value})

    def test_workflow_candidate_gate_before_promotion_and_retention(self):
        import yaml
        workflow = Path(__file__).resolve().parents[1] / ".github/workflows/deploy-wiki.yml"
        data = yaml.safe_load(workflow.read_text(encoding="utf-8"))
        text = workflow.read_text(encoding="utf-8")
        self.assertIn("cmp --silent .cloudflare-wiki/index.html /tmp/wiki.html", text)
        self.assertIn('metadata["build_commit"] == os.environ["GAME_BUILD_COMMIT"]', text)
        steps = data["jobs"]["cloudflare-deploy"]["steps"]
        names = [step["name"] for step in steps]
        ordered = ["Capture active game rollback identity", "Upload immutable R2 release objects",
                   "Switch game Worker to verified commit", "Verify Cloudflare wiki, game, range, and download",
                   "Remove superseded Windows downloads from R2", "Create immutable-name verified backup branch"]
        positions = [names.index(name) for name in ordered]
        self.assertEqual(positions, sorted(positions))
        rollback = next(step for step in steps if step["name"].startswith("Restore previous game"))
        self.assertIn("failure()", rollback["if"])
        self.assertIn("steps.game_promotion.outcome == 'success'", rollback["if"])


if __name__ == "__main__":
    unittest.main()
