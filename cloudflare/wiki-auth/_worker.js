const USER_ROLES = Object.freeze(["planner", "developer"]);
const USER_KEYS = Object.freeze({
  planner: "users/planner.json",
  developer: "users/developer.json",
});
const ROLE_USERNAMES = Object.freeze({
  planner: "planner",
  developer: "developer",
});
const SESSION_PREFIX = "sessions/";
const LOGIN_PREFIX = "login-attempts/";
const SESSION_COOKIE = "sfh_wiki_session";
const DEFAULT_SESSION_TTL = 8 * 60 * 60;
const MIN_PASSWORD_LENGTH = 4;
const MAX_BODY_BYTES = 16 * 1024;
const MAX_LOGIN_FAILURES = 5;
const LOGIN_LOCK_SECONDS = 15 * 60;
// Cloudflare workerd rejects Web Crypto PBKDF2 requests above 100,000 iterations.
const PBKDF2_ITERATIONS = 100000;
const MAX_PBKDF2_ITERATIONS = 100000;
const encoder = new TextEncoder();

function json(payload, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store, max-age=0",
      ...extraHeaders,
    },
  });
}

function withSecurityHeaders(response, protectedContent = false) {
  const headers = new Headers(response.headers);
  headers.set("x-content-type-options", "nosniff");
  headers.set("referrer-policy", "same-origin");
  headers.set("permissions-policy", "camera=(), microphone=(), geolocation=()");
  headers.set("x-frame-options", "DENY");
  if (protectedContent) {
    headers.set("cache-control", "private, no-store, max-age=0");
    headers.set("vary", "Cookie");
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

function parseCookies(request) {
  const cookies = new Map();
  for (const part of (request.headers.get("cookie") || "").split(";")) {
    const separator = part.indexOf("=");
    if (separator < 1) continue;
    cookies.set(part.slice(0, separator).trim(), part.slice(separator + 1).trim());
  }
  return cookies;
}

function base64Url(bytes) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/u, "");
}

function fromBase64Url(value) {
  const padded = value.replaceAll("-", "+").replaceAll("_", "/") + "===".slice((value.length + 3) % 4);
  const binary = atob(padded);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function randomToken(byteLength = 32) {
  const bytes = new Uint8Array(byteLength);
  crypto.getRandomValues(bytes);
  return base64Url(bytes);
}

async function sha256(value) {
  const digest = await crypto.subtle.digest("SHA-256", encoder.encode(value));
  return base64Url(new Uint8Array(digest));
}

async function passwordDigest(password, salt, pepper, iterations = PBKDF2_ITERATIONS) {
  const material = await crypto.subtle.importKey(
    "raw",
    encoder.encode(`${password}\u0000${pepper}`),
    "PBKDF2",
    false,
    ["deriveBits"],
  );
  const bits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      hash: "SHA-256",
      salt: fromBase64Url(salt),
      iterations,
    },
    material,
    256,
  );
  return base64Url(new Uint8Array(bits));
}

function safeEqual(left, right) {
  const leftBytes = encoder.encode(left);
  const rightBytes = encoder.encode(right);
  let difference = leftBytes.length ^ rightBytes.length;
  const length = Math.max(leftBytes.length, rightBytes.length);
  for (let index = 0; index < length; index += 1) {
    difference |= (leftBytes[index] || 0) ^ (rightBytes[index] || 0);
  }
  return difference === 0;
}

function validatePassword(password) {
  return (
    typeof password === "string"
    && password.length >= MIN_PASSWORD_LENGTH
    && password.length <= 128
  );
}

async function readJsonObject(bucket, key) {
  const object = await bucket.get(key);
  if (!object) return null;
  try {
    return await object.json();
  } catch {
    return null;
  }
}

async function writeJsonObject(bucket, key, value) {
  await bucket.put(key, JSON.stringify(value), {
    httpMetadata: { contentType: "application/json" },
  });
}

async function parseJsonBody(request) {
  const contentLength = Number(request.headers.get("content-length") || 0);
  if (contentLength > MAX_BODY_BYTES) throw new Error("body_too_large");
  if (!(request.headers.get("content-type") || "").toLowerCase().startsWith("application/json")) {
    throw new Error("invalid_content_type");
  }
  const text = await request.text();
  if (encoder.encode(text).byteLength > MAX_BODY_BYTES) throw new Error("body_too_large");
  return JSON.parse(text);
}

