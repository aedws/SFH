(function () {
  "use strict";

  var mapDataPromise = null;
  var initializedHosts = new WeakSet();
  var knowledgeMapScriptUrl = document.currentScript && document.currentScript.src
    ? new URL(document.currentScript.src, window.location.href)
    : null;

  function element(tagName, className, text) {
    var node = document.createElement(tagName);
    if (className) node.className = className;
    if (typeof text === "string") node.textContent = text;
    return node;
  }

  function getSiteRoot() {
    // Material instant navigation keeps the first page's __config node alive.
    // The script URL is stable across page depth changes, so prefer it as the
    // canonical root and only use __config as a non-JavaScript fallback.
    if (knowledgeMapScriptUrl) return new URL("../", knowledgeMapScriptUrl);

    var configNode = document.getElementById("__config");
    var base = ".";
    if (configNode) {
      try {
        base = JSON.parse(configNode.textContent || "{}").base || ".";
      } catch (_error) {
        base = ".";
      }
    }
    return new URL(base.replace(/\/$/, "") + "/", window.location.href);
  }

  function getDataUrl() {
    return new URL("assets/knowledge-map.json", getSiteRoot()).href;
  }

  function getRouteUrl(route, siteRoot) {
    var normalizedRoute = String(route || "").replace(/^\/+/, "");
    return new URL(normalizedRoute, siteRoot).href;
  }

  function loadMapData() {
    if (!mapDataPromise) {
      mapDataPromise = fetch(getDataUrl(), { cache: "no-cache" }).then(function (response) {
        if (!response.ok) throw new Error("knowledge map unavailable");
        return response.json();
      });
    }
    return mapDataPromise;
  }

  function normalizedPath(url) {
    var path = new URL(url, window.location.href).pathname.replace(/index\.html$/, "");
    return path.endsWith("/") ? path : path + "/";
  }

  function resolveInitialPath(root, siteRoot) {
    var currentPath = normalizedPath(window.location.href);
    for (var categoryIndex = 0; categoryIndex < root.categories.length; categoryIndex += 1) {
      var category = root.categories[categoryIndex];
      for (var groupIndex = 0; groupIndex < category.groups.length; groupIndex += 1) {
        var group = category.groups[groupIndex];
        for (var documentIndex = 0; documentIndex < group.documents.length; documentIndex += 1) {
          var documentNode = group.documents[documentIndex];
          if (normalizedPath(getRouteUrl(documentNode.route, siteRoot)) === currentPath) {
            return { categoryIndex: categoryIndex, groupIndex: groupIndex, documentIndex: documentIndex };
          }
        }
      }
    }
    return { categoryIndex: 0, groupIndex: 0, documentIndex: -1 };
  }

  function countDocuments(root) {
    return root.categories.reduce(function (total, category) {
      return total + category.groups.reduce(function (categoryTotal, group) {
        return categoryTotal + group.documents.length;
      }, 0);
    }, 0);
  }

  function buildNode(label, detail, level, selected) {
    var button = element("button", "sfh-map-node sfh-map-node--" + level + (selected ? " is-selected" : ""));
    button.type = "button";
    button.append(element("strong", "", label), element("small", "", detail || ""));
	 button.setAttribute("aria-label", label + (detail ? ". " + detail : ""));
    return button;
  }

  function buildMap(data) {
    var root = data.root;
    var siteRoot = getSiteRoot();
    var initial = resolveInitialPath(root, siteRoot);
    var state = {
      categoryIndex: initial.categoryIndex,
      groupIndex: initial.groupIndex,
      documentIndex: initial.documentIndex
    };
    var wrapper = element("section", "sfh-knowledge-map");
    wrapper.id = "sfh-knowledge-map";
    wrapper.setAttribute("role", "region");
    wrapper.setAttribute("data-sfh-knowledge-map", "");

    var header = element("header", "sfh-knowledge-map__header");
    var heading = element("div", "");
    var headingTitle = element("h2", "", "전체 문서 노드맵");
    headingTitle.id = "sfh-knowledge-map-title";
    heading.append(element("small", "", "KNOWLEDGE GRAPH // L1-L4"), headingTitle);
	 wrapper.setAttribute("aria-labelledby", headingTitle.id);
    var status = element("div", "sfh-knowledge-map__status");
    status.append(element("b", "", String(countDocuments(root))), element("span", "", "DOCUMENT NODES"));
    header.append(heading, status);

    var intro = element("p", "sfh-knowledge-map__intro", "대분류에서 세부 문서까지 연결을 따라가거나, 문서명을 입력해 전체 노드에서 바로 찾습니다.");
    var search = element("input", "sfh-knowledge-map__search");
    search.type = "search";
    search.placeholder = "전체 " + countDocuments(root) + "개 문서 노드 검색";
    search.setAttribute("aria-label", "전체 문서 노드 검색");
	 search.setAttribute("aria-controls", "sfh-knowledge-map-results");
    var searchResults = element("div", "sfh-knowledge-map__results");
	 searchResults.id = "sfh-knowledge-map-results";
	 searchResults.setAttribute("role", "status");
	 searchResults.setAttribute("aria-live", "polite");
	 searchResults.setAttribute("aria-label", "문서 검색 결과");
    searchResults.hidden = true;
    var breadcrumb = element("div", "sfh-knowledge-map__path");
    breadcrumb.setAttribute("aria-live", "polite");

    var graph = element("div", "sfh-knowledge-map__graph");
	 graph.setAttribute("role", "group");
	 graph.setAttribute("aria-label", "대분류부터 세부 문서까지 네 단계 문서 탐색");
    var rootColumn = element("section", "sfh-map-column sfh-map-column--root");
    var categoryColumn = element("section", "sfh-map-column");
    var groupColumn = element("section", "sfh-map-column");
    var documentColumn = element("section", "sfh-map-column sfh-map-column--documents");
    graph.append(rootColumn, categoryColumn, groupColumn, documentColumn);

    function columnHeader(level, label) {
      var node = element("header", "sfh-map-column__header");
      node.append(element("small", "", level), element("strong", "", label));
      return node;
    }

    function renderPath() {
      var category = root.categories[state.categoryIndex];
      var group = category.groups[state.groupIndex];
      var documentNode = state.documentIndex >= 0 ? group.documents[state.documentIndex] : null;
      breadcrumb.replaceChildren();
      [root.label, category.label, group.label, documentNode ? documentNode.label : "세부 문서 선택"].forEach(function (label, index) {
        if (index > 0) breadcrumb.append(element("i", "", "→"));
        breadcrumb.append(element("span", index === 3 && documentNode ? "is-current" : "", label));
      });
    }

    function renderRoot() {
      rootColumn.replaceChildren(columnHeader("L1 · 대", "프로젝트"));
	  rootColumn.setAttribute("aria-label", "1단계 프로젝트");
	  var rootNode = element("div", "sfh-map-node sfh-map-node--root is-selected");
	  rootNode.append(element("strong", "", root.label), element("small", "", root.description));
	  rootNode.setAttribute("aria-label", root.label + ". " + root.description);
      rootColumn.append(rootNode);
    }

    function renderCategories() {
      categoryColumn.replaceChildren(columnHeader("L2 · 중", "큰 영역"));
	  categoryColumn.setAttribute("aria-label", "2단계 큰 영역");
      root.categories.forEach(function (category, index) {
        var node = buildNode(category.label, category.description, "category", index === state.categoryIndex);
        node.setAttribute("aria-pressed", index === state.categoryIndex ? "true" : "false");
		node.dataset.mapLevel = "category";
		node.dataset.mapIndex = String(index);
		node.setAttribute("aria-controls", "sfh-map-groups");
        node.addEventListener("click", function () {
          state.categoryIndex = index;
          state.groupIndex = 0;
          state.documentIndex = -1;
		  renderAll({ level: "category", index: index });
        });
        categoryColumn.append(node);
      });
    }

    function renderGroups() {
      var category = root.categories[state.categoryIndex];
      groupColumn.replaceChildren(columnHeader("L3 · 소", category.label));
	  groupColumn.id = "sfh-map-groups";
	  groupColumn.setAttribute("aria-label", "3단계 " + category.label + " 하위 영역");
      category.groups.forEach(function (group, index) {
        var node = buildNode(group.label, group.description, "group", index === state.groupIndex);
        node.setAttribute("aria-pressed", index === state.groupIndex ? "true" : "false");
		node.dataset.mapLevel = "group";
		node.dataset.mapIndex = String(index);
		node.setAttribute("aria-controls", "sfh-map-documents");
        node.addEventListener("click", function () {
          state.groupIndex = index;
          state.documentIndex = -1;
		  renderAll({ level: "group", index: index });
        });
        groupColumn.append(node);
      });
    }

    function renderDocuments() {
      var category = root.categories[state.categoryIndex];
      var group = category.groups[state.groupIndex];
      documentColumn.replaceChildren(columnHeader("L4 · 세부", group.label + " · " + group.documents.length));
	  documentColumn.id = "sfh-map-documents";
	  documentColumn.setAttribute("aria-label", "4단계 " + group.label + " 세부 문서");
      group.documents.forEach(function (documentNode, index) {
        var link = element("a", "sfh-map-node sfh-map-node--document" + (index === state.documentIndex ? " is-selected is-current" : ""));
        link.href = getRouteUrl(documentNode.route, siteRoot);
		link.setAttribute("aria-label", documentNode.label + ". " + documentNode.summary);
        link.append(element("strong", "", documentNode.label), element("small", "", documentNode.summary));
        if (index === state.documentIndex) link.setAttribute("aria-current", "page");
        link.addEventListener("focus", function () {
          state.documentIndex = index;
          renderPath();
        });
        documentColumn.append(link);
      });
    }

    function renderAll(focusTarget) {
      renderRoot();
      renderCategories();
      renderGroups();
      renderDocuments();
      renderPath();
	  if (focusTarget) {
		var selector = '[data-map-level="' + focusTarget.level + '"][data-map-index="' + focusTarget.index + '"]';
		var restored = graph.querySelector(selector);
		if (restored) restored.focus({ preventScroll: true });
	  }
    }

    function allDocuments() {
      var flattened = [];
      root.categories.forEach(function (category) {
        category.groups.forEach(function (group) {
          group.documents.forEach(function (documentNode) {
            flattened.push({ category: category, group: group, documentNode: documentNode });
          });
        });
      });
      return flattened;
    }

    search.addEventListener("input", function () {
      var query = search.value.trim().toLocaleLowerCase("ko");
      searchResults.replaceChildren();
      searchResults.hidden = query.length === 0;
      graph.hidden = query.length > 0;
      breadcrumb.hidden = query.length > 0;
      if (!query) return;
      var matches = allDocuments().filter(function (entry) {
        return [entry.category.label, entry.group.label, entry.documentNode.label, entry.documentNode.summary]
          .join(" ").toLocaleLowerCase("ko").includes(query);
      }).slice(0, 12);
      if (!matches.length) {
		searchResults.setAttribute("aria-label", "문서 검색 결과 0개");
        searchResults.append(element("p", "sfh-knowledge-map__empty", "일치하는 문서 노드가 없습니다."));
        return;
      }
	  searchResults.setAttribute("aria-label", "문서 검색 결과 " + matches.length + "개");
      matches.forEach(function (entry) {
        var link = element("a", "sfh-map-search-result");
        link.href = getRouteUrl(entry.documentNode.route, siteRoot);
		link.setAttribute("aria-label", entry.documentNode.label + ". " + entry.category.label + ", " + entry.group.label);
        var copy = element("span", "");
        copy.append(element("strong", "", entry.documentNode.label), element("small", "", entry.documentNode.summary));
        link.append(copy, element("em", "", entry.category.label + " → " + entry.group.label));
        searchResults.append(link);
      });
    });

    graph.addEventListener("keydown", function (event) {
      if (!["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].includes(event.key)) return;
      var current = event.target.closest(".sfh-map-node");
      if (!current) return;
      var column = current.closest(".sfh-map-column");
      var columns = Array.from(graph.querySelectorAll(".sfh-map-column"));
      var columnIndex = columns.indexOf(column);
      var nodes = Array.from(column.querySelectorAll(".sfh-map-node:not(:disabled)"));
      var nodeIndex = nodes.indexOf(current);
      var target = null;
      if (event.key === "ArrowUp") target = nodes[Math.max(0, nodeIndex - 1)];
      if (event.key === "ArrowDown") target = nodes[Math.min(nodes.length - 1, nodeIndex + 1)];
      if (event.key === "ArrowLeft" && columnIndex > 0) target = columns[columnIndex - 1].querySelector(".is-selected:not(:disabled), .sfh-map-node:not(:disabled)");
      if (event.key === "ArrowRight" && columnIndex < columns.length - 1) target = columns[columnIndex + 1].querySelector(".is-selected:not(:disabled), .sfh-map-node:not(:disabled)");
      if (target) {
        event.preventDefault();
        target.focus();
      }
    });

    wrapper.append(header, intro, search, searchResults, breadcrumb, graph);
    renderAll();
    return wrapper;
  }

  function initializeKnowledgeMap() {
    if (window.location.pathname === "/" || window.location.pathname === "/index.html" || window.location.pathname.startsWith("/access/login")) return;
    var article = document.querySelector(".md-content__inner");
    if (!article || initializedHosts.has(article)) return;
    initializedHosts.add(article);
    var host = article.querySelector("[data-sfh-knowledge-map-host]") || article;
    var drawer = element("details", "sfh-article-map");
    drawer.append(element("summary", "", "전체 문서 노드맵 펼치기 · 구조를 한눈에 볼 때"));
    host.append(drawer);
    var requested = false;
    drawer.addEventListener("toggle", function () {
      if (!drawer.open || requested) return;
      requested = true;
      loadMapData().then(function (data) {
        if (!drawer.isConnected || drawer.querySelector("[data-sfh-knowledge-map]")) return;
        drawer.append(buildMap(data));
      }).catch(function () {
        drawer.append(element("p", "sfh-knowledge-map__error", "문서 노드맵을 불러오지 못했습니다. 상위·하위 문서 링크 또는 상단 검색을 사용해 주세요."));
      });
    });
  }

  if (typeof document$ !== "undefined" && document$.subscribe) {
    document$.subscribe(initializeKnowledgeMap);
  } else if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializeKnowledgeMap, { once: true });
  } else {
    initializeKnowledgeMap();
  }
})();
