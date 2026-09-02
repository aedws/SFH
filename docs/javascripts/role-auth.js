(() => {
  const API = "/api/auth";
  const ROLE_LABELS = { planner: "기획자", developer: "개발자" };
  let currentSession = { authenticated: false };

  async function api(path, options = {}) {
    const response = await fetch(`${API}${path}`, {
      credentials: "same-origin",
      cache: "no-store",
      ...options,
      headers: {
        ...(options.body ? { "content-type": "application/json" } : {}),
        ...(currentSession.csrf ? { "x-csrf-token": currentSession.csrf } : {}),
        ...(options.headers || {}),
      },
    });
    const payload = await response.json().catch(() => ({ error: "응답을 읽을 수 없습니다." }));
    if (!response.ok) throw new Error(payload.error || "요청에 실패했습니다.");
    return payload;
  }

  function rolePath(role) {
    return role === "planner" ? "/access/planner/" : "/access/developer/";
  }

  function safeReturnPath() {
    const value = new URLSearchParams(location.search).get("return") || "";
    return value.startsWith("/") && !value.startsWith("//") ? value : "";
  }

  function safeRoleReturnPath(role) {
    const path = safeReturnPath();
    if (!path) return "";
    if (path.startsWith("/access/planner") && role !== "planner") return "";
    if (path.startsWith("/access/developer") && role !== "developer") return "";
    return path;
  }

  function setStatus(element, message, state = "") {
    if (!element) return;
    element.textContent = message;
    element.dataset.state = state;
  }

  function mountHeader() {
    document.querySelectorAll("[data-sfh-role-auth-bar]").forEach((node) => node.remove());
    const host = document.querySelector(".md-header__inner") || document.body;
    const bar = document.createElement("nav");
    bar.className = "sfh-role-auth-bar";
    bar.dataset.sfhRoleAuthBar = "";
    bar.setAttribute("aria-label", "역할 작업 공간");

    if (!currentSession.authenticated) {
      bar.innerHTML = '<a class="sfh-auth-chip" href="/access/login/"><span class="sfh-auth-signal"></span>역할 로그인</a>';
    } else {
      const label = ROLE_LABELS[currentSession.role] || "사용자";
      const required = currentSession.must_change ? '<b class="sfh-auth-alert">변경 필요</b>' : "";
      bar.innerHTML = `
        <a class="sfh-auth-chip is-active" href="${rolePath(currentSession.role)}"><span class="sfh-auth-signal"></span>${label} 탭</a>
        <a class="sfh-auth-chip" href="/access/account/">${currentSession.username}${required}</a>
        <button class="sfh-auth-chip" type="button" data-sfh-auth-logout>로그아웃</button>`;
      bar.querySelector("[data-sfh-auth-logout]").addEventListener("click", async () => {
        try {
          await api("/logout", { method: "POST" });
          location.assign("/");
        } catch (error) {
          window.alert(error.message);
        }
      });
    }
    host.append(bar);
    document.documentElement.dataset.sfhRole = currentSession.authenticated ? currentSession.role : "public";
    const publicPath = location.pathname === "/" || location.pathname === "/index.html" || location.pathname.startsWith("/access/login");
    document.documentElement.dataset.sfhPublicSurface = String(publicPath && !currentSession.authenticated);
  }

  function bindRoleTabs(root) {
    const roleInput = root.querySelector('[name="role"]');
    const usernameInput = root.querySelector('[name="username"]');
    const selectRole = (role) => {
      roleInput.value = role;
      usernameInput.value = role;
    };
    selectRole(roleInput.value || "planner");
    root.querySelectorAll("[data-sfh-login-role]").forEach((button) => {
      button.addEventListener("click", () => {
        root.querySelectorAll("[data-sfh-login-role]").forEach((candidate) => {
          candidate.setAttribute("aria-selected", String(candidate === button));
        });
        selectRole(button.dataset.sfhLoginRole);
        root.querySelector('[name="password"]').focus();
      });
    });
  }

  function bindLogin() {
    const root = document.querySelector("[data-sfh-auth-login]");
    if (!root) return;
    if (currentSession.authenticated) {
      location.replace(currentSession.must_change ? "/access/account/?required=1" : rolePath(currentSession.role));
      return;
    }
    bindRoleTabs(root);
    const form = root.querySelector("form");
    const status = root.querySelector("[data-sfh-auth-status]");
    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      const submit = form.querySelector('button[type="submit"]');
      submit.disabled = true;
      setStatus(status, "인증 중…", "loading");
      const data = new FormData(form);
      try {
        currentSession = await api("/login", {
          method: "POST",
          body: JSON.stringify({
            role: data.get("role"),
            username: data.get("username"),
            password: data.get("password"),
          }),
        });
        const destination = currentSession.must_change
          ? "/access/account/?required=1"
          : safeRoleReturnPath(currentSession.role) || rolePath(currentSession.role);
        location.assign(destination);
      } catch (error) {
        setStatus(status, error.message, "error");
        submit.disabled = false;
      }
    });
  }

  function bindAccount() {
    const root = document.querySelector("[data-sfh-auth-account]");
    if (!root) return;
    const identity = root.querySelector("[data-sfh-auth-identity]");
    const notice = root.querySelector("[data-sfh-auth-required]");
    const form = root.querySelector("form");
    const status = root.querySelector("[data-sfh-auth-status]");
    if (!currentSession.authenticated) {
      location.replace(`/access/login/?return=${encodeURIComponent(location.pathname + location.search)}`);
      return;
    }
    identity.textContent = `${ROLE_LABELS[currentSession.role]} · ${currentSession.username}`;
    notice.hidden = !currentSession.must_change;
    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      const data = new FormData(form);
      if (data.get("new_password") !== data.get("confirm_password")) {
        setStatus(status, "새 비밀번호 확인이 일치하지 않습니다.", "error");
        return;
      }
      const submit = form.querySelector('button[type="submit"]');
      submit.disabled = true;
      setStatus(status, "안전하게 변경 중…", "loading");
      try {
        currentSession = await api("/credentials", {
          method: "POST",
          body: JSON.stringify({
            current_password: data.get("current_password"),
            new_password: data.get("new_password"),
          }),
        });
        setStatus(status, "변경되었습니다. 기존 세션은 무효화했습니다.", "success");
        form.reset();
        notice.hidden = true;
        mountHeader();
      } catch (error) {
        setStatus(status, error.message, "error");
      } finally {
        submit.disabled = false;
      }
    });
  }

  async function boot() {
    try {
      currentSession = await api("/session");
    } catch {
      currentSession = { authenticated: false };
    }
    mountHeader();
    bindLogin();
    bindAccount();
  }

  if (typeof window.document$ !== "undefined" && typeof window.document$.subscribe === "function") {
    window.document$.subscribe(boot);
  } else if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot, { once: true });
  } else {
    boot();
  }
})();
