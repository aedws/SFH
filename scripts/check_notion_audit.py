"""Validate the complete, manually reviewed Notion/code crosswalk and render its table."""
import argparse
import collections
import json
from pathlib import Path

import snapshot_notion_source as gdd
import snapshot_notion_tracker as tracker

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "docs/assets/notion-code-audit.json"
DOCUMENT = ROOT / "docs/design/master-gdd-alignment.md"
START, END = "<!-- notion-audit:start -->", "<!-- notion-audit:end -->"
LABELS = {"code_supported": "구현 근거 있음", "partial": "부분 대응", "conflict": "규칙 충돌", "missing": "신규 미구현", "decision_pending": "기획 판단 대기"}


def validate(audit, source, tasks):
    gdd.validate(source)
    tracker.validate(tasks)
    if audit["gdd_sha256"] != source["content_sha256"] or audit["tracker_sha256"] != tasks["content_sha256"]:
        raise ValueError("source drift: review the GDD AND tracker before updating audit hashes")
    expected = {row["id"]: row for row in tasks["rows"]}
    rows = audit["rows"]
    if len(rows) != len(expected) or {row["notion_id"] for row in rows} != set(expected):
        raise ValueError("audit must cover every tracker row exactly once")
    if audit["scoring"]["weights"] != {"결정 (미구현)": 3, "미정 (검토필요)": 1} or audit["scoring"]["scores"] != {"code_supported": 1, "partial": 0.5, "conflict": 0, "missing": 0, "decision_pending": 0}:
        raise ValueError("scoring contract changed; requires explicit review")
    for row in rows:
        original = expected[row["notion_id"]]
        for field in ("title", "request_id", "planner_status"):
            if row[field] != original[field]:
                raise ValueError(f"source row mismatch: {row['notion_id']} {field}")
        if row["assessment"] not in LABELS or not row["finding"] or not row["next_packet"].startswith("N26-"):
            raise ValueError("invalid assessment or packet")
        if original["planner_status"] == "미정 (검토필요)" and row["assessment"] != "decision_pending":
            raise ValueError("undecided requirement must not silently become accepted")
        if not row["code"] or not row["existing_tests"]:
            raise ValueError("existing code/test reference or gap boundary required")
        for relative in row["code"] + row["existing_tests"]:
            path = (ROOT / relative).resolve()
            if not path.is_relative_to(ROOT.resolve()) or not path.is_file():
                raise ValueError(f"missing/unsafe evidence: {relative}")


def summary(audit):
    weights, scores = audit["scoring"]["weights"], audit["scoring"]["scores"]
    denominator = sum(weights[row["planner_status"]] for row in audit["rows"])
    numerator = sum(weights[row["planner_status"]] * scores[row["assessment"]] for row in audit["rows"])
    return numerator, denominator, collections.Counter(row["assessment"] for row in audit["rows"])


def render(audit, tasks):
    original = {r["id"]: r for r in tasks["rows"]}
    numerator, denominator, counts = summary(audit)
    lines = [START, "", "## 66개 항목 코드 대조", "",
             f"정적 코드·기존 테스트 소스 대조: **{numerator:g}/{denominator} = {100*numerator/denominator:.1f}%**. 출시 준비율이나 이번 턴의 실제 플레이 통과율이 아닙니다.", "",
             " / ".join(f"{LABELS[k]} {counts[k]}" for k in LABELS), "",
             "확정 요구 ×3, 미정 ×1. 구현 근거 1점, 부분 0.5점, 충돌·신규 미구현·판단 대기 0점. 테스트 파일은 검증해야 할 기존 근거이며, 파일 존재만으로 최신 요구 전체의 E2E 통과를 선언하지 않습니다.", ""]
    for request_id in sorted({r["request_id"] for r in audit["rows"]}):
        subset = sorted((r for r in audit["rows"] if r["request_id"] == request_id), key=lambda r:r["title"])
        lines += [f'<details markdown="1"><summary>{request_id} · {len(subset)}개 항목</summary>', ""]
        for row in subset:
            url = "https://wobbly-pawpaw-1ff.notion.site/" + row["notion_id"].replace("-", "")
            lines += [f"### [{row['title']}]({url})", "",
                      f"노션: **{row['planner_status']}** · 코드: **{LABELS[row['assessment']]}** · 작업: **{row['next_packet']}**", "",
                      row["finding"], "", "수락 기준: " + original[row["notion_id"]]["acceptance"], "",
                      "코드 경계: " + ", ".join(f"`{p}`" for p in row["code"]), "",
                      "기존 검사 근거: " + ", ".join(f"`{p}`" for p in row["existing_tests"]), ""]
        lines += ["</details>", ""]
    return "\n".join(lines + [END])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--render", action="store_true")
    args = parser.parse_args()
    audit = json.loads(AUDIT.read_text(encoding="utf-8"))
    source = json.loads((ROOT / "docs/assets/notion-source-snapshot.json").read_text(encoding="utf-8"))
    tasks = json.loads((ROOT / "docs/assets/notion-tracker-snapshot.json").read_text(encoding="utf-8"))
    validate(audit, source, tasks)
    document = DOCUMENT.read_text(encoding="utf-8")
    if document.count(START) != 1 or document.count(END) != 1:
        raise ValueError("audit document markers missing or duplicated")
    before, remainder = document.split(START)
    _, after = remainder.split(END)
    expected = before + render(audit, tasks) + after
    if args.render:
        DOCUMENT.write_text(expected, encoding="utf-8")
    elif document != expected:
        raise ValueError("audit document stale; review data then render")
    numerator, denominator, counts = summary(audit)
    print(f"NOTION_CODE_AUDIT_OK rows={len(audit['rows'])} score={numerator:g}/{denominator} states={dict(counts)}")


if __name__ == "__main__":
    main()
