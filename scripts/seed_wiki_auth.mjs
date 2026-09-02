import { mkdir, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { webcrypto } from "node:crypto";

globalThis.crypto ??= webcrypto;

const encoder = new TextEncoder();
const ITERATIONS = 210000;

function base64Url(bytes) {
  return Buffer.from(bytes).toString("base64url");
}

function randomToken(byteLength = 18) {
  const bytes = new Uint8Array(byteLength);
  crypto.getRandomValues(bytes);
  return base64Url(bytes);
}

async function passwordDigest(password, salt, pepper) {
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
      salt: Buffer.from(salt, "base64url"),
      iterations: ITERATIONS,
    },
    material,
    256,
  );
  return base64Url(new Uint8Array(bits));
}

async function pepperFingerprint(pepper) {
  const digest = await crypto.subtle.digest("SHA-256", encoder.encode(`sfh-wiki-auth-pepper-v1\u0000${pepper}`));
  return base64Url(new Uint8Array(digest));
}

async function createRecord(role, username, password, pepper) {
  const salt = randomToken();
  return {
    schema: 1,
    role,
    username,
    password: {
      algorithm: "PBKDF2-SHA256",
      iterations: ITERATIONS,
      salt,
      digest: await passwordDigest(password, salt, pepper),
    },
    credential_version: 1,
    must_change: true,
    updated_at: new Date().toISOString(),
  };
}

const outputIndex = process.argv.indexOf("--output");
if (outputIndex < 0 || !process.argv[outputIndex + 1]) {
  throw new Error("Usage: node scripts/seed_wiki_auth.mjs --output <directory>");
}

const pepper = process.env.SFH_WIKI_AUTH_PEPPER;
const plannerPassword = process.env.SFH_WIKI_PLANNER_INITIAL_PASSWORD;
const developerPassword = process.env.SFH_WIKI_DEVELOPER_INITIAL_PASSWORD;
if (!pepper || pepper.length < 32 || !plannerPassword || !developerPassword) {
  throw new Error("Wiki auth seed secrets are missing or too short.");
}

const outputDirectory = resolve(process.argv[outputIndex + 1]);
await mkdir(outputDirectory, { recursive: true });
const records = {
  planner: await createRecord("planner", "sfh-planner", plannerPassword, pepper),
  developer: await createRecord("developer", "sfh-developer", developerPassword, pepper),
};

for (const [role, record] of Object.entries(records)) {
  await writeFile(resolve(outputDirectory, `${role}.json`), JSON.stringify(record), { mode: 0o600 });
}
await writeFile(resolve(outputDirectory, "pepper.json"), JSON.stringify({
  schema: 1,
  fingerprint: await pepperFingerprint(pepper),
}), { mode: 0o600 });

process.stdout.write("WIKI_AUTH_SEED_RECORDS_READY\n");
