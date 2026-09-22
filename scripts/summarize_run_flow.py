"""Summarize local run evidence; never awards a human/FUN QA pass."""
import argparse
import json
import math
import statistics


def distribution(values):
    if not values:
        return {"samples": 0, "median_s": None, "p90_s": None}
    ordered = sorted(values)
    return {"samples": len(values), "median_s": statistics.median(values),
            "p90_s": ordered[math.ceil(len(ordered) * .9) - 1]}


def summarize(report):
    if report.get("schema") != 1:
        raise ValueError("unsupported run flow schema")
    visits = report.get("visits", [])
    decisions = report.get("decisions", [])
    loops = [row["loop_s"] for row in visits if row.get("status") == "complete"]
    resolved = [row for row in decisions if row.get("resolved")]
    first_after_clear = []
    for visit in visits:
        fight = visit.get("encounter", {})
        start, clear = fight.get("start_s", -1), fight.get("clear_s", -1)
        end = visit.get("next_entry_s", -1)
        if start < visit["entry_s"] or clear < start:
            continue
        choices = [row["end_s"] - clear for row in resolved
                   if row["room"] == visit["room"] and row["open_s"] >= clear
                   and (end < 0 or row["end_s"] <= end)]
        if choices:
            first_after_clear.append(min(choices))
    result = {
        "run_id": report["run_id"], "outcome": report["outcome"],
        "ended": report["ended"], "clock": report["clock"],
        "context": report.get("context", {}),
        "loop": distribution(loops),
        "loop_60_to_120_s_count": sum(60 <= value <= 120 for value in loops),
        "resolved_preview": distribution([row["duration_s"] for row in resolved]),
        "first_decision_after_clear": distribution(first_after_clear),
        "first_decision_after_clear_le_3_s_count": sum(value <= 3 for value in first_after_clear),
        "interrupted_previews": sum(not row.get("resolved", False) for row in decisions),
        "noncomplete_visits": len(visits) - len(loops),
        "missing_events": report.get("missing_events", 0),
        "overflow": report.get("overflow", 0),
        "missing_sources": [key for key, enabled in report.get("sources", {}).items() if not enabled],
        "human_acceptance": "not_evaluated",
        "warning": "First decision is not all rewards processed; missing/unfinished samples are not passes.",
    }
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", help="run-flow-latest.json (or browser RUN_FLOW_JSON payload)")
    args = parser.parse_args()
    with open(args.report, encoding="utf-8") as source:
        print(json.dumps(summarize(json.load(source)), ensure_ascii=False, indent=2))
