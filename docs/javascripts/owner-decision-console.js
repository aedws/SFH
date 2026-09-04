(function () {
  "use strict";

  var initializedHosts = new WeakSet();
  var dataPromise = null;
  var scriptUrl = document.currentScript && document.currentScript.src ? new URL(document.currentScript.src, location.href) : null;

  function element(tag, className, value) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (typeof value === "string") node.textContent = value;
    return node;
  }

  function siteRoot() { return scriptUrl ? new URL("../", scriptUrl) : new URL("/", location.href); }

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
    return ({ principle: "원칙", decision: "결정", risk: "위험", work_item: "작업", module: "코드 모듈", document: "근거 문서", source: "원본 시스템", authority: "판단 주체", contributor: "근거 제공자" })[type] || type;
  }

  function relationLabel(type) {
    return ({ decides: "최종 판단", documented_by: "문서 근거", informed_by: "판단 근거", governs: "적용 원칙", governed_by: "원칙 적용", implemented_by: "구현", verified_by: "검증", configured_by: "데이터 설정", affects: "영향", blocks: "진행 차단", requires: "선행 의존", extends: "확장 기반" })[type] || type;
  }

  function buildConsole(data) {
    var objectById = new Map(data.objects.map(function (item) { return [item.id, item]; }));
    var statusById = new Map(data.statuses.map(function (item) { return [item.id, item]; }));
    var actionById = new Map(data.action_types.map(function (item) { return [item.id, item]; }));
    var trackedTypes = new Set(["principle", "decision", "risk", "work_item"]);
    var tracked = data.objects.filter(function (item) { return trackedTypes.has(item.type); });
    var requested = new URL(location.href).searchParams.get("decision");
    var fallback = tracked.find(function (item) { return item.status === "needs_decision"; }) || tracked[0];
    var state = { selected: requested && objectById.has(requested) ? requested : fallback.id, view: "decisions" };

    var wrapper = element("section", "sfh-owner-console");
    wrapper.setAttribute("data-sfh-owner-decision-console", "");
    wrapper.setAttribute("aria-labelledby", "sfh-owner-console-title");
    var header = element("header", "sfh-owner-console__header");
    var heading = element("div");
    heading.append(element("small", "", "SFH OPERATIONAL ONTOLOGY // READ ONLY"));
    var title = element("h2", "", "프로젝트 오너 운영 콘솔");
    title.id = "sfh-owner-console-title";
    heading.append(title, element("p", "", "객체·관계·행동·원본·검증 계보를 한곳에서 추적합니다."));
    var authority = element("div", "sfh-owner-console__authority");
    authority.append(element("small", "", "FINAL AUTHORITY"), element("b", "", data.authority.label), element("span", "", "범위 · 우선순위 · 수락 · 출시"));
    header.append(heading, authority);

    var lifecycle = element("ol", "sfh-owner-console__lifecycle");
    lifecycle.setAttribute("aria-label", "판단에서 배포까지 운영 생명 주기");
    data.lifecycle.forEach(function (stage, index) {
      var action = actionById.get(stage.action);
      var item = element("li");
      item.append(element("i", "", String(index + 1).padStart(2, "0")), element("b", "", stage.label), element("small", "", action ? action.label : stage.action));
      lifecycle.append(item);
    });

    var metrics = element("div", "sfh-owner-console__metrics");
    [[data.summary.owner_decisions, "오너 판단 필요", "needs_decision"], [data.summary.blocked, "선행 조건 대기", "blocked"], [data.summary.ready, "구현 준비", "ready"], [data.summary.implemented, "구현·검증됨", "implemented"]].forEach(function (item) {
      var metric = element("button", "is-" + item[2]);
      metric.type = "button";
      metric.append(element("b", "", String(item[0])), element("small", "", item[1]));
      metric.addEventListener("click", function () { state.view = "decisions"; renderTabs(); renderDecisionView(item[2]); });
      metrics.append(metric);
    });

    var tabs = element("div", "sfh-owner-console__tabs");
    tabs.setAttribute("role", "tablist");
    [["decisions", "판단 대기열", "결정·위험·작업"], ["objects", "객체 탐색", "모든 운영 객체"], ["lineage", "관계·계보", "원본→판단→결과"], ["operations", "행동·관측", "권한·가드·건강도"]].forEach(function (definition) {
      var button = element("button");
      button.type = "button";
      button.setAttribute("role", "tab");
      button.dataset.view = definition[0];
      button.append(element("b", "", definition[1]), element("small", "", definition[2]));
      button.addEventListener("click", function () { state.view = definition[0]; renderTabs(); renderView(); });
      tabs.append(button);
    });

    var viewport = element("div", "sfh-owner-console__viewport");
    viewport.setAttribute("role", "tabpanel");
    var footer = element("footer", "sfh-owner-console__footer");
    footer.append(element("span", "", "읽기 전용 · 변경은 승인된 원본과 PR에서만 수행"), element("code", "", data.source_sha256.slice(0, 12)));

    function relationEntries(objectId) {
      return data.relations.filter(function (relation) { return relation.from === objectId || relation.to === objectId; }).map(function (relation) {
        var outgoing = relation.from === objectId;
        return { relation: relation, target: objectById.get(outgoing ? relation.to : relation.from), outgoing: outgoing };
      }).filter(function (entry) { return Boolean(entry.target); });
    }

    function setSelected(objectId, nextView) {
      if (!objectById.has(objectId)) return;
      state.selected = objectId;
      if (nextView) state.view = nextView;
      var url = new URL(location.href);
      url.searchParams.set("decision", objectId);
      history.replaceState({}, "", url);
      renderTabs();
      renderView();
    }

    function objectControl(item, compact) {
      var button = element("button", "sfh-owner-object is-" + (item.status || "reference"));
      button.type = "button";
      button.setAttribute("aria-pressed", String(item.id === state.selected));
      var top = element("span", "sfh-owner-object__top");
      top.append(element("small", "", typeLabel(item.type)), element("em", "", (statusById.get(item.status) || { label: item.status || "참조" }).label));
      button.append(top, element("b", "", item.label), element("span", "", item.summary || item.id));
      if (compact) button.classList.add("is-compact");
      button.addEventListener("click", function () { setSelected(item.id); });
      return button;
    }

    function appendField(host, label, value) {
      if (!value) return;
      var row = element("div", "sfh-owner-console__field");
      row.append(element("small", "", label), element("p", "", value));
      host.append(row);
    }

    function targetControl(entry) {
      var target = entry.target;
      var caption = (entry.outgoing ? "→ " : "← ") + relationLabel(entry.relation.type);
      if (target.route !== undefined) {
        var link = element("a", "sfh-owner-relation");
        link.href = new URL(target.route, siteRoot()).href;
        link.append(element("small", "", caption), element("b", "", target.label));
        return link;
      }
      var button = element("button", "sfh-owner-relation");
      button.type = "button";
      button.append(element("small", "", caption), element("b", "", target.label));
      button.addEventListener("click", function () { setSelected(target.id, "lineage"); });
      return button;
    }

    function detailPanel(item) {
      var detail = element("aside", "sfh-owner-console__detail");
      detail.setAttribute("aria-live", "polite");
      var status = statusById.get(item.status) || { label: item.status || "참조" };
      var top = element("header");
      var headingBox = element("div");
      headingBox.append(element("small", "", typeLabel(item.type) + " · " + (item.certainty || "derived")), element("h3", "", item.label));
      top.append(headingBox, element("em", "is-" + (item.status || "reference"), status.label));
      detail.append(top);
      appendField(detail, "현재 상태", item.summary);
      appendField(detail, "수락 조건", item.acceptance);
      appendField(detail, "다음 행동", item.next_action);
      if (trackedTypes.has(item.type)) appendField(detail, "최종 판단 주체", data.authority.label + " · 기획/개발은 근거 제공자");
      if (item.source) appendField(detail, "원본 위치", item.source);
      var related = relationEntries(item.id).filter(function (entry) { return entry.target.id !== data.authority.id; });
      var relations = element("div", "sfh-owner-console__relations");
      relations.append(element("h4", "", "직접 관계 · " + related.length));
      related.forEach(function (entry) { relations.append(targetControl(entry)); });
      detail.append(relations);
      return detail;
    }

    function filterToolbar(onChange, decisionOnly) {
      var toolbar = element("div", "sfh-owner-console__toolbar");
      var search = element("input");
      search.type = "search";
      search.placeholder = "객체·관계·근거 검색";
      search.setAttribute("aria-label", "프로젝트 온톨로지 검색");
      var select = element("select");
      select.setAttribute("aria-label", "객체 유형 필터");
      var all = element("option", "", "전체 유형"); all.value = "all"; select.append(all);
      data.object_types.filter(function (type) { return !decisionOnly || trackedTypes.has(type.id); }).forEach(function (type) {
        var option = element("option", "", type.label); option.value = type.id; select.append(option);
      });
      function changed() { onChange(search.value.trim().toLocaleLowerCase("ko"), select.value); }
      search.addEventListener("input", changed); select.addEventListener("change", changed);
      toolbar.append(search, select);
      return toolbar;
    }

    function renderDecisionView(forcedStatus) {
      viewport.replaceChildren();
      var filter = { query: "", type: "all", status: forcedStatus || "all" };
      var statusSelect = element("select");
      statusSelect.setAttribute("aria-label", "판단 상태 필터");
      var allStatus = element("option", "", "전체 상태"); allStatus.value = "all"; statusSelect.append(allStatus);
      data.statuses.forEach(function (status) { var option = element("option", "", status.label); option.value = status.id; statusSelect.append(option); });
      statusSelect.value = filter.status;
      var list = element("div", "sfh-owner-console__list");
      var workspace = element("div", "sfh-owner-console__workspace");
      var listWrap = element("section", "sfh-owner-console__list-wrap");
      var result = element("small", "sfh-owner-console__result");
      var listHeader = element("header"); listHeader.append(element("b", "", "판단 대기열"), result); listWrap.append(listHeader, list);
      function draw() {
        list.replaceChildren();
        var filtered = tracked.filter(function (item) {
          if (filter.type !== "all" && item.type !== filter.type) return false;
          if (filter.status !== "all" && item.status !== filter.status) return false;
          var related = relationEntries(item.id).map(function (entry) { return entry.target.label; }).join(" ");
          return !filter.query || [item.id, item.label, item.summary, item.next_action || "", related].join(" ").toLocaleLowerCase("ko").includes(filter.query);
        }).sort(function (a, b) { return (statusById.get(a.status) || { rank: 99 }).rank - (statusById.get(b.status) || { rank: 99 }).rank; });
        result.textContent = filtered.length + " / " + tracked.length;
        if (!filtered.length) list.append(element("p", "sfh-owner-console__empty", "조건에 맞는 판단 객체가 없습니다."));
        filtered.forEach(function (item) { list.append(objectControl(item)); });
      }
      var toolbar = filterToolbar(function (query, type) { filter.query = query; filter.type = type; draw(); }, true);
      toolbar.append(statusSelect);
      statusSelect.addEventListener("change", function () { filter.status = statusSelect.value; draw(); });
      viewport.append(toolbar); workspace.append(listWrap, detailPanel(objectById.get(state.selected))); viewport.append(workspace); draw();
    }

    function renderObjectView() {
      viewport.replaceChildren();
      var filter = { query: "", type: "all" };
      var layout = element("div", "sfh-owner-console__workspace");
      var listWrap = element("section", "sfh-owner-console__list-wrap");
      var list = element("div", "sfh-owner-console__object-grid");
      var result = element("small", "sfh-owner-console__result");
      var listHeader = element("header"); listHeader.append(element("b", "", "객체 레지스트리"), result); listWrap.append(listHeader, list);
      function draw() {
        list.replaceChildren();
        var filtered = data.objects.filter(function (item) { return (filter.type === "all" || item.type === filter.type) && (!filter.query || [item.id, item.label, item.summary || "", item.source || ""].join(" ").toLocaleLowerCase("ko").includes(filter.query)); });
        result.textContent = filtered.length + " / " + data.objects.length;
        filtered.slice(0, 120).forEach(function (item) { list.append(objectControl(item, true)); });
        if (filtered.length > 120) list.append(element("p", "sfh-owner-console__empty", "검색 범위를 좁히면 나머지 객체를 볼 수 있습니다."));
      }
      viewport.append(filterToolbar(function (query, type) { filter.query = query; filter.type = type; draw(); }, false));
      layout.append(listWrap, detailPanel(objectById.get(state.selected))); viewport.append(layout); draw();
    }

    function renderLineageView() {
      viewport.replaceChildren();
      var selected = objectById.get(state.selected) || fallback;
      var entries = relationEntries(selected.id);
      var upstream = entries.filter(function (entry) { return !entry.outgoing || ["informed_by", "requires", "governed_by", "configured_by"].includes(entry.relation.type); });
      var downstream = entries.filter(function (entry) { return entry.outgoing && !["informed_by", "requires", "governed_by", "configured_by"].includes(entry.relation.type); });
      function lane(label, items) {
        var column = element("section"); column.append(element("h3", "", label));
        if (!items.length) column.append(element("p", "sfh-owner-console__empty", "연결된 객체 없음"));
        items.forEach(function (entry) { column.append(targetControl(entry)); }); return column;
      }
      var center = element("section", "sfh-owner-lineage__focus");
      center.append(element("small", "", typeLabel(selected.type)), element("h3", "", selected.label), element("p", "", selected.summary || selected.id));
      var trace = element("div", "sfh-owner-lineage"); trace.append(lane("원본·선행", upstream), center, lane("구현·검증·영향", downstream));
      var picker = element("div", "sfh-owner-lineage__picker"); picker.append(element("b", "", "추적 기준 객체")); tracked.forEach(function (item) { picker.append(objectControl(item, true)); });
      viewport.append(picker, trace);
    }

    function renderOperationsView() {
      viewport.replaceChildren();
      var health = element("div", "sfh-owner-health");
      [[data.summary.broken_relations, "깨진 관계", "0이어야 통과"], [data.summary.ownerless_governed_objects, "오너 없는 판단", "0이어야 통과"], [data.summary.sources, "원본 시스템", "권한·상태 표시"], [data.summary.actions, "행동 계약", "입력·출력·가드"]].forEach(function (item) {
        var card = element("article"); card.append(element("b", "", String(item[0])), element("span", "", item[1]), element("small", "", item[2])); health.append(card);
      });
      var actions = element("div", "sfh-owner-action-grid");
      data.action_types.forEach(function (action, index) {
        var actor = objectById.get(action.actor); var card = element("article");
        card.append(element("small", "", "ACTION " + String(index + 1).padStart(2, "0")), element("h3", "", action.label), element("b", "", "실행 주체 · " + (actor ? actor.label : action.actor)), element("p", "", action.input + " → " + action.output), element("em", "", action.guard)); actions.append(card);
      });
      var sources = element("div", "sfh-owner-source-grid");
      data.source_systems.forEach(function (source) {
        var link = element("a"); link.href = new URL(source.route, siteRoot()).href;
        link.append(element("small", "", source.system + " · " + source.status), element("b", "", source.label), element("span", "", source.summary)); sources.append(link);
      });
      viewport.append(health, element("h3", "sfh-owner-section-title", "행동 계약 · 자동 실행 없음"), actions, element("h3", "sfh-owner-section-title", "원본 시스템과 계보"), sources);
    }

    function renderTabs() {
      tabs.querySelectorAll("button").forEach(function (button) { var active = button.dataset.view === state.view; button.setAttribute("aria-selected", String(active)); button.tabIndex = active ? 0 : -1; });
    }
    function renderView() {
      if (state.view === "objects") renderObjectView(); else if (state.view === "lineage") renderLineageView(); else if (state.view === "operations") renderOperationsView(); else renderDecisionView();
    }

    wrapper.append(header, lifecycle, metrics, tabs, viewport, footer); renderTabs(); renderView(); return wrapper;
  }

  function initialize() {
    document.querySelectorAll("[data-sfh-owner-decision-console-host]").forEach(function (host) {
      if (initializedHosts.has(host)) return;
      initializedHosts.add(host);
      loadData().then(function (data) { if (host.isConnected && !host.querySelector("[data-sfh-owner-decision-console]")) host.append(buildConsole(data)); }).catch(function () { host.append(element("p", "sfh-owner-console__error", "운영 콘솔을 불러오지 못했습니다. 인증 상태와 생성 검사를 확인해 주세요.")); });
    });
  }

  if (window.document$ && typeof window.document$.subscribe === "function") window.document$.subscribe(initialize);
  else if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", initialize);
  else initialize();
})();
