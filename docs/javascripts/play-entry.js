(function () {
  "use strict";

  var GAMEPLAY_ORIGIN = "https://sfh-game.vstock-market.workers.dev";

  function getPlayUrl() {
    return GAMEPLAY_ORIGIN + "/";
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
  }

  if (typeof document$ !== "undefined" && document$.subscribe) {
    document$.subscribe(initializePlayEntry);
  } else if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializePlayEntry, { once: true });
  } else {
    initializePlayEntry();
  }
})();
