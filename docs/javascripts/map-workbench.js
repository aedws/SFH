(function(){
  'use strict';
  const node=(tag,text)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;return n;};
  function mount(host,catalog){
    host.replaceChildren();host.classList.add('sfh-map-workbench');
    let facilities=structuredClone(catalog.facilities),plan,selected=0;
    const status=node('p');status.setAttribute('role','status');
    const controls=node('div');controls.className='sfh-map-controls';
    function select(label,options){const wrap=node('label',label),s=node('select');s.setAttribute('aria-label',label);for(const [v,t] of options){const o=node('option',t);o.value=v;s.append(o);}wrap.append(s);controls.append(wrap);return s;}
    const region=select('지역',catalog.regions.map(r=>[r.id,r.name]));
    const tier=select('규모',[['small','소형'],['medium','중형'],['large','대형']]);
    const seedLabel=node('label','시드'),seed=node('input');seed.type='number';seed.min='0';seed.max='2147483646';seed.step='1';seed.value='90808';seedLabel.append(seed);controls.append(seedLabel);
    function button(text,action,parent=controls){const b=node('button',text);b.type='button';b.addEventListener('click',action);parent.append(b);return b;}
    button('다른 시드',()=>{seed.value=String((Number(seed.value)+7919)%2147483647);change();});
    button('현행 피스로 복원',()=>{facilities=structuredClone(catalog.facilities);change();});
    const legend=node('p','S 시작 · E 탈출 · ◆ 필수 피스 · 숫자 보조 시설 / 선: 도로·출입 연결');
    const body=node('div');body.className='sfh-map-body';
    const mapHost=node('div');mapHost.className='sfh-map-canvas';
    const detail=node('section');detail.className='sfh-map-detail';
    const roomLabel=node('label','공간 선택 (지도 클릭과 동일)'),room=node('select');room.setAttribute('aria-label','공간 선택 (지도 클릭과 동일)');roomLabel.append(room);detail.append(roomLabel);
    const info=node('p'),editor=node('div');detail.append(info,editor);
    body.append(mapHost,detail);
    const invariant=node('p');invariant.className='sfh-map-invariants';
    const draft=node('details');draft.append(node('summary','아이디어 정리 · Notion에 전달'));
    draft.append(node('p','이 브라우저에서 초안을 작성합니다. 복사한 내용을 Notion에 붙여 공유하세요. 자동 제출·승인·게임 적용 기능이 아닙니다.'));
    const notesLabel=node('label','목적 → 기대 경험 → 확인 기준'),notes=node('textarea');notes.rows=4;notes.maxLength=4000;notes.placeholder='예: 의료 구역을 북쪽에 고정. 두 번째 출격에서 길 찾는 시간이 줄어드는지 비교. 치료 기능은 별도 제안.';notesLabel.append(notes);draft.append(notesLabel);
    const sourceLabel=node('label','근거 Notion 주소 (선택)'),source=node('input');source.type='url';source.placeholder='https://…notion.site/…';sourceLabel.append(source);draft.append(sourceLabel);
    const output=node('textarea');output.rows=8;output.readOnly=true;output.setAttribute('aria-label','Notion에 붙일 제안 초안');
    const draftStatus=node('p');draftStatus.setAttribute('role','status');
    button('제안 초안 만들기',()=>{
      try{render();if(!plan)return;
        if(source.value){const u=new URL(source.value);if(u.protocol!=='https:'||!/(^|\.)(notion\.site|notion\.so)$/.test(u.hostname))throw Error('근거는 HTTPS Notion 주소로 입력하세요.');}
        output.value=window.SFHMapModel.proposal(catalog,region.value,tier.value,Number(seed.value),facilities,notes.value,source.value);draftStatus.textContent='작성 완료 · 복사한 뒤 Notion에서 공유해야 전달됩니다.';
      }catch(e){draftStatus.textContent=e.message;}
    },draft);
    button('초안 복사',async()=>{if(!output.value){draftStatus.textContent='먼저 초안을 만드세요.';return;}try{await navigator.clipboard.writeText(output.value);draftStatus.textContent='복사 완료 · Notion에 붙여 공유하세요.';}catch(_){output.focus();output.select();draftStatus.textContent='자동 복사가 제한됐습니다. 선택된 초안을 직접 복사하세요.';}},draft);
    draft.append(output,draftStatus);
    host.append(controls,status,legend,body,invariant,draft,node('p','범위: 실제 게임과 같은 건물·도로·필수 피스 배치. 적·장애물·드랍·전투 난이도는 시뮬레이션하지 않습니다. 시드 0은 미리보기에서 재현 가능하지만 게임에서는 자동 시드입니다.'));
    function change(){output.value='';draftStatus.textContent='설정이 변경되었습니다. 초안을 다시 만드세요.';render();}
    [region,tier,seed].forEach(n=>n.addEventListener('change',change));
    room.addEventListener('change',()=>{selected=Number(room.value);showDetail();highlight();});
    function highlight(){mapHost.querySelectorAll('[data-room]').forEach(n=>n.classList.toggle('selected',Number(n.dataset.room)===selected));}
    function showDetail(){
      const b=plan.buildings[selected],r=facilities.find(r=>r.facility_id===b.facility_id);room.value=String(selected);editor.replaceChildren();
      info.textContent=`${r.display_name} · ${b.required?'필수 기준점':'보조 배치'} · ${b.rect[2]}×${b.rect[3]}칸 · ${b.axis==='horizontal'?'좌우':'상하'} 출입구. ${r.planner_note}`;
      const box=node('label'),required=node('input');required.type='checkbox';required.checked=r.required_regions==='*'||r.required_regions.split('|').includes(region.value);required.disabled=r.encounter==='objective';box.append(required,document.createTextNode(' 이 지역 필수 피스'));editor.append(box);
      const description=node('small','아래는 선택한 한 건물이 아니라 같은 종류의 피스 규칙을 시험합니다. 시작·탈출·도로·금고 수는 바꾸지 않습니다.');editor.append(description);
      required.addEventListener('change',()=>{
        let ids=r.required_regions==='*'?catalog.regions.map(x=>x.id):r.required_regions.split('|').filter(x=>x!=='none'&&x!==region.value);
        ids=ids.filter(x=>x!==region.value);if(required.checked)ids.push(region.value);r.required_regions=ids.join('|')||'none';change();
      });
      const fields=[['anchor_zone','필수 위치',[['west','서쪽'],['east','동쪽'],['north','북쪽'],['south','남쪽'],['center','중앙']]],['entrance_axis','필수 출입 방향',[['horizontal','좌우'],['vertical','상하']]]];
      for(const [key,label,options] of fields){const wrap=node('label',label),s=node('select');s.setAttribute('aria-label',label);for(const [v,t] of options){const o=node('option',t);o.value=v;s.append(o);}s.value=r[key];s.disabled=!required.checked;s.addEventListener('change',()=>{r[key]=s.value;change();});wrap.append(s);editor.append(wrap);}
      for(const [key,label] of [['shape_x','필수 가로 비율'],['shape_y','필수 세로 비율']]){const wrap=node('label',label),n=node('input');n.type='range';n.min='0';n.max='1';n.step='.05';n.value=r[key];n.disabled=!required.checked;const value=node('output',String(r[key]));n.addEventListener('input',()=>value.textContent=n.value);n.addEventListener('change',()=>{r[key]=Number(n.value);change();});wrap.append(n,value);editor.append(wrap);}
    }
    function render(){
      try{
        plan=window.SFHMapModel.build(catalog.tiers[tier.value],region.value,Number(seed.value),facilities);
        selected=Math.min(selected,plan.count-1);
        status.textContent=`${JSON.stringify(facilities)===JSON.stringify(catalog.facilities)?'현행 CSV':'시험 변경 · 미적용'} ${catalog.version} · 시드 ${plan.seed} · ${plan.count}개 건물`;
        const ns='http://www.w3.org/2000/svg',svg=document.createElementNS(ns,'svg');svg.setAttribute('viewBox',`0 0 ${plan.columns*plan.stride[0]+8} ${plan.rows*plan.stride[1]+8}`);svg.setAttribute('role','img');svg.setAttribute('aria-label','지역 건물과 연결 도로. 아래 공간 선택 목록으로 모든 건물을 확인할 수 있습니다.');
        const rect=(bounds,cls)=>{const n=document.createElementNS(ns,'rect');['x','y','width','height'].forEach((k,i)=>n.setAttribute(k,bounds[i]));n.setAttribute('class',cls);svg.append(n);return n;};
        [...plan.streets,...plan.passages].forEach(r=>rect(r,'road'));
        room.replaceChildren();
        for(const b of plan.buildings){const r=facilities.find(r=>r.facility_id===b.facility_id),symbol=b.index===0?'S':plan.exits.includes(b.index)?'E':b.required?'◆':String(b.index+1);
          const shape=rect(b.rect,`building ${b.required?'required':''} ${b.index===0?'start':''} ${plan.exits.includes(b.index)?'exit':''}`);shape.dataset.room=b.index;shape.addEventListener('click',()=>{selected=b.index;showDetail();highlight();});
          const title=document.createElementNS(ns,'title');title.textContent=`${symbol} ${r.display_name}`;shape.append(title);
          const text=document.createElementNS(ns,'text');text.setAttribute('x',b.rect[0]+b.rect[2]/2);text.setAttribute('y',b.rect[1]+b.rect[3]/2);text.textContent=symbol;svg.append(text);
          const o=node('option',`${symbol} · ${r.display_name} · ${b.required?'필수':'보조'}`);o.value=b.index;room.append(o);
        }
        mapHost.replaceChildren(svg);showDetail();highlight();
        invariant.textContent=`유지: 시작 1 · 출구 2 · 순환 도로 · 건물당 출입구 2 · 선택 금고 1 / 필수 피스: ${plan.buildings.filter(b=>b.required).map(b=>facilities.find(r=>r.facility_id===b.facility_id).display_name).join(', ')}`;
      }catch(e){plan=null;status.textContent=e.message;mapHost.replaceChildren();info.textContent='입력값을 수정하세요.';editor.replaceChildren();invariant.textContent='생성하지 못했습니다.';}
    }
    render();
  }
  function scan(){document.querySelectorAll('[data-sfh-map-workbench]:not([data-mounted])').forEach(host=>{host.dataset.mounted='true';fetch(new URL(host.dataset.catalog,location.href),{credentials:'same-origin',cache:'no-cache'}).then(r=>{if(!r.ok)throw Error('카탈로그 접근 실패');return r.json();}).then(c=>{if(host.isConnected)mount(host,c);}).catch(()=>{host.textContent='맵 자료를 불러오지 못했습니다. 로그인 상태를 확인하고 새로고침하세요.';delete host.dataset.mounted;});});}
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',scan);else scan();
  if(typeof document$!=='undefined')document$.subscribe(scan);
})();
