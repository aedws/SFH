import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
await import('../docs/javascripts/dps-loadout.js');
await import('../docs/javascripts/dps-engine.js');
const E=globalThis.SFHDps, catalog=JSON.parse(readFileSync(new URL('../docs/assets/dps-catalog.json',import.meta.url)));
const near=(a,b)=>assert.ok(Math.abs(a-b)<1e-6, `${a} != ${b}`);
let i=E.defaults(catalog,'assault_rifle','magnetic_field');
let x=E.resolve(catalog,i);
near(x.cycle,.98); near(x.hit,1.6*1.06*1.0375); near(x.perCast,66); assert.equal(x.ticks,10);
i={...i,damage:0,innate:false,crit:0,horizon:5};
let s=E.simulate(catalog,i); near(s.skillDamage,66); assert.equal(s.casts,1);
near(s.points[0].skill,6.6); // Immediate first tick, no extra tick at duration.
i={...E.defaults(catalog,'service_pistol','magnetic_field'),horizon:10};
s=E.simulate(catalog,i); assert.equal(s.casts,0); assert.equal(s.skillDamage,0); assert.equal(s.resolved.allowed,false);
assert.equal(E.simulate(catalog,E.defaults(catalog,'assault_rifle','speed_boost')).skillDamage,0);
i={...E.defaults(catalog,'service_pistol'),damage:10,interval:1,crit:0,innate:false,horizon:5,hp:15,armor:10};
s=E.simulate(catalog,i); near(s.total,60); near(s.ttk,2); near(s.points[0].armor,0); near(s.points[0].hp,15);
assert.equal(E.simulate(catalog,{...i,hp:5,armor:0}).ttk,0);
assert.equal(E.simulate(catalog,{...i,hitRate:0}).ttk,null);
assert.equal(E.simulate(catalog,{...i,hp:1000}).ttk,null);
i={...E.defaults(catalog,'service_pistol','blink'),damage:0,innate:false,energy:0,regen:0,horizon:20};
assert.equal(E.simulate(catalog,i).casts,0);
assert.equal(E.simulate(catalog,{...i,resourceLimits:false}).casts,5);
assert.equal(E.simulate(catalog,{...i,energy:100,regen:0,skillCost:0,charges:1,recharge:7,skillCooldown:1}).casts,3);
near(E.resolve(catalog,{...i,shock:true}).skillDamage,12*1.15+8);
for (const bad of [NaN,Infinity,-1]) assert.throws(()=>E.simulate(catalog,{...i,hp:bad}));
assert.throws(()=>E.simulate(catalog,{...i,horizon:1.005}));
assert.throws(()=>E.simulate(catalog,{...i,energy:101}));
assert.throws(()=>E.defaults(catalog,'missing'));
const saved=JSON.stringify(catalog);
for(const w of catalog.weapons) for(const skill of ['',...catalog.skills.map(s=>s.skill_id)]) {
  const result=E.simulate(catalog,E.defaults(catalog,w.id,skill));
  assert.ok(Number.isFinite(result.dps));
  assert.ok(result.points.every((p,j,a)=>!j || p.total>=a[j-1].total));
}
assert.equal(JSON.stringify(catalog),saved,'Source must remain immutable');
console.log('DPS engine PASS: burst, crit, field ticks, tags, armor pool, AP, serial charges, zero/invalid inputs, all catalog combinations');
