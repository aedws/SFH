(function () {
  "use strict";

  var requestPromise = null;

  function siteRoot() {
    var base = document.querySelector("base");
    return new URL(base ? base.href : document.baseURI);
  }

  function dataUrl() {
    return new URL("assets/planner-requests.json", siteRoot()).href;
  }

  function element(name, className, text) {
    var node = document.createElement(name);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
  }

  function loadRequests() {
    if (!requestPromise) {
      requestPromise = fetch(dataUrl(), { cache: "no-cache" }).then(function (response) {
        if (!response.ok) throw new Error("planner request data unavailable");
        return response.json();
      });
    }
    return requestPromise;
  }

  function statusOrder(status) {
    return { request: 0, data: 1, complete: 2 }[status] ?? 9;
  }

  function buildCard(item, notionUrl) {
    var article = element("article", "sfh-planner-request is-" + item.status);
    article.dataset.requestId = item.id;
    var header = element("header", "sfh-planner-request__header");
    header.append(element("span", "sfh-planner-request__tag", item.tag));
    header.append(element("code", "sfh-planner-request__id", item.id));
    article.append(header);
    article.append(element("h3", "", item.title));
    article.append(element("p", "sfh-planner-request__summary", item.summary));
    var basis = element("p", "sfh-planner-request__basis");
    basis.append(element("b", "", "작성 근거"));
    basis.append(document.createTextNode(" · " + item.basis));
    article.append(basis);
    article.append(element("p", "sfh-planner-request__prompt", item.notion_prompt));
    var link = element("a", "sfh-planner-request__notion", "Notion 근거 작성·확인 →");
    link.href = notionUrl;
    link.target = "_blank";
    link.rel = "noopener noreferrer";
    link.setAttribute("aria-label", item.id + " Notion 근거 작성 또는 확인");
    article.append(link);
    return article;
  }

  function render(host, data) {
    var items = Array.isArray(data.items) ? data.items.slice() : [];
    items.sort(function (a, b) {
      var statusDelta = statusOrder(a.status) - statusOrder(b.status);
      if (statusDelta !== 0) return statusDelta;
      return a.status === "complete" ? b.id.localeCompare(a.id) : a.id.localeCompare(b.id);
    });
    var counts = { request: 0, data: 0, complete: 0 };
    items.forEach(function (item) { counts[item.status] = (counts[item.status] || 0) + 1; });
    var status = host.querySelector("[data-sfh-planner-request-status]");
    if (status) {
      status.textContent = "작업 " + counts.request + " · 데이터 " + counts.data + " · 완료 " + counts.complete;
    }
    var grid = host.querySelector("[data-sfh-planner-request-grid]");
    grid.replaceChildren();
    items.forEach(function (item) { grid.append(buildCard(item, data.notion_url)); });
    var instruction = host.querySelector("[data-sfh-planner-request-instruction]");
    if (instruction) instruction.textContent = data.instruction;
    host.dataset.loaded = "true";
  }

  function install() {
    var host = document.querySelector("[data-sfh-planner-requests]");
    if (!host || host.dataset.loaded === "true") return;
    loadRequests().then(function (data) {
      if (host.isConnected) render(host, data);
    }).catch(function () {
      var grid = host.querySelector("[data-sfh-planner-request-grid]");
      if (grid) grid.append(element("p", "sfh-planner-request__error", "요청 목록을 불러오지 못했습니다. 기획 요청 운영 문서를 확인해 주세요."));
    });
  }

  if (window.document$ && typeof window.document$.subscribe === "function") {
    window.document$.subscribe(install);
  } else {
    document.addEventListener("DOMContentLoaded", install);
  }
})();
