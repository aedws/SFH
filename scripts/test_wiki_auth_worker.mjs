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
const initialPassword = "0000";
const changedPassword = "9573";
const tamperedPlannerId = "planner-owner";
assert.equal(__test.PBKDF2_ITERATIONS, 100000, "PBKDF2 must stay within the Cloudflare workerd limit");
assert.equal(__test.MAX_PBKDF2_ITERATIONS, 100000);

async function userRecord(role, username, password) {
  const salt = __test.randomToken(18);
  return {
    schema: 2,
    bootstrap_revision: 3,
    role,
    username,
    password: {
      algorithm: "PBKDF2-SHA256",
      iterations: __test.PBKDF2_ITERATIONS,
      salt,
      digest: await __test.passwordDigest(password, salt, pepper),
    },
    credential_version: 3,
    must_change: false,
  };
}

const store = new MemoryR2();
await store.put("users/planner.json", JSON.stringify(await userRecord("planner", "planner", initialPassword)));
await store.put("users/developer.json", JSON.stringify(await userRecord("developer", "developer", initialPassword)));

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

const incompatibleStore = new MemoryR2();
const incompatibleRecord = await userRecord("planner", "planner", initialPassword);
incompatibleRecord.password.iterations = __test.MAX_PBKDF2_ITERATIONS + 1;
await incompatibleStore.put("users/planner.json", JSON.stringify(incompatibleRecord));
const incompatibleEnv = { ...env, WIKI_AUTH: incompatibleStore };
let incompatibleResponse = await worker.fetch(request("/api/auth/login", {
  method: "POST",
  headers: { "content-type": "application/json", origin: "https://sfh-dev-wiki.pages.dev" },
  body: JSON.stringify({ role: "planner", username: "planner", password: initialPassword }),
}), incompatibleEnv);
assert.equal(incompatibleResponse.status, 401, "out-of-range PBKDF2 records must fail without a runtime exception");

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
  body: JSON.stringify({ role: "planner", username: "planner", password: initialPassword }),
}), env);
assert.equal(response.status, 200);
let session = await response.json();
assert.equal(session.role, "planner");
assert.equal(session.username, "planner");
assert.equal(session.must_change, false);
let plannerCookie = cookieFrom(response);

response = await worker.fetch(request("/access/planner/", { headers: { cookie: plannerCookie } }), env);
assert.equal(response.status, 200);
assert.equal(await response.text(), "asset:/access/planner/");

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
    current_password: initialPassword,
    new_username: tamperedPlannerId,
    new_password: changedPassword,
  }),
}), env);
assert.equal(response.status, 200);
session = await response.json();
assert.equal(session.username, "planner", "role username must remain fixed even if a client tampers with new_username");
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
  body: JSON.stringify({ role: "planner", username: "planner", password: initialPassword }),
}), env);
assert.equal(response.status, 401);

response = await worker.fetch(request("/api/auth/login", {
  method: "POST",
  headers: { "content-type": "application/json", origin: "https://sfh-dev-wiki.pages.dev" },
  body: JSON.stringify({ role: "planner", username: tamperedPlannerId, password: changedPassword }),
}), env);
assert.equal(response.status, 401, "planner ID must remain fixed");

response = await worker.fetch(request("/api/auth/login", {
  method: "POST",
  headers: { "content-type": "application/json", origin: "https://sfh-dev-wiki.pages.dev" },
  body: JSON.stringify({ role: "planner", username: "planner", password: changedPassword }),
}), env);
assert.equal(response.status, 200, "changed password must work with the fixed planner ID");

response = await worker.fetch(request("/api/auth/login", {
  method: "POST",
  headers: { "content-type": "application/json", origin: "https://sfh-dev-wiki.pages.dev" },
  body: JSON.stringify({ role: "developer", username: "developer", password: initialPassword }),
}), env);
assert.equal(response.status, 200);
const developerSession = await response.json();
const developerCookie = cookieFrom(response);
assert.equal(developerSession.role, "developer");
assert.equal(developerSession.username, "developer");

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
