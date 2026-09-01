const CONTENT_TYPES = new Map([
  [".html", "text/html; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".wasm", "application/wasm"],
  [".pck", "application/octet-stream"],
  [".png", "image/png"],
  [".svg", "image/svg+xml"],
  [".ico", "image/x-icon"],
  [".zip", "application/zip"],
  [".sha256", "text/plain; charset=utf-8"],
]);

function jsonResponse(payload, status = 200) {
  return new Response(`${JSON.stringify(payload)}\n`, {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
    },
  });
}

function normalizePath(pathname) {
  let decoded;
  try {
    decoded = decodeURIComponent(pathname);
  } catch {
    return null;
  }
  const stripped = decoded.replace(/^\/+/, "");
  if (stripped.split("/").some((part) => part === ".." || part === ".")) {
    return null;
  }
  return stripped;
}

function contentTypeFor(key) {
  const dot = key.lastIndexOf(".");
  return CONTENT_TYPES.get(dot >= 0 ? key.slice(dot).toLowerCase() : "") ?? "application/octet-stream";
}

function gameHeaders(headers, key) {
  headers.set("x-sfh-surface", "gameplay");
  headers.set("cross-origin-opener-policy", "same-origin");
  headers.set("cross-origin-embedder-policy", "require-corp");
  headers.set("cross-origin-resource-policy", "same-origin");
  headers.set("referrer-policy", "no-referrer");
  headers.set("x-content-type-options", "nosniff");
  headers.set("content-type", headers.get("content-type") || contentTypeFor(key));
  headers.set(
    "cache-control",
    key.endsWith(".html") ? "no-cache" : "public, max-age=300, must-revalidate",
  );
}

function downloadHeaders(headers, key) {
  headers.set("x-sfh-surface", "windows-download");
  headers.set("x-content-type-options", "nosniff");
  headers.set("content-type", headers.get("content-type") || contentTypeFor(key));
  headers.set("cache-control", "public, max-age=31536000, immutable");
  if (key.endsWith(".zip")) {
    headers.set("content-disposition", `attachment; filename="${key.split("/").at(-1)}"`);
  }
}

function addObjectMetadata(headers, object) {
  if (typeof object.writeHttpMetadata === "function") {
    object.writeHttpMetadata(headers);
  }
  if (object.httpEtag) {
    headers.set("etag", object.httpEtag);
  }
}

function applyRangeHeaders(headers, object) {
  if (!object.range || typeof object.range.offset !== "number") {
    return false;
  }
  const length = object.range.length;
  const end = object.range.offset + length - 1;
  headers.set("content-range", `bytes ${object.range.offset}-${end}/${object.size}`);
  headers.set("content-length", String(length));
  headers.set("accept-ranges", "bytes");
  return true;
}

export default {
  async fetch(request, env) {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return jsonResponse({ error: "method_not_allowed" }, 405);
    }

    const url = new URL(request.url);
    if (url.pathname === "/healthz" || url.pathname === "/release.json") {
      return jsonResponse({
        status: "ok",
        service: "sfh-game",
        release_version: env.RELEASE_VERSION,
        build_commit: env.BUILD_COMMIT,
        release_prefix: env.RELEASE_PREFIX,
        download_prefix: env.DOWNLOAD_PREFIX || "downloads",
        public_surface: "gameplay",
        storage_access: "private_worker_binding",
      });
    }

    let path = normalizePath(url.pathname);
    if (path === null) {
      return jsonResponse({ error: "invalid_path" }, 400);
    }
    if (path === "" || path === "play" || path === "play/") {
      path = "index.html";
    } else if (path.startsWith("play/")) {
      path = path.slice("play/".length);
    }

    const downloadPrefix = `${env.DOWNLOAD_PREFIX || "downloads"}/`;
    const isDownload = path.startsWith(downloadPrefix);
    const key = isDownload ? path : `${env.RELEASE_PREFIX}/${path}`;
    const rangeRequested = request.headers.has("range");
    const object = request.method === "HEAD"
      ? await env.ASSETS.head(key)
      : await env.ASSETS.get(key, rangeRequested ? { range: request.headers } : undefined);
    if (object === null) {
      return jsonResponse({ error: "not_found", path: url.pathname }, 404);
    }

    const headers = new Headers();
    addObjectMetadata(headers, object);
    if (isDownload) {
      downloadHeaders(headers, key);
    } else {
      gameHeaders(headers, key);
    }
    const partial = applyRangeHeaders(headers, object);
    const body = request.method === "HEAD" ? null : object.body;
    return new Response(body, { status: partial ? 206 : 200, headers });
  },
};
