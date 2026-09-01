import assert from "node:assert/strict";
import worker from "../cloudflare/worker/src/index.mjs";

class FakeObject {
  constructor(key, body, range = null, size = body.byteLength) {
    this.key = key;
    this.body = body;
    this.size = size;
    this.range = range;
    this.httpEtag = `"${key}"`;
  }

  writeHttpMetadata(headers) {
    headers.set("content-type", this.key.endsWith(".wasm") ? "application/wasm" : "text/html; charset=utf-8");
  }
}

class FakeBucket {
  constructor() {
    this.lastKey = "";
  }

  async get(key, options) {
    this.lastKey = key;
    if (key.includes("missing")) return null;
    const body = new TextEncoder().encode("0123456789abcdef");
    if (options?.range) {
      return new FakeObject(key, body.slice(0, 4), { offset: 0, length: 4 }, body.byteLength);
    }
    return new FakeObject(key, body);
  }

  async head(key) {
    this.lastKey = key;
    if (key.includes("missing")) return null;
    return new FakeObject(key, new Uint8Array(16));
  }
}

const bucket = new FakeBucket();
const env = {
  ASSETS: bucket,
  RELEASE_PREFIX: "game/releases/test-commit",
  RELEASE_VERSION: "v0.1.0",
  BUILD_COMMIT: "test-commit",
};

let response = await worker.fetch(new Request("https://sfh-game.example/"), env);
assert.equal(response.status, 200);
assert.equal(bucket.lastKey, "game/releases/test-commit/index.html");
assert.equal(response.headers.get("cross-origin-opener-policy"), "same-origin");
assert.equal(response.headers.get("cross-origin-embedder-policy"), "require-corp");

response = await worker.fetch(
  new Request("https://sfh-game.example/index.wasm", { headers: { range: "bytes=0-3" } }),
  env,
);
assert.equal(response.status, 206);
assert.equal(response.headers.get("content-range"), "bytes 0-3/16");

response = await worker.fetch(
  new Request("https://sfh-game.example/downloads/v0.1.0/SFH-Windows-x64-v0.1.0.zip"),
  env,
);
assert.equal(bucket.lastKey, "downloads/v0.1.0/SFH-Windows-x64-v0.1.0.zip");
assert.match(response.headers.get("content-disposition"), /attachment/);

response = await worker.fetch(new Request("https://sfh-game.example/healthz"), env);
assert.equal(response.status, 200);
assert.equal((await response.json()).build_commit, "test-commit");

response = await worker.fetch(new Request("https://sfh-game.example/missing.wasm"), env);
assert.equal(response.status, 404);

response = await worker.fetch(new Request("https://sfh-game.example/%2e%2e%2fsecret"), env);
assert.equal(response.status, 400);

console.log("CLOUDFLARE_WORKER_OK routing range headers downloads health traversal");
