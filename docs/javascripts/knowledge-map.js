(function () {
  "use strict";

  var mapDataPromise = null;
  var initializedHosts = new WeakSet();

  function element(tagName, className, text) {
    var node = document.createElement(tagName);
    if (className) node.className = className;
    if (typeof text === "string") node.textContent = text;
    return node;
  }

  function getSiteRoot() {
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
          if (normalizedPath(new URL(documentNode.route, siteRoot)) === currentPath) {
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
    wrapper.setAttribute("aria-label", "SFH 전체 문서 노드맵");
    wrapper.setAttribute("data-sfh-knowledge-map", "");

    var header = element("header", "sfh-knowledge-map__header");
    var heading = element("div", "");
    heading.append(element("small", "", "KNOWLEDGE GRAPH // L1-L4"), element("h2", "", "전체 문서 노드맵"));
    var status = element("div", "sfh-knowledge-map__status");
    status.append(element("b", "", String(countDocuments(root))), element("span", "", "DOCUMENT NODES"));
    header.append(heading, status);

    var intro = element("p", "sfh-knowledge-map__intro", "대분류에서 세부 문서까지 연결을 따라가거나, 문서명을 입력해 전체 노드에서 바로 찾습니다.");
    var search = element("input", "sfh-knowledge-map__search");
    search.type = "search";
    search.placeholder = "전체 55개 문서 노드 검색";
    search.setAttribute("aria-label", "전체 문서 노드 검색");
    var searchResults = element("div", "sfh-knowledge-map__results");
    searchResults.hidden = true;
    var breadcrumb = element("div", "sfh-knowledge-map__path");
    breadcrumb.setAttribute("aria-live", "polite");

    var graph = element("div", "sfh-knowledge-map__graph");
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
      var rootNode = buildNode(root.label, root.description, "root", true);
      rootNode.disabled = true;
      rootColumn.append(rootNode);
    }

    function renderCategories() {
      categoryColumn.replaceChildren(columnHeader("L2 · 중", "큰 영역"));
      root.categories.forEach(function (category, index) {
        var node = buildNode(category.label, category.description, "category", index === state.categoryIndex);
        node.setAttribute("aria-pressed", index === state.categoryIndex ? "true" : "false");
        node.addEventListener("click", function () {
          state.categoryIndex = index;
          state.groupIndex = 0;
          state.documentIndex = -1;
          renderAll();
        });
        categoryColumn.append(node);
      });
    }

    function renderGroups() {
      var category = root.categories[state.categoryIndex];
      groupColumn.replaceChildren(columnHeader("L3 · 소", category.label));
      category.groups.forEach(function (group, index) {
        var node = buildNode(group.label, group.description, "group", index === state.groupIndex);
        node.setAttribute("aria-pressed", index === state.groupIndex ? "true" : "false");
        node.addEventListener("click", function () {
          state.groupIndex = index;
          state.documentIndex = -1;
          renderAll();
        });
        groupColumn.append(node);
      });
    }

    function renderDocuments() {
      var category = root.categories[state.categoryIndex];
      var group = category.groups[state.groupIndex];
      documentColumn.replaceChildren(columnHeader("L4 · 세부", group.label + " · " + group.documents.length));
      group.documents.forEach(function (documentNode, index) {
        var link = element("a", "sfh-map-node sfh-map-node--document" + (index === state.documentIndex ? " is-selected is-current" : ""));
        link.href = new URL(documentNode.route, siteRoot).href;
        link.append(element("strong", "", documentNode.label), element("small", "", documentNode.summary));
        if (index === state.documentIndex) link.setAttribute("aria-current", "page");
        link.addEventListener("focus", function () {
          state.documentIndex = index;
          renderPath();
        });
        documentColumn.append(link);
      });
    }

    function renderAll() {
      renderRoot();
      renderCategories();
      renderGroups();
      renderDocuments();
      renderPath();
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
        searchResults.append(element("p", "sfh-knowledge-map__empty", "일치하는 문서 노드가 없습니다."));
        return;
      }
      matches.forEach(function (entry) {
        var link = element("a", "sfh-map-search-result");
        link.href = new URL(entry.documentNode.route, siteRoot).href;
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
    var host = document.querySelector(".md-content__inner");
    if (!host || initializedHosts.has(host)) return;
    initializedHosts.add(host);
    loadMapData().then(function (data) {
      if (!host.isConnected || host.querySelector("[data-sfh-knowledge-map]")) return;
      host.append(buildMap(data));
    }).catch(function () {
      var notice = element("p", "sfh-knowledge-map__error", "문서 노드맵을 불러오지 못했습니다. 좌측 목차 또는 상단 검색을 사용해 주세요.");
      host.append(notice);
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
