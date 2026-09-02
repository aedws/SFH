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
    var state = { selected: "core", layer: "all", query: "", webPage: 0 };
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

    var web = element("section", "sfh-code-web");
    web.setAttribute("aria-label", "선택 모듈 중심 관계 거미줄");
    var webHeader = element("header", "sfh-code-web__header");
    webHeader.append(
      element("b", "", "RELATION WEB // 선택 노드 중심"),
      element("small", "", "화살표 방향은 호출·상속·검증 흐름입니다")
    );
    var webStage = element("div", "sfh-code-web__stage");
    var webPager = element("nav", "sfh-code-web__pager");
    webPager.setAttribute("aria-label", "관계 노드 페이지");
    web.append(webHeader, webStage, webPager);

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
      state.webPage = 0;
      renderWeb();
      renderNodes();
      renderDetail();
      var url = new URL(window.location.href);
      url.searchParams.set("module", moduleId);
      window.history.replaceState({}, "", url);
      if (focusDetail) detail.focus({ preventScroll: true });
    }

    function mergedRelations(moduleId) {
      var merged = new Map();
      data.edges.forEach(function (edge) {
        if (edge.from !== moduleId && edge.to !== moduleId) return;
        var targetId = edge.from === moduleId ? edge.to : edge.from;
        var direction = edge.from === moduleId ? "outgoing" : "incoming";
        var relation = merged.get(targetId) || {
          targetId: targetId,
          incoming: false,
          outgoing: false,
          types: new Set(),
          evidence: 0
        };
        relation[direction] = true;
        relation.types.add(edge.type);
        relation.evidence += edge.evidence_count || 1;
        merged.set(targetId, relation);
      });
      return Array.from(merged.values()).sort(function (a, b) {
        return b.evidence - a.evidence || moduleById.get(a.targetId).label.localeCompare(moduleById.get(b.targetId).label, "ko");
      });
    }

    function svgElement(tag, attributes) {
      var node = document.createElementNS("http://www.w3.org/2000/svg", tag);
      Object.keys(attributes || {}).forEach(function (key) { node.setAttribute(key, attributes[key]); });
      return node;
    }

    function renderWeb() {
      webStage.replaceChildren();
      webPager.replaceChildren();
      var module = moduleById.get(state.selected) || data.modules[0];
      var relations = mergedRelations(module.id);
      var compact = web.clientWidth > 0 && web.clientWidth <= 480;
      var medium = web.clientWidth > 480 && web.clientWidth <= 800;
      var pageSize = compact ? 6 : medium ? 8 : 12;
      var pageCount = Math.max(1, Math.ceil(relations.length / pageSize));
      state.webPage = Math.min(state.webPage, pageCount - 1);
      var visible = relations.slice(state.webPage * pageSize, (state.webPage + 1) * pageSize);
      var svg = svgElement("svg", { viewBox: "0 0 100 100", preserveAspectRatio: "none", "aria-hidden": "true" });
      svg.classList.add("sfh-code-web__lines");
      var defs = svgElement("defs");
      var marker = svgElement("marker", { id: "sfh-code-arrow", viewBox: "0 0 8 8", refX: "7", refY: "4", markerWidth: "5", markerHeight: "5", orient: "auto-start-reverse" });
      marker.append(svgElement("path", { d: "M 0 0 L 8 4 L 0 8 z" }));
      defs.append(marker);
      svg.append(defs);

      var positions = [];
      visible.forEach(function (relation, index) {
        var angle = -Math.PI / 2 + (Math.PI * 2 * index / Math.max(visible.length, 1));
        var radiusX = compact ? 34 : 42;
        var radiusY = compact ? 30 : medium ? 35 : 40;
        var position = { x: 50 + radiusX * Math.cos(angle), y: 50 + radiusY * Math.sin(angle) };
        positions.push(position);
        var type = Array.from(relation.types)[0] || "references";
        var line = svgElement("line", { x1: "50", y1: "50", x2: position.x.toFixed(2), y2: position.y.toFixed(2) });
        line.classList.add("is-" + type);
        if (relation.outgoing) line.setAttribute("marker-end", "url(#sfh-code-arrow)");
        if (relation.incoming) line.setAttribute("marker-start", "url(#sfh-code-arrow)");
        svg.append(line);
      });

      visible.forEach(function (left, leftIndex) {
        visible.slice(leftIndex + 1).forEach(function (right, offset) {
          var rightIndex = leftIndex + offset + 1;
          var linked = data.edges.some(function (edge) {
            return (edge.from === left.targetId && edge.to === right.targetId) || (edge.from === right.targetId && edge.to === left.targetId);
          });
          if (!linked) return;
          var bridge = svgElement("line", {
            x1: positions[leftIndex].x.toFixed(2), y1: positions[leftIndex].y.toFixed(2),
            x2: positions[rightIndex].x.toFixed(2), y2: positions[rightIndex].y.toFixed(2)
          });
          bridge.classList.add("is-bridge");
          svg.insertBefore(bridge, svg.children[1]);
        });
      });
      webStage.append(svg);

      visible.forEach(function (relation, index) {
        var target = moduleById.get(relation.targetId);
        if (!target) return;
        var button = element("button", "sfh-code-web__satellite", "");
        button.type = "button";
        button.style.left = positions[index].x + "%";
        button.style.top = positions[index].y + "%";
        button.setAttribute("aria-label", target.label + ", " + (relation.incoming ? "현재 노드를 사용" : "현재 노드가 사용"));
        var direction = relation.incoming && relation.outgoing ? "↔" : relation.incoming ? "→ 중심" : "중심 →";
        button.append(
          element("strong", "", target.label),
          element("small", "", direction + " · " + Array.from(relation.types).map(relationLabel).join("+") + " · " + relation.evidence)
        );
        button.addEventListener("click", function () { selectModule(target.id, false); });
        webStage.append(button);
      });

      var center = element("button", "sfh-code-web__center", "");
      center.type = "button";
      center.setAttribute("aria-current", "true");
      center.append(
        element("small", "", module.layer.toUpperCase()),
        element("strong", "", module.label),
        element("span", "", module.class_count + " CLS · " + relations.length + " LINK")
      );
      center.addEventListener("click", function () { detail.focus({ preventScroll: false }); });
      webStage.append(center);

      if (!relations.length) webStage.append(element("p", "sfh-code-web__empty", "직접 연결된 코드 관계가 없습니다."));
      var previous = element("button", "sfh-code-web__page", "‹");
      var next = element("button", "sfh-code-web__page", "›");
      previous.type = next.type = "button";
      previous.disabled = state.webPage === 0;
      next.disabled = state.webPage >= pageCount - 1;
      previous.setAttribute("aria-label", "이전 관계 노드");
      next.setAttribute("aria-label", "다음 관계 노드");
      previous.addEventListener("click", function () { state.webPage -= 1; renderWeb(); });
      next.addEventListener("click", function () { state.webPage += 1; renderWeb(); });
      webPager.append(previous, element("span", "", (state.webPage + 1) + " / " + pageCount + " · " + relations.length + " 관계"), next);
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

    wrapper.append(header, metrics, toolbar, web, workspace);
    var resizeTimer = 0;
    var lastWebBucket = "";
    var resizeObserver = new ResizeObserver(function () {
      window.clearTimeout(resizeTimer);
      resizeTimer = window.setTimeout(function () {
        var bucket = web.clientWidth <= 480 ? "compact" : web.clientWidth <= 800 ? "medium" : "wide";
        if (bucket !== lastWebBucket) {
          lastWebBucket = bucket;
          state.webPage = 0;
          renderWeb();
        }
      }, 80);
    });
    resizeObserver.observe(web);
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
        host.append(element("p", "sfh-code-map__error", "코드 모듈 노드맵을 불러오지 못했습니다. 위키 빌드의 코드 맵 검사를 확인해 주세요."));
      });
    });
  }

  if (typeof document$ !== "undefined" && document$.subscribe) document$.subscribe(initialize);
  else if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", initialize, { once: true });
  else initialize();
})();
