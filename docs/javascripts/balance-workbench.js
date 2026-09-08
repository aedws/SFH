/* Role presenters: local trials -> immutable planner confirmation -> read-only graph. */
(() => {
  'use strict';
  const el=(tag,text)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;return n;};
  const label=(text,node)=>{const n=el('label',text);node.setAttribute('aria-label',text);n.append(node);return n;};
  const button=text=>{const n=el('button',text);n.type='button';return n;};
  const json=async(path,options={})=>{const r=await fetch(path,{credentials:'same-origin',cache:'no-store',...options});if(!r.ok)throw Error((await r.json()).error||'데이터 요청 실패');return r.json();};
  function draw(host,graph,current=false){
    host.replaceChildren();host.classList.add('dps-graph');
    const ns='http://www.w3.org/2000/svg',svg=document.createElementNS(ns,'svg');
    const width=Math.max(280,host.clientWidth-18),height=280,points=graph.points;
    const min=Math.min(0,...points.flatMap(p=>[p.base,p.value])),max=Math.max(1,...points.flatMap(p=>[p.base,p.value]));
    const X=j=>55+j/Math.max(1,points.length-1)*(width-75),Y=v=>225-(v-min)/(max-min)*180;
    const node=(tag,attrs,text)=>{const n=document.createElementNS(ns,tag);Object.entries(attrs).forEach(([k,v])=>n.setAttribute(k,v));if(text!==undefined)n.textContent=text;svg.append(n);return n;};
    svg.setAttribute('viewBox',`0 0 ${width} ${height}`);svg.setAttribute('role','img');
    node('title',{},`${graph.title}. ${graph.yLabel}. ${graph.note}`);
    node('text',{x:55,y:20},graph.yLabel);
    const format=v=>Math.abs(v)>9999?v.toExponential(1):Number(v.toFixed(2)).toString();
    for(let k=0;k<=4;k++){const v=min+(max-min)*k/4;node('line',{x1:55,x2:width-20,y1:Y(v),y2:Y(v),class:'dps-gridline'});node('text',{x:0,y:Y(v)+4},format(v));}
    for(const [key,cls]of [['base','dps-base'],['value','dps-total']])node('path',{d:points.map((p,j)=>`${j?'L':'M'}${X(j)},${Y(p[key])}`).join(' '),class:`dps-line ${cls}`});
    for(const j of [...new Set(width<500?[0,points.length-1]:[0,Math.floor((points.length-1)/2),points.length-1])])node('text',{x:X(j),y:247,'text-anchor':j===0?'start':j===points.length-1?'end':'middle'},String(points[j]?.label||'').slice(0,width<500?9:23));
    host.append(svg,el('p',`${graph.xLabel} · ${graph.note}`));
    // Values remain accessible without relying on color, hover or a wide canvas.
    const details=el('details'),summary=el('summary','그래프 수치 읽기');details.append(summary);
    const table=el('table'),head=el('tr');(current?['원본 행','현행 CSV 값']:['구간 / 행','기준','시험 / 확정','차이','변화율']).forEach(v=>head.append(el('th',v)));table.append(head);
    points.forEach(p=>{const row=el('tr');(current?[p.label,String(p.value)]:[p.label,format(p.base),format(p.value),format(p.value-p.base),p.base===0?'기준 0: 비율 없음':format((p.value-p.base)/Math.abs(p.base)*100)+'%']).forEach(v=>row.append(el('td',v)));table.append(row);});details.append(table);host.append(details);
  }
  function confirmation(root,getTrial){
    const details=el('details');details.className='balance-confirm';details.append(el('summary','검토한 수치를 기획 확정으로 전달'));
    const title=el('input'),reason=el('textarea'),notion=el('input');title.maxLength=100;reason.maxLength=2000;notion.type='url';
    details.append(label('안건 제목',title),label('기획 사유와 목표',reason),label('근거 Notion 링크',notion));
    const consent=el('input');consent.type='checkbox';details.append(label('현재 입력과 그래프를 검토했습니다. 기획 확정은 오너 승인·게임 적용과 별도입니다.',consent));
    const save=button('기획 확정본 저장'),status=el('p');status.setAttribute('role','status');details.append(save,status);root.append(details);
    let pending=null,busy=false;
    save.addEventListener('click',async()=>{
      if(busy)return;
      busy=true;save.disabled=true;
      try{
        const trial=getTrial();if(!trial)throw Error('유효한 계산 결과가 필요합니다.');
        if(!consent.checked||!title.value.trim()||!reason.value.trim()||!notion.value.trim())throw Error('제목·사유·Notion 링크와 검토 확인이 필요합니다.');
        const draft={title:title.value,reason:reason.value,notion:notion.value,...trial,source:await SFHBalance.fingerprint(trial.sources),model_version:SFHBalance.version};
        delete draft.sources;
        const signature=JSON.stringify(draft);
        if(pending?.signature!==signature)pending={signature,body:{id:`${Date.now()}-${crypto.randomUUID()}`,...draft}};
        status.textContent='기획 확정본 저장 중…';
        const session=await json('/api/auth/session');
        if(session.role!=='planner')throw Error('기획자 로그인에서만 확정할 수 있습니다.');
        const saved=await json('/api/auth/balance',{method:'POST',headers:{'content-type':'application/json','x-csrf-token':session.csrf},body:JSON.stringify(pending.body)});
        status.textContent=`기획 확정 저장 완료 · ${saved.confirmed_at} · ${saved.id}. 개발자 그래프에 공유되었습니다. 게임에는 아직 적용되지 않았습니다.`;
        consent.checked=false;
        root.dispatchEvent(new CustomEvent('sfh-confirmed',{detail:saved}));
      }catch(e){status.textContent=`저장되지 않음: ${e.message}`;}finally{busy=false;save.disabled=false;}
    });
  }
  function drawBundle(host,graph){
    const primary=el('div');host.replaceChildren(primary);draw(primary,graph);
    for(const series of graph.series||[]){const details=el('details'),body=el('div');details.append(el('summary',series.title),body);host.append(details);const render=()=>draw(body,{...series,xLabel:graph.xLabel,yLabel:series.title,note:'동일 초기 자원의 독립 스킬 비교 / 생존은 회복·회피 없음. 각 스킬을 동시 사용한 합산 DPS가 아닙니다.'});render();details.addEventListener('toggle',()=>{if(details.open)render();});}
  }
  globalThis.SFHBalanceView=Object.freeze({draw,drawBundle});
  globalThis.SFHBalanceConfirm=confirmation;
  function currentCombat(root){
    const panel=el('details');panel.open=true;panel.className='balance-combat-default';panel.append(el('summary','기본 전투 성능 · 확정안 우선 / 없으면 현행 구현값'));
    const status=el('p'),graph=el('div'),retry=button('전투 기본값 새로고침');status.setAttribute('role','status');panel.append(status,retry,graph);root.append(panel);
    let activeGraph=null,width=graph.clientWidth;
    const render=value=>{activeGraph=value;drawBundle(graph,value);};
    const observer=new ResizeObserver(()=>{if(!panel.isConnected){observer.disconnect();return;}if(width!==graph.clientWidth){width=graph.clientWidth;if(activeGraph)drawBundle(graph,activeGraph);}});observer.observe(graph);
    async function load(){
      retry.disabled=true;activeGraph=null;graph.replaceChildren();delete panel.dataset.source;delete panel.dataset.ready;
      try{
        const catalog=await json(new URL(root.dataset.combatCatalog||'../../assets/dps-catalog.json',location.href));
        let latest=null,failed=false;
        try{latest=(await json('/api/auth/balance?latest=combat')).record;}catch(e){failed=true;status.textContent=`확정안 조회 실패: ${e.message}. 아래는 별도의 현행 구현 기준값입니다.`;}
        const fingerprint=await SFHBalance.fingerprint(catalog.sources);
        if(latest&&latest.source===fingerprint&&latest.model_version===SFHBalance.version){
          status.textContent=`기본값: 기획 확정 · ${latest.title} · ${latest.confirmed_at}. 오너 승인·게임 적용과 별도입니다.`;render(latest.graph);panel.dataset.source='confirmed';
        }else{
          if(!failed)status.textContent=latest?'기획 확정본의 코드/계산 모델이 달라 재검토가 필요합니다. 현재 구현값을 기본으로 표시합니다.':'전투 기획 확정본이 없습니다. 현재 구현값을 기본으로 표시합니다.';
          const input=SFHDps.defaults(catalog,catalog.weapons.some(w=>w.id==='assault_rifle')?'assault_rifle':catalog.weapons[0].id,catalog.skills[0]?.skill_id||'');
          render(SFHBalance.calculate('combat',catalog,input));panel.dataset.source='implemented';
        }
        panel.dataset.ready='true';
      }catch(e){status.textContent=`전투 그래프 연결 실패: ${e.message}`;delete panel.dataset.ready;}
      finally{retry.disabled=false;}
    }
    retry.addEventListener('click',load);load();return load;
  }
  async function workbench(root){
    if(root.dataset.mounted)return;root.dataset.mounted='true';root.classList.add('dps-lab');
    try{
      const catalog=await json(new URL(root.dataset.catalog,location.href));root.replaceChildren();
      const mode=el('select');[['table','전체 수치 목록'],['facility','시설 위험·스폰'],['recovery','투입·회수 시나리오']].forEach(([id,name])=>{const o=el('option',name);o.value=id;mode.append(o);});root.append(label('계산 대상',mode));
      const controls=el('div');controls.className='balance-controls';root.append(controls);
      const error=el('p');error.setAttribute('role','alert');error.hidden=true;root.append(error);
      const graph=el('div');root.append(graph);let input={},valid=false;
      function update(){try{const result=SFHBalance.calculate(mode.value,catalog,input);draw(graph,result);graph.hidden=false;error.hidden=true;valid=true;root.dataset.ready='true';}catch(e){error.textContent=e.message;error.hidden=false;graph.hidden=true;valid=false;}}
      function field(key,name,value,min,max,parent=controls){const n=el('input');n.type='number';n.min=min;n.max=max;n.step='any';n.value=value;input[key]=value;n.addEventListener('input',()=>{input[key]=n.value===''?NaN:Number(n.value);update();});parent.append(label(name,n));return n;}
      function load(){
        controls.replaceChildren();input={};
        if(mode.value==='table'){
          const dataset=el('select'),column=el('select'),rows=el('div'),source=el('p');rows.className='balance-rows';
          catalog.datasets.forEach(d=>{const o=el('option',`${d.title} · ${d.id}`);o.value=d.id;dataset.append(o);});
          controls.append(label('수치 목록',dataset),label('변수 열',column),source,rows);
          const renderRows=()=>{rows.replaceChildren();const d=catalog.datasets.find(d=>d.id===dataset.value);input={dataset:d.id,column:column.value,values:structuredClone(d.columns[column.value])};source.textContent=`${d.source} · CSV ${catalog.version}. 이름·ID·문자열 열은 원본에서 편집합니다. 음수 허용 여부 등 게임별 검증은 CSV 적용 시 별도로 수행합니다.`;
            input.values.forEach(p=>{const n=el('input');n.type='number';n.step='any';n.value=p.value;n.addEventListener('input',()=>{p.value=n.value===''?NaN:Number(n.value);update();});rows.append(label(d.labels[p.id],n));});update();};
          const changeDataset=()=>{column.replaceChildren();const d=catalog.datasets.find(d=>d.id===dataset.value);Object.keys(d.columns).forEach(key=>{const o=el('option',`${d.column_labels[key]} · ${key}`);o.value=key;column.append(o);});renderRows();};
          dataset.addEventListener('change',changeDataset);column.addEventListener('change',renderRows);changeDataset();
        }else if(mode.value==='facility'){
          field('minimum','기본 최소 적 수',12,1,500);field('maximum','기본 최대 적 수',18,1,500);field('risk','시설 risk_bonus',.25,0,2);field('capacity','잔여 동시 수용량',36,0,1000);update();
        }else{
          field('cost','투입 크레딧 C',100,0,1e6);field('minimum','최소 회수 배수 (가정)',2.5,0,100);field('maximum','최대 회수 배수 (가정)',5,0,100);field('success','생환율 가정 (0~1)',.5,0,1);update();
        }
      }
      mode.addEventListener('change',load);load();
      const reset=button('현재 원본으로 초기화');reset.addEventListener('click',load);root.append(reset);
      confirmation(root,()=>valid?{model:mode.value,sources:catalog.sources,input:structuredClone(input)}:null);
      let width=root.clientWidth;const observer=new ResizeObserver(()=>{if(!root.isConnected){observer.disconnect();return;}if(width!==root.clientWidth){width=root.clientWidth;update();}});observer.observe(root);
    }catch(e){root.textContent=`계산기 연결 실패: ${e.message}`;const retry=button('다시 불러오기');retry.addEventListener('click',()=>{delete root.dataset.mounted;workbench(root);});root.append(retry);}
  }
  // Read-only repository snapshot; never synthesizes or saves a planner confirmation.
  function currentBalance(root,path){
    const panel=el('details');panel.className='balance-current';panel.append(el('summary','현행 밸런스 데이터 · CSV 기준값'));
    const body=el('div');panel.append(body);root.append(panel);
    let loaded=false,busy=false;
    async function load(){
      if(loaded||busy)return;busy=true;body.textContent='현행 CSV 읽는 중…';
      try{
        const catalog=await json(new URL(path,location.href));
        if(!catalog.datasets?.length)throw Error('수치 목록이 비어 있습니다.');
        body.replaceChildren(el('p',`현행 CSV ${catalog.version} · ${catalog.datasets.length}개 수치 목록. 기획 확정 여부와 별개의 저장소 기준값입니다. 실시간 Sheet 시험값·실행 중 세이브 보정값은 포함하지 않습니다.`));
        const controls=el('div');controls.className='balance-controls';
        const dataset=el('select'),column=el('select'),source=el('p'),graph=el('div');source.className='dps-source';
        catalog.datasets.forEach(d=>{const o=el('option',`${d.title} · ${d.id}`);o.value=d.id;dataset.append(o);});
        controls.append(label('현행 수치 목록',dataset),label('현행 변수 열',column));body.append(controls,source,graph);
        function render(){
          const d=catalog.datasets.find(d=>d.id===dataset.value);
          source.textContent=`${d.source} · ${column.value} · ${d.column_labels[column.value]} · SHA-256 ${catalog.sources[d.source]}`;
          const result=SFHBalance.calculate('table',catalog,{dataset:d.id,column:column.value,values:d.columns[column.value]});
          result.note='청록선 = 현행 CSV 수치. 행별 비교이며 합산 DPS·실제 난이도를 의미하지 않습니다. 아래 표에서 원본 정밀도의 값을 확인하세요.';
          draw(graph,result,true);panel.dataset.ready='true';
        }
        function choose(){const d=catalog.datasets.find(d=>d.id===dataset.value);column.replaceChildren();Object.keys(d.columns).forEach(key=>{const o=el('option',`${d.column_labels[key]} · ${key}`);o.value=key;column.append(o);});render();}
        dataset.addEventListener('change',choose);column.addEventListener('change',render);choose();loaded=true;
        let width=body.clientWidth;const observer=new ResizeObserver(()=>{if(!body.isConnected){observer.disconnect();return;}if(width!==body.clientWidth){width=body.clientWidth;render();}});observer.observe(body);
      }catch(e){body.textContent=`현행 데이터 연결 실패: ${e.message}`;const retry=button('현행 데이터 다시 불러오기');retry.addEventListener('click',load);body.append(retry);}
      finally{busy=false;}
    }
    panel.addEventListener('toggle',()=>{if(panel.open)load();});return panel;
  }
  async function gallery(root){
    if(root.dataset.mounted)return;root.dataset.mounted='true';root.classList.add('dps-lab');
    root.replaceChildren();const refresh=button('확정 그래프 새로고침'),list=el('div'),more=button('이전 확정본 더 보기'),status=el('p');status.setAttribute('role','status');more.hidden=true;root.append(refresh,status,list,more);
    const refreshCombat=currentCombat(root);
    root.insertBefore(root.querySelector('.balance-combat-default'),list);
    const baseline=currentBalance(root,root.dataset.catalog);let cursor=null;
    async function load(reset){
      refresh.disabled=more.disabled=true;
      try{
        const data=await json('/api/auth/balance'+(!reset&&cursor?`?cursor=${encodeURIComponent(cursor)}`:''));
        if(reset)list.replaceChildren();
        for(const record of data.records){
          const details=el('details');details.append(el('summary',`${record.title} · ${record.confirmed_at}`));list.append(details);
          details.addEventListener('toggle',async()=>{if(!details.open||details.dataset.loaded)return;details.dataset.loaded='true';
            try{const saved=await json(`/api/auth/balance?id=${encodeURIComponent(record.id)}`);const host=el('div');details.append(el('p',`기획 확정 · 오너 승인 대기 · 게임 미적용 · 모델 v${saved.model_version}`),host);drawBundle(host,saved.graph);
              const evidence=el('p',saved.reason),link=el('a','Notion 기획 근거');link.href=saved.notion;link.rel='noopener';details.append(evidence,link);
              let width=host.clientWidth;const observer=new ResizeObserver(()=>{if(!host.isConnected){observer.disconnect();return;}if(width!==host.clientWidth){width=host.clientWidth;drawBundle(host,saved.graph);}});observer.observe(host);
            }catch(e){details.append(el('p',`읽기 실패: ${e.message}. 새로고침으로 다시 시도하세요.`));}
          });
        }
        cursor=data.cursor;more.hidden=!cursor;status.textContent=list.children.length?'저장된 기획 확정안을 먼저 표시합니다. 아직 확정하지 않은 항목은 아래 현행 CSV에서 조회하세요. 확정안과 현행값의 자동 대체·게임 적용은 하지 않습니다.':'기획자가 저장한 확정본이 아직 없습니다. 현행 CSV 밸런스 데이터를 표시합니다. 기획 확정값은 아닙니다.';
        if(reset)baseline.open=!list.children.length;
      }catch(e){status.textContent=`확정본 연결 실패: ${e.message}. 확정본 유무를 판단할 수 없습니다. 아래 현행 CSV는 별도 기준 자료입니다.`;baseline.open=true;}finally{refresh.disabled=more.disabled=false;}
    }
    refresh.addEventListener('click',()=>{load(true);refreshCombat();});more.addEventListener('click',()=>load(false));load(true);
  }
  const init=()=>{
    document.querySelectorAll('[data-sfh-balance-workbench]').forEach(workbench);
    document.querySelectorAll('[data-sfh-balance-gallery]').forEach(gallery);
    document.querySelectorAll('[data-sfh-dps-lab][data-confirmable]').forEach(root=>{if(root.dataset.confirmMounted||!root.sfhBalanceTrial)return;root.dataset.confirmMounted='true';confirmation(root,()=>root.sfhBalanceTrial);});
  };
  document.addEventListener('sfh-balance-trial',init);
  if(typeof document$!=='undefined')document$.subscribe(init);
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();
