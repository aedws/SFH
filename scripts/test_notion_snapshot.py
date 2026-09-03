"""Regression: unchecked Notion 'No' must not be interpreted as completion."""
import hashlib
import json
import unittest
from unittest.mock import patch
from io import BytesIO

import snapshot_notion_source as source


class CheckboxTests(unittest.TestCase):
    def test_explicit_values(self):
        for value, expected in [("Yes", True), ("No", False), (True, True), (False, False)]:
            with self.subTest(value=value):
                self.assertIs(source._checked({"checked": [[value]]}), expected)
                self.assertIs(source._checked({"checked": value}), expected)

    def test_absent_is_not_confirmation(self):
        for properties in [{}, None, []]:
            self.assertIsNone(source._checked(properties))

    def test_unknown_encodings_fail_closed(self):
        for value in [[], [[]], [["false"]], [["Maybe"]], 1, None]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                source._checked({"checked": value})

    def snapshot(self, checked):
        payload = {"recordMap": {"block": {source.PAGE_ID: {"value": {
            "type": "to_do", "version": 1, "properties": {
                "title": [["Phase 6"]], "checked": [[checked]],
            },
        }}}}}
        with patch.object(source.urllib.request, "urlopen", return_value=BytesIO(json.dumps(payload).encode())):
            snapshot = source.fetch_snapshot()
        source.validate(snapshot)
        return snapshot

    def test_checkbox_only_edit_changes_hash(self):
        unchecked, checked = self.snapshot("No"), self.snapshot("Yes")
        self.assertIs(unchecked["blocks"][0]["checked"], False)
        self.assertIs(checked["blocks"][0]["checked"], True)
        self.assertNotEqual(unchecked["content_sha256"], checked["content_sha256"])

    def test_snapshot_rejects_string_checkbox_even_with_valid_hash(self):
        snapshot = self.snapshot("No")
        snapshot["blocks"][0]["checked"] = "No"
        canonical = json.dumps(snapshot["blocks"], ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        snapshot["content_sha256"] = hashlib.sha256(canonical.encode()).hexdigest()
        with self.assertRaisesRegex(ValueError, "checkbox"):
            source.validate(snapshot)


if __name__ == "__main__":
    unittest.main()
