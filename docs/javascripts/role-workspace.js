/* Disclosure navigation adapter. Existing presenters retain their state and authority. */
(function () {
  'use strict';
  function reveal(hash, focus) {
    if (!hash || hash === '#') return;
    let id;
    try { id = decodeURIComponent(hash.slice(1)); } catch (_) { return; }
    const target = document.getElementById(id);
    if (!target || !target.closest('[data-sfh-workspace]')) return;
    for (let node = target; node; node = node.parentElement) {
      if (node.tagName === 'DETAILS') node.open = true;
    }
    requestAnimationFrame(function () {
      if (!target.isConnected) return;
      target.scrollIntoView({block: 'start', behavior: 'instant'});
      if (focus) {
        const destination = target.tagName === 'DETAILS' ? target.querySelector('summary') : target;
        if (!destination.hasAttribute('tabindex')) destination.setAttribute('tabindex', '-1');
        destination.focus({preventScroll: true});
      }
    });
    return true;
  }
  function mount() {
    reveal(location.hash, false);
    // Preserve existing links directly into an owner-console view/object.
    if (!location.hash && /[?&](view|decision)=/.test(location.search)) {
      reveal('#owner-decision-console', false);
    }
  }
  document.addEventListener('click', function (event) {
    const link = event.target.closest('a[href]');
    if (!link || event.defaultPrevented || event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    const url = new URL(link.href, location.href);
    if (url.origin !== location.origin || url.pathname !== location.pathname) return;
    if (link.closest('.sfh-workspace-launcher') && url.hash) url.search = location.search;
    else if (url.search !== location.search) return;
    // Material's instant-navigation also handles anchors. Own only workspace
    // destinations, once, so its scroll handler cannot steal keyboard focus.
    if (reveal(url.hash, true)) {
      event.preventDefault();
      event.stopPropagation();
      if (location.hash !== url.hash) history.pushState(history.state, '', url);
    }
  }, true);
  window.addEventListener('hashchange', function () { reveal(location.hash, true); });
  window.addEventListener('popstate', mount);
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', mount);
  else mount();
  if (typeof document$ !== 'undefined') document$.subscribe(mount);
})();
