/* Attachment editor. It emits a draft; only the pure resolver decides validity. */
(() => {
  const el=(tag,text)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;return n;};
  function mount(host,catalog,weaponId,changed){
    const data=catalog.loadout;let state=SFHLoadout.defaults(catalog),activeWeapon=weaponId;
    const panel=el('details');panel.className='dps-loadout';panel.append(el('summary','장착 시뮬레이터 · 파츠 / 무기·방어구·캐릭터 모듈'));
    const content=el('div');panel.append(content);host.append(panel);
    const label=(name,node,parent)=>{const l=el('label',name);node.setAttribute('aria-label',name);l.append(node);parent.append(l);};
    function select(name,rows,value,parent,onChange){const n=el('select');for(const [id,title]of rows){const o=el('option',title);o.value=id;n.append(o);}n.value=value;n.addEventListener('change',()=>{onChange(n.value);changed();});label(name,n,parent);return n;}
    function number(name,value,max,parent,onChange){const n=el('input');n.type='number';n.min='0.01';n.max=max;n.step='any';n.value=value;n.addEventListener('input',()=>{onChange(n.value===''?NaN:Number(n.value));changed();});label(name,n,parent);}
    function carrier(name,definition,item,kind){
      const section=el('details');section.append(el('summary',`${name} · 모듈 ${definition.slots}칸 / 코스트 ${definition.capacity}`));const grid=el('div');grid.className='dps-fields';section.append(grid);content.append(section);
      select(`${name} 장비 레벨`,Array.from({length:definition.maximum_level},(_,j)=>[j+1,`Lv.${j+1}`]),item.level,grid,v=>item.level=Number(v));
      number(`${name} 품질 배율`,item.quality,100,grid,v=>item.quality=v);
      if(kind==='weapon')for(const socket of definition.part_sockets){
        const compatible=data.parts.filter(p=>p.socket===socket&&p.minor_tags.includes(definition.minor_tag));
        const installed=item.parts.find(p=>compatible.some(d=>d.id===p.id));
        const group=el('div');group.className='dps-attachment-row';section.append(group);
        const level=el('select');
        const reloadLevel=id=>{level.replaceChildren();const p=compatible.find(p=>p.id===id);for(let j=1;j<=(p?.maximum_level||1);j++){const o=el('option',`Lv.${j}`);o.value=j;level.append(o);}level.value=item.parts.find(p=>p.id===id)?.level||1;level.disabled=!id;};
        const choice=select(`${name} 파츠 ${socket}`,[['','미장착'],...compatible.map(p=>[p.id,p.name])],installed?.id||'',group,id=>{item.parts=item.parts.filter(p=>!compatible.some(d=>d.id===p.id));if(id)item.parts.push({id,level:1});reloadLevel(id);});
        label(`${name} 파츠 ${socket} 강화`,level,group);reloadLevel(choice.value);level.addEventListener('change',()=>{item.parts.find(p=>p.id===choice.value).level=Number(level.value);changed();});
      }
      const tagRows=[['','소켓 없음'],...[...new Set(data.modules.flatMap(m=>m.tags))].map(t=>[t,t])];
      for(let slot=0;slot<definition.slots;slot++){
        const group=el('div');group.className='dps-attachment-row';section.append(group);const prefix=`${name} 모듈 ${slot+1}`;
        const installed=item.modules.find(m=>m.slot===slot);const level=el('select'),q=el('input');q.type='number';q.min='.01';q.max='100';q.step='any';q.value=installed?.quality||1;
        const reloadLevel=id=>{level.replaceChildren();const m=data.modules.find(m=>m.id===id);for(let j=1;j<=(m?.maximum_level||1);j++){const o=el('option',`Lv.${j} · 비용 ${m?.levels[j-1].cost??0}`);o.value=j;level.append(o);}level.value=item.modules.find(m=>m.slot===slot)?.level||1;level.disabled=q.disabled=!id;};
        const choice=select(prefix,[['','미장착'],...data.modules.map(m=>[m.id,m.name])],installed?.id||'',group,id=>{item.modules=item.modules.filter(m=>m.slot!==slot);if(id)item.modules.push({id,slot,level:1,quality:1});q.value=1;reloadLevel(id);});
        label(`${prefix} 강화`,level,group);label(`${prefix} 품질`,q,group);reloadLevel(choice.value);
        level.addEventListener('change',()=>{item.modules.find(m=>m.slot===slot).level=Number(level.value);changed();});
        q.addEventListener('input',()=>{item.modules.find(m=>m.slot===slot).quality=q.value===''?NaN:Number(q.value);changed();});
        select(`${prefix} 소켓 태그`,tagRows,item.sockets[slot]||'',group,tag=>{if(tag)item.sockets[slot]=tag;else delete item.sockets[slot];});
      }
    }
    function render(){
      content.replaceChildren();
      select('캐릭터 원본',data.characters.map(c=>[c.character_id,`${c.display_name} · ${c.passive_name}`]),state.characterId,content,id=>state.characterId=id);
      carrier('무기',data.weapons.find(w=>w.id===activeWeapon),state.weapon,'weapon');
      for(const slot of [...new Set(data.armor.map(a=>a.slot))]){
        const selected=state.armor.find(a=>data.armor.find(d=>d.id===a.id)?.slot===slot);
        select(`방어구 ${slot}`,[['','미장착'],...data.armor.filter(a=>a.slot===slot).map(a=>[a.id,a.name])],selected?.id||'',content,id=>{state.armor=state.armor.filter(a=>data.armor.find(d=>d.id===a.id)?.slot!==slot);if(id)state.armor.push({id,...SFHLoadout.carrier()});render();});
        if(selected)carrier(data.armor.find(a=>a.id===selected.id).name,data.armor.find(a=>a.id===selected.id),selected,'armor');
      }
      carrier('캐릭터',data.character_carrier,state.character,'character');
      content.append(el('p','동일 장비 내 중복·비용 초과·파츠 비호환은 계산을 차단합니다. 소켓 태그는 최대 레벨 필요. 품질은 실물 performance_multiplier입니다. 랜덤 부여 옵션·런 버프는 별도이며 자동 적용하지 않습니다.'));
    }
    render();
    return {read:()=>structuredClone(state),weapon:id=>{if(id!==activeWeapon){activeWeapon=id;state.weapon=SFHLoadout.carrier();render();}},reset:()=>{state=SFHLoadout.defaults(catalog);render();}};
  }
  globalThis.SFHLoadoutUI=Object.freeze({mount});
})();
