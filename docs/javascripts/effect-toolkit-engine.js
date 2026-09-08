/* Declarative authoring -> reviewed change plan. No eval, network or gameplay writes. */
(() => {
  'use strict';
  const columns=['spec_id','status','target_kind','target_id','field_id','value','notion_url','intent','acceptance','owner_status','source_fingerprint'];
  const states=['draft','provisional','confirmed','hold'];
  function parseCSV(text){
    const rows=[];let row=[],cell='',quoted=false,closed=false;
    text=text.replace(/^\uFEFF/,'');if(text.length>1000000)throw Error('명세는 1MB 이하로 나눠 주세요.');
    for(let i=0;i<text.length;i++){
      const c=text[i];
      if(closed&&!['\r','\n',','].includes(c))throw Error('CSV 닫는 따옴표 뒤에 문자가 있습니다.');
      if(c==='"'){if(quoted&&text[i+1]==='"'){cell+='"';i++;}else if(quoted){quoted=false;closed=true;}else if(cell==='')quoted=true;else throw Error('잘못된 CSV 따옴표');}
      else if(!quoted&&(c===','||c==='\n'||c==='\r')){row.push(cell);cell='';closed=false;if(c!==','){if(row.some(Boolean))rows.push(row);row=[];if(c==='\r'&&text[i+1]==='\n')i++;}}
      else cell+=c;
    }
    if(quoted)throw Error('닫히지 않은 CSV 따옴표');if(cell||row.length){row.push(cell);rows.push(row);}
    const header=rows.shift();if(!header||header.length!==columns.length||header.some((v,i)=>v!==columns[i]))throw Error('EffectSpec 헤더/열 순서가 계약과 다릅니다.');
    return rows.filter(r=>r[0]!=='명세 고유 ID').map((r,i)=>{if(r.length!==columns.length)throw Error(`${i+2}행 열 수가 다릅니다.`);return Object.fromEntries(columns.map((k,j)=>[k,r[j]]));});
  }
  function compile(records,catalog){
    if(!Array.isArray(records)||!records.length||records.length>500)throw Error('명세는 1~500행이어야 합니다.');
    const changes=[],requests=[],seen=new Set();
    for(const r of records){
      if(Object.keys(r).some(k=>!columns.includes(k)))throw Error('알 수 없는 명세 열');
      if(!/^[a-z][a-z0-9_-]{2,79}$/.test(r.spec_id||''))throw Error('spec_id는 영문 소문자·숫자·밑줄·하이픈 3~80자입니다.');
      if(!states.includes(r.status)||!['pending','approved','rejected'].includes(r.owner_status))throw Error('기획 상태 또는 오너 판단 상태가 잘못되었습니다.');
      if(!['skill','weapon','character','module'].includes(r.target_kind)||!r.target_id?.trim())throw Error('대상 종류·ID가 필요합니다.');
      if(!r.intent?.trim()||!r.acceptance?.trim())throw Error('기획 의도와 플레이 수락 조건을 적어 주세요.');
      if([r.intent,r.acceptance,r.value].some(v=>String(v).length>3000))throw Error('각 입력은 3000자 이하입니다.');
      if(r.notion_url){let url;try{url=new URL(r.notion_url);}catch{throw Error('Notion 근거 URL을 확인하세요.');}
        if(url.protocol!=='https:'||!['notion.site','notion.so'].some(d=>url.hostname===d||url.hostname.endsWith('.'+d))||url.username||url.password)throw Error('Notion HTTPS 근거 링크가 필요합니다.');}
      else if(r.status==='confirmed'||r.owner_status==='approved')throw Error('확정·승인에는 Notion 근거가 필요합니다.');
      if(r.source_fingerprint!==catalog.fingerprint)throw Error('원본이 변경되었습니다. 현행값을 다시 읽고 검토하세요.');
      const key=[r.target_kind,r.target_id,r.field_id].join(':');if(seen.has(key))throw Error(`같은 대상·변수 중복: ${key}`);seen.add(key);
      if(r.field_id==='custom_effect'){
        if(!String(r.value||'').trim())throw Error('새 효과의 발동 조건·대상·종료·중첩 규칙을 적어 주세요.');
        requests.push({...r,result:'implementation_required'});continue;
      }
      const f=catalog.fields.find(f=>f.id===r.field_id&&f.kind===r.target_kind),target=f?.targets.find(t=>t.id===r.target_id);
      if(!target)throw Error(`지원하지 않는 대상/효과: ${key}. 새 효과 요청으로 분리하세요.`);
      let value=r.value;
      if(f.choices){if(!f.choices.includes(value))throw Error(`${f.label}: ${f.choices.join(', ')} 중 선택하세요.`);}
      else{if(value===null||value===undefined||typeof value==='boolean'||!String(value).trim())throw Error(`${f.label}: 빈값은 0이 아닙니다.`);
        value=Number(value);if(!Number.isFinite(value)||value<f.minimum||value>f.maximum||(f.integer&&!Number.isInteger(value)))throw Error(`${f.label}: ${f.minimum}~${f.maximum} ${f.unit}${f.integer?' 정수':''}`);}
      changes.push({...r,value,current:target.current,label:f.label,unit:f.unit,effect:f.effect,
        result:r.status==='confirmed'&&r.owner_status==='approved'?'reviewed_change_plan':'review_required',
        bindings:target.bindings.map(b=>({...b,source_sha256:catalog.sources[b.path]}))});
    }
    // Validate composed weapon settings, not each row in isolation.
    for(const change of changes.filter(c=>c.target_kind==='weapon')){
      const resolved=id=>changes.find(c=>c.target_id===change.target_id&&c.field_id===id)?.value??catalog.fields.find(f=>f.id===id)?.targets.find(t=>t.id===change.target_id)?.current;
      if(resolved('weapon.innate_effect_kind')==='electric_area'&&!(resolved('weapon.innate_effect_radius')>0))throw Error('전기 광역 효과는 0보다 큰 반경이 필요합니다. 반경 행도 함께 지정하세요.');
    }
    return {schema:1,source_fingerprint:catalog.fingerprint,game_applied:false,changes,requests,
      next:requests.length?'신규 행동 모듈 구현·E2E 필요':changes.every(c=>c.result==='reviewed_change_plan')?'Sheet/Resource 동기화 후 CSV·Web payload·E2E·PR 필요':'오너 검토 후 구현 가능'};
  }
  function markdown(records,catalog){
    const plan=compile(records,catalog);
    return ['# SFH 효과·스탯 명세','',...records.flatMap(r=>[
      `## ${r.spec_id}`,`- 상태: ${r.status} / 오너: ${r.owner_status}`,`- 대상: ${r.target_kind} / ${r.target_id}`,
      `- 변수·효과 ID: ${r.field_id}`,`- 요청값: ${r.value}`,`- 근거: ${r.notion_url||'작성 후 원본 링크 입력'}`,
      `- 기획 의도: ${r.intent}`,`- 플레이 수락 조건: ${r.acceptance}`,
      `- 원본 지문: ${r.source_fingerprint}`,'']),
      '## 구현 연결',...plan.changes.flatMap(c=>[`- ${c.label}: ${c.current} → ${c.value} ${c.unit}`,`  - 동작: ${c.effect}`,
        ...c.bindings.map(b=>`  - ${b.path} / ${b.section||JSON.stringify(b.selector)} / ${b.field}`)]),
      ...plan.requests.map(r=>`- 신규 구현 필요: ${r.value}`),'',`다음 작업: ${plan.next}`,
      '노션 작성·시트 입력만으로 게임에 자동 적용되지 않습니다. 승인·검증·배포를 별도로 진행합니다.'].join('\n');
  }
  function csv(records){const quote=v=>'"'+String(v??'').replaceAll('"','""')+'"';return columns.join(',')+'\n'+records.map(r=>columns.map(k=>quote(r[k])).join(',')).join('\n')+'\n';}
  globalThis.SFHEffectToolkit=Object.freeze({columns,states,compile,markdown,csv,parseCSV});
})();
