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

  function svgElement(tag, attributes) {
    var node = document.createElementNS("http://www.w3.org/2000/svg", tag);
    Object.keys(attributes || {}).forEach(function (key) { node.setAttribute(key, attributes[key]); });
    return node;
  }

  function siteRoot() {
    if (scriptUrl) return new URL("../", scriptUrl);
    return new URL("/", window.location.href);
  }

  function loadData() {
    if (!dataPromise) {
      dataPromise = fetch(new URL("assets/code-module-map.json", siteRoot()), { cache: "no-cache" })
        .then(function (response) {
          if (!response.ok) throw new Error("code module map unavailable");
          return response.json();
        });
    }
    return dataPromise;
  }

  function relationLabel(type) {
    return {
      requires: "활성 조건",
      references: "직접 참조",
      verifies: "테스트 검증",
      inherits: "코드 상속"
    }[type] || type;
  }

  function buildMap(data) {
    var moduleById = new Map(data.modules.map(function (item) { return [item.id, item]; }));
    var classById = new Map(data.classes.map(function (item) { return [item.id, item]; }));
    var requested = new URL(window.location.href).searchParams.get("module");
    var initialModule = requested && moduleById.has(requested) ? requested : "core";
    if (!moduleById.has(initialModule)) initialModule = data.modules[0].id;
    var state = {
      selected: initialModule,
      layer: "all",
      domain: "all",
      query: "",
      webPage: 0,
      history: [initialModule]
    };
    var redrawWebLines = function () {};

    var wrapper = element("section", "sfh-code-map");
    wrapper.setAttribute("data-sfh-code-module-map", "");
    wrapper.setAttribute("aria-labelledby", "sfh-code-map-title");

    var header = element("header", "sfh-code-map__header");
    var titleBox = element("div", "");
    titleBox.append(element("small", "", "LIVE SOURCE GRAPH // GENERATED"));
    var title = element("h2", "", "현재 코드 모듈 지도");
    title.id = "sfh-code-map-title";
    titleBox.append(
      title,
      element("p", "", "왼쪽은 이 기능을 사용하는 곳, 오른쪽은 이 기능이 사용하는 곳입니다. 노드를 눌러 코드 흐름을 따라가세요.")
    );
    var digest = element("code", "sfh-code-map__digest", data.source_sha256.slice(0, 12));
    digest.title = "스캔한 GDScript 전체의 SHA-256 앞 12자리";
    header.append(titleBox, digest);

    var metrics = element("div", "sfh-code-map__metrics");
    [
      [data.summary.modules, "모듈"],
      [data.summary.named_classes, "공개 클래스"],
      [data.summary.relationships, "직접 관계"],
      [data.summary.project_inheritance, "프로젝트 상속"]
    ].forEach(function (metric) {
      var card = element("span", "");
      card.append(element("b", "", String(metric[0])), element("small", "", metric[1]));
      metrics.append(card);
    });

    var toolbar = element("div", "sfh-code-map__toolbar");
    var searchWrap = element("label", "sfh-code-map__field");
    searchWrap.append(element("span", "", "빠른 찾기"));
    var search = element("input", "sfh-code-map__search");
    search.type = "search";
    search.placeholder = "예: 인벤토리, 전투 자원, class_name";
    search.setAttribute("aria-label", "코드 모듈 검색");
    searchWrap.append(search);

    var domainWrap = element("label", "sfh-code-map__field");
    domainWrap.append(element("span", "", "업무 영역"));
    var domainSelect = element("select", "sfh-code-map__domain");
    domainSelect.setAttribute("aria-label", "업무 영역 필터");
    var allDomain = element("option", "", "전체 영역");
    allDomain.value = "all";
    domainSelect.append(allDomain);
    (data.domains || []).forEach(function (domain) {
      var option = element("option", "", domain.label);
      option.value = domain.id;
      domainSelect.append(option);
    });
    domainWrap.append(domainSelect);

    var filters = element("div", "sfh-code-map__filters");
    filters.setAttribute("role", "group");
    filters.setAttribute("aria-label", "코드 레이어 필터");
    [{ id: "all", label: "전체 레이어" }].concat(data.layers).forEach(function (layer) {
      var button = element("button", "sfh-code-map__filter", layer.label);
      button.type = "button";
      button.dataset.layer = layer.id;
      button.setAttribute("aria-pressed", layer.id === "all" ? "true" : "false");
      button.addEventListener("click", function () {
        state.layer = layer.id;
        filters.querySelectorAll("button").forEach(function (item) {
          item.setAttribute("aria-pressed", item === button ? "true" : "false");
        });
        renderNodes();
      });
      filters.append(button);
    });
    var toolbarTop = element("div", "sfh-code-map__toolbar-top");
    toolbarTop.append(searchWrap, domainWrap);
    toolbar.append(toolbarTop, filters);

    var trace = element("nav", "sfh-code-map__trace");
    trace.setAttribute("aria-label", "모듈 탐색 경로");

    var web = element("section", "sfh-code-web");
    web.setAttribute("aria-label", "선택 모듈의 직접 관계 흐름");
    var webHeader = element("header", "sfh-code-web__header");
    var webTitle = element("div", "");
    webTitle.append(element("b", "", "DIRECT FLOW // 직접 연결"), element("small", "", "선택 노드를 중심으로 1단계 관계만 표시"));
    var legend = element("div", "sfh-code-web__legend");
    [
      ["requires", "활성 조건"],
      ["references", "직접 참조"],
      ["verifies", "검증"],
      ["inherits", "상속"]
    ].forEach(function (item) {
      var key = element("span", "is-" + item[0]);
      key.append(element("i", ""), document.createTextNode(item[1]));
      legend.append(key);
    });
    webHeader.append(webTitle, legend);
    var webStage = element("div", "sfh-code-web__stage");
    var webPager = element("nav", "sfh-code-web__pager");
    webPager.setAttribute("aria-label", "관계 노드 페이지");
    web.append(webHeader, webStage, webPager);

    var workspaceHeader = element("div", "sfh-code-map__index-header");
    workspaceHeader.append(element("div", "", "전체 모듈 인덱스"), element("small", "sfh-code-map__result", ""));
    var workspace = element("div", "sfh-code-map__workspace");
    var graph = element("div", "sfh-code-map__graph");
    graph.setAttribute("role", "group");
    graph.setAttribute("aria-label", "현재 코드 모듈 노드 목록");
    var detail = element("aside", "sfh-code-map__detail");
    detail.setAttribute("aria-live", "polite");
    workspace.append(graph, detail);

    function neighbors(moduleId) {
      var incoming = [];
      var outgoing = [];
      data.edges.forEach(function (edge) {
        if (edge.to === moduleId) incoming.push(edge);
        if (edge.from === moduleId) outgoing.push(edge);
      });
      return { incoming: incoming, outgoing: outgoing };
    }

    function searchable(module) {
      return [module.id, module.label, module.path, module.domain_label].concat(module.classes).join(" ").toLocaleLowerCase("ko");
    }

    function setUrlModule(moduleId) {
      var url = new URL(window.location.href);
      url.searchParams.set("module", moduleId);
      window.history.replaceState({}, "", url);
    }

    function selectModule(moduleId, options) {
      options = options || {};
      if (!moduleById.has(moduleId)) return;
      if (options.historyIndex !== undefined) {
        state.history = state.history.slice(0, options.historyIndex + 1);
      } else if (moduleId !== state.selected) {
        state.history.push(moduleId);
        if (state.history.length > 8) state.history.shift();
      }
      state.selected = moduleId;
      state.webPage = 0;
      setUrlModule(moduleId);
      renderTrace();
      renderWeb();
      renderNodes();
      renderDetail();
      if (options.focusDetail) detail.focus({ preventScroll: true });
    }

    function renderTrace() {
      trace.replaceChildren();
      var back = element("button", "sfh-code-map__back", "이전");
      back.type = "button";
      back.disabled = state.history.length < 2;
      back.setAttribute("aria-label", "이전 선택 모듈로 이동");
      back.addEventListener("click", function () {
        if (state.history.length < 2) return;
        state.history.pop();
        selectModule(state.history[state.history.length - 1], { historyIndex: state.history.length - 1 });
      });
      trace.append(back, element("small", "", "탐색 경로"));
      state.history.slice(-5).forEach(function (moduleId, index, shown) {
        var module = moduleById.get(moduleId);
        if (!module) return;
        if (index) trace.append(element("i", "", ">"));
        var button = element("button", "sfh-code-map__crumb", module.label);
        button.type = "button";
        button.setAttribute("aria-current", index === shown.length - 1 ? "page" : "false");
        var realIndex = state.history.length - shown.length + index;
        button.addEventListener("click", function () { selectModule(moduleId, { historyIndex: realIndex }); });
        trace.append(button);
      });
    }

    function mergedRelations(moduleId) {
      var merged = new Map();
      data.edges.forEach(function (edge) {
        if (edge.from !== moduleId && edge.to !== moduleId) return;
        var targetId = edge.from === moduleId ? edge.to : edge.from;
        var direction = edge.from === moduleId ? "outgoing" : "incoming";
        var relation = merged.get(targetId) || { targetId: targetId, incoming: false, outgoing: false, types: new Set(), evidence: 0 };
        relation[direction] = true;
        relation.types.add(edge.type);
        relation.evidence += edge.evidence_count || 1;
        merged.set(targetId, relation);
      });
      return Array.from(merged.values()).sort(function (a, b) {
        return b.evidence - a.evidence || moduleById.get(a.targetId).label.localeCompare(moduleById.get(b.targetId).label, "ko");
      });
    }

    function drawConnections(svg, center, cards) {
      svg.replaceChildren();
      var stageRect = webStage.getBoundingClientRect();
      var centerRect = center.getBoundingClientRect();
      if (!stageRect.width || !stageRect.height) return;
      svg.setAttribute("viewBox", "0 0 " + stageRect.width + " " + stageRect.height);
      var defs = svgElement("defs");
      var marker = svgElement("marker", { id: "sfh-code-arrow", viewBox: "0 0 8 8", refX: "7", refY: "4", markerWidth: "6", markerHeight: "6", orient: "auto-start-reverse" });
      marker.append(svgElement("path", { d: "M 0 0 L 8 4 L 0 8 z" }));
      defs.append(marker);
      svg.append(defs);
      cards.forEach(function (card) {
        var cardRect = card.getBoundingClientRect();
        var incoming = card.dataset.incoming === "true";
        var outgoing = card.dataset.outgoing === "true";
        var leftLane = card.classList.contains("is-incoming");
        var line = svgElement("line", {
          x1: (leftLane ? cardRect.right : centerRect.right) - stageRect.left,
          y1: (leftLane ? cardRect.top + cardRect.height / 2 : centerRect.top + centerRect.height / 2) - stageRect.top,
          x2: (leftLane ? centerRect.left : cardRect.left) - stageRect.left,
          y2: (leftLane ? centerRect.top + centerRect.height / 2 : cardRect.top + cardRect.height / 2) - stageRect.top
        });
        line.classList.add("is-" + card.dataset.type);
        if (leftLane || outgoing) line.setAttribute("marker-end", "url(#sfh-code-arrow)");
        if (!leftLane && incoming && outgoing) line.setAttribute("marker-start", "url(#sfh-code-arrow)");
        svg.append(line);
      });
    }

    function relationCard(relation, side) {
      var target = moduleById.get(relation.targetId);
      var button = element("button", "sfh-code-web__satellite is-" + side, "");
      button.type = "button";
      button.dataset.incoming = String(relation.incoming);
      button.dataset.outgoing = String(relation.outgoing);
      button.dataset.type = Array.from(relation.types)[0] || "references";
      var direction = relation.incoming && relation.outgoing ? "양방향" : side === "incoming" ? "사용처" : "의존처";
      button.setAttribute("aria-label", target.label + ", " + direction + ", 근거 " + relation.evidence + "개");
      button.append(
        element("small", "sfh-code-web__direction", direction),
        element("strong", "", target.label),
        element("code", "", target.id),
        element("span", "", Array.from(relation.types).map(relationLabel).join(" + ") + " · 근거 " + relation.evidence)
      );
      button.addEventListener("click", function () { selectModule(target.id); });
      return button;
    }

    function renderWeb() {
      webStage.replaceChildren();
      webPager.replaceChildren();
      var module = moduleById.get(state.selected) || data.modules[0];
      var relations = mergedRelations(module.id);
      var incoming = relations.filter(function (item) { return item.incoming && !item.outgoing; });
      var outgoing = relations.filter(function (item) { return item.outgoing; });
      var compact = web.clientWidth > 0 && web.clientWidth <= 480;
      var medium = web.clientWidth > 480 && web.clientWidth <= 800;
      var pageSize = compact ? 6 : medium ? 8 : 12;
      var sideSize = pageSize / 2;
      var pageCount = Math.max(1, Math.ceil(incoming.length / sideSize), Math.ceil(outgoing.length / sideSize));
      state.webPage = Math.min(state.webPage, pageCount - 1);
      var incomingVisible = incoming.slice(state.webPage * sideSize, (state.webPage + 1) * sideSize);
      var outgoingVisible = outgoing.slice(state.webPage * sideSize, (state.webPage + 1) * sideSize);

      var svg = svgElement("svg", { preserveAspectRatio: "none", "aria-hidden": "true" });
      svg.classList.add("sfh-code-web__lines");
      var incomingLane = element("section", "sfh-code-web__lane is-incoming");
      incomingLane.append(element("header", "", "사용처 → 선택 기능"));
      var outgoingLane = element("section", "sfh-code-web__lane is-outgoing");
      outgoingLane.append(element("header", "", "선택 기능 → 의존처"));
      var cards = [];
      incomingVisible.forEach(function (relation) {
        var card = relationCard(relation, "incoming");
        cards.push(card);
        incomingLane.append(card);
      });
      outgoingVisible.forEach(function (relation) {
        var card = relationCard(relation, "outgoing");
        cards.push(card);
        outgoingLane.append(card);
      });
      if (!incomingVisible.length) incomingLane.append(element("p", "sfh-code-web__empty", "직접 사용처 없음"));
      if (!outgoingVisible.length) outgoingLane.append(element("p", "sfh-code-web__empty", "직접 의존처 없음"));

      var center = element("button", "sfh-code-web__center", "");
      center.type = "button";
      center.setAttribute("aria-current", "true");
      center.setAttribute("aria-label", module.label + " 상세 정보로 이동");
      center.append(
        element("small", "", module.domain_label),
        element("strong", "", module.label),
        element("code", "", module.id),
        element("span", "", module.class_count + " 클래스 · " + relations.length + " 연결")
      );
      center.addEventListener("click", function () { detail.focus({ preventScroll: false }); });
      webStage.append(svg, incomingLane, center, outgoingLane);
      redrawWebLines = function () { drawConnections(svg, center, cards); };
      window.requestAnimationFrame(redrawWebLines);

      var previous = element("button", "sfh-code-web__page", "이전");
      var next = element("button", "sfh-code-web__page", "다음");
      previous.type = next.type = "button";
      previous.disabled = state.webPage === 0;
      next.disabled = state.webPage >= pageCount - 1;
      previous.setAttribute("aria-label", "이전 관계 노드");
      next.setAttribute("aria-label", "다음 관계 노드");
      previous.addEventListener("click", function () { state.webPage -= 1; renderWeb(); });
      next.addEventListener("click", function () { state.webPage += 1; renderWeb(); });
      webPager.append(previous, element("span", "", (state.webPage + 1) + " / " + pageCount + " · 사용처 " + incoming.length + " · 의존처 " + outgoing.length), next);
    }

    function renderNodes() {
      graph.replaceChildren();
      var selectedRelations = neighbors(state.selected);
      var related = new Set([state.selected]);
      selectedRelations.incoming.concat(selectedRelations.outgoing).forEach(function (edge) {
        related.add(edge.from);
        related.add(edge.to);
      });
      var visible = data.modules.filter(function (module) {
        var layerMatch = state.layer === "all" || module.layer === state.layer;
        var domainMatch = state.domain === "all" || module.domain === state.domain;
        var queryMatch = !state.query || searchable(module).includes(state.query);
        return layerMatch && domainMatch && queryMatch;
      });
      wrapper.querySelector(".sfh-code-map__result").textContent = visible.length + " / " + data.modules.length + "개 표시";
      data.layers.forEach(function (layer) {
        var laneModules = visible.filter(function (module) { return module.layer === layer.id; });
        if (!laneModules.length) return;
        var lane = element("section", "sfh-code-map__lane sfh-code-map__lane--" + layer.id);
        var laneHeader = element("header", "sfh-code-map__lane-header");
        laneHeader.append(element("b", "", layer.label), element("small", "", layer.description + " · " + laneModules.length));
        var nodes = element("div", "sfh-code-map__nodes");
        laneModules.forEach(function (module) {
          var button = element("button", "sfh-code-node", "");
          button.type = "button";
          button.dataset.module = module.id;
          button.setAttribute("aria-pressed", module.id === state.selected ? "true" : "false");
          button.setAttribute("aria-label", module.label + ", " + module.domain_label + ", 클래스 " + module.class_count + "개");
          if (module.id === state.selected) button.classList.add("is-selected");
          else if (related.has(module.id)) button.classList.add("is-related");
          else if (state.selected && !state.query) button.classList.add("is-muted");
          var status = module.enabled === true ? "ON" : module.enabled === false ? "OFF" : "SYS";
          var top = element("span", "sfh-code-node__top");
          top.append(element("small", "sfh-code-node__status", status), element("small", "sfh-code-node__domain", module.domain_label));
          button.append(top, element("strong", "", module.label), element("code", "", module.id), element("span", "", module.class_count + " 클래스 · " + (module.incoming_count + module.outgoing_count) + " 연결"));
          button.addEventListener("click", function () { selectModule(module.id); });
          nodes.append(button);
        });
        lane.append(laneHeader, nodes);
        graph.append(lane);
      });
      if (!visible.length) graph.append(element("p", "sfh-code-map__empty", "일치하는 코드 노드가 없습니다. 검색어나 필터를 바꿔 보세요."));
    }

    function relationColumn(label, edges, direction) {
      var column = element("section", "sfh-code-map__relation-column");
      column.append(element("small", "", label + " · " + edges.length));
      if (!edges.length) {
        column.append(element("span", "sfh-code-map__relation-empty", "없음"));
        return column;
      }
      edges.slice(0, 12).forEach(function (edge) {
        var targetId = direction === "incoming" ? edge.from : edge.to;
        var target = moduleById.get(targetId);
        if (!target) return;
        var button = element("button", "sfh-code-map__relation");
        button.type = "button";
        button.append(element("b", "", target.label), element("span", "", relationLabel(edge.type) + " · 근거 " + edge.evidence_count));
        button.addEventListener("click", function () { selectModule(targetId); });
        column.append(button);
      });
      return column;
    }

    function renderDetail() {
      var module = moduleById.get(state.selected) || data.modules[0];
      var links = neighbors(module.id);
      detail.replaceChildren();
      detail.tabIndex = -1;
      var detailHeader = element("header", "sfh-code-map__detail-header");
      var copy = element("div", "");
      copy.append(element("small", "", module.domain_label + " / " + module.layer.toUpperCase()), element("h3", "", module.label), element("code", "", module.id));
      var badge = element("span", "sfh-code-map__state", module.enabled === true ? "ENABLED" : module.enabled === false ? "DISABLED" : "SYSTEM");
      detailHeader.append(copy, badge);
      var summary = element("p", "sfh-code-map__plain-summary", "이 모듈을 사용하는 곳 " + links.incoming.length + "개 · 이 모듈이 사용하는 곳 " + links.outgoing.length + "개 · 공개 클래스 " + module.class_count + "개");
      var path = element("code", "sfh-code-map__path", module.path);
      var flow = element("div", "sfh-code-map__flow");
      flow.append(relationColumn("이 모듈을 사용하는 곳", links.incoming, "incoming"), relationColumn("이 모듈이 사용하는 곳", links.outgoing, "outgoing"));

      var classSection = element("section", "sfh-code-map__classes");
      classSection.append(element("h4", "", "공개 클래스와 상속"));
      var ownClasses = data.classes.filter(function (item) { return item.module === module.id; });
      if (!ownClasses.length) {
        classSection.append(element("p", "", "공개 class_name이 없습니다. 파일 단위 조립 또는 테스트 노드입니다."));
      } else {
        var classList = element("div", "sfh-code-map__class-list");
        ownClasses.forEach(function (item) {
          var base = item.base_id ? classById.get(item.base_id) : null;
          var row = element("article", "sfh-code-class");
          row.append(element("strong", "", item.name));
          var chain = element("span", "");
          chain.append(element("code", "", item.extends), element("i", "", base ? "PROJECT BASE" : "ENGINE BASE"));
          row.append(chain, element("small", "", item.path));
          classList.append(row);
        });
        classSection.append(classList);
      }

      var wiki = element("a", "sfh-code-map__wiki", "관련 설계 문서 열기");
      wiki.href = new URL(module.wiki_route, siteRoot()).href;
      detail.append(detailHeader, summary, path, flow, classSection, wiki);
    }

    search.addEventListener("input", function () {
      state.query = search.value.trim().toLocaleLowerCase("ko");
      renderNodes();
    });
    domainSelect.addEventListener("change", function () {
      state.domain = domainSelect.value;
      renderNodes();
    });

    wrapper.append(header, metrics, toolbar, trace, web, workspaceHeader, workspace);
    var resizeTimer = 0;
    var lastWebBucket = "";
    if (typeof ResizeObserver !== "undefined") {
      var resizeObserver = new ResizeObserver(function () {
        window.clearTimeout(resizeTimer);
        resizeTimer = window.setTimeout(function () {
          var bucket = web.clientWidth <= 480 ? "compact" : web.clientWidth <= 800 ? "medium" : "wide";
          if (bucket !== lastWebBucket) {
            lastWebBucket = bucket;
            state.webPage = 0;
            renderWeb();
          } else {
            redrawWebLines();
          }
        }, 80);
      });
      resizeObserver.observe(web);
    }
    renderTrace();
    renderWeb();
    renderNodes();
    renderDetail();
    return wrapper;
  }

  function initialize() {
    document.querySelectorAll("[data-sfh-code-module-map-host]").forEach(function (host) {
      if (initializedHosts.has(host)) return;
      initializedHosts.add(host);
      loadData().then(function (data) {
        if (host.isConnected && !host.querySelector("[data-sfh-code-module-map]")) host.append(buildMap(data));
      }).catch(function () {
        host.append(element("p", "sfh-code-map__error", "코드 모듈 지도를 불러오지 못했습니다. 위키 빌드의 코드 맵 검사를 확인해 주세요."));
      });
    });
  }

  if (typeof document$ !== "undefined" && document$.subscribe) document$.subscribe(initialize);
  else if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", initialize, { once: true });
  else initialize();
})();
