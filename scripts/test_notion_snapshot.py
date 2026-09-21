"""Regression: unchecked Notion 'No' must not be interpreted as completion."""
import hashlib
import json
import re
import unittest
from copy import deepcopy
from pathlib import Path
from unittest.mock import patch
from io import BytesIO

import snapshot_notion_source as source
import snapshot_notion_tracker as tracker
import check_notion_audit as audit_check


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

    def test_snapshot_rejects_a_different_source_url(self):
        snapshot = self.snapshot("No")
        snapshot["source_url"] = "https://example.invalid/obsolete-gdd"
        with self.assertRaisesRegex(ValueError, "source URL mismatch"):
            source.validate(snapshot)


class PageScopeTests(unittest.TestCase):
    def page(self, parent_version=1):
        return {"recordMap": {"block": {
            source.PAGE_ID: {"value": {"type": "page", "version": 2, "content": ["child"]}},
            "child": {"value": {"type": "text", "properties": {"title": [["body"]]}}},
            "parent": {"value": {"version": parent_version}},
        }}}

    def test_parent_edit_does_not_change_document_hash(self):
        with patch.object(source, "request_json", side_effect=[self.page(1), self.page(99)]):
            first, second = source.fetch_snapshot(), source.fetch_snapshot()
        self.assertEqual(first["content_sha256"], second["content_sha256"])
        self.assertEqual(first["block_count"], 2)
        source.validate(first)

    def test_pagination_collects_missing_descendant(self):
        first = self.page()
        child = first["recordMap"]["block"].pop("child")
        first["cursor"] = {"stack": ["next"]}
        last = {"recordMap": {"block": {"child": child}}, "cursor": {"stack": []}}
        with patch.object(source, "request_json", side_effect=[first, last]) as request:
            self.assertEqual(source.fetch_snapshot()["block_count"], 2)
        self.assertEqual(request.call_args_list[1].args[1]["cursor"], first["cursor"])

    def test_missing_child_fails_closed(self):
        page = self.page()
        del page["recordMap"]["block"]["child"]
        with patch.object(source, "request_json", return_value=page), self.assertRaisesRegex(ValueError, "missing source block"):
            source.fetch_snapshot()

    def test_repeated_cursor_fails_closed(self):
        page = self.page()
        page["cursor"] = {"stack": ["next"]}
        with patch.object(source, "request_json", return_value=page), self.assertRaisesRegex(ValueError, "repeated page cursor"):
            source.fetch_snapshot()

    def test_root_metadata_is_validated(self):
        with patch.object(source, "request_json", return_value=self.page()):
            snapshot = source.fetch_snapshot()
        snapshot["root_version"] += 1
        with self.assertRaisesRegex(ValueError, "metadata mismatch"):
            source.validate(snapshot)


class TrackerTests(unittest.TestCase):
    def payload(self, more=False):
        properties = {"title": [["이동"]], "TrYw": [["CORE-01"]], "[eq>": [["결정 (미구현)"]],
                      ";Od`": [["전투"]], "RV~f": [["실제 이동"]]}
        result = {"collection_group_results": {"hasMore": more, "blockIds": ["task"]}}
        return {"result": {"reducerResults": result},
                "recordMap": {"block": {"task": {"value": {"value": {"properties": properties}}}}}}

    def test_status_is_preserved_not_converted_to_completion(self):
        with patch.object(tracker, "request_json", return_value=self.payload()):
            snapshot = tracker.fetch_snapshot()
        self.assertEqual(snapshot["rows"][0]["planner_status"], "결정 (미구현)")
        tracker.validate(snapshot)

    def test_incomplete_set_fails_closed(self):
        for more in [True, None]:
            with self.subTest(more=more), patch.object(tracker, "request_json", return_value=self.payload(more)), self.assertRaisesRegex(ValueError, "incomplete"):
                tracker.fetch_snapshot()

    def test_limit_expands_until_complete(self):
        with patch.object(tracker, "request_json", side_effect=[self.payload(True), self.payload(False)]) as request:
            tracker.fetch_snapshot()
        self.assertEqual(request.call_args_list[1].args[1]["loader"]["reducers"]["collection_group_results"]["limit"], 500)

    def test_duplicates_rejected(self):
        payload = self.payload()
        payload["result"]["reducerResults"]["collection_group_results"]["blockIds"].append("task")
        with patch.object(tracker, "request_json", return_value=payload), self.assertRaisesRegex(ValueError, "duplicate"):
            tracker.fetch_snapshot()

    def test_unknown_status_rejected(self):
        payload = self.payload()
        payload["recordMap"]["block"]["task"]["value"]["value"]["properties"]["[eq>"] = [["unknown"]]
        with patch.object(tracker, "request_json", return_value=payload), self.assertRaisesRegex(ValueError, "status drift"):
            tracker.fetch_snapshot()


