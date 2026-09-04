(function () {
  "use strict";

  var initializedHosts = new WeakSet();
  var dataPromise = null;
  var scriptUrl = document.currentScript && document.currentScript.src
    ? new URL(document.currentScript.src, window.location.href)
    : null;

  function element(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (typeof text === "string") node.textContent = text;
    return node;
  }

  function siteRoot() {
    if (scriptUrl) return new URL("../", scriptUrl);
    return new URL("/", window.location.href);
  }

  function loadData() {
    if (!dataPromise) {
      dataPromise = fetch(new URL("assets/project-ontology.json", siteRoot()), {
        cache: "no-cache",
        credentials: "same-origin"
      }).then(function (response) {
        if (!response.ok) throw new Error("project ontology unavailable");
        return response.json();
      });
    }
    return dataPromise;
  }

  function typeLabel(type) {
    return {
      principle: "원칙",
      decision: "결정",
      risk: "위험",
      work_item: "작업",
      module: "코드 모듈",
      document: "근거 문서",
      authority: "판단 주체"
    }[type] || type;
  }

  function relationLabel(type) {
    return {
      decides: "최종 판단",
      documented_by: "문서 근거",
      informed_by: "판단 근거",
      governs: "적용 원칙",
      governed_by: "원칙 적용",
      implemented_by: "구현 모듈",
      verified_by: "검증 근거",
      configured_by: "데이터 설정",
      affects: "영향 대상",
      blocks: "진행 차단",
      requires: "선행 의존",
      extends: "확장 기반"
    }[type] || type;
  }

  function buildConsole(data) {
    var objectById = new Map(data.objects.map(function (item) { return [item.id, item]; }));
    var statusById = new Map(data.statuses.map(function (item) { return [item.id, item]; }));
    var trackedTypes = new Set(["principle", "decision", "risk", "work_item"]);
    var tracked = data.objects.filter(function (item) { return trackedTypes.has(item.type); });
    var requested = new URL(window.location.href).searchParams.get("decision");
    var initial = requested && tracked.some(function (item) { return item.id === requested; })
      ? requested
      : (tracked.find(function (item) { return item.status === "needs_decision"; }) || tracked[0]).id;
    var state = { selected: initial, status: "all", type: "all", query: "" };

    var wrapper = element("section", "sfh-owner-console");
    wrapper.setAttribute("data-sfh-owner-decision-console", "");
    wrapper.setAttribute("aria-labelledby", "sfh-owner-console-title");

    var header = element("header", "sfh-owner-console__header");
    var heading = element("div", "");
    heading.append(element("small", "", "OWNER DECISION ONTOLOGY // READ ONLY"));
    var title = element("h2", "", "프로젝트 오너 판단 콘솔");
    title.id = "sfh-owner-console-title";
    heading.append(title, element("p", "", "기획 제안과 개발 근거를 모아 최종 판단이 필요한 순서로 보여줍니다."));
    var authority = element("div", "sfh-owner-console__authority");
    authority.append(
      element("small", "", "FINAL AUTHORITY"),
      element("b", "", data.authority.label),
      element("span", "", "범위 · 우선순위 · 수락 · 출시")
    );
    header.append(heading, authority);

    var metrics = element("div", "sfh-owner-console__metrics");
    [
      [data.summary.owner_decisions, "오너 판단 필요", "needs_decision"],
      [data.summary.blocked, "선행 조건 대기", "blocked"],
      [data.summary.ready, "구현 준비", "ready"],
      [data.summary.implemented, "구현·검증됨", "implemented"]
    ].forEach(function (item) {
      var metric = element("button", "is-" + item[2]);
      metric.type = "button";
      metric.dataset.status = item[2];
      metric.setAttribute("aria-pressed", "false");
      metric.append(element("b", "", String(item[0])), element("small", "", item[1]));
      metric.addEventListener("click", function () {
        state.status = state.status === item[2] ? "all" : item[2];
        syncControls();
        renderList();
      });
      metrics.append(metric);
    });

    var toolbar = element("div", "sfh-owner-console__toolbar");
    var search = element("input", "");
    search.type = "search";
    search.placeholder = "결정·위험·작업·근거 검색";
    search.setAttribute("aria-label", "프로젝트 판단 객체 검색");
    var typeSelect = element("select", "");
    typeSelect.setAttribute("aria-label", "판단 객체 유형 필터");
    [
      ["all", "전체 유형"],
      ["decision", "결정"],
      ["risk", "위험"],
      ["work_item", "작업"],
      ["principle", "원칙"]
    ].forEach(function (item) {
      var option = element("option", "", item[1]);
      option.value = item[0];
      typeSelect.append(option);
    });
    var statusSelect = element("select", "");
    statusSelect.setAttribute("aria-label", "판단 상태 필터");
    var allStatus = element("option", "", "전체 상태");
    allStatus.value = "all";
    statusSelect.append(allStatus);
    data.statuses.forEach(function (status) {
      var option = element("option", "", status.label);
      option.value = status.id;
      statusSelect.append(option);
    });
    toolbar.append(search, typeSelect, statusSelect);

    var workspace = element("div", "sfh-owner-console__workspace");
    var listWrap = element("section", "sfh-owner-console__list-wrap");
    var listHeader = element("header", "");
    listHeader.append(element("b", "", "판단 대기열"), element("small", "sfh-owner-console__result", ""));
    var list = element("div", "sfh-owner-console__list");
    list.setAttribute("role", "list");
    listWrap.append(listHeader, list);
    var detail = element("aside", "sfh-owner-console__detail");
    detail.tabIndex = -1;
    detail.setAttribute("aria-live", "polite");
    workspace.append(listWrap, detail);

    var footer = element("footer", "sfh-owner-console__footer");
    footer.append(
      element("span", "", "읽기 전용 · 상태 변경은 원본과 PR에서 수행"),
      element("code", "", data.source_sha256.slice(0, 12))
    );

    function syncControls() {
      typeSelect.value = state.type;
      statusSelect.value = state.status;
      metrics.querySelectorAll("button").forEach(function (button) {
        button.setAttribute("aria-pressed", String(button.dataset.status === state.status));
      });
    }

    function selectObject(objectId, focus) {
      if (!objectById.has(objectId) || !trackedTypes.has(objectById.get(objectId).type)) return;
      state.selected = objectId;
      var url = new URL(window.location.href);
      url.searchParams.set("decision", objectId);
      window.history.replaceState({}, "", url);
      renderList();
      renderDetail();
      if (focus) detail.focus({ preventScroll: true });
    }

    function relationEntries(objectId) {
      return data.relations.filter(function (relation) {
        return relation.from === objectId || relation.to === objectId;
      }).map(function (relation) {
        var outgoing = relation.from === objectId;
        return {
          relation: relation,
          target: objectById.get(outgoing ? relation.to : relation.from),
          outgoing: outgoing
        };
      }).filter(function (item) { return Boolean(item.target); });
    }

    function matches(item) {
      if (state.type !== "all" && item.type !== state.type) return false;
      if (state.status !== "all" && item.status !== state.status) return false;
      if (!state.query) return true;
      var relationText = relationEntries(item.id).map(function (entry) { return entry.target.label; }).join(" ");
      return [item.id, item.label, item.summary, item.next_action || "", relationText]
        .join(" ").toLocaleLowerCase("ko").includes(state.query);
    }

    function renderList() {
      list.replaceChildren();
      var filtered = tracked.filter(matches).sort(function (a, b) {
        var aRank = (statusById.get(a.status) || { rank: 99 }).rank;
        var bRank = (statusById.get(b.status) || { rank: 99 }).rank;
        return aRank - bRank || a.label.localeCompare(b.label, "ko");
      });
      wrapper.querySelector(".sfh-owner-console__result").textContent = filtered.length + " / " + tracked.length;
      if (!filtered.length) {
        list.append(element("p", "sfh-owner-console__empty", "조건에 맞는 판단 객체가 없습니다."));
        return;
      }
      filtered.forEach(function (item) {
        var button = element("button", "sfh-owner-object is-" + item.status);
        button.type = "button";
        button.setAttribute("role", "listitem");
        button.setAttribute("aria-pressed", String(item.id === state.selected));
        var top = element("span", "sfh-owner-object__top");
        top.append(
          element("small", "", typeLabel(item.type)),
          element("em", "", (statusById.get(item.status) || { label: item.status }).label)
        );
        button.append(top, element("b", "", item.label), element("span", "", item.summary));
        button.addEventListener("click", function () { selectObject(item.id, true); });
        list.append(button);
      });
    }

    function appendField(host, label, value) {
      if (!value) return;
      var row = element("div", "sfh-owner-console__field");
      row.append(element("small", "", label), element("p", "", value));
      host.append(row);
    }

    function targetControl(entry) {
      var target = entry.target;
      var label = (entry.outgoing ? "→ " : "← ") + relationLabel(entry.relation.type);
      if (target.route !== undefined) {
        var link = element("a", "sfh-owner-relation");
        link.href = new URL(target.route, siteRoot()).href;
        link.append(element("small", "", label), element("b", "", target.label));
        return link;
      }
      if (trackedTypes.has(target.type)) {
        var button = element("button", "sfh-owner-relation");
        button.type = "button";
        button.append(element("small", "", label), element("b", "", target.label));
        button.addEventListener("click", function () { selectObject(target.id, true); });
        return button;
      }
      var text = element("span", "sfh-owner-relation");
      text.append(element("small", "", label), element("b", "", target.label));
      return text;
    }

    function renderDetail() {
      detail.replaceChildren();
      var item = objectById.get(state.selected);
      if (!item) return;
      var status = statusById.get(item.status) || { label: item.status };
      var top = element("header", "");
      var headingBox = element("div", "");
      headingBox.append(element("small", "", typeLabel(item.type) + " · " + item.certainty), element("h3", "", item.label));
      top.append(headingBox, element("em", "is-" + item.status, status.label));
      detail.append(top);
      appendField(detail, "현재 판단", item.summary);
      appendField(detail, "수락 조건", item.acceptance);
      appendField(detail, "다음 행동", item.next_action);
      appendField(detail, "최종 판단 주체", data.authority.label + " · 기획/개발은 근거 제공자");
      var related = relationEntries(item.id).filter(function (entry) {
        return entry.target.id !== data.authority.id;
      });
      var relations = element("div", "sfh-owner-console__relations");
      relations.append(element("h4", "", "직접 관계 · " + related.length));
      related.forEach(function (entry) { relations.append(targetControl(entry)); });
      detail.append(relations);
    }

    search.addEventListener("input", function () {
      state.query = search.value.trim().toLocaleLowerCase("ko");
      renderList();
    });
    typeSelect.addEventListener("change", function () { state.type = typeSelect.value; renderList(); });
    statusSelect.addEventListener("change", function () {
      state.status = statusSelect.value;
      syncControls();
      renderList();
    });

    wrapper.append(header, metrics, toolbar, workspace, footer);
    syncControls();
    renderList();
    renderDetail();
    return wrapper;
  }

  function initialize() {
    document.querySelectorAll("[data-sfh-owner-decision-console-host]").forEach(function (host) {
      if (initializedHosts.has(host)) return;
      initializedHosts.add(host);
      loadData().then(function (data) {
        if (host.isConnected && !host.querySelector("[data-sfh-owner-decision-console]")) {
          host.append(buildConsole(data));
        }
      }).catch(function () {
        host.append(element("p", "sfh-owner-console__error", "판단 콘솔을 불러오지 못했습니다. 인증 상태와 생성 검사를 확인해 주세요."));
      });
    });
  }

  if (window.document$ && typeof window.document$.subscribe === "function") {
    window.document$.subscribe(initialize);
  } else if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initialize);
  } else {
    initialize();
  }
})();
