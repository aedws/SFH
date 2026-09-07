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
    return ({ principle: "원칙", decision: "결정", risk: "위험", work_item: "작업", module: "코드 모듈", document: "근거 문서", collection: "문서 묶음", source: "원본 시스템", authority: "판단 주체", contributor: "근거 제공자" })[type] || type;
  }

  function relationLabel(type) {
    return ({ decides: "최종 판단", documented_by: "문서 근거", informed_by: "판단 근거", governs: "적용 원칙", governed_by: "원칙 적용", implemented_by: "구현", verified_by: "검증", configured_by: "데이터 설정", affects: "영향", blocks: "진행 차단", requires: "선행 의존", extends: "확장 기반", part_of: "소속" })[type] || type;
  }

  function sourceFreshness(source) {
    var freshness = source.freshness;
    if (!freshness) return { state: "validated", label: "저장소 검증", detail: "CI가 현재 저장소 산출물을 검증합니다." };
    if (!freshness.observed_at) return { state: "warning", label: "원본 확인 필요", detail: freshness.check || "실시간 원본을 확인해야 합니다." };
    var observed = Date.parse(freshness.observed_at);
    var ageDays = Number.isFinite(observed) ? Math.max(0, Math.floor((Date.now() - observed) / 86400000)) : Infinity;
    var maxAge = Number(freshness.max_age_days || 0);
    if (!Number.isFinite(ageDays) || ageDays > maxAge) {
      return { state: "stale", label: "갱신 확인 필요", detail: ageDays === Infinity ? freshness.check : ageDays + "일 전 관측 · " + freshness.check };
    }
    return { state: "current", label: "스냅샷 확인", detail: ageDays + "일 전 관측 · REV " + (freshness.revision || "-") };
  }

  function buildConsole(data, host) {
    var objectById = new Map(data.objects.map(function (item) { return [item.id, item]; }));
    var statusById = new Map(data.statuses.map(function (item) { return [item.id, item]; }));
    var actionById = new Map(data.action_types.map(function (item) { return [item.id, item]; }));
    var trackedTypes = new Set(["principle", "decision", "risk", "work_item"]);
    var tracked = data.objects.filter(function (item) { return trackedTypes.has(item.type); });
    var pageUrl = new URL(location.href);
    var requested = pageUrl.searchParams.get("decision");
    var requestedView = pageUrl.searchParams.get("view");
    var validViews = new Set(["overview", "decisions", "objects", "lineage", "operations"]);
    var fallback = objectById.get(host.dataset.focusObject) || tracked.find(function (item) { return item.status === "needs_decision"; }) || tracked[0];
    var state = {
      selected: requested && objectById.has(requested) ? requested : fallback.id,
      view: validViews.has(requestedView) ? requestedView : (requested && objectById.has(requested) ? "objects" : "overview"),
      decisions: { query: "", type: "all", status: "all", page: 0 },
      objects: { query: "", type: "all", page: 0 }
    };
    var pageSize = 6;
    if (requested && objectById.has(requested)) state.objects.page = Math.floor(data.objects.indexOf(objectById.get(requested)) / pageSize);

    var wrapper = element("section", "sfh-owner-console");
    wrapper.setAttribute("data-sfh-owner-decision-console", "");
    wrapper.setAttribute("aria-labelledby", "sfh-owner-console-title");
    var header = element("header", "sfh-owner-console__header");
    var heading = element("div");
    heading.append(element("small", "", "SFH OPERATIONAL ONTOLOGY // READ ONLY"));
    var title = element("h2", "", "개발 운영 작업대");
    title.id = "sfh-owner-console-title";
    heading.append(title, element("p", "", "작업 선택 → 선행 조건 → 코드·검증 근거"));
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
      metric.addEventListener("click", function () { state.decisions.status = item[2]; state.decisions.page = 0; switchView("decisions"); viewport.focus(); });
      metrics.append(metric);
    });

    var tabs = element("div", "sfh-owner-console__tabs");
    tabs.setAttribute("role", "tablist");
    [["overview", "작업 개요", "지금 볼 것"], ["decisions", "판단 대기열", "결정·위험·작업"], ["objects", "객체 탐색", "검색·선택"], ["lineage", "관계·계보", "연결 추적"], ["operations", "행동·관측", "검증·원본"]].forEach(function (definition) {
      var button = element("button");
      button.type = "button";
      button.setAttribute("role", "tab");
      button.id = "sfh-owner-tab-" + definition[0];
      button.setAttribute("aria-controls", "sfh-owner-panel");
      button.dataset.view = definition[0];
      button.append(element("b", "", definition[1]), element("small", "", definition[2]));
      button.addEventListener("click", function () {
        switchView(definition[0]);
      });
      tabs.append(button);
    });

    var viewport = element("div", "sfh-owner-console__viewport");
    viewport.id = "sfh-owner-panel";
    viewport.setAttribute("role", "tabpanel");
    viewport.tabIndex = 0;
    tabs.addEventListener("keydown", function (event) {
      var buttons = Array.from(tabs.querySelectorAll("button"));
      var index = buttons.indexOf(document.activeElement);
      if (index < 0 || !["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
      event.preventDefault();
      var next = event.key === "Home" ? 0 : event.key === "End" ? buttons.length - 1 : (index + (event.key === "ArrowRight" ? 1 : -1) + buttons.length) % buttons.length;
      buttons[next].click(); buttons[next].focus();
    });
    var footer = element("footer", "sfh-owner-console__footer");
    footer.append(element("span", "", "읽기 전용 · 최종 판단은 프로젝트 오너 · 변경은 승인된 원본과 PR에서만 수행"), element("code", "", data.source_sha256.slice(0, 12)));

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
      url.searchParams.set("view", state.view);
      history.replaceState({}, "", url);
      renderTabs();
      renderView();
      var selectedButton = Array.from(viewport.querySelectorAll("[data-object-id]")).find(function (button) { return button.dataset.objectId === objectId; });
      var detail = viewport.querySelector(".sfh-owner-console__detail");
      if (detail && window.matchMedia("(max-width: 768px)").matches) detail.focus();
      else if (selectedButton) selectedButton.focus({ preventScroll: true });
    }

    function switchView(view) {
      state.view = view;
      var url = new URL(location.href);
      url.searchParams.set("view", view);
      url.searchParams.set("decision", state.selected);
      history.replaceState({}, "", url);
      renderTabs(); renderView();
    }

    function objectControl(item, compact) {
      var button = element("button", "sfh-owner-object is-" + (item.status || "reference"));
      button.type = "button";
      button.dataset.objectId = item.id;
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
      detail.tabIndex = -1;
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
      var traceButton = element("button", "sfh-owner-command", "이 객체의 관계 추적 →");
      traceButton.type = "button";
      traceButton.addEventListener("click", function () { setSelected(item.id, "lineage"); viewport.focus(); });
      detail.append(traceButton);
      if (item.route !== undefined) {
        var sourceLink = element("a", "sfh-owner-command", "관련 문서 열기 ↗");
        sourceLink.href = new URL(item.route, siteRoot()).href; detail.append(sourceLink);
      }
      var related = relationEntries(item.id).filter(function (entry) { return entry.target.id !== data.authority.id; });
      var relations = element("div", "sfh-owner-console__relations");
      relations.append(element("h4", "", "직접 관계 · " + related.length));
      related.forEach(function (entry) { relations.append(targetControl(entry)); });
      var disclosure = element("details", "sfh-owner-disclosure");
      disclosure.append(element("summary", "", "연결 근거 " + related.length + "개 보기"), relations);
      detail.append(disclosure);
      return detail;
    }

    function filterToolbar(onChange, decisionOnly, filter) {
      var toolbar = element("div", "sfh-owner-console__toolbar");
      var search = element("input");
      search.type = "search";
      search.placeholder = "객체·관계·근거 검색";
      search.setAttribute("aria-label", "프로젝트 온톨로지 검색");
      search.value = filter.query;
      var select = element("select");
      select.setAttribute("aria-label", "객체 유형 필터");
      var all = element("option", "", "전체 유형"); all.value = "all"; select.append(all);
      data.object_types.filter(function (type) { return !decisionOnly || trackedTypes.has(type.id); }).forEach(function (type) {
        var option = element("option", "", type.label); option.value = type.id; select.append(option);
      });
      select.value = filter.type;
      function changed() { onChange(search.value.trim().toLocaleLowerCase("ko"), select.value); }
      search.addEventListener("input", changed); select.addEventListener("change", changed);
      toolbar.append(search, select);
      return toolbar;
    }

    function appendPage(list, filtered, filter, draw) {
      var pages = Math.max(1, Math.ceil(filtered.length / pageSize));
      filter.page = Math.min(filter.page, pages - 1);
      filtered.slice(filter.page * pageSize, (filter.page + 1) * pageSize).forEach(function (item) { list.append(objectControl(item, true)); });
      if (!filtered.length) list.append(element("p", "sfh-owner-console__empty", "검색 결과가 없습니다. 검색어나 필터를 바꿔 주세요."));
      var pager = element("nav", "sfh-owner-pager"); pager.setAttribute("aria-label", "객체 목록 페이지");
      [-1, 1].forEach(function (direction) {
        var button = element("button", "sfh-owner-command", direction < 0 ? "← 이전" : "다음 →");
        button.type = "button"; button.disabled = direction < 0 ? filter.page === 0 : filter.page >= pages - 1;
        button.addEventListener("click", function () { filter.page += direction; draw(); var nav = list.querySelector("nav"); nav.tabIndex = -1; nav.focus({ preventScroll: true }); });
        pager.append(button);
        if (direction < 0) { var counter = element("span", "", (filter.page + 1) + " / " + pages); counter.setAttribute("aria-live", "polite"); pager.append(counter); }
      });
      list.append(pager);
    }

    function renderDecisionView() {
      viewport.replaceChildren();
      var filter = state.decisions;
      var statusSelect = element("select");
      statusSelect.setAttribute("aria-label", "판단 상태 필터");
      var allStatus = element("option", "", "전체 상태"); allStatus.value = "all"; statusSelect.append(allStatus);
      data.statuses.forEach(function (status) { var option = element("option", "", status.label); option.value = status.id; statusSelect.append(option); });
      statusSelect.value = filter.status;
      var list = element("div", "sfh-owner-console__list");
      var workspace = element("div", "sfh-owner-console__workspace");
      var detailHost = element("div", "sfh-owner-detail-host");
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
        appendPage(list, filtered, filter, draw);
        var selected = filtered.find(function (item) { return item.id === state.selected; });
        detailHost.replaceChildren(selected ? detailPanel(selected) : element("p", "sfh-owner-console__empty", "목록에서 객체를 선택하면 수락 조건과 근거가 표시됩니다."));
      }
      var toolbar = filterToolbar(function (query, type) { filter.query = query; filter.type = type; filter.page = 0; draw(); }, true, filter);
      toolbar.append(statusSelect);
      statusSelect.addEventListener("change", function () { filter.status = statusSelect.value; filter.page = 0; draw(); });
      viewport.append(toolbar); workspace.append(listWrap, detailHost); viewport.append(workspace); draw();
    }

    function renderObjectView() {
      viewport.replaceChildren();
      var filter = state.objects;
      var layout = element("div", "sfh-owner-console__workspace");
      var detailHost = element("div", "sfh-owner-detail-host");
      var listWrap = element("section", "sfh-owner-console__list-wrap");
      var list = element("div", "sfh-owner-console__object-grid");
      var result = element("small", "sfh-owner-console__result");
      var listHeader = element("header"); listHeader.append(element("b", "", "객체 레지스트리"), result); listWrap.append(listHeader, list);
      function draw() {
        list.replaceChildren();
        var filtered = data.objects.filter(function (item) { return (filter.type === "all" || item.type === filter.type) && (!filter.query || [item.id, item.label, item.summary || "", item.source || ""].join(" ").toLocaleLowerCase("ko").includes(filter.query)); });
        result.textContent = filtered.length + " / " + data.objects.length;
        appendPage(list, filtered, filter, draw);
        var selected = filtered.find(function (item) { return item.id === state.selected; });
        detailHost.replaceChildren(selected ? detailPanel(selected) : element("p", "sfh-owner-console__empty", "목록에서 객체를 선택하면 수락 조건과 근거가 표시됩니다."));
      }
      viewport.append(filterToolbar(function (query, type) { filter.query = query; filter.type = type; filter.page = 0; draw(); }, false, filter));
      layout.append(listWrap, detailHost); viewport.append(layout); draw();
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
      var picker = element("div", "sfh-owner-lineage__picker sfh-owner-console__toolbar");
      var select = element("select"); select.setAttribute("aria-label", "추적 기준 객체");
      data.objects.forEach(function (item) { var option = element("option", "", typeLabel(item.type) + " · " + item.label); option.value = item.id; select.append(option); });
      select.value = selected.id;
      select.addEventListener("change", function () { setSelected(select.value, "lineage"); viewport.querySelector("select").focus({ preventScroll: true }); });
      picker.append(select);
      viewport.append(picker, trace);
    }

    function renderOperationsView() {
      viewport.replaceChildren();
      var sourceStates = data.source_systems.map(function (source) { return sourceFreshness(source); });
      var sourceWarnings = sourceStates.filter(function (item) { return item.state === "warning" || item.state === "stale"; }).length;
      var health = element("div", "sfh-owner-health");
      [[data.summary.broken_relations, "깨진 관계", "0이어야 통과"], [data.summary.isolated_documents, "고립 문서", "0이어야 통과"], [sourceWarnings, "원본 확인 필요", "Notion·Sheet 최신성"], [data.summary.generated_milestones, "자동 작업 객체", "마일스톤 표 연동"]].forEach(function (item) {
        var card = element("article"); card.append(element("b", "", String(item[0])), element("span", "", item[1]), element("small", "", item[2])); health.append(card);
      });
      var actions = element("div", "sfh-owner-action-grid");
      data.action_types.forEach(function (action, index) {
        var actor = objectById.get(action.actor); var card = element("article");
        card.append(element("small", "", "ACTION " + String(index + 1).padStart(2, "0")), element("h3", "", action.label), element("b", "", "실행 주체 · " + (actor ? actor.label : action.actor)), element("p", "", action.input + " → " + action.output), element("em", "", action.guard)); actions.append(card);
      });
      var sources = element("div", "sfh-owner-source-grid");
      data.source_systems.forEach(function (source) {
        var freshness = sourceFreshness(source);
        var link = element("a", "is-" + freshness.state); link.href = new URL(source.route, siteRoot()).href;
        link.append(element("small", "", source.system + " · " + freshness.label), element("b", "", source.label), element("span", "", source.summary), element("em", "", freshness.detail)); sources.append(link);
      });
      var actionDetails = element("details", "sfh-owner-disclosure");
      actionDetails.append(element("summary", "", "행동 계약 · 자동 실행 없음"), lifecycle, actions);
      viewport.append(health, element("h3", "sfh-owner-section-title", "원본 시스템 " + data.summary.sources + "개 · 확인 필요 " + sourceWarnings + "개"), sources, actionDetails);
    }

    function renderOverview() {
      viewport.replaceChildren();
      var layout = element("div", "sfh-owner-overview");
      var focus = element("article", "sfh-owner-focus");
      focus.append(element("small", "", "CURRENT WORK · 원본에 기록된 다음 행동"), element("h3", "", fallback.label));
      appendField(focus, "다음 행동", fallback.next_action || fallback.summary);
      var inspect = element("button", "sfh-owner-command", "작업 객체 열기 →"); inspect.type = "button";
      inspect.addEventListener("click", function () { state.objects = { query: "", type: "all", page: Math.floor(data.objects.indexOf(fallback) / pageSize) }; setSelected(fallback.id, "objects"); });
      focus.append(inspect);
      var context = element("article", "sfh-owner-focus");
      context.append(element("small", "", "CONTEXT · 먼저 확인"), element("h3", "", "선행 조건과 원본"));
      var dependencies = relationEntries(fallback.id).filter(function (entry) { return entry.target.type === "decision" || entry.relation.type === "depends_on" || entry.relation.type === "requires"; });
      context.append(element("p", "", "선행 연결 " + dependencies.length + "개 · 상위 작업의 차단 상태는 독립 후속 작업의 금지를 뜻하지 않습니다."));
      var trace = element("button", "sfh-owner-command", "선행 조건 추적 →"); trace.type = "button";
      trace.addEventListener("click", function () { setSelected(fallback.id, "lineage"); viewport.focus(); });
      context.append(trace);
      var warnings = data.source_systems.filter(function (source) { return ["warning", "stale"].includes(sourceFreshness(source).state); });
      var health = element("button", "sfh-owner-command", "원본 확인 필요 " + warnings.length + "개 · 행동·관측 열기"); health.type = "button";
      health.addEventListener("click", function () { switchView("operations"); viewport.focus(); }); context.append(health);
      layout.append(focus, context);
      viewport.append(layout, element("h3", "sfh-owner-section-title", "전체 등록 객체 · 상태별 보기 (게임 진행률 아님)"), metrics);
    }

    function renderTabs() {
      tabs.querySelectorAll("button").forEach(function (button) { var active = button.dataset.view === state.view; button.setAttribute("aria-selected", String(active)); button.tabIndex = active ? 0 : -1; });
      viewport.setAttribute("aria-labelledby", "sfh-owner-tab-" + state.view);
    }
    function renderView() {
      if (state.view === "overview") renderOverview(); else if (state.view === "objects") renderObjectView(); else if (state.view === "lineage") renderLineageView(); else if (state.view === "operations") renderOperationsView(); else renderDecisionView();
    }

    wrapper.append(header, tabs, viewport, footer); renderTabs(); renderView(); return wrapper;
  }

  function initialize() {
    document.querySelectorAll("[data-sfh-owner-decision-console-host]").forEach(function (host) {
      if (initializedHosts.has(host)) return;
      initializedHosts.add(host);
      loadData().then(function (data) { if (host.isConnected && !host.querySelector("[data-sfh-owner-decision-console]")) host.append(buildConsole(data, host)); }).catch(function () { host.append(element("p", "sfh-owner-console__error", "운영 콘솔을 불러오지 못했습니다. 인증 상태와 생성 검사를 확인해 주세요.")); });
    });
  }

  if (window.document$ && typeof window.document$.subscribe === "function") window.document$.subscribe(initialize);
  else if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", initialize);
  else initialize();
})();
