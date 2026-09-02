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
      requires: "필수 의존",
      references: "코드 참조",
      verifies: "검증",
      inherits: "프로젝트 상속"
    }[type] || type;
  }

  function buildMap(data) {
    var moduleById = new Map(data.modules.map(function (item) { return [item.id, item]; }));
    var classById = new Map(data.classes.map(function (item) { return [item.id, item]; }));
    var state = { selected: "core", layer: "all", query: "" };
    var requested = new URL(window.location.href).searchParams.get("module");
    if (requested && moduleById.has(requested)) state.selected = requested;

    var wrapper = element("section", "sfh-code-map");
    wrapper.setAttribute("data-sfh-code-module-map", "");
    wrapper.setAttribute("aria-labelledby", "sfh-code-map-title");

    var header = element("header", "sfh-code-map__header");
    var titleBox = element("div", "");
    titleBox.append(element("small", "", "LIVE SOURCE GRAPH // GENERATED"));
    var title = element("h2", "", "현재 코드 모듈 노드맵");
    title.id = "sfh-code-map-title";
    titleBox.append(title, element("p", "", "실제 GDScript의 클래스·상속·로드 경로·검증 참조를 읽어 만든 현재 구조입니다."));
    var digest = element("code", "sfh-code-map__digest", data.source_sha256.slice(0, 12));
    digest.title = "스캔한 GDScript 전체의 SHA-256 앞 12자리";
    header.append(titleBox, digest);

    var metrics = element("div", "sfh-code-map__metrics");
    [
      [data.summary.modules, "MODULES"],
      [data.summary.named_classes, "CLASSES"],
      [data.summary.relationships, "RELATIONS"],
      [data.summary.enabled_toggles, "ACTIVE FLAGS"]
    ].forEach(function (metric) {
      var card = element("span", "");
      card.append(element("b", "", String(metric[0])), element("small", "", metric[1]));
      metrics.append(card);
    });

    var toolbar = element("div", "sfh-code-map__toolbar");
    var search = element("input", "sfh-code-map__search");
    search.type = "search";
    search.placeholder = "모듈·클래스·경로 검색";
    search.setAttribute("aria-label", "코드 모듈 검색");
    var filters = element("div", "sfh-code-map__filters");
    filters.setAttribute("role", "group");
    filters.setAttribute("aria-label", "코드 레이어 필터");
    [{ id: "all", label: "전체" }].concat(data.layers).forEach(function (layer) {
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
    toolbar.append(search, filters);

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
      return [module.id, module.label, module.path].concat(module.classes).join(" ").toLocaleLowerCase("ko");
    }

    function selectModule(moduleId, focusDetail) {
      state.selected = moduleId;
      renderNodes();
      renderDetail();
      var url = new URL(window.location.href);
      url.searchParams.set("module", moduleId);
      window.history.replaceState({}, "", url);
      if (focusDetail) detail.focus({ preventScroll: true });
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
        var queryMatch = !state.query || searchable(module).includes(state.query);
        return layerMatch && queryMatch;
      });
      data.layers.forEach(function (layer) {
        var laneModules = visible.filter(function (module) { return module.layer === layer.id; });
        if (!laneModules.length) return;
        var lane = element("section", "sfh-code-map__lane sfh-code-map__lane--" + layer.id);
        var laneHeader = element("header", "sfh-code-map__lane-header");
        laneHeader.append(element("b", "", layer.label), element("small", "", layer.description + " · " + laneModules.length));
        var nodes = element("div", "sfh-code-map__nodes");
        laneModules.forEach(function (module) {
          var classes = module.class_count + " CLS";
          var links = (module.incoming_count + module.outgoing_count) + " LINK";
          var button = element("button", "sfh-code-node", "");
          button.type = "button";
          button.dataset.module = module.id;
          button.setAttribute("aria-pressed", module.id === state.selected ? "true" : "false");
          button.setAttribute("aria-label", module.label + ", 클래스 " + module.class_count + "개, 관계 " + (module.incoming_count + module.outgoing_count) + "개");
          if (module.id === state.selected) button.classList.add("is-selected");
          else if (related.has(module.id)) button.classList.add("is-related");
          else if (state.selected && !state.query) button.classList.add("is-muted");
          var status = module.enabled === true ? "ON" : module.enabled === false ? "OFF" : "SYS";
          button.append(
            element("small", "sfh-code-node__status", status),
            element("strong", "", module.label),
            element("span", "", classes + " · " + links)
          );
          button.addEventListener("click", function () { selectModule(module.id, false); });
          nodes.append(button);
        });
        lane.append(laneHeader, nodes);
        graph.append(lane);
      });
      if (!visible.length) graph.append(element("p", "sfh-code-map__empty", "일치하는 코드 노드가 없습니다."));
    }

    function relationColumn(label, edges, direction) {
      var column = element("section", "sfh-code-map__relation-column");
      column.append(element("small", "", label));
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
        button.append(element("b", "", target.label), element("span", "", relationLabel(edge.type) + " · " + edge.evidence_count));
        button.addEventListener("click", function () { selectModule(targetId, false); });
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
      copy.append(element("small", "", module.layer.toUpperCase() + " NODE"), element("h3", "", module.label));
      var badge = element("span", "sfh-code-map__state", module.enabled === true ? "ENABLED" : module.enabled === false ? "DISABLED" : "SYSTEM");
      detailHeader.append(copy, badge);
      var path = element("code", "sfh-code-map__path", module.path);

      var flow = element("div", "sfh-code-map__flow");
      flow.append(
        relationColumn("이 노드를 쓰는 곳", links.incoming, "incoming"),
        relationColumn("이 노드가 쓰는 곳", links.outgoing, "outgoing")
      );

      var classSection = element("section", "sfh-code-map__classes");
      classSection.append(element("h4", "", "클래스·상속"));
      var ownClasses = data.classes.filter(function (item) { return item.module === module.id; });
      if (!ownClasses.length) {
        classSection.append(element("p", "", "class_name 공개 클래스가 없습니다. 파일 단위 조립 또는 테스트 노드입니다."));
      } else {
        var classList = element("div", "sfh-code-map__class-list");
        ownClasses.forEach(function (item) {
          var base = item.base_id ? classById.get(item.base_id) : null;
          var row = element("article", "sfh-code-class");
          row.append(element("strong", "", item.name));
          var chain = element("span", "");
          chain.append(element("code", "", item.extends));
          if (base) chain.append(element("i", "", "PROJECT BASE"));
          else chain.append(element("i", "", "ENGINE BASE"));
          row.append(chain, element("small", "", item.path));
          classList.append(row);
        });
        classSection.append(classList);
      }

      var wiki = element("a", "sfh-code-map__wiki", "관련 위키 계약 열기 →");
      wiki.href = new URL(module.wiki_route, siteRoot()).href;
      detail.append(detailHeader, path, flow, classSection, wiki);
    }

    search.addEventListener("input", function () {
      state.query = search.value.trim().toLocaleLowerCase("ko");
      renderNodes();
    });

    wrapper.append(header, metrics, toolbar, workspace);
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
        host.append(element("p", "sfh-code-map__error", "코드 모듈 노드맵을 불러오지 못했습니다. 위키 빌드의 코드 맵 검사를 확인해 주세요."));
      });
    });
  }

  if (typeof document$ !== "undefined" && document$.subscribe) document$.subscribe(initialize);
  else if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", initialize, { once: true });
  else initialize();
})();
