import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import '../docs/javascripts/dps-loadout.js';
import '../docs/javascripts/dps-engine.js';
import '../docs/javascripts/balance-engine.js';
const catalog=JSON.parse(await readFile('docs/assets/dps-catalog.json','utf8')),E=globalThis.SFHDps;
for(const f of catalog.distance_fixtures){const w=catalog.weapons.find(w=>w.id===f.weapon);assert.ok(Math.abs(E.distanceMultiplier(E.distanceCurve(w.balance.distance_damage_curve),f.ratio*w.balance.target_range_px,w.balance.target_range_px)-f.multiplier)<1e-6);}
for(const bad of ['', '0:1', '0:1;0:2;1:1', '0:1;1:4', '0:nan;1:1', '0:1;0.9:1','0:1;;1:1'])assert.throws(()=>E.distanceCurve(bad));
const i=E.defaults(catalog,'pulse_rifle');const near=E.resolve(catalog,i),mid=E.resolve(catalog,{...i,distancePx:380});assert.ok(Math.abs(mid.hit/near.hit-1.25)<1e-8);
const unreachable=E.simulate(catalog,{...i,distancePx:100000});assert.equal(unreachable.weaponDamage,0);assert.equal(unreachable.procs,0);
const graph=SFHBalance.calculate('distance',catalog,{...i,distanceCurve:'0:1;1:0.2'});assert.equal(graph.points.length,101);assert.ok(graph.points.at(-1).value<graph.points.at(-1).base);
const without=E.resolve(catalog,{...i,innate:false,distancePx:380});assert.ok(Math.abs(mid.sustainedWeapon-without.sustainedWeapon-(near.sustainedWeapon-E.resolve(catalog,{...i,innate:false}).sustainedWeapon))<1e-8,'fixed innate must not scale with distance');
console.log(`WEAPON_DISTANCE_JS_OK ${catalog.distance_fixtures.length} Godot fixtures / range / immutable innate / graph`);
