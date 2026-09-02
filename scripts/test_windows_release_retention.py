from pathlib import Path
from tempfile import TemporaryDirectory
from unittest import TestCase, main
from unittest.mock import patch

from prune_windows_releases import list_r2_objects, prune_local, prune_r2


class WindowsRetentionTests(TestCase):
    def test_only_old_windows_archives_are_deleted(self) -> None:
        with TemporaryDirectory() as directory:
            root = Path(directory)
            keep = root / "SFH-Windows-x64-v0.2.0.zip"
            keep_hash = root / "SFH-Windows-x64-v0.2.0.zip.sha256"
            old = root / "SFH-Windows-x64-v0.1.0.zip"
            old_hash = root / "SFH-Windows-x64-v0.1.0.zip.sha256"
            unrelated = root / "index.zip"
            for path in (keep, keep_hash, old, old_hash, unrelated):
                path.write_text(path.name, encoding="utf-8")
            removed = prune_local(root, "v0.2.0")
            self.assertEqual({old, old_hash}, set(removed))
            self.assertTrue(keep.exists())
            self.assertTrue(keep_hash.exists())
            self.assertTrue(unrelated.exists())

    def test_dry_run_does_not_delete(self) -> None:
        with TemporaryDirectory() as directory:
            root = Path(directory)
            old = root / "SFH-Windows-x64-v0.0.1.zip"
            old.write_text("old", encoding="utf-8")
            self.assertEqual([old], prune_local(root, "v0.2.0", dry_run=True))
            self.assertTrue(old.exists())

    @patch("prune_windows_releases._request")
    def test_r2_pagination_and_exact_delete_scope(self, request) -> None:
        request.side_effect = [
            {
                "success": True,
                "result": [
                    {"key": "downloads/v0.1.0/SFH-Windows-x64-v0.1.0.zip"},
                    {"key": "downloads/v0.2.0/SFH-Windows-x64-v0.2.0.zip"},
                ],
                "result_info": {"is_truncated": True, "cursor": "next"},
            },
            {
                "success": True,
                "result": [
                    {"key": "downloads/v0.1.0/SFH-Windows-x64-v0.1.0.zip.sha256"},
                    {"key": "downloads/v0.1.0/SFH-Windows-x64-v9.9.9.zip"},
                    {"key": "downloads/v0.1.0/release-notes.json"},
                    {"key": "game/releases/commit/index.pck"},
                ],
                "result_info": {"is_truncated": False},
            },
            {"success": True},
            {"success": True},
        ]
        removed = prune_r2("account", "token", "bucket", "v0.2.0")
        self.assertEqual(
            [
                "downloads/v0.1.0/SFH-Windows-x64-v0.1.0.zip",
                "downloads/v0.1.0/SFH-Windows-x64-v0.1.0.zip.sha256",
            ],
            removed,
        )
        delete_calls = [call for call in request.call_args_list if call.kwargs.get("method") == "DELETE"]
        self.assertEqual(2, len(delete_calls))
        self.assertTrue(all("downloads/v0.1.0/" in call.args[0] for call in delete_calls))

    @patch("prune_windows_releases._request")
    def test_r2_list_uses_prefix_and_cursor(self, request) -> None:
        request.side_effect = [
            {"success": True, "result": [], "result_info": {"is_truncated": True, "cursor": "c2"}},
            {"success": True, "result": [], "result_info": {"is_truncated": False}},
        ]
        self.assertEqual([], list_r2_objects("account", "token", "bucket", "downloads/"))
        self.assertIn("prefix=downloads%2F", request.call_args_list[0].args[0])
        self.assertIn("cursor=c2", request.call_args_list[1].args[0])


if __name__ == "__main__":
    main()
