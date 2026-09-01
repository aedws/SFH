(function () {
  "use strict";

  var GAMEPLAY_ORIGIN = "https://sfh-game.vstock-market.workers.dev";
  var SURFACE_REGISTRY = "assets/deployment-surfaces.json";

  function siteRoot() {
    var base = document.querySelector("base");
    return new URL(base ? base.href : document.baseURI);
  }

  function loadEffectiveOrigin() {
    return fetch(new URL(SURFACE_REGISTRY, siteRoot()).href, { cache: "no-cache" })
      .then(function (response) { return response.ok ? response.json() : null; })
      .then(function (data) {
        if (!data || !data.game) return GAMEPLAY_ORIGIN;
        if (data.game.cutover_status === "ready") return data.game.desired_origin;
        return data.game.effective_origin || GAMEPLAY_ORIGIN;
      })
      .catch(function () { return GAMEPLAY_ORIGIN; });
  }

  function getPlayUrl() {
    return GAMEPLAY_ORIGIN + "/";
  }


  function applySurfaceLinks(origin) {
    document.querySelectorAll("[data-sfh-surface='gameplay']").forEach(function (link) {
      if (link.tagName === "A") link.href = origin + "/";
    });
    document.querySelectorAll("a[data-sfh-surface='windows-download']").forEach(function (link) {
      var path = new URL(link.href).pathname;
      link.href = origin + path;
    });
  }

  function initializePlayEntry() {
    var host = document.querySelector('.md-header__inner');
    if (!host) {
      return;
    }
    var entry = document.querySelector("[data-sfh-global-play]");
    if (!entry) {
      entry = document.createElement("a");
      entry.className = "sfh-global-play";
      entry.setAttribute("data-sfh-global-play", "");
      entry.setAttribute("data-sfh-surface", "gameplay");
      entry.setAttribute("aria-label", "SFH 브라우저 빌드 플레이");
      entry.title = "브라우저로 플레이";
      entry.innerHTML = [
        '<i aria-hidden="true">▶</i>',
        '<span><small>PLAY SFH</small><strong>브라우저로 플레이</strong></span>'
      ].join("");
    }
	entry.href = getPlayUrl();
    entry.target = "_blank";
    entry.rel = "noopener noreferrer";
    if (entry.parentElement !== host) {
      host.insertBefore(entry, host.querySelector('.md-header__source'));
    }
	loadEffectiveOrigin().then(function (origin) {
	  entry.href = origin + "/";
	  applySurfaceLinks(origin);
	});
  }

  if (typeof document$ !== "undefined" && document$.subscribe) {
    document$.subscribe(initializePlayEntry);
  } else if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializePlayEntry, { once: true });
  } else {
    initializePlayEntry();
  }
})();
