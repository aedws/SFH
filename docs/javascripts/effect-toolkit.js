/* Role-scoped authoring UI. Network reads only; explicit copying, no remote writes. */
(() => {
  'use strict';
  const el=(tag,text)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;return n;};
  const labelled=(title,node)=>{const label=el('label',title);node.setAttribute('aria-label',title);label.append(node);return label;};
  const select=items=>{const n=el('select');for(const [id,title]of items){const o=el('option',title);o.value=id;n.append(o);}return n;};
  async function mount(root){
    if(root.dataset.mounted)return;root.dataset.mounted='true';root.classList.add('dps-lab','effect-toolkit');
    try{
      const response=await fetch(new URL(root.dataset.catalog,location.href),{credentials:'same-origin',cache:'no-store'});
      if(!response.ok)throw Error('로그인과 원본 연결을 확인하세요.');const catalog=await response.json(),E=globalThis.SFHEffectToolkit;
      const readonly=root.dataset.readonly==='true';root.replaceChildren();
      root.append(el('p',`현재 CSV ${catalog.version} · 지원 변수 ${catalog.fields.length}종 · 노션/시트 입력은 자동 배포가 아닙니다.`));
      const controls=el('div');controls.className='balance-controls';
      const kind=select([['skill','스킬'],['weapon','무기'],['character','캐릭터'],['module','모듈']]),field=el('select'),target=el('select'),value=el('input');
      controls.append(labelled('대상 종류',kind),labelled('효과·스탯',field),labelled('대상 ID',target));root.append(controls);
      const detail=el('p');detail.className='dps-note';root.append(detail);
      const values=el('div');root.append(values);
      const evidence=el('details');evidence.append(el('summary','구현 원본·변경 경로'));const paths=el('p');paths.className='dps-source';evidence.append(paths);root.append(evidence);
      let record=null,editor=value;
      const draft=el('div');draft.className='balance-controls';
      const id=el('input'),notion=el('input'),intent=el('textarea'),acceptance=el('textarea'),status=select(E.states.map(s=>[s,({draft:'초안',provisional:'임시',confirmed:'기획 확정',hold:'보류'})[s]]));
      id.value='effect-spec-001';notion.type='url';intent.maxLength=acceptance.maxLength=3000;
      draft.append(labelled('명세 ID',id),labelled('기획 상태',status),labelled('Notion 근거 링크',notion),labelled('기획 의도',intent),labelled('플레이 수락 조건',acceptance));
      const generate=el('button','명세 검증·노션 작성문 생성');generate.type='button';
      const error=el('p');error.setAttribute('role','alert');error.hidden=true;
      const output=el('textarea');output.readOnly=true;output.setAttribute('aria-label','노션 작성문');output.rows=12;
      const result=el('div');result.hidden=true;const summary=el('p');summary.setAttribute('role','status');
      const csv=el('textarea');csv.readOnly=true;csv.rows=5;csv.setAttribute('aria-label','EffectSpec CSV');
      const copy=el('button','노션 작성문 복사');copy.type='button';
      result.append(summary,labelled('노션에 붙여 넣기',output),copy,labelled('EffectSpec CSV (가져오기용)',csv));
      if(!readonly)root.append(draft,generate,error,result);
      else root.append(el('p','개발자는 원본·동작·변경 경로를 조회합니다. EffectSpec을 내려받아 검증한 계획은 승인·구현·E2E 근거와 함께 검토하세요.'));
      function stale(){result.hidden=true;record=null;}
      function show(){
        stale();const f=catalog.fields.find(f=>f.id===field.value),t=f?.targets.find(t=>t.id===target.value);
        values.replaceChildren();
        if(!f||!t)return;
        detail.textContent=`${f.effect} · 현재 ${t.current} ${f.unit}. ${f.choices?'선택: '+f.choices.join(' / '):`입력 범위 ${f.minimum}~${f.maximum} ${f.unit}${f.integer?' (정수)':''}`}`;
        paths.textContent=t.bindings.map(b=>`${b.path} / ${b.section||JSON.stringify(b.selector)} / ${b.field}`).join('\n');
        if(readonly){values.append(el('strong',`현행값: ${t.current} ${f.unit}`));return;}
        editor=f.choices?select(f.choices.map(v=>[v,v])):el('input');
        if(!f.choices){editor.type='number';editor.min=f.minimum;editor.max=f.maximum;editor.step=f.integer?'1':'any';}
        editor.value=t.current;editor.addEventListener('input',stale);editor.addEventListener('change',stale);values.append(labelled('요청값',editor));
      }
      function targets(){target.replaceChildren();const f=catalog.fields.find(f=>f.id===field.value);f?.targets.forEach(t=>{const o=el('option',`${t.name} · ${t.id}`);o.value=t.id;target.append(o);});show();}
      function fields(){field.replaceChildren();catalog.fields.filter(f=>f.kind===kind.value).forEach(f=>{const o=el('option',f.label+' · '+f.id);o.value=f.id;field.append(o);});targets();}
      kind.addEventListener('change',fields);field.addEventListener('change',targets);target.addEventListener('change',show);draft.addEventListener('input',stale);draft.addEventListener('change',stale);fields();
      generate.addEventListener('click',()=>{try{
        record={spec_id:id.value.trim(),status:status.value,target_kind:kind.value,target_id:target.value,field_id:field.value,value:editor.value,
          notion_url:notion.value.trim(),intent:intent.value.trim(),acceptance:acceptance.value.trim(),owner_status:'pending',source_fingerprint:catalog.fingerprint};
        output.value=E.markdown([record],catalog);csv.value=E.csv([record]);error.hidden=true;result.hidden=false;summary.textContent='명세 검증 완료 · 오너 판단 대기 · 게임 미적용';
      }catch(e){stale();error.textContent=e.message;error.hidden=false;}});
      copy.addEventListener('click',async()=>{if(!record)return;try{await navigator.clipboard.writeText(output.value);summary.textContent='복사 완료 · Notion에 붙여 넣으세요.';}catch{output.focus();output.select();summary.textContent='자동 복사가 차단되었습니다. 선택된 작성문을 직접 복사하세요.';}});
      root.dataset.ready='true';
    }catch(e){root.textContent=`효과 툴킷 연결 실패: ${e.message}`;const retry=el('button','툴킷 다시 불러오기');retry.type='button';retry.addEventListener('click',()=>{delete root.dataset.mounted;mount(root);});root.append(retry);}
  }
  const init=()=>document.querySelectorAll('[data-sfh-effect-toolkit]').forEach(mount);
  if(typeof document$!=='undefined')document$.subscribe(init);
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();
