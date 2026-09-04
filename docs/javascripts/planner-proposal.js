(function () {
  "use strict";

  function text(host, selector) {
    var field = host.querySelector(selector);
    return field ? field.value.trim() : "";
  }

  function renderDraft(host) {
    var kind = text(host, "[name='kind']") || "PLAN";
    var status = text(host, "[name='status']") || "제안";
    var requestId = text(host, "[name='request_id']") || kind + "-P?-??-??";
    var titleInput = text(host, "[name='title']");
    var scopeInput = text(host, "[name='scope']");
    var decisionInput = text(host, "[name='decision']");
    var appliesAtInput = text(host, "[name='applies_at']");
    var acceptanceInput = text(host, "[name='acceptance']");
    var title = titleInput || "제목 입력 필요";
    var scope = scopeInput || "미정 — 적용 대상을 작성하세요";
    var decision = decisionInput || "미정 — 플레이어에게 일어날 동작을 작성하세요";
    var unknowns = text(host, "[name='unknowns']") || "미정 — 예외가 없으면 없음이라고 작성하세요";
    var appliesAt = appliesAtInput || "미정";
    var reviewTrigger = text(host, "[name='review_trigger']") || "미정";
    var basis = text(host, "[name='basis']") || "Notion 근거 블록 또는 결정 ID 입력 필요";
    var acceptance = acceptanceInput || "플레이어가 인지할 수 있는 완료 조건 입력 필요";
    var sheet = text(host, "[name='sheet_target']") || "목록 추가 시 Google Sheet 확장 → 확정 CSV";
    var supersedesInput = text(host, "[name='supersedes']");
    var supersedes = supersedesInput || "없음";
    var required = [[titleInput, "제목"], [scopeInput, "대상"], [decisionInput, "결정"], [appliesAtInput, "적용 시점"], [acceptanceInput, "수락 기준"]];
    var missing = required.filter(function (entry) { return !entry[0]; }).map(function (entry) { return entry[1]; });
    var readiness = "오너 확정 검토 가능";
    if (status === "제안" || status === "보류") readiness = "작업 금지 — 상태 변경 전 비교·기록만 수행";
    else if (status === "임시" || status === "부분 확정") readiness = "임시 시험 가능 — 미정 항목은 기획 완료로 계산하지 않음";
    else if (status === "변경" && !supersedesInput) readiness = "결정 필요 — 변경할 이전 결정 ID 입력";
    else if ((status === "확정" || status === "변경" || status === "검수 완료") && missing.length) readiness = "결정 필요 — " + missing.join("·") + " 입력";
    var draft = [
      "## [" + requestId + "][" + status + "] " + title,
      "",
      "- 상태: " + status,
      "- 대상: " + scope,
      "- 결정: " + decision,
      "- 미정·예외: " + unknowns,
      "- 적용 시점: " + appliesAt,
      "- 근거: " + basis,
      "- 수락 기준: " + acceptance,
      "- 데이터: " + sheet,
      "- 재검토 조건: " + reviewTrigger,
      "- 반영 준비: " + readiness,
      "- 최종 판단 주체: 프로젝트 오너",
      "- 구현 원칙: 모듈 경계 + 플레이어 인식 E2E + PR 검증",
      "- supersedes: " + supersedes,
      "- conflicts_with: 없음",
    ].join("\n");
    var output = host.querySelector("[data-sfh-proposal-output]");
    if (output) output.value = draft;
    var state = host.querySelector("[data-sfh-proposal-state]");
    if (state) state.textContent = readiness;
    return draft;
  }

  async function copyDraft(host) {
    var draft = renderDraft(host);
    try {
      await navigator.clipboard.writeText(draft);
      host.querySelector("[data-sfh-proposal-state]").textContent = "복사 완료 · Notion에 붙여넣은 뒤 결정 ID를 유지하세요.";
    } catch (_error) {
      var output = host.querySelector("[data-sfh-proposal-output]");
      output.focus();
      output.select();
      host.querySelector("[data-sfh-proposal-state]").textContent = "자동 복사가 차단됐습니다. 선택된 초안을 직접 복사하세요.";
    }
  }

  function install() {
    var host = document.querySelector("[data-sfh-proposal-composer]");
    if (!host || host.dataset.ready === "true") return;
    host.dataset.ready = "true";
    host.addEventListener("input", function () { renderDraft(host); });
    host.querySelector("[data-sfh-proposal-copy]").addEventListener("click", function () { copyDraft(host); });
    renderDraft(host);
  }

  if (window.document$ && typeof window.document$.subscribe === "function") {
    window.document$.subscribe(install);
  } else {
    document.addEventListener("DOMContentLoaded", install);
  }
})();
