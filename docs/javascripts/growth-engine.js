/* One identity across growth stages. Never connect unrelated catalog rows. */
(() => {
  const metrics={weapon:{dps:'지속 무기 DPS',hit:'기대 직격 피해'},character:{max_health:'최대 HP',defense:'방어력',movement_speed:'이동속도 (px/초)'},armor:{defense:'착용 시 방어력',max_health:'착용 시 최대 HP',movement_speed:'착용 시 이동속도 (px/초)'}};
  function entities(c,kind){
    if(kind==='weapon')return c.loadout.weapons.map(w=>({id:w.id,name:w.name,maximum:w.maximum_level}));
    if(kind==='armor')return c.loadout.armor.map(a=>({id:a.id,name:a.name,maximum:a.maximum_level}));
    if(kind==='character')return c.loadout.characters.map(a=>({id:a.character_id,name:a.display_name,maximum:c.loadout.character_carrier.maximum_level}));
    throw Error('지원하지 않는 성장 대상입니다.');
  }
  function baseline(c,i){
    const entity=entities(c,i.kind).find(e=>e.id===i.entityId);
    if(!entity||!Object.hasOwn(metrics[i.kind],i.metric))throw Error('성장 대상 또는 지표가 원본에 없습니다.');
    if(!Number.isInteger(entity.maximum)||entity.maximum<1||entity.maximum>100)throw Error('성장 단계 범위 오류');
    const input=SFHDps.defaults(c,i.kind==='weapon'?i.entityId:c.weapons[0].id);
    input.loadout.armor=[]; // One armor at most; never aggregate the catalog or full loadout.
    if(i.kind==='character')input.loadout.characterId=i.entityId;
    if(i.kind==='armor')input.loadout.armor=[{id:i.entityId,...SFHLoadout.carrier()}];
    const values=Array.from({length:entity.maximum},(_,n)=>{
      const level=n+1;
      if(i.kind==='weapon')input.loadout.weapon.level=level;
      if(i.kind==='character')input.loadout.character.level=level;
      if(i.kind==='armor')input.loadout.armor[0].level=level;
      const x=SFHDps.resolve(c,input);
      return i.kind==='weapon'?(i.metric==='dps'?x.sustainedWeapon:x.hit):x.loadout.player[i.metric];
    });
    return {entity,values};
  }
  function calculate(c,i){
    const {entity,values}=baseline(c,i),trial=i.values??values;
    if(!Array.isArray(trial)||trial.length!==values.length||trial.some(v=>typeof v!=='number'||!Number.isFinite(v)||v<0||v>1e7))throw Error('모든 성장 단계에 0~10,000,000 범위 수치가 필요합니다.');
    const axis=i.kind==='character'?'외부 캐릭터 레벨':'장비 강화 단계';
    const flat=values.every(v=>Math.abs(v-values[0])<1e-8);
    return {kind:'growth',entityId:i.entityId,title:`${entity.name} · ${metrics[i.kind][i.metric]} 성장`,xLabel:axis,yLabel:metrics[i.kind][i.metric],
      points:values.map((v,n)=>({x:n+1,label:String(n+1),base:v,value:trial[n],increase:trial[n]-trial[0],growth:trial[0]===0?null:(trial[n]/trial[0]-1)*100})),
      note:`동일 대상 ${entity.name} 하나만 ${axis} 1~${entity.maximum}로 변경. 품질 1·파츠/모듈 없음·내부 레벨 1·거리 0 고정. 방어구는 한 부위만 착용하고 캐릭터 레벨 1을 고정합니다. 청록 시험/현행, 회색 현재 구현 곡선. ${flat?'현행 이 지표는 성장 효과가 없어 평탄합니다.':'성장률은 선택한 대상의 1단계 대비 변화입니다.'}`};
  }
  globalThis.SFHGrowth=Object.freeze({metrics,entities,baseline,calculate});
})();