function assertSameOrigin(request) {
  const origin = request.headers.get("origin");
  if (origin && origin !== new URL(request.url).origin) throw new Error("cross_origin");
}

function sessionCookie(token, maxAge) {
  return `${SESSION_COOKIE}=${token}; Path=/; Max-Age=${maxAge}; HttpOnly; Secure; SameSite=Strict`;
}

function expiredSessionCookie() {
  return `${SESSION_COOKIE}=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Strict`;
}

async function verifyPassword(env, user, password) {
  if (!user || !user.password || !env.AUTH_PEPPER) return false;
  const iterations = Number(user.password.iterations || PBKDF2_ITERATIONS);
  if (!Number.isSafeInteger(iterations) || iterations < 1 || iterations > MAX_PBKDF2_ITERATIONS) return false;
  const digest = await passwordDigest(
    password,
    user.password.salt,
    env.AUTH_PEPPER,
    iterations,
  );
  return safeEqual(digest, user.password.digest);
}

async function createSession(env, role, user) {
  const token = randomToken();
  const tokenHash = await sha256(token);
  const ttl = Math.max(900, Math.min(Number(env.SESSION_TTL_SECONDS) || DEFAULT_SESSION_TTL, 24 * 60 * 60));
  const session = {
    role,
    credential_version: user.credential_version,
    csrf: randomToken(24),
    created_at: Date.now(),
    expires_at: Date.now() + ttl * 1000,
  };
  await writeJsonObject(env.WIKI_AUTH, `${SESSION_PREFIX}${tokenHash}.json`, session);
  return { token, session, ttl };
}

async function getSession(request, env) {
  const token = parseCookies(request).get(SESSION_COOKIE);
  if (!token || token.length > 128) return null;
  const key = `${SESSION_PREFIX}${await sha256(token)}.json`;
  const session = await readJsonObject(env.WIKI_AUTH, key);
  if (!session || !USER_ROLES.includes(session.role) || session.expires_at <= Date.now()) {
    if (session) await env.WIKI_AUTH.delete(key);
    return null;
  }
  const user = await readJsonObject(env.WIKI_AUTH, USER_KEYS[session.role]);
  if (!user || user.credential_version !== session.credential_version) {
    await env.WIKI_AUTH.delete(key);
    return null;
  }
  return { token, key, session, user };
}

function publicSession(sessionState) {
  if (!sessionState) return { authenticated: false };
  return {
    authenticated: true,
    role: sessionState.session.role,
    username: sessionState.user.username,
    must_change: Boolean(sessionState.user.must_change),
    csrf: sessionState.session.csrf,
  };
}

async function loginAttemptKey(request, username) {
  const address = request.headers.get("cf-connecting-ip") || "local";
  return `${LOGIN_PREFIX}${await sha256(`${address}|${username.toLowerCase()}`)}.json`;
}

async function handleLogin(request, env) {
  assertSameOrigin(request);
  const body = await parseJsonBody(request);
  const username = typeof body.username === "string" ? body.username.trim() : "";
  const role = typeof body.role === "string" ? body.role : "";
  const password = typeof body.password === "string" ? body.password : "";
  if (!USER_ROLES.includes(role) || username !== ROLE_USERNAMES[role] || password.length > 128) {
    return json({ error: "아이디 또는 비밀번호를 확인해 주세요." }, 401);
  }

  const attemptKey = await loginAttemptKey(request, username);
  let attempts = (await readJsonObject(env.WIKI_AUTH, attemptKey)) || { count: 0, locked_until: 0, window_started: Date.now() };
  if (attempts.locked_until > Date.now()) {
    return json({ error: "로그인 시도가 잠겼습니다. 15분 후 다시 시도해 주세요." }, 429);
  }
  if (!attempts.window_started || attempts.window_started + LOGIN_LOCK_SECONDS * 1000 <= Date.now()) {
    attempts = { count: 0, locked_until: 0, window_started: Date.now() };
  }

  const user = await readJsonObject(env.WIKI_AUTH, USER_KEYS[role]);
  const valid = (
    user
    && user.role === role
    && user.username === ROLE_USERNAMES[role]
    && await verifyPassword(env, user, password)
  );
  if (!valid) {
    const count = Number(attempts.count || 0) + 1;
    await writeJsonObject(env.WIKI_AUTH, attemptKey, {
      count,
      locked_until: count >= MAX_LOGIN_FAILURES ? Date.now() + LOGIN_LOCK_SECONDS * 1000 : 0,
      window_started: attempts.window_started,
    });
    return json({ error: "아이디 또는 비밀번호를 확인해 주세요." }, 401);
  }

  await env.WIKI_AUTH.delete(attemptKey);
  const created = await createSession(env, role, user);
  return json(publicSession({ session: created.session, user }), 200, {
    "set-cookie": sessionCookie(created.token, created.ttl),
  });
}

