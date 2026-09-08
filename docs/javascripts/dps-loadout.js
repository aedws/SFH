/* Equipment projection only. CSV/Resource-derived modifiers; no game or persistence writes. */
(() => {
  'use strict';
  const carrier=()=>({level:1,quality:1,modules:[],parts:[],sockets:{}});
  function defaults(catalog){const slots=new Set();return {characterId:catalog.loadout.characters[0].character_id,weapon:carrier(),armor:catalog.loadout.armor.filter(a=>{if(slots.has(a.slot))return false;slots.add(a.slot);return true;}).map(a=>({id:a.id,...carrier()})),character:carrier()};}
  const integer=(v,min,max,name)=>{if(!Number.isInteger(v)||v<min||v>max)throw Error(`${name}: ${min}~${max} 정수 필요`);};
  const quality=v=>{if(typeof v!=='number'||!Number.isFinite(v)||v<=0||v>100)throw Error('품질 배율: 0 초과 100 이하');return v;};
  function merge(target,source,q=1){for(const [id,v] of Object.entries(source||{})){const t=target[id]||{add:0,multiply:1};t.add+=(v.add||0)*q;t.multiply*=1+((v.multiply??1)-1)*q;target[id]=t;}}
  function weaponMerge(target,source,q=1){for(const [id,v]of Object.entries(source||{})){target[id]=id==='damage_add'?(target[id]||0)+v*q:(target[id]??1)*(1+(v-1)*q);}}
  function resolve(catalog,weaponId,input){
    const data=catalog.loadout;
    if(!data||!input||!Array.isArray(input.armor)||input.armor.length>data.armor.length)throw Error('장착 카탈로그 또는 방어구 선택 오류');
    const selected=data.characters.find(c=>c.character_id===input.characterId);
    if(!selected)throw Error('캐릭터 원본이 없습니다.');
    const stats={},weapon={},costs=[],notes=[];
    merge(stats,selected.runtime_modifiers);
    const definition=data.weapons.find(w=>w.id===weaponId);
    if(!definition)throw Error('무기 장착 원본이 없습니다.');
    const occupied=new Set();
    function apply(def,state,kind){
      if(!state||!Array.isArray(state.modules)||!Array.isArray(state.parts)||typeof state.sockets!=='object'||!state.sockets)throw Error('장착 상태 형식 오류');
      integer(state.level,1,def.maximum_level,'장비 레벨');const q=quality(state.quality);
      if(state.modules.length>def.slots)throw Error(`${def.name}: 모듈 슬롯 초과`);
      const sockets=Object.entries(state.sockets);
      const tags=new Set(data.modules.flatMap(m=>m.tags));
      for(const [index,tag]of sockets){if(!/^\d+$/.test(index))throw Error('소켓 번호 오류');integer(Number(index),0,def.slots-1,'소켓 번호');if(!tags.has(tag))throw Error('소켓 태그 오류');}
      // Socket assignment is unlocked at max level; this editor models fresh configurations.
      if(sockets.length&&state.level<def.maximum_level)throw Error('소켓 최적화는 장비 최대 레벨에서 가능합니다.');
      if(kind==='weapon'){
        weaponMerge(weapon,def.levels[state.level-1].weapon);weapon.damage_multiply=(weapon.damage_multiply??1)*q;
      }else if(kind==='armor'){
        merge(stats,def.stats,q);merge(stats,def.levels[state.level-1].player);
        for(const o of def.options)merge(stats,{[o.modifier_id]:{add:o.operation==='add'?o.amount:0,multiply:o.operation==='multiply'?o.amount:1}});
      }
      if(state.parts.length>(def.part_sockets?.length||0))throw Error('파츠 소켓 수 초과');
      const partSockets=new Set();
      for(const p of state.parts){
        const part=data.parts.find(row=>row.id===p.id);
        if(kind!=='weapon'||!part||!part.minor_tags.includes(def.minor_tag)||!def.part_sockets.includes(part.socket)||partSockets.has(part.socket))throw Error('호환되지 않거나 중복된 파츠');
        integer(p.level,1,part.maximum_level,'파츠 강화');partSockets.add(part.socket);merge(stats,part.stats);
        notes.push(`${part.name}: 현행 파츠는 직접 탄환 DPS 보정이 없으며 강화 단계도 피해에 연결되지 않습니다.`);
      }
      const ids=new Set(),slots=new Set();let used=0;
      for(const m of state.modules){
        const module=data.modules.find(row=>row.id===m.id);
        if(!module||ids.has(m.id))throw Error('없거나 같은 장비에 중복된 모듈');
        integer(m.slot,0,def.slots-1,'모듈 슬롯');if(slots.has(m.slot))throw Error('모듈 슬롯 중복');slots.add(m.slot);ids.add(m.id);
        integer(m.level,1,module.maximum_level,'모듈 강화');const mq=quality(m.quality),level=module.levels[m.level-1],tag=state.sockets[m.slot];
        used+=tag?Math.ceil(level.cost*(module.tags.includes(tag)?data.sockets.matching:data.sockets.mismatching)):level.cost;
        merge(stats,module.stats,mq);merge(stats,level.player,mq);
        // Runtime only routes weapon upgrade modifiers from the ACTIVE weapon carrier.
        if(kind==='weapon')weaponMerge(weapon,level.weapon,mq);
        else if(Object.entries(level.weapon).some(([k,v])=>v!==(k==='damage_add'?0:1)))notes.push(`${module.name}: 방어구/캐릭터 장착에서는 무기 피해 보정이 적용되지 않습니다.`);
      }
      if(used>def.capacity)throw Error(`${def.name}: 모듈 코스트 ${used}/${def.capacity} 초과`);
      costs.push({name:def.name,used,capacity:def.capacity});
    }
    apply(definition,input.weapon,'weapon');
    for(const state of input.armor){const def=data.armor.find(a=>a.id===state.id);if(!def||occupied.has(def.slot))throw Error('방어구 슬롯 중복 또는 원본 없음');occupied.add(def.slot);apply(def,state,'armor');}
    apply({...data.character_carrier,name:'캐릭터'},input.character,'character');
    // Same external character growth as MetaProgressionSystem (no loadout mutation).
    merge(stats,{max_health:{add:(input.character.level-1)*5,multiply:1},movement_speed:{add:0,multiply:Math.pow(1.02,input.character.level-1)}});
    const player={...data.player};for(const [id,v]of Object.entries(stats))player[id]=((player[id]||0)+v.add)*v.multiply;
    player.max_health=Math.max(1,player.max_health);player.defense=Math.max(0,player.defense);player.movement_speed=Math.max(0,player.movement_speed);
    for(const key of Object.keys(stats))if(!Object.hasOwn(data.player,key))notes.push(`${key}: 플레이어 미사용 수치이며 무기/스킬 피해에 자동 합산하지 않습니다.`);
    return {player,weapon,costs,notes:[...new Set(notes)],character:selected};
  }
  globalThis.SFHLoadout=Object.freeze({defaults,resolve,carrier});
})();
