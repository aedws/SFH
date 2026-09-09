const assert=require('node:assert/strict'),fs=require('node:fs'),crypto=require('node:crypto');
const model=require('../docs/javascripts/map-model.js'),catalog=require('../docs/assets/map-catalog.json');
for(const [path,hash] of Object.entries(catalog.sources))assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path,'utf8').replace(/\r\n/g,'\n')).digest('hex'),hash,`Stale map catalog: ${path}`);
for(const f of require('./fixtures/regional-map.json'))assert.deepEqual(model.build(catalog.tiers[f.tier],f.plan.region,f.plan.seed,catalog.facilities),f.plan);
let count=0;
for(const region of catalog.regions)for(const config of Object.values(catalog.tiers)){
 const baseline=model.build(config,region.id,1,catalog.facilities);
 for(let seed=2;seed<=100;seed++){
  const plan=model.build(config,region.id,seed,catalog.facilities);
  assert.deepEqual(plan.buildings.filter(b=>b.required),baseline.buildings.filter(b=>b.required));
  assert.notDeepEqual(plan.buildings,baseline.buildings);
  assert.equal(plan.buildings.filter(b=>catalog.facilities.find(r=>r.facility_id===b.facility_id).encounter==='objective').length,1);
  assert.deepEqual(model.build(config,region.id,seed,catalog.facilities.slice().reverse()),plan);
  count++;
 }
}
assert.throws(()=>model.build(catalog.tiers.small,'ruined_city',NaN,catalog.facilities));
assert.throws(()=>model.build(catalog.tiers.small,'ruined_city',1,[]));
const custom=model.build({...catalog.tiers.small,urban:{avenue_width:999,entrance_width:1}},'ruined_city',1,catalog.facilities);
assert.deepEqual(custom.urban_settings,{avenue_width:20,local_width:10,sidewalk_width:3,entrance_width:3});
assert.equal(model.build({...catalog.tiers.small,urban_enabled:false},'ruined_city',1,catalog.facilities).version,1);
console.log(`MAP_MODEL_OK 27 engine parity fixtures ${count} stable-landmark / varied-filler / reorder cases`);