async function handleLogout(request, env) {
  assertSameOrigin(request);
  const current = await getSession(request, env);
  if (current) {
    if (request.headers.get("x-csrf-token") !== current.session.csrf) {
      return json({ error: "요청 검증에 실패했습니다." }, 403);
    }
    await env.WIKI_AUTH.delete(current.key);
  }
  return json({ ok: true }, 200, { "set-cookie": expiredSessionCookie() });
}

async function handleCredentialChange(request, env) {
  assertSameOrigin(request);
  const current = await getSession(request, env);
  if (!current) return json({ error: "로그인이 필요합니다." }, 401);
  if (request.headers.get("x-csrf-token") !== current.session.csrf) {
    return json({ error: "요청 검증에 실패했습니다." }, 403);
  }
  const body = await parseJsonBody(request);
  const currentPassword = typeof body.current_password === "string" ? body.current_password : "";
  const newPassword = typeof body.new_password === "string" ? body.new_password : "";
  if (!await verifyPassword(env, current.user, currentPassword)) {
    return json({ error: "현재 비밀번호가 일치하지 않습니다." }, 403);
  }
  if (!validatePassword(newPassword)) {
    return json({ error: "새 비밀번호는 4~128자로 입력해 주세요." }, 400);
  }
  if (safeEqual(currentPassword, newPassword)) {
    return json({ error: "현재 비밀번호와 다른 비밀번호를 사용해 주세요." }, 400);
  }
  const salt = randomToken(18);
  const updatedUser = {
    ...current.user,
    username: ROLE_USERNAMES[current.session.role],
    password: {
      algorithm: "PBKDF2-SHA256",
      iterations: PBKDF2_ITERATIONS,
      salt,
      digest: await passwordDigest(newPassword, salt, env.AUTH_PEPPER),
    },
    credential_version: Number(current.user.credential_version || 0) + 1,
    must_change: false,
    updated_at: new Date().toISOString(),
  };
  await writeJsonObject(env.WIKI_AUTH, USER_KEYS[current.session.role], updatedUser);
  await env.WIKI_AUTH.delete(current.key);
  const created = await createSession(env, current.session.role, updatedUser);
  return json(publicSession({ session: created.session, user: updatedUser }), 200, {
    "set-cookie": sessionCookie(created.token, created.ttl),
  });
}

function requiredRole(pathname) {
  if (pathname === "/access/planner" || pathname.startsWith("/access/planner/")) return "planner";
  if (pathname === "/access/developer" || pathname.startsWith("/access/developer/")) return "developer";
  if (pathname === "/access/account" || pathname.startsWith("/access/account/")) return "authenticated";
  if (isPublicPath(pathname)) return null;
  return "authenticated";
}

function isPublicPath(pathname) {
  if (pathname === "/" || pathname === "/index.html") return true;
  if (pathname === "/access/login" || pathname.startsWith("/access/login/")) return true;
  if (pathname.startsWith("/assets/") && /\.(?:css|js|woff2?|ttf|png|jpe?g|webp|svg|gif|ico|map)$/iu.test(pathname)) return true;
  if (pathname.startsWith("/stylesheets/") || pathname.startsWith("/javascripts/")) return true;
  if (pathname === "/favicon.ico" || pathname === "/manifest.webmanifest") return true;
  return false;
}

