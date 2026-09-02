import assert from "node:assert/strict";

const origin = (process.argv[2] || "").replace(/\/$/u, "");
if (!origin) throw new Error("Usage: node scripts/test_wiki_auth_deployment.mjs <origin>");

async function request(path, options = {}) {
  return fetch(`${origin}${path}`, { redirect: "manual", ...options });
}

let response = await request("/");
assert.equal(response.status, 200, "public wiki must remain available");

response = await request("/api/auth/session");
assert.equal(response.status, 200, "auth binding and server secret must be ready");
assert.deepEqual(await response.json(), { authenticated: false });

response = await request("/access/planner/");
assert.equal(response.status, 302, "protected planner HTML must redirect before login");
assert.match(response.headers.get("location") || "", /^\/access\/login\//u);
assert.equal(await response.text(), "", "protected HTML must not leak in the redirect body");

response = await request("/access/developer/");
assert.equal(response.status, 302, "protected developer HTML must redirect before login");

const allowMutation = process.env.SFH_WIKI_AUTH_E2E_ALLOW_MUTATION === "1";
if (allowMutation) {
  const url = new URL(origin);
  if (!(url.hostname === "127.0.0.1" || url.hostname === "localhost")) {
    throw new Error("Credential mutation E2E is restricted to a local Pages runtime.");
  }
  const currentPassword = process.env.SFH_WIKI_AUTH_E2E_PASSWORD;
  if (!currentPassword) throw new Error("SFH_WIKI_AUTH_E2E_PASSWORD is required for local mutation E2E.");

  response = await request("/api/auth/login", {
    method: "POST",
    headers: { "content-type": "application/json", origin },
    body: JSON.stringify({ role: "planner", username: "sfh-planner", password: currentPassword }),
  });
  assert.equal(response.status, 200);
  const session = await response.json();
  const cookie = (response.headers.get("set-cookie") || "").split(";", 1)[0];
  assert.equal(session.must_change, true);

  response = await request("/access/planner/", { headers: { cookie } });
  assert.equal(response.status, 302);
  assert.equal(response.headers.get("location"), "/access/account/?required=1");

  response = await request("/api/auth/credentials", {
    method: "POST",
    headers: { "content-type": "application/json", origin, cookie, "x-csrf-token": session.csrf },
    body: JSON.stringify({
      current_password: currentPassword,
      new_username: "local-planner",
      new_password: "Changed-Local-Planner-95!",
    }),
  });
  assert.equal(response.status, 200);
  const changed = await response.json();
  const changedCookie = (response.headers.get("set-cookie") || "").split(";", 1)[0];
  assert.equal(changed.must_change, false);

  response = await request("/access/planner/", { headers: { cookie: changedCookie } });
  assert.equal(response.status, 200);
  assert.match(await response.text(), /기획자 전용 작업 탭/u);

  response = await request("/access/developer/", { headers: { cookie: changedCookie } });
  assert.equal(response.status, 403);
}

console.log(`WIKI_AUTH_DEPLOYMENT_E2E_OK origin=${origin} mutation=${allowMutation}`);
