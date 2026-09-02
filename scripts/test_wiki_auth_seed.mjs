import { execFileSync } from "node:child_process";
import { pbkdf2Sync, webcrypto } from "node:crypto";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { resolve } from "node:path";

globalThis.crypto ??= webcrypto;

const pepper = "sfh-auth-seed-contract-test-pepper-2026";
const outputDirectory = await mkdtemp(resolve(tmpdir(), "sfh-wiki-auth-seed-"));

function decodeBase64Url(value) {
  return Buffer.from(value, "base64url");
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

try {
  execFileSync(process.execPath, ["scripts/seed_wiki_auth.mjs", "--output", outputDirectory], {
    cwd: resolve(import.meta.dirname, ".."),
    env: { ...process.env, SFH_WIKI_AUTH_PEPPER: pepper },
    stdio: "pipe",
  });

  const records = {};
  for (const role of ["planner", "developer"]) {
    records[role] = JSON.parse(await readFile(resolve(outputDirectory, `${role}.json`), "utf8"));
    const record = records[role];
    assert(record.schema === 2, `${role} schema must be 2`);
    assert(record.bootstrap_revision === 2, `${role} bootstrap revision must be 2`);
    assert(record.role === role && record.username === role, `${role} ID must be fixed to its role name`);
    assert(record.credential_version === 2 && record.must_change === false, `${role} bootstrap state is invalid`);
    assert(!Object.hasOwn(record, "plaintext_password"), `${role} record must not store plaintext`);

    const digest = pbkdf2Sync(
      Buffer.from(`0000\0${pepper}`, "utf8"),
      decodeBase64Url(record.password.salt),
      record.password.iterations,
      32,
      "sha256",
    ).toString("base64url");
    assert(digest === record.password.digest, `${role} bootstrap password digest is not 0000`);
  }

  assert(records.planner.password.salt !== records.developer.password.salt, "role accounts must use distinct salts");
  assert(records.planner.password.digest !== records.developer.password.digest, "role account digests must be distinct");
  process.stdout.write("WIKI_AUTH_SEED_CONTRACT_OK\n");
} finally {
  await rm(outputDirectory, { recursive: true, force: true });
}