class CodeCrosswalkTests(unittest.TestCase):
    def setUp(self):
        assets = Path(__file__).resolve().parents[1] / "docs/assets"
        self.gdd = json.loads((assets / "notion-source-snapshot.json").read_text(encoding="utf-8"))
        self.tasks = json.loads((assets / "notion-tracker-snapshot.json").read_text(encoding="utf-8"))
        self.audit = json.loads((assets / "notion-code-audit.json").read_text(encoding="utf-8"))

    def test_all_rows_and_weighted_result(self):
        audit_check.validate(self.audit, self.gdd, self.tasks)
        numerator, denominator, counts = audit_check.summary(self.audit)
        # Owner accepted the alternative renderer; normal-play QA stays partial.
        self.assertEqual((numerator, denominator, len(self.audit["rows"])), (136.5, 170, 66))
        self.assertEqual((counts["code_supported"], counts["partial"]), (45, 1))
        self.assertEqual(counts["decision_pending"], 14)

    def test_day_close_technical_gap_and_next_day_links(self):
        root = Path(__file__).resolve().parents[1]
        row = next(r for r in self.audit["rows"] if r["title"].startswith("TileMapLayer"))
        self.assertEqual(row["assessment"], "code_supported")
        self.assertIn("2026-09-09 오너 대체 승인", row["finding"])
        self.assertEqual(row["planner_status"], "결정 (미구현)")
        self.assertIn("game/features/map_generation/dungeon_floor_layer.gd", row["code"])
        self.assertIn("extends Node2D", (root / row["code"][1]).read_text(encoding="utf-8"))
        document = (root / "docs/design/master-gdd-alignment.md").read_text(encoding="utf-8")
        self.assertEqual(document.count("{#day-close}"), 1)
        self.assertIn("136.5/170", document)
        workline = (root / "docs/design/current-milestone-workline.md").read_text(encoding="utf-8")
        next_sections = set(re.findall(r"\{#(next-\d{8})\}", workline))
        self.assertTrue(next_sections, "The workline must provide a dated execution section")
        latest = max(next_sections)
        for page in ["docs/access/planner.md", "docs/access/developer.md", "docs/index.md", "docs/development-status.md"]:
            links = set(re.findall(r"current-milestone-workline(?:\.md|/)?#(next-\d{8})", (root / page).read_text(encoding="utf-8")))
            self.assertIn(latest, links, f"{page}: latest workline link must survive daily home compression")
            self.assertTrue(links <= next_sections, f"{page}: dangling dated execution anchor")

    def test_missing_or_duplicate_row_fails(self):
        for duplicate in [False, True]:
            changed = deepcopy(self.audit)
            changed["rows"].pop()
            if duplicate:
                changed["rows"].append(deepcopy(changed["rows"][0]))
            with self.subTest(duplicate=duplicate), self.assertRaisesRegex(ValueError, "every tracker row"):
                audit_check.validate(changed, self.gdd, self.tasks)

    def test_either_source_drift_requires_review(self):
        for key in ["gdd_sha256", "tracker_sha256"]:
            changed = deepcopy(self.audit)
            changed[key] = "stale"
            with self.subTest(key=key), self.assertRaisesRegex(ValueError, "source drift"):
                audit_check.validate(changed, self.gdd, self.tasks)

    def test_planner_status_not_silently_changed(self):
        self.audit["rows"][0]["planner_status"] = "구현완료"
        with self.assertRaisesRegex(ValueError, "source row mismatch"):
            audit_check.validate(self.audit, self.gdd, self.tasks)

    def test_undecided_cannot_be_accepted(self):
        row = next(r for r in self.audit["rows"] if r["assessment"] == "decision_pending")
        row["assessment"] = "code_supported"
        with self.assertRaisesRegex(ValueError, "undecided"):
            audit_check.validate(self.audit, self.gdd, self.tasks)

    def test_unsafe_evidence_rejected(self):
        self.audit["rows"][0]["code"] = ["../outside.gd"]
        with self.assertRaisesRegex(ValueError, "unsafe evidence"):
            audit_check.validate(self.audit, self.gdd, self.tasks)

    def test_extensions_do_not_inflate_notion_score(self):
        before = audit_check.summary(self.audit)
        extra = deepcopy(self.audit["extensions"][0])
        extra["id"] = "EXT-ADDITIONAL-TEST"
        self.audit["extensions"].append(extra)
        audit_check.validate(self.audit, self.gdd, self.tasks)
        self.assertEqual(audit_check.summary(self.audit), before)

    def test_progress_matches_audit_without_exposing_public_dashboard(self):
        numerator, denominator, _counts = audit_check.summary(self.audit)
        percentage = f"{100 * numerator / denominator:.1f}"
        docs = Path(__file__).resolve().parents[1] / "docs"
        page = (docs / "development-status.md").read_text(encoding="utf-8")
        self.assertIn(f'aria-valuenow="{percentage}"', page)
        self.assertIn(f"<b>{percentage}%</b>", page)
        self.assertIn("출시", page)
        self.assertLess(page.index('aria-valuenow='), page.index("## 현재 빌드 상태"))
        home = (docs / "index.md").read_text(encoding="utf-8")
        self.assertNotIn('sfh-progress-panel', home)
        self.assertIn("access/login/?return=%2Fdesign%2Fmaster-gdd-alignment%2F%23day-close", home)

    def test_extension_evidence_and_ids_fail_closed(self):
        for mutation in ("duplicate", "outside", "status", "empty"):
            changed = deepcopy(self.audit)
            if mutation == "duplicate":
                changed["extensions"].append(deepcopy(changed["extensions"][0]))
            elif mutation == "outside":
                changed["extensions"][0]["code"] = ["../outside.gd"]
            elif mutation == "status":
                changed["extensions"][0]["planner_status"] = "구현완료"
            else:
                changed["extensions"][0]["existing_tests"] = []
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                audit_check.validate(changed, self.gdd, self.tasks)


