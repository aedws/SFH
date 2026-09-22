import unittest
from summarize_run_flow import summarize


class RunFlowSummaryTest(unittest.TestCase):
    def test_empty_is_not_pass(self):
        result = summarize(dict(schema=1, run_id="empty", outcome="lost", ended=True, clock="wall"))
        self.assertIsNone(result["loop"]["median_s"])
        self.assertEqual(result["human_acceptance"], "not_evaluated")

    def test_targets_are_counts_not_acceptance(self):
        report = dict(schema=1, run_id="fixture", outcome="extracted", ended=True, clock="wall",
                      visits=[dict(room=1, entry_s=0, next_entry_s=90, status="complete", loop_s=90,
                                   encounter=dict(start_s=1, clear_s=60))],
                      decisions=[dict(room=1, open_s=61, end_s=62, duration_s=1, resolved=True),
                                 dict(room=1, open_s=65, end_s=69, duration_s=4, resolved=False)],
                      sources={"decision_observed": True, "encounter_started": False})
        result = summarize(report)
        self.assertEqual(result["loop_60_to_120_s_count"], 1)
        self.assertEqual(result["first_decision_after_clear"]["median_s"], 2)
        self.assertEqual(result["interrupted_previews"], 1)
        self.assertEqual(result["missing_sources"], ["encounter_started"])
        self.assertEqual(result["human_acceptance"], "not_evaluated")


if __name__ == "__main__":
    unittest.main()
