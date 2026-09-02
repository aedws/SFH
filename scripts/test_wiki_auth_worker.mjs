import assert from "node:assert/strict";
import worker, { __test } from "../cloudflare/wiki-auth/_worker.js";

class MemoryBody {
  constructor(value) {
    this.value = value;
  }

  async json() {
    return JSON.parse(this.value);
  }
}

class MemoryR2 {
  constructor() {
    this.values = new Map();
  }

  async get(key) {
    const value = this.values.get(key);
    return value === undefined ? null : new MemoryBody(value);
  }

  async put(key, value) {
    this.values.set(key, String(value));
  }

  async delete(key) {
    this.values.delete(key);
  }
}

const pepper = "test-only-pepper-that-is-at-least-thirty-two-characters";
const plannerPassword = "Planner-Initial-47Qx";
const developerPassword = "Developer-Initial-82Vz";

async function userRecord(role, username, password) {
  const salt = __test.randomToken(18);
  return {
    schema: 1,
    role,
    username,
    password: {
      algorithm: "PBKDF2-SHA256",
      iterations: __test.PBKDF2_ITERATIONS,
      salt,
      digest: await __test.passwordDigest(password, salt, pepper),
    },
    credential_version: 1,
    must_change: true,
  };
}

const store = new MemoryR2();
await store.put("users/planner.json", JSON.stringify(await userRecord("planner", "sfh-planner", plannerPassword)));
await store.put("users/developer.json", JSON.stringify(await userRecord("developer", "sfh-developer", developerPassword)));

const env = {
  WIKI_AUTH: store,
  AUTH_PEPPER: pepper,
  SESSION_TTL_SECONDS: "28800",
  ASSETS: {
    async fetch(request) {
      return new Response(`asset:${new URL(request.url).pathname}`, { status: 200 });
    },
  },
};

function request(path, options = {}) {
  return new Request(`https://sfh-dev-wiki.pages.dev${path}`, options);
}

function cookieFrom(response) {
  return response.headers.get("set-cookie").split(";", 1)[0];
}

let response = await worker.fetch(request("/"), env);
assert.equal(response.status, 200);
assert.equal(await response.text(), "asset:/");

response = await worker.fetch(request("/access/planner/"), env);
assert.equal(response.status, 302);
assert.match(response.headers.get("location"), /^\/access\/login\//u);

response = await worker.fetch(request("/%61ccess//planner/index.html"), env);
assert.equal(response.status, 302, "encoded and repeated slashes must not bypass protected routing");

response = await worker.fetch(request("/api/auth/login", {
  method: "POST",
  headers: { "content-type": "application/json", origin: "https://sfh-dev-wiki.pages.dev" },
  body: JSON.stringify({ role: "planner", username: "sfh-planner", password: plannerPassword }),
}), env);
assert.equal(response.status, 200);
let session = await response.json();
assert.equal(session.role, "planner");
assert.equal(session.must_change, true);
let plannerCookie = cookieFrom(response);

response = await worker.fetch(request("/access/planner/", { headers: { cookie: plannerCookie } }), env);
assert.equal(response.status, 302);
assert.equal(response.headers.get("location"), "/access/account/?required=1");

response = await worker.fetch(request("/access/account/", { headers: { cookie: plannerCookie } }), env);
assert.equal(response.status, 200);
assert.equal(response.headers.get("cache-control"), "private, no-store, max-age=0");

response = await worker.fetch(request("/api/auth/credentials", {
  method: "POST",
  headers: {
    "content-type": "application/json",
    origin: "https://sfh-dev-wiki.pages.dev",
    cookie: plannerCookie,
    "x-csrf-token": session.csrf,
  },
  body: JSON.stringify({
    current_password: plannerPassword,
    new_username: "planner-owner",
    new_password: "Changed-Planner-Password-95!",
  }),
}), env);
assert.equal(response.status, 200);
session = await response.json();
assert.equal(session.username, "planner-owner");
assert.equal(session.must_change, false);
plannerCookie = cookieFrom(response);

response = await worker.fetch(request("/access/planner/", { headers: { cookie: plannerCookie } }), env);
assert.equal(response.status, 200);
assert.equal(await response.text(), "asset:/access/planner/");

response = await worker.fetch(request("/access/developer/", { headers: { cookie: plannerCookie } }), env);
assert.equal(response.status, 403);

response = await worker.fetch(request("/api/auth/login", {
  method: "POST",
  headers: { "content-type": "application/json", origin: "https://sfh-dev-wiki.pages.dev" },
  body: JSON.stringify({ role: "planner", username: "sfh-planner", password: plannerPassword }),
}), env);
assert.equal(response.status, 401);

response = await worker.fetch(request("/api/auth/login", {
  method: "POST",
  headers: { "content-type": "application/json", origin: "https://sfh-dev-wiki.pages.dev" },
  body: JSON.stringify({ role: "developer", username: "sfh-developer", password: developerPassword }),
}), env);
assert.equal(response.status, 200);
const developerSession = await response.json();
const developerCookie = cookieFrom(response);
assert.equal(developerSession.role, "developer");

response = await worker.fetch(request("/access/planner/", { headers: { cookie: developerCookie } }), env);
assert.equal(response.status, 403);

response = await worker.fetch(request("/api/auth/logout", {
  method: "POST",
  headers: {
    origin: "https://sfh-dev-wiki.pages.dev",
    cookie: plannerCookie,
    "x-csrf-token": session.csrf,
  },
}), env);
assert.equal(response.status, 200);
assert.match(response.headers.get("set-cookie"), /Max-Age=0/u);

response = await worker.fetch(request("/api/auth/session", {
  headers: { cookie: plannerCookie },
}), env);
assert.deepEqual(await response.json(), { authenticated: false });

console.log("WIKI_ROLE_AUTH_E2E_OK");