class SeptemberDeltaTests(unittest.TestCase):
    def test_new_rows_keep_identity_evidence_and_planning_separate(self):
        root = Path(__file__).resolve().parents[1]
        assets = root / "docs/assets"
        delta = json.loads((assets / "notion-delta-audit-20260921.json").read_text(encoding="utf-8"))
        base = json.loads((assets / "notion-tracker-snapshot.json").read_text(encoding="utf-8"))
        base_ids = {row["id"] for row in base["rows"]}
        rows = {row["id"]: row for row in delta["rows"]}
        self.assertEqual(len(rows), delta["delta_row_count"])
        self.assertEqual(len(rows), 16)
        self.assertFalse(base_ids & rows.keys())
        self.assertEqual(len(base_ids) + len(rows), delta["source"]["tracker_rows"])
        duplicates = [row for row in rows.values() if row["code_status"] == "duplicate"]
        self.assertEqual(len(duplicates), 1)
        self.assertEqual(len(rows) - len(duplicates), delta["unique_requirement_count"])
        for row in rows.values():
            self.assertEqual(row["planner_status"], "결정 (미구현)")
            self.assertIn(row["code_status"], {"implemented", "partial", "unimplemented", "duplicate"})
            self.assertTrue(row["assessment"] and row["work_order"])
            for relative in row["evidence"] + row["existing_test_context"] + row.get("verified_by", []):
                path = (root / relative).resolve()
                self.assertTrue(path.is_relative_to(root) and path.is_file(), relative)
            if row["code_status"] == "implemented":
                self.assertTrue(row.get("verified_by"))
            if row["code_status"] == "duplicate":
                original = rows[row["duplicate_of"]]
                self.assertNotEqual(original["code_status"], "duplicate")
                self.assertEqual(original["request_id"], row["request_id"])
                self.assertEqual(original["acceptance"], row["acceptance"])


if __name__ == "__main__":
    unittest.main()
