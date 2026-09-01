(function () {
  "use strict";

  function text(host, selector) {
    var field = host.querySelector(selector);
    return field ? field.value.trim() : "";
  }

  function renderDraft(host) {
    var kind = text(host, "[name='kind']") || "PLAN";
    var requestId = text(host, "[name='request_id']") || kind + "-P?-??-??";
    var title = text(host, "[name='title']") || "제목 입력 필요";
    var basis = text(host, "[name='basis']") || "Notion 근거 블록 또는 결정 ID 입력 필요";
    var acceptance = text(host, "[name='acceptance']") || "플레이어가 인지할 수 있는 완료 조건 입력 필요";
    var sheet = text(host, "[name='sheet_target']") || "목록 추가 시 Google Sheet 확장 → 확정 CSV";
    var draft = [
      "## " + requestId + " · " + title,
      "",
      "- 상태: 제안 초안 (Notion 승인 전 미확정)",
      "- 근거: " + basis,
      "- 수락 기준: " + acceptance,
      "- 데이터: " + sheet,
      "- 구현 원칙: 모듈 경계 + 플레이어 인식 E2E + PR 검증",
      "- supersedes: 없음",
      "- conflicts_with: 없음",
    ].join("\n");
    var output = host.querySelector("[data-sfh-proposal-output]");
    if (output) output.value = draft;
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
