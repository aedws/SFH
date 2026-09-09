/* Pure, bounded planning model. No DOM, network, game mutations or saved profiles. */
(() => {
  'use strict';
  const copy = value => JSON.parse(JSON.stringify(value));
  function distanceCurve(value='0:1;1:1') {
    if(typeof value!=='string')throw Error('거리 곡선 문자열이 필요합니다.');
    const entries=value.split(';');if(entries.length<2||entries.length>16)throw Error('거리 곡선은 2~16점이어야 합니다.');
    const points=[];
    for(const entry of entries){const pair=entry.split(':');
      if(pair.length!==2||pair.some(v=>!v.trim()||!/^[-+]?(?:\d+\.?\d*|\.\d+)(?:e[-+]?\d+)?$/i.test(v.trim())))throw Error('거리:배율 형식이 필요합니다.');
      const [x,y]=pair.map(Number);if(!Number.isFinite(x)||!Number.isFinite(y)||x<0||x>1||y<0||y>3||(points.length&&x<=points.at(-1)[0]))throw Error('거리 0~1 오름차순, 배율 0~3이 필요합니다.');points.push([x,y]);}
    if(points[0][0]!==0||points.at(-1)[0]!==1)throw Error('거리 곡선 양 끝은 0과 1이어야 합니다.');return points;
  }
  function distanceMultiplier(points,distance,range){
    const ratio=Math.max(0,Math.min(1,distance/range));
    for(let n=1;n<points.length;n++){const [x,y]=points[n],[a,b]=points[n-1];if(ratio<=x)return b+(y-b)*(ratio-a)/(x-a);}return points.at(-1)[1];
  }
  const limits = {
    distancePx:[0,100000],
    damage:[0,10000], interval:[0.02,120], burst:[1,20], burstInterval:[0.02,10], projectiles:[1,32],
    crit:[0,1], critMultiplier:[1,10], damageAdd:[0,10000], damageMultiplier:[0,10], intervalMultiplier:[0.02,10], level:[1,100],
    skillDamage:[0,10000], skillCooldown:[0.05,120], skillDuration:[0.01,120], skillTick:[0.01,10],
    skillCost:[0,1000], charges:[1,10], recharge:[0.1,120], skillMultiplier:[0,10],
    hp:[1,1000000], armor:[0,1000000], enemyDamage:[0,10000], enemyInterval:[0.01,120],
    horizon:[1,120], hitRate:[0,1], coverage:[0,1], energy:[0,10000], maxEnergy:[1,10000], regen:[0,1000], regenDelay:[0,60], targetTime:[0.1,120],
  };
  function defaults(catalog, weaponId, skillId = '') {
    const w = catalog.weapons.find(row => row.id === weaponId);
    if (!w) throw Error('무기 원본이 없습니다.');
    const s = catalog.skills.find(row => row.skill_id === skillId);
    if (skillId && !s) throw Error('스킬 원본이 없습니다.');
    const b = w.balance, p = s?.parameters || {}, r = catalog.resources;
    return {weaponId, skillId, distancePx:0, distanceCurve:b.distance_damage_curve??'0:1;1:1', damage:b.damage, interval:b.fire_interval_sec, burst:b.burst_count,
      burstInterval:Math.max(0.02,b.burst_interval_sec), projectiles:b.projectiles_per_shot, crit:b.critical_chance,
      critMultiplier:b.critical_multiplier, damageAdd:0, damageMultiplier:1, intervalMultiplier:1, level:1,
      skillDamage:p.path_damage?.damage ?? p.tick_damage ?? 0, skillCooldown:s?.cooldown_seconds ?? 5,
      skillDuration:p.duration_seconds ?? 1, skillTick:p.tick_interval_seconds ?? 0.5,
      skillCost:s?.energy_cost ?? 0, charges:s?.maximum_charges ?? 1, recharge:s?.charge_recovery_seconds ?? 1,
      skillMultiplier:1, hp:catalog.enemy.hp, armor:catalog.enemy.armor, enemyDamage:catalog.enemy.damage,
      enemyInterval:catalog.enemy.interval, horizon:30, hitRate:1, coverage:1, energy:r.starting,
      maxEnergy:r.maximum, regen:r.regen, regenDelay:r.delay, targetTime:5, innate:true, fixedOptions:true,
      shock:false, resourceLimits:true, ...(catalog.loadout?{loadout:globalThis.SFHLoadout.defaults(catalog)}:{})};
  }
  function validate(input) {
    const errors = [];
    for (const [key,[min,max]] of Object.entries(limits)) {
      if(key==='distancePx' && input[key]===undefined)continue; // Pre-distance saved trials.
      if (typeof input[key] !== 'number' || !Number.isFinite(input[key]) || input[key] < min || input[key] > max) errors.push(`${key}: ${min}~${max} 범위의 숫자가 필요합니다.`);
    }
    for (const key of ['burst','projectiles','charges','level','horizon']) if (!Number.isInteger(input[key])) errors.push(`${key}: 정수가 필요합니다.`);
    if (input.energy > input.maxEnergy) errors.push('시작 AP는 최대 AP보다 클 수 없습니다.');
    return errors;
  }
  function resolve(catalog, input) {
    const errors = validate(input);
    if (errors.length) throw Error(errors.join(' '));
    const weapon = catalog.weapons.find(row => row.id === input.weaponId);
    const skill = catalog.skills.find(row => row.skill_id === input.skillId);
    if (!weapon || (input.skillId && !skill)) throw Error('선택한 무기/스킬이 원본에 없습니다.');
    if (skill && !['path','field','utility'].includes(skill.kind)) throw Error('새 스킬 효과는 계산 모델 등록이 필요합니다.');
    let add=input.damageAdd, multiply=input.damageMultiplier, intervalMultiply=input.intervalMultiplier;
    const loadout=catalog.loadout?globalThis.SFHLoadout.resolve(catalog,input.weaponId,input.loadout):null;
    let rangeMultiply=loadout?.weapon.target_range_multiply??1;
    if(loadout){add+=loadout.weapon.damage_add||0;multiply*=loadout.weapon.damage_multiply??1;intervalMultiply*=loadout.weapon.fire_interval_multiply??1;}
    if (input.fixedOptions) for (const option of weapon.options) {
      if (option.modifier_id === 'damage_add') add += option.amount;
      if (option.modifier_id === 'damage_multiply') multiply *= option.amount;
      if (option.modifier_id === 'fire_interval_multiply') intervalMultiply *= option.amount;
      if (option.modifier_id === 'target_range_multiply') rangeMultiply *= option.amount;
    }
    const range=Math.max(32,weapon.balance.target_range_px*rangeMultiply);
    const points=distanceCurve(input.distanceCurve??weapon.balance.distance_damage_curve??'0:1;1:1');
    const distanceFactor=distanceMultiplier(points,input.distancePx??0,range);
    const melee=['melee_arc','melee_thrust'].includes(weapon.balance.attack_mode);
    const reachable=(input.distancePx??0)<=(melee?range:Math.min(range,weapon.balance.projectile_speed_px_sec*weapon.balance.projectile_lifetime_sec));
    const hit = ((input.damage+add)*multiply + Math.floor((input.level-1)/3)) * (1+input.crit*(input.critMultiplier-1))*distanceFactor*(reachable?1:0);
    const gap = Math.max(0.02,input.interval*intervalMultiply);
    const burstGap = Math.max(0.02,input.burstInterval*intervalMultiply);
    const cycle = gap + (input.burst-1)*burstGap;
    const allowed = !skill || skill.required_combat_tags.every(tag => weapon.tags.includes(tag));
    const override = weapon.overrides[input.skillId] || {};
    const skillDamage = input.skillDamage * input.skillMultiplier * (skill?.kind === 'field' ? override.tick_damage_multiplier ?? 1 : override.damage_multiplier ?? 1)
      + (skill?.kind === 'path' && input.shock ? skill.parameters.path_damage.trigger_bonus_damage : 0);
    const duration = input.skillDuration*(override.duration_multiplier ?? 1);
    const ticks = skill?.kind === 'field' ? Math.ceil(duration/input.skillTick-1e-9) : 1;
    const perCast = skill?.kind === 'utility' || !skill || !allowed ? 0 : skillDamage*ticks*input.coverage;
    const innate = input.innate && reachable ? (weapon.innate.fixed_damage || 0) / (weapon.innate.trigger_every_hits || 1) : 0;
    return {weapon,skill,allowed,hit,gap,burstGap,cycle,skillDamage,duration,ticks,perCast,loadout,range,distanceFactor,reachable,
      sustainedWeapon:(hit+innate)*input.projectiles*input.burst*input.hitRate/cycle,
      activeSkillDps:skill?.kind === 'field' && allowed ? skillDamage/input.skillTick*input.coverage : 0};
  }
  function simulate(catalog, input) {
    const x = resolve(catalog,input), dt=0.01, budget=input.hp+input.armor;
    if (x.skill?.kind === 'field' && x.ticks*(1+input.horizon/input.skillCooldown)>200000) throw Error('계산 예산 초과: 지속 시간·관측 시간을 줄이거나 틱 간격을 늘려주세요.');
    let energy=input.energy, idle=0, charges=input.charges, recharge=0, cooldown=0;
    let nextShot=0, burstIndex=0, weaponDamage=0, skillDamage=0, confirmed=0, procs=0, casts=0, ttk=null, active=[];
    const player=x.loadout?.player||catalog.loadout?.player||{max_health:100,defense:0,movement_speed:280};
    const receivedHit=Math.max(1,input.enemyDamage-player.defense);
    const points=[];
    const totalSteps=Math.round(input.horizon/dt);
    for (let step=0; step<=totalSteps; step++) {
      const time=step*dt;
      if (step>0) {
        energy=Math.min(input.maxEnergy,energy+Math.max(0,dt-Math.max(0,input.regenDelay-idle))*input.regen);
        idle+=dt; cooldown=Math.max(0,cooldown-dt);
        if (charges<input.charges) {
          recharge-=dt;
          while(recharge<=1e-9 && charges<input.charges) { charges++; recharge=charges<input.charges ? recharge+input.recharge : 0; }
        }
      }
      if (time+1e-9>=nextShot) {
        weaponDamage+=x.hit*input.projectiles*input.hitRate;
        const previous=confirmed;
        confirmed+=input.projectiles*input.hitRate*(x.reachable?1:0);
        const threshold=x.weapon.innate.trigger_every_hits || 1;
        // Fractional contact is an expected-hit approximation, not a random combat replay.
        const triggers=x.reachable?(input.hitRate===1 ? Math.floor(confirmed/threshold)-Math.floor(previous/threshold) : input.projectiles*input.hitRate/threshold):0;
        if (input.innate) { weaponDamage+=triggers*(x.weapon.innate.fixed_damage || 0); procs+=triggers; }
        burstIndex++;
        nextShot=time+(burstIndex<input.burst ? x.burstGap : x.gap);
        if(burstIndex>=input.burst) burstIndex=0;
      }
      if(x.skill && x.allowed && cooldown<=1e-9 && (!input.resourceLimits || (charges>0 && energy+0.001>=input.skillCost))) {
        casts++; cooldown=input.skillCooldown;
        if(input.resourceLimits) {
          energy=Math.max(0,energy-input.skillCost); if(input.skillCost>0) idle=0;
          charges--; if(recharge<=0) recharge=input.recharge;
        }
        if(x.skill.kind==='field') active.push({start:time,next:time,end:time+x.duration});
        else if(x.skill.kind==='path') skillDamage+=x.skillDamage*input.coverage;
      }
      for(const field of active) {
        while(time+1e-9>=field.next && field.next<field.end-1e-9) {
          skillDamage+=x.skillDamage*input.coverage; field.next+=input.skillTick;
        }
      }
      active=active.filter(field=>field.next<field.end-1e-9);
      const total=weaponDamage+skillDamage;
      if(ttk===null && total+1e-9>=budget) ttk=time;
      if(step%10===0 || step===totalSteps) points.push({time,weapon:weaponDamage,skill:skillDamage,total,
        hp:Math.max(0,input.hp-Math.max(0,total-input.armor)),armor:Math.max(0,input.armor-total),energy,
        playerHp:Math.max(0,player.max_health-(Math.floor((time+1e-9)/input.enemyInterval)+1)*receivedHit)});
    }
    return {points,ttk,casts,procs,weaponDamage,skillDamage,total:weaponDamage+skillDamage,
      dps:(weaponDamage+skillDamage)/input.horizon,enemyDps:input.enemyDamage/input.enemyInterval,
      resolved:x, energy, charges,player,receivedHit,receivedDps:receivedHit/input.enemyInterval,
      survivalTime:(Math.ceil(player.max_health/receivedHit)-1)*input.enemyInterval};
  }
  function skillComparisons(catalog,input){
    // Each skill gets the SAME full initial AP pool; this is not simultaneous skill rotation.
    return catalog.skills.map(skill=>{
      const i={...input,skillId:skill.skill_id};const baseline=defaults(catalog,input.weaponId,skill.skill_id);
      for(const key of ['skillDamage','skillCooldown','skillDuration','skillTick','skillCost','charges','recharge'])i[key]=skill.skill_id===input.skillId?input[key]:baseline[key];
      return {id:skill.skill_id,name:skill.display_name,result:simulate(catalog,i)};
    });
  }
  globalThis.SFHDps = Object.freeze({defaults,resolve,simulate,skillComparisons,validate,limits,copy,distanceCurve,distanceMultiplier});
})();
