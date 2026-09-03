(function () {
  "use strict";

  var STORAGE_KEY = "sfh-wiki-search-signals-v1";
  var dashboardConfigPromise = null;
  var initializedSearchRoots = new WeakSet();
  var searchDashboardScriptUrl = document.currentScript && document.currentScript.src
    ? new URL(document.currentScript.src, window.location.href)
    : null;
  var fallbackConfig = {
    title: "기획자 검색 허브",
    description: "입력 즉시 전체 문서를 검색합니다.",
    rankings: [
      { query: "개발 진행도", label: "개발 진행도", description: "현재 완료 근거", category: "기획", priority: 100 },
      { query: "앞으로 해야 할 작업", label: "앞으로 해야 할 작업", description: "후속 우선순위", category: "기획", priority: 90 },
      { query: "코어 플레이 루프", label: "코어 플레이 루프", description: "거점부터 정산까지", category: "설계", priority: 80 }
    ],
    planner_groups: []
  };

  function createElement(tagName, className, text) {
    var node = document.createElement(tagName);
    if (className) {
      node.className = className;
    }
    if (typeof text === "string") {
      node.textContent = text;
    }
    return node;
  }

  function getConfigUrl() {
    if (searchDashboardScriptUrl) {
      return new URL("../assets/search-priorities.json", searchDashboardScriptUrl).href;
    }
    var configNode = document.getElementById("__config");
    var base = ".";
    if (configNode) {
      try {
        base = JSON.parse(configNode.textContent || "{}").base || ".";
      } catch (_error) {
        base = ".";
      }
    }
    return new URL(base.replace(/\/$/, "") + "/assets/search-priorities.json", window.location.href).href;
  }

  function loadDashboardConfig() {
    if (!dashboardConfigPromise) {
      dashboardConfigPromise = fetch(getConfigUrl(), { cache: "no-cache" })
        .then(function (response) {
          if (!response.ok) {
            throw new Error("search priority data unavailable");
          }
          return response.json();
        })
        .catch(function () {
          return fallbackConfig;
        });
    }
    return dashboardConfigPromise;
  }

  function readSignals() {
    try {
      var parsed = JSON.parse(window.localStorage.getItem(STORAGE_KEY) || "{}");
      return {
        counts: parsed.counts && typeof parsed.counts === "object" ? parsed.counts : {},
        recent: Array.isArray(parsed.recent) ? parsed.recent.slice(0, 6) : []
      };
    } catch (_error) {
      return { counts: {}, recent: [] };
    }
  }

  function writeSignals(signals) {
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(signals));
    } catch (_error) {
      return;
    }
  }

  function recordQuery(query) {
    var normalized = String(query || "").trim();
    if (normalized.length < 2) {
      return;
    }
    var signals = readSignals();
    var previous = signals.counts[normalized] || { count: 0, last: 0 };
    signals.counts[normalized] = {
      count: Math.min(99, Number(previous.count || 0) + 1),
      last: Date.now()
    };
    signals.recent = [normalized].concat(signals.recent.filter(function (item) {
      return item !== normalized;
    })).slice(0, 6);
    writeSignals(signals);
  }

  function rankingScore(item, signals) {
    var activity = signals.counts[item.query] || { count: 0, last: 0 };
    var ageHours = Math.max(0, (Date.now() - Number(activity.last || 0)) / 3600000);
    var recencyBonus = activity.last ? Math.max(0, 28 - ageHours / 6) : 0;
    return Number(item.priority || 0) + Number(activity.count || 0) * 12 + recencyBonus;
  }

  function renderRecent(container, recent, activateQuery) {
    container.replaceChildren();
    if (!recent.length) {
      container.hidden = true;
      return;
    }
    container.hidden = false;
    var label = createElement("strong", "sfh-search-section-label", "최근 선택");
    var chips = createElement("div", "sfh-search-chips");
    recent.forEach(function (query) {
      var button = createElement("button", "sfh-search-chip", query);
      button.type = "button";
      button.addEventListener("click", function () {
        activateQuery(query, true);
      });
      chips.appendChild(button);
    });
    container.append(label, chips);
  }

  function renderDashboard(dashboard, config, activateQuery) {
    var signals = readSignals();
    var rankings = (config.rankings || []).slice().sort(function (left, right) {
      return rankingScore(right, signals) - rankingScore(left, signals);
    }).slice(0, 10);
    var rankingList = dashboard.querySelector("[data-sfh-search-rankings]");
    var recent = dashboard.querySelector("[data-sfh-search-recent]");
    var groups = dashboard.querySelector("[data-sfh-search-groups]");
    rankingList.replaceChildren();
    groups.replaceChildren();

    rankings.forEach(function (item, index) {
      var activity = signals.counts[item.query] || { count: 0 };
      var button = createElement("button", "sfh-search-rank");
      button.type = "button";
      button.setAttribute("aria-label", item.label + " 검색");
      var rank = createElement("span", "sfh-search-rank__number", String(index + 1).padStart(2, "0"));
      var copy = createElement("span", "sfh-search-rank__copy");
      copy.append(
        createElement("strong", "", item.label),
        createElement("small", "", item.description || item.query)
      );
      var meta = createElement("span", "sfh-search-rank__meta");
      meta.append(
        createElement("i", "", item.category || "문서"),
        createElement("b", "", Number(activity.count || 0) > 0 ? "▲ " + activity.count : "LIVE")
      );
      button.append(rank, copy, meta);
      button.addEventListener("click", function () {
        activateQuery(item.query, true);
      });
      rankingList.appendChild(button);
    });

    (config.planner_groups || []).forEach(function (group) {
      var section = createElement("section", "sfh-search-group");
      section.appendChild(createElement("strong", "", group.label));
      var chips = createElement("div", "sfh-search-chips");
      (group.queries || []).forEach(function (query) {
        var button = createElement("button", "sfh-search-chip", query);
        button.type = "button";
        button.addEventListener("click", function () {
          activateQuery(query, true);
        });
        chips.appendChild(button);
      });
      section.appendChild(chips);
      groups.appendChild(section);
    });

    renderRecent(recent, signals.recent, activateQuery);
  }

  function createDashboard(config) {
    var dashboard = createElement("section", "sfh-search-dashboard");
    dashboard.setAttribute("aria-label", "기획자 검색 추천");
    var header = createElement("header", "sfh-search-dashboard__header");
    var title = createElement("span", "");
    title.append(
      createElement("small", "", "SFH SEARCH COMMAND"),
      createElement("strong", "", config.title || "기획자 검색 허브")
    );
    header.append(title, createElement("b", "", "LIVE"));
    dashboard.append(
      header,
      createElement("p", "sfh-search-dashboard__description", config.description || ""),
      createElement("div", "sfh-search-recent", "")
    );
    dashboard.lastElementChild.setAttribute("data-sfh-search-recent", "");
    var rankingHeader = createElement("div", "sfh-search-ranking-head");
    rankingHeader.append(
      createElement("strong", "", "실시간 탐색 순위"),
      createElement("small", "", "기획 우선순위 + 현재 브라우저 선택")
    );
    var rankings = createElement("div", "sfh-search-rankings");
    rankings.setAttribute("data-sfh-search-rankings", "");
    var plannerLabel = createElement("strong", "sfh-search-section-label", "기획 영역 빠른 검색");
    var groups = createElement("div", "sfh-search-groups");
    groups.setAttribute("data-sfh-search-groups", "");
    dashboard.append(rankingHeader, rankings, plannerLabel, groups);
    return dashboard;
  }

  function initializeSearch() {
    if (window.location.pathname === "/" || window.location.pathname === "/index.html" || window.location.pathname.startsWith("/access/login")) return;
    var searchRoot = document.querySelector('[data-md-component="search"]');
    if (!searchRoot) {
      return;
    }
    // Header and search panel have different lifetimes during instant navigation.
    var trigger = document.querySelector('.md-header__button[for="__search"]');
    if (trigger && !trigger.classList.contains("sfh-header-search")) {
      trigger.classList.add("sfh-header-search");
      trigger.append(createElement("span", "sfh-search-label", "검색"));
      trigger.setAttribute("aria-label", "문서 검색 열기");
      trigger.setAttribute("title", "문서 검색 · 게임 실행 아님");
      trigger.setAttribute("role", "button");
      trigger.tabIndex = 0;
      trigger.addEventListener("keydown", function (event) {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault();
          trigger.click();
        }
      });
    }
    if (initializedSearchRoots.has(searchRoot)) return;
    var input = searchRoot.querySelector('[data-md-component="search-query"]');
    var result = searchRoot.querySelector('[data-md-component="search-result"]');
    var meta = result && result.querySelector(".md-search-result__meta");
    var list = result && result.querySelector(".md-search-result__list");
    if (!input || !result || !meta || !list) {
      return;
    }
    initializedSearchRoots.add(searchRoot);
    input.placeholder = "문서 검색 · 기획 / 기능 / 버그";
    input.setAttribute("aria-label", "문서 검색");

    loadDashboardConfig().then(function (config) {
      if (!result.isConnected || result.querySelector(".sfh-search-dashboard")) {
        return;
      }
      var dashboard = createDashboard(config);
      var liveHeader = createElement("div", "sfh-search-live");
      var liveCopy = createElement("span", "");
      liveCopy.append(
        createElement("small", "", "LIVE DOCUMENT SEARCH"),
        createElement("strong", "", "실시간 문서 검색")
      );
      var liveQuery = createElement("b", "", "");
      liveHeader.append(liveCopy, liveQuery);
      result.insertBefore(liveHeader, meta);
      result.insertBefore(dashboard, liveHeader);

      function activateQuery(query, shouldRecord) {
        input.value = query;
        if (shouldRecord) {
          recordQuery(query);
        }
        input.dispatchEvent(new Event("input", { bubbles: true }));
        input.dispatchEvent(new KeyboardEvent("keyup", {
          bubbles: true,
          key: "End",
          code: "End"
        }));
        input.focus();
      }

      function updateMode() {
        var query = input.value.trim();
        var isEmpty = query.length === 0;
        dashboard.hidden = !isEmpty;
        liveHeader.hidden = isEmpty;
        meta.hidden = isEmpty;
        list.hidden = isEmpty;
        liveQuery.textContent = query ? '"' + query + '"' : "";
        if (isEmpty) {
          renderDashboard(dashboard, config, activateQuery);
        }
      }

      input.addEventListener("input", updateMode);
      list.addEventListener("click", function (event) {
        if (event.target.closest("a") && input.value.trim()) {
          recordQuery(input.value);
        }
      });
      var searchToggle = document.getElementById("__search");
      if (searchToggle) {
        searchToggle.addEventListener("change", function () {
          if (searchToggle.checked) {
            updateMode();
          }
        });
      }
      updateMode();
    });
  }

  if (typeof document$ !== "undefined" && document$.subscribe) {
    document$.subscribe(initializeSearch);
  } else if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializeSearch, { once: true });
  } else {
    initializeSearch();
  }
})();
