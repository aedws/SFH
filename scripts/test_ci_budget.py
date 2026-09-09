"""Behavioral regression gates for CI savings without accepting untested code."""
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import ci_budget as ci


class RoutingTests(unittest.TestCase):
    def test_git_trust_is_limited_to_current_checkout(self):
        with patch.object(ci.subprocess, "check_output", return_value="tree\n") as command:
            self.assertEqual(ci.git("rev-parse", "HEAD^{tree}"), "tree")
            command.assert_called_once_with(
                ["git", "-c", f"safe.directory={Path.cwd().as_posix()}", "rev-parse", "HEAD^{tree}"], text=True)

    def test_gate_handles_omitted_empty_outputs_and_fails_closed(self):
        def needs(game="true", reuse=None, export="success", e2e="success", windows="skipped", plan="success"):
            outputs = {"game": game}
            if reuse is not None:
                outputs["reuse_run"] = reuse
            return {"plan": {"result": plan, "outputs": outputs},
                    "export-game": {"result": export}, "e2e": {"result": e2e},
                    "package-windows": {"result": windows}}
        ci.require_checks(needs(), "pull_request")
        ci.require_checks(needs(windows="success"), "push")
        ci.require_checks(needs(game="false", export="skipped", e2e="skipped"), "push")
        for state, event in ((needs(export="failure"), "pull_request"),
                             (needs(reuse="123", export="skipped", e2e="skipped", windows="success"), "push"),
                             (needs(e2e="cancelled"), "pull_request"),
                             (needs(), "push"), (needs(plan="failure"), "pull_request"),
                             (needs(game="unknown"), "push")):
            with self.assertRaises(ValueError):
                ci.require_checks(state, event)

    def test_docs_skip_but_unknown_deleted_and_build_inputs_do_not(self):
        self.assertTrue(ci.documentation_only(["docs/index.md", "docs/stylesheets/extra.css"]))
        for paths in ([], ["game/foo.gd"], [".godot-version"], ["export_presets.cfg"],
                      ["scripts/sync_new_catalog.py"], ["docs/index.md", "new-engine-config"]):
            self.assertFalse(ci.documentation_only(paths), paths)

    def test_payload_rejects_changed_tree_missing_extra_and_tampered_files(self):
        files = {"index.html": b"html", "index.wasm": b"wasm", "index.pck": b"pack"}
        files[ci.PROOF] = json.dumps({"schema": 1, "tree": "tree", "run_id": "123",
                                     "files": ci.payload_hashes(files)}).encode()
        ci.verify_payload(files, "tree", "123")
        for tree, run in (("wrong", "123"), ("tree", "456")):
            with self.assertRaises(ValueError):
                ci.verify_payload(files, tree, run)
        for key, value in (("index.pck", b"changed"), ("injected.js", b"extra")):
            with self.assertRaises(ValueError):
                ci.verify_payload(dict(files, **{key: value}), "tree", "123")
        del files["index.wasm"]
        with self.assertRaises(ValueError):
            ci.verify_payload(files, "tree", "123")

    def test_game_push_always_uses_full_checks_without_artifact_api(self):
        with tempfile.TemporaryDirectory() as directory:
            event = Path(directory) / "event.json"
            output = Path(directory) / "out"
            event.write_text(json.dumps({"before": "b" * 40}))
            env = {"GITHUB_EVENT_PATH": str(event), "GITHUB_EVENT_NAME": "push",
                   "GITHUB_SHA": "a" * 40, "GITHUB_REPOSITORY": "owner/repo",
                   "GITHUB_RUN_ID": "456", "GITHUB_OUTPUT": str(output)}
            with patch.dict(ci.os.environ, env), patch.object(ci, "git", side_effect=["tree", "game/new.gd"]):
                ci.plan()
            result = output.read_text()
            self.assertIn("game=true", result)
            self.assertNotIn("reuse_run", result)

    def test_documents_preserve_game_and_never_attempt_reuse(self):
        with tempfile.TemporaryDirectory() as directory:
            event = Path(directory) / "event.json"
            output = Path(directory) / "out"
            event.write_text(json.dumps({"before": "b" * 40}))
            env = {"GITHUB_EVENT_PATH": str(event), "GITHUB_EVENT_NAME": "push",
                   "GITHUB_SHA": "a" * 40, "GITHUB_REPOSITORY": "owner/repo",
                   "GITHUB_RUN_ID": "456", "GITHUB_OUTPUT": str(output)}
            with patch.dict(ci.os.environ, env), patch.object(ci, "git", side_effect=["tree", "docs/index.md"]):
                ci.plan()
            self.assertIn("game=false", output.read_text())

    def test_runner_is_manual_only_and_never_falls_back_to_hosted(self):
        with tempfile.TemporaryDirectory() as directory:
            event = Path(directory) / "event.json"
            output = Path(directory) / "out"
            for sender, repository, lease, enabled, expected in (
                ("owner", "owner/repo", "1180", "true", True),
                ("owner", "owner/repo", "999", "true", True),
                ("owner", "owner/repo", "99999999", "true", True),
                ("owner", "owner/repo", "invalid", "true", True),
                ("owner", "owner/repo", "1180", "false", True),
                ("collaborator", "owner/repo", "1180", "true", False),
                ("owner", "other/fork", "1180", "true", False),
            ):
                event.write_text(json.dumps({"sender": {"login": sender}, "pull_request": {
                    "base": {"sha": "b" * 40}, "head": {"repo": {"full_name": repository}}}}))
                output.write_text("")
                env = {"GITHUB_EVENT_PATH": str(event), "GITHUB_EVENT_NAME": "pull_request",
                       "GITHUB_SHA": "a" * 40, "GITHUB_REPOSITORY": "owner/repo",
                       "GITHUB_RUN_ID": "456", "GITHUB_OUTPUT": str(output),
                       "SFH_SELF_HOSTED_ENABLED": enabled, "SFH_SELF_HOSTED_READY_UNTIL": lease}
                with self.subTest(sender=sender, repo=repository, lease=lease, enabled=enabled), \
                     patch.dict(ci.os.environ, env), \
                     patch.object(ci, "git", side_effect=["tree", "game/new.gd"]):
                    if expected:
                        ci.plan()
                        self.assertIn('runner=["self-hosted"', output.read_text())
                        self.assertNotIn('ubuntu-', output.read_text())
                    else:
                        with self.assertRaisesRegex(ValueError, 'Untrusted PR'):
                            ci.plan()
                        self.assertEqual(output.read_text(), '')

    def test_every_workflow_uses_private_runner_and_trust_gate(self):
        # Guard the bootstrap/build/deploy jobs too, not just the routed game jobs.
        import yaml
        root = Path(__file__).resolve().parents[1]
        for file in (root / '.github/workflows').glob('*.yml'):
            data = yaml.safe_load(file.read_text(encoding='utf-8'))
            for name, job in data['jobs'].items():
                runner = job.get('runs-on')
                self.assertTrue(runner == ['self-hosted', 'Linux', 'X64', 'sfh-build']
                                or runner == '${{ fromJSON(needs.plan.outputs.runner) }}', (file, name))
        deploy = (root / ci.WORKFLOW).read_text(encoding='utf-8')
        self.assertIn('github.actor == github.repository_owner', deploy)
        self.assertIn("!cancelled() && needs.plan.result == 'success'", deploy)


if __name__ == "__main__":
    unittest.main()
