import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import '../docs/javascripts/dps-loadout.js';
import '../docs/javascripts/dps-engine.js';
const catalog=JSON.parse(readFileSync('docs/assets/dps-catalog.json','utf8')),E=SFHDps;
const near=(a,b,label)=>assert.ok(Number.isFinite(a)&&Math.abs(a-b)<1e-4,`${label}: ${a} != ${b}`);
assert.ok(catalog.loadout.fixtures.length>=80,'real Godot fixture coverage');
for(const fixture of catalog.loadout.fixtures){
  const input={...E.defaults(catalog,fixture.weaponId),loadout:fixture.input};
  const resolved=E.resolve(catalog,input);
  for(const [id,value]of Object.entries(fixture.player))near(resolved.loadout.player[id],value,`Godot Player ${fixture.weaponId} ${id}`);
  for(const [id,value]of Object.entries(fixture.weapon))near(resolved.loadout.weapon[id],value,`Godot Equipment ${id}`);
  for(const [id,value]of Object.entries(fixture.skill||{}))near(resolved.loadout.skill[id],value,`Godot armor skill ${id}`);
  near(resolved.hit/(1+input.crit*(input.critMultiplier-1)),fixture.shot.damage*resolved.distanceFactor,'Godot AutoWeapon damage with impact distance');
  near(resolved.gap,fixture.shot.fire_interval_sec,'Godot fire interval');
  assert.deepEqual(resolved.loadout.costs.map(c=>c.used).sort(),fixture.costs.sort(),'Godot module cost');
}
const fresh=()=>E.defaults(catalog,'assault_rifle','magnetic_field');
const setInput=(id,count)=>{const input=fresh();input.loadout.armor=catalog.loadout.armor.filter(a=>a.set_id===id).slice(0,count).map(a=>({id:a.id,...SFHLoadout.carrier()}));return input;};
const two=E.resolve(catalog,setInput('conduit',2)),four=E.resolve(catalog,setInput('conduit',4)),none=E.resolve(catalog,fresh());
near(two.skillCooldown,none.skillCooldown*.9,'two-piece skill cooldown');
near(two.skillDamage,none.skillDamage,'two-piece no damage bonus');
near(four.skillDamage,none.skillDamage*1.2,'four-piece skill damage');
near(E.resolve(catalog,setInput('strider',4)).gap,none.gap*.9,'four-piece weapon rhythm');
for(const id of ['combat_dagger','greatsword','arc_spear']){
  const input=E.defaults(catalog,id);const range=E.resolve(catalog,input).range;
  input.distancePx=range;assert.ok(E.resolve(catalog,input).hit>0,'Melee uses reach, not projectile travel');
  input.distancePx=range+1;assert.equal(E.resolve(catalog,input).hit,0,'Melee out of reach');
}
let i=fresh();i.loadout.weapon.modules=[{id:'ballistic_core',level:3,quality:1,slot:0}];
assert.ok(E.resolve(catalog,i).hit>E.resolve(catalog,fresh()).hit);
const module=i.loadout.weapon.modules[0];i.loadout.character.modules=[module];i.loadout.weapon.modules=[];
near(E.resolve(catalog,i).hit,E.resolve(catalog,fresh()).hit,'character module does not secretly buff gun');
i=fresh();i.loadout.armor[1].modules=[{id:'armor_plate',level:4,quality:1,slot:0}];
assert.ok(E.simulate(catalog,i).receivedDps<E.simulate(catalog,fresh()).receivedDps);
i=fresh();i.loadout.weapon.parts=[{id:'pistol_compensator',level:1}];assert.throws(()=>E.resolve(catalog,i),/호환/);
i=fresh();i.loadout.weapon.modules=[{id:'vitality_matrix',level:1,quality:1,slot:0},{id:'ballistic_core',level:1,quality:1,slot:1}];assert.throws(()=>E.resolve(catalog,i),/코스트/);
i.loadout.weapon.level=catalog.loadout.weapons.find(w=>w.id===i.weaponId).maximum_level;i.loadout.weapon.sockets={0:'survival',1:'ballistic'};
assert.equal(E.resolve(catalog,i).loadout.costs[0].used,5,'per-module ceil matching socket cost');
i.loadout.weapon.modules[1]={...i.loadout.weapon.modules[0],slot:1};assert.throws(()=>E.resolve(catalog,i),/중복/);
i=fresh();i.loadout.weapon.quality=NaN;assert.throws(()=>E.resolve(catalog,i),/품질/);
const future=structuredClone(catalog);future.skills.push({...future.skills[0],skill_id:'future_field',display_name:'Future compatible skill'});
future.loadout.armor.push({...future.loadout.armor[0],id:'future_same_slot'});
assert.equal(E.defaults(future,'assault_rifle').loadout.armor.length,2,'preserve starter vest/boots despite new armor choices');
E.resolve(future,E.defaults(future,'assault_rifle'));
assert.ok(E.skillComparisons(future,fresh()).some(s=>s.id==='future_field'),'new supported-kind skill auto discovery');
assert.equal(E.skillComparisons(catalog,fresh()).find(s=>s.id==='speed_boost').result.skillDamage,0);
console.log(`DPS_LOADOUT_PARITY_OK ${catalog.loadout.fixtures.length} Godot runtime cases, parts/modules/armor/character, slots/cost/quality, independent future skills`);
