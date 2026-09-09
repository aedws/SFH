"""No-artifact-storage transport: identity, hashes, isolation and cleanup."""
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import ci_transfer as transfer


class TransferTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / "run" / "1"
        self.source = self.base / "source"
        self.source.mkdir()
        (self.source / "index.html").write_text("SFH", encoding="utf-8")
        (self.source / ".hidden").write_text("must survive", encoding="utf-8")
        self.identity = {"schema": 1, "GITHUB_SHA": "a" * 40, "tree": "b" * 40,
                         "GITHUB_REPOSITORY": "owner/repo", "GITHUB_RUN_ID": "123",
                         "GITHUB_RUN_ATTEMPT": "1"}

    def publish(self):
        transfer.publish(self.root, self.identity, "wiki-site", self.source)

    def test_round_trip_including_hidden_files(self):
        for surface in sorted(transfer.SURFACES):
            transfer.publish(self.root, self.identity, surface, self.source)
            destination = self.base / surface
            transfer.retrieve(self.root, self.identity, surface, destination)
            self.assertEqual(transfer.hashes(destination), transfer.hashes(self.source))

    def test_wrong_identity_rejected(self):
        self.publish()
        for key in ("GITHUB_SHA", "tree", "GITHUB_REPOSITORY", "GITHUB_RUN_ID", "GITHUB_RUN_ATTEMPT"):
            with self.subTest(key=key), self.assertRaisesRegex(ValueError, "identity mismatch"):
                transfer.retrieve(self.root, {**self.identity, key: "wrong"}, "wiki-site", self.base / "out")

    def test_missing_extra_and_corrupted_files_fail_closed(self):
        self.publish()
        payload = self.root / "wiki-site" / "payload"
        for change in ("corrupt", "missing", "extra"):
            original = (payload / "index.html").read_bytes()
            if change == "corrupt":
                (payload / "index.html").write_bytes(b"tamper")
            elif change == "missing":
                (payload / "index.html").unlink()
            else:
                (payload / "inject.js").write_bytes(b"extra")
            with self.assertRaises(ValueError):
                transfer.retrieve(self.root, self.identity, "wiki-site", self.base / "out")
            (payload / "index.html").write_bytes(original)
            (payload / "inject.js").unlink(missing_ok=True)

    def test_clean_keeps_source_and_other_attempts(self):
        self.publish()
        sibling = self.root.parent / "2"
        sibling.mkdir()
        transfer.clean(self.root)
        self.assertFalse(self.root.exists())
        self.assertTrue(sibling.exists())
        self.assertTrue(self.source.exists())
        transfer.clean(self.root)

    def test_empty_unknown_duplicate_and_overwrite_rejected(self):
        with self.assertRaises(ValueError):
            transfer.publish(self.root, self.identity, "../outside", self.source)
        empty = self.base / "empty"
        empty.mkdir()
        with self.assertRaises(ValueError):
            transfer.publish(self.root, self.identity, "wiki-site", empty)
        self.publish()
        with self.assertRaises(ValueError):
            self.publish()
        with self.assertRaises(ValueError):
            transfer.retrieve(self.root, self.identity, "wiki-site", self.source)

    def test_symlink_payload_and_store_are_rejected(self):
        link = self.source / "link"
        try:
            link.symlink_to(self.source / "index.html")
        except OSError:
            self.skipTest("Host needs symlink privilege; mandatory on Linux CI")
        with self.assertRaises(ValueError):
            self.publish()
        link.unlink()
        self.root.parent.mkdir()
        self.root.symlink_to(self.source, target_is_directory=True)
        with self.assertRaises(ValueError):
            transfer.clean(self.root)
        self.root.unlink()

    def test_context_rejects_untrusted_path_inputs_and_wrong_checkout(self):
        env = {key: value for key, value in self.identity.items() if key.startswith("GITHUB_")}
        env["GITHUB_WORKSPACE"] = str(self.base / "checkout")
        with patch.dict(os.environ, env), patch.object(transfer, "git", side_effect=["a" * 40, "b" * 40]):
            identity = transfer.context()
            self.assertEqual(identity, self.identity)
            self.assertIn(transfer.STORE, transfer.run_root(identity).parts)
        for key, value in (("GITHUB_RUN_ID", "../123"), ("GITHUB_RUN_ATTEMPT", "0"),
                           ("GITHUB_REPOSITORY", "../../escape"), ("GITHUB_SHA", "c" * 40)):
            with patch.dict(os.environ, {**env, key: value}), patch.object(transfer, "git", return_value="a" * 40):
                with self.assertRaises(ValueError):
                    transfer.context()


if __name__ == "__main__":
    unittest.main()
