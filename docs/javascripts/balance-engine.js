/* Pure planning projections shared by the browser and authenticated confirmation API. */
(() => {
  'use strict';
  const version=2;
  const number=(v,min,max)=>{if(typeof v!=='number'||!Number.isFinite(v)||v<min||v>max)throw Error(`수치는 ${min}~${max} 범위여야 합니다.`);return v;};
  function table(catalog,input){
    const dataset=catalog.datasets.find(d=>d.id===input.dataset);
    const column=dataset?.columns[input.column];
    if(!column||!Array.isArray(input.values)||input.values.length!==column.length)throw Error('원본 목록 또는 열이 변경되었습니다.');
    const ids=new Set();
    const points=column.map((p,i)=>{const v=input.values[i];if(v.id!==p.id||ids.has(v.id))throw Error('행 ID가 일치하지 않습니다.');ids.add(v.id);return {x:i,label:dataset.labels[p.id],base:p.value,value:number(v.value,-1e7,1e7)};});
    return {title:`${dataset.title} · ${input.column}`,xLabel:'원본 행 (순서형 시간축 아님)',yLabel:dataset.column_labels[input.column],points,
      note:'청록 시험값 / 회색 원본. 열 단위 직접 수치 비교이며 서로 다른 행의 합을 DPS·확률·난이도로 해석하지 않습니다.'};
  }
  function recovery(_,i){
    number(i.cost,0,1e6);number(i.minimum,0,100);number(i.maximum,i.minimum,100);number(i.success,0,1);
    return {title:'투입 대비 회수 시나리오',xLabel:'회수 배수',yLabel:'크레딧 C',points:Array.from({length:21},(_,n)=>{const x=i.minimum+(i.maximum-i.minimum)*n/20;return{x,label:x.toFixed(2),base:i.cost,value:i.cost*x*i.success};}),
      note:'시험선 = 투입액 × 회수 배수 × 가정 생환율. 기준선 = 투입액. 사망 회수 0 가정의 기대 회수이며 실제 드랍 분포·파우치·장비 손실은 제외합니다.'};
  }
  function facility(_,i){
    number(i.minimum,1,500);number(i.maximum,i.minimum,500);number(i.risk,0,2);number(i.capacity,0,1000);
    if(![i.minimum,i.maximum,i.capacity].every(Number.isInteger))throw Error('적 수량과 잔여 수용량은 정수여야 합니다.');
    return{title:'시설 중심 깊이별 생성 수량 범위',xLabel:'중심 깊이 (0 바깥 / 1 중심)',yLabel:'적 수량',points:Array.from({length:11},(_,n)=>{const x=n/10;return{x,label:x.toFixed(1),base:i.capacity<i.minimum?0:Math.min(i.capacity,Math.round(i.minimum*(1+x*i.risk))),value:i.capacity<i.minimum?0:Math.min(i.capacity,Math.round(i.maximum*(1+x*i.risk)))};}),
      note:'회색 최소 / 청록 최대. patrol 후보수 × (1 + 중심 깊이 × risk_bonus), 잔여 동시 수용량 적용. 최소 미달이면 대기(0). 총 생성 예산·금고 예약·안전 위치 부족은 별도 제한입니다.'};
  }
  function combat(catalog,input){
    const E=globalThis.SFHDps;
    for(const flag of ['fixedOptions','innate','resourceLimits','shock'])if(typeof input[flag]!=='boolean')throw Error('효과 적용 여부는 체크박스로 지정하세요.');
    const resolved=E.resolve(catalog,input);
    const work=input.horizon*100*(1+Math.min(resolved.duration,input.horizon)/input.skillCooldown);
    if(resolved.skill?.kind==='field'&&work>250000)throw Error('확정 계산 예산 초과: 관측·지속 시간을 줄이거나 쿨타임을 늘려주세요.');
    const result=E.simulate(catalog,input);
    return{title:`${result.resolved.weapon.name} · ${result.resolved.skill?.display_name||'무기만'}`,xLabel:'시간 (초)',yLabel:'누적 피해',
      points:result.points.filter((_,n)=>n%10===0).map(p=>({x:p.time,label:String(p.time),value:p.total,base:input.hp+input.armor})),
      series:[{title:'무기 누적 피해',points:result.points.filter((_,n)=>n%10===0).map(p=>({x:p.time,label:String(p.time),base:0,value:p.weapon}))},
        ...E.skillComparisons(catalog,input).map(s=>({title:`${s.name} · ${s.result.resolved.allowed?'독립 AP 조건':'태그 불일치 · 피해 0'}`,points:s.result.points.filter((_,n)=>n%10===0).map(p=>({x:p.time,label:String(p.time),base:0,value:p.skill}))})),
        {title:'플레이어 잔여 HP · 회복/회피 없음',points:result.points.filter((_,n)=>n%10===0).map(p=>({x:p.time,label:String(p.time),base:result.player.max_health,value:p.playerHp}))}],
      note:`관측 DPS ${result.dps.toFixed(2)} · TTK ${result.ttk===null?'구간 내 미처치':result.ttk.toFixed(2)+'초'} · 플레이어 HP ${result.player.max_health.toFixed(2)} / 방어 ${result.player.defense.toFixed(2)} / 속도 ${result.player.movement_speed.toFixed(2)}. ${result.resolved.loadout?.costs.map(c=>`${c.name} 코스트 ${c.used}/${c.capacity}`).join(' · ')||''}. 회색은 HP+방어막. 단일 대상 기대 피해 모델. 스킬별 그래프는 독립 AP 조건이며 동시 사용 합계가 아닙니다.`};
  }
  const models=Object.freeze({table,recovery,facility,combat});
  function calculate(model,catalog,input){if(!Object.hasOwn(models,model))throw Error('지원하지 않는 계산 모델');return models[model](catalog,input);}
  async function fingerprint(sources){const bytes=await crypto.subtle.digest('SHA-256',new TextEncoder().encode(JSON.stringify(sources)));return Array.from(new Uint8Array(bytes),v=>v.toString(16).padStart(2,'0')).join('');}
  globalThis.SFHBalance=Object.freeze({version,calculate,fingerprint});
})();
