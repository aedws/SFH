import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../', import.meta.url));
const catalog = JSON.parse(readFileSync(resolve(root, 'docs/assets/dps-catalog.json'), 'utf8'));
assert.equal(catalog.schema, 1);
const files = [...catalog.source_files];
function collect(dir) {
  for (const entry of readdirSync(resolve(root,dir), {withFileTypes:true})) {
    const path = `${dir}/${entry.name}`;
    if (entry.isDirectory()) collect(path);
    else if (/\.(gd|tres|tscn|csv)$/.test(path)) files.push(path);
  }
}
catalog.source_roots.forEach(collect);
assert.deepEqual(files.sort(), Object.keys(catalog.sources).sort(), 'DPS source topology changed; regenerate catalog with Godot');
for (const path of files) {
  const hash = createHash('sha256').update(readFileSync(resolve(root,path),'utf8').replaceAll('\r\n','\n')).digest('hex');
  assert.equal(hash,catalog.sources[path], `Stale DPS catalog: ${path}. Run scripts/export_dps_catalog.gd`);
}
assert.ok(catalog.weapons.length && catalog.skills.length);
assert.equal(new Set(catalog.weapons.map(w=>w.id)).size,catalog.weapons.length);
assert.equal(new Set(catalog.skills.map(s=>s.skill_id)).size,catalog.skills.length);
assert.ok(catalog.skills.every(s=>['path','field','utility','pattern'].includes(s.kind)));
assert.ok(catalog.skills.length >= 40);
console.log(`DPS source freshness PASS (${files.length} files)`);