function decodedPathname(url) {
  try {
    return decodeURIComponent(url.pathname).replace(/\/{2,}/gu, "/");
  } catch {
    return url.pathname.replace(/\/{2,}/gu, "/");
  }
}

function loginRedirect(request) {
  const url = new URL(request.url);
  const destination = `${url.pathname}${url.search}`;
  const location = `/access/login/?return=${encodeURIComponent(destination)}`;
  return new Response(null, { status: 302, headers: { location, "cache-control": "no-store" } });
}

async function publicSurfaceResponse(request, env) {
  const response = await env.ASSETS.fetch(request);
  const contentType = response.headers.get("content-type") || "";
  if (!contentType.includes("text/html") || typeof HTMLRewriter === "undefined") return response;
  const remove = { element(element) { element.remove(); } };
  return new HTMLRewriter()
    .on('[data-md-component="search"]', remove)
    .on('[data-md-component="sidebar"]', remove)
    .on('label.md-header__button[for="__drawer"]', remove)
    .transform(response);
}

async function handleApi(request, env) {
  const pathname = decodedPathname(new URL(request.url));
  try {
    if (pathname === "/api/auth/login" && request.method === "POST") return await handleLogin(request, env);
    if (pathname === "/api/auth/session" && request.method === "GET") {
      return json(publicSession(await getSession(request, env)));
    }
    if (pathname === "/api/auth/logout" && request.method === "POST") return await handleLogout(request, env);
    if (pathname === "/api/auth/credentials" && request.method === "POST") {
      return await handleCredentialChange(request, env);
    }
    return json({ error: "지원하지 않는 요청입니다." }, 404);
  } catch (error) {
    const known = new Set(["body_too_large", "invalid_content_type", "cross_origin"]);
    return json({ error: known.has(error.message) ? "요청 형식이 올바르지 않습니다." : "인증 처리 중 오류가 발생했습니다." }, 400);
  }
}

async function handleRequest(request, env) {
  const url = new URL(request.url);
  const pathname = decodedPathname(url);
  if (pathname.startsWith("/api/auth/")) {
    return withSecurityHeaders(await handleApi(request, env), true);
  }

  const role = requiredRole(pathname);
  if (role) {
    const current = await getSession(request, env);
    if (!current) return withSecurityHeaders(loginRedirect(request), true);
    if (role !== "authenticated" && current.session.role !== role) {
      return withSecurityHeaders(json({ error: "이 역할에서는 열 수 없는 문서입니다." }, 403), true);
    }
    if (current.user.must_change && role !== "authenticated") {
      return withSecurityHeaders(new Response(null, {
        status: 302,
        headers: { location: "/access/account/?required=1", "cache-control": "no-store" },
      }), true);
    }
    return withSecurityHeaders(await env.ASSETS.fetch(request), true);
  }

  if (pathname === "/" || pathname === "/index.html" || pathname === "/access/login" || pathname.startsWith("/access/login/")) {
    return withSecurityHeaders(await publicSurfaceResponse(request, env));
  }
  return withSecurityHeaders(await env.ASSETS.fetch(request));
}

export default {
  async fetch(request, env) {
    if (!env.WIKI_AUTH || !env.AUTH_PEPPER) {
      const url = new URL(request.url);
      const pathname = decodedPathname(url);
      if (pathname.startsWith("/api/auth/") || requiredRole(pathname)) {
        return withSecurityHeaders(json({ error: "인증 저장소가 아직 연결되지 않았습니다." }, 503), true);
      }
      if (pathname === "/" || pathname === "/index.html" || pathname === "/access/login" || pathname.startsWith("/access/login/")) {
        return withSecurityHeaders(await publicSurfaceResponse(request, env));
      }
      return withSecurityHeaders(await env.ASSETS.fetch(request));
    }
    return handleRequest(request, env);
  },
};

export const __test = {
  passwordDigest,
  randomToken,
  requiredRole,
  isPublicPath,
  publicSurfaceResponse,
  PBKDF2_ITERATIONS,
  MAX_PBKDF2_ITERATIONS,
};
