import assert from "node:assert/strict";

const origin = (process.argv[2] || "").replace(/\/$/u, "");
if (!origin) throw new Error("Usage: node scripts/test_wiki_auth_deployment.mjs <origin>");

async function request(path, options = {}) {
  return fetch(`${origin}${path}`, { redirect: "manual", ...options });
}

let response = await request("/");
assert.equal(response.status, 200, "public wiki must remain available");
const publicHome = await response.text();
assert.match(publicHome, /PUBLIC PLAYTEST/u, "public home must be the promotional playtest surface");
assert.doesNotMatch(publicHome, /개발 현황과 업데이트/u, "public home HTML must not expose internal navigation");
assert.doesNotMatch(publicHome, /data-md-component="search"/u, "public home HTML must not expose protected search UI");

response = await request("/access/login/");
assert.equal(response.status, 200, "login page must remain public");
const publicLogin = await response.text();
assert.match(publicLogin, /ROLE ACCESS GATE/u);
assert.doesNotMatch(publicLogin, /개발 현황과 업데이트/u, "login HTML must not expose internal navigation");

response = await request("/api/auth/session");
assert.equal(response.status, 200, "auth binding and server secret must be ready");
assert.deepEqual(await response.json(), { authenticated: false });

response = await request("/access/planner/");
assert.equal(response.status, 302, "protected planner HTML must redirect before login");
assert.match(response.headers.get("location") || "", /^\/access\/login\//u);
assert.equal(await response.text(), "", "protected HTML must not leak in the redirect body");

response = await request("/access/developer/");
assert.equal(response.status, 302, "protected developer HTML must redirect before login");

for (const protectedPath of [
  "/development-status/",
  "/features/game-loop/",
  "/search/search_index.json",
  "/assets/knowledge-map.json",
  "/assets/search-priorities.json",
  "/sitemap.xml",
  "/404.html",
]) {
  response = await request(protectedPath);
  assert.equal(response.status, 302, `${protectedPath} must not be public`);
  assert.equal(await response.text(), "", `${protectedPath} must not leak content`);
}

for (const publicPath of ["/access/login/", "/stylesheets/extra.css", "/javascripts/role-auth.js"]) {
  response = await request(publicPath);
  assert.equal(response.status, 200, `${publicPath} must support the public landing page`);
}

const bootstrapRoles = (process.env.SFH_WIKI_AUTH_E2E_BOOTSTRAP_ROLES || "")
  .split(",")
  .map((role) => role.trim())
  .filter(Boolean);
const bootstrapPassword = ["00", "00"].join("");
for (const role of bootstrapRoles) {
  assert.ok(["planner", "developer"].includes(role), `unsupported bootstrap role: ${role}`);
  response = await request("/api/auth/login", {
    method: "POST",
    headers: { "content-type": "application/json", origin },
    body: JSON.stringify({ role, username: role, password: bootstrapPassword }),
  });
  assert.equal(response.status, 200, `${role} bootstrap login must work after migration`);
  const session = await response.json();
  const cookie = (response.headers.get("set-cookie") || "").split(";", 1)[0];
  assert.equal(session.username, role);

  response = await request(`/access/${role}/`, { headers: { cookie } });
  assert.equal(response.status, 200, `${role} must open its protected page`);
  response = await request("/development-status/", { headers: { cookie } });
  assert.equal(response.status, 200, `${role} must read shared internal documents`);
  const otherRole = role === "planner" ? "developer" : "planner";
  response = await request(`/access/${otherRole}/`, { headers: { cookie } });
  assert.equal(response.status, 403, `${role} must not open the other role page`);

  response = await request("/api/auth/logout", {
    method: "POST",
    headers: { origin, cookie, "x-csrf-token": session.csrf },
  });
  assert.equal(response.status, 200, `${role} bootstrap verification must clean up its session`);
  console.log(`WIKI_AUTH_BOOTSTRAP_LOGIN_OK role=${role}`);
}

const allowMutation = process.env.SFH_WIKI_AUTH_E2E_ALLOW_MUTATION === "1";
if (allowMutation) {
  const url = new URL(origin);
  if (!(url.hostname === "127.0.0.1" || url.hostname === "localhost")) {
    throw new Error("Credential mutation E2E is restricted to a local Pages runtime.");
  }
  const currentPassword = process.env.SFH_WIKI_AUTH_E2E_PASSWORD || "0000";
  const changedPassword = "9573";
  const tamperedPlannerId = "tampered-planner-id";

  response = await request("/api/auth/login", {
    method: "POST",
    headers: { "content-type": "application/json", origin },
    body: JSON.stringify({ role: "planner", username: "planner", password: currentPassword }),
  });
  assert.equal(response.status, 200);
  const session = await response.json();
  const cookie = (response.headers.get("set-cookie") || "").split(";", 1)[0];
  assert.equal(session.username, "planner");

  response = await request("/access/planner/", { headers: { cookie } });
  assert.equal(response.status, 200);

  response = await request("/api/auth/credentials", {
    method: "POST",
    headers: { "content-type": "application/json", origin, cookie, "x-csrf-token": session.csrf },
    body: JSON.stringify({
      current_password: currentPassword,
      new_username: tamperedPlannerId,
      new_password: changedPassword,
    }),
  });
  assert.equal(response.status, 200);
  const changed = await response.json();
  const changedCookie = (response.headers.get("set-cookie") || "").split(";", 1)[0];
  assert.equal(changed.username, "planner");
  assert.equal(changed.must_change, false);

  response = await request("/access/planner/", { headers: { cookie: changedCookie } });
  assert.equal(response.status, 200);
  assert.match(await response.text(), /기획자 작업실/u);

  response = await request("/access/developer/", { headers: { cookie: changedCookie } });
  assert.equal(response.status, 403);
}

console.log(`WIKI_AUTH_DEPLOYMENT_E2E_OK origin=${origin} mutation=${allowMutation}`);
