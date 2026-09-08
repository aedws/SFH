/* Growth presentation; trial edits never alter the current implementation. */
(() => {
  const el=(tag,text)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;return n;};
  const label=(name,node)=>{const l=el('label',name);node.setAttribute('aria-label',name);l.append(node);return l;};
  async function mount(root){
    if(root.dataset.mounted)return;root.dataset.mounted='true';root.classList.add('dps-lab');
    try{
      const response=await fetch(new URL(root.dataset.catalog,location.href),{credentials:'same-origin',cache:'no-cache'});
      if(!response.ok)throw Error('성장 원본을 읽지 못했습니다.');const c=await response.json();root.replaceChildren();
      const kind=root.dataset.kind,editable=root.hasAttribute('data-editable'),select=el('select'),metric=el('select');
      for(const e of SFHGrowth.entities(c,kind)){const o=el('option',e.name);o.value=e.id;select.append(o);}
      for(const [id,name]of Object.entries(SFHGrowth.metrics[kind])){const o=el('option',name);o.value=id;metric.append(o);}
      if(kind==='armor'&&SFHGrowth.entities(c,kind).some(e=>e.id==='tactical_vest'))select.value='tactical_vest';
      const controls=el('div');controls.className='balance-controls';controls.append(label('성장 대상 하나 선택',select),label('성장 지표',metric));root.append(controls);
      const status=el('p'),graph=el('div'),table=el('div'),editor=el('details'),fields=el('div');status.setAttribute('role','status');table.className='dps-table-scroll';fields.className='balance-rows';
      const numbers=el('details');numbers.append(el('summary','성장 수치·증가율 표'),table);
      editor.append(el('summary','선택한 대상의 단계별 목표값 수정'),fields);if(editable)root.append(editor);root.append(status,graph,numbers);
      let input,valid=false,rendered;
      function update(){
        try{rendered=SFHGrowth.calculate(c,input);valid=true;SFHBalanceView.draw(graph,rendered,false,true);
          const first=rendered.points[0],last=rendered.points.at(-1),rate=last.growth===null?'기준값 0 · 성장률 정의 불가':`${last.growth.toFixed(1)}%`;
          status.textContent=`${rendered.title} · 1단계 ${first.value.toFixed(2)} → ${last.x}단계 ${last.value.toFixed(2)} · 증가량 ${(last.value-first.value).toFixed(2)} · 성장률 ${rate}`;
          const t=el('table'),head=el('tr');['단계','현재 구현','시험 / 표시값','1단계 대비 증가량','성장률'].forEach(v=>head.append(el('th',v)));t.append(head);
          for(const p of rendered.points){const row=el('tr');[p.x,p.base.toFixed(2),p.value.toFixed(2),p.increase.toFixed(2),p.growth===null?'기준 0':p.growth.toFixed(1)+'%'].forEach(v=>row.append(el('td',v)));t.append(row);}table.replaceChildren(t);root.dataset.ready='true';
        }catch(e){valid=false;rendered=null;graph.replaceChildren();table.replaceChildren();status.textContent=e.message;}
      }
      function reset(){input={kind,entityId:select.value,metric:metric.value};fields.replaceChildren();
        input.values=SFHGrowth.baseline(c,input).values;
        if(editable)input.values.forEach((v,n)=>{const f=el('input');f.type='number';f.min='0';f.max='10000000';f.step='any';f.value=v;f.addEventListener('input',()=>{input.values[n]=f.value===''?NaN:Number(f.value);update();});fields.append(label(`${n+1}단계 목표값`,f));});update();}
      select.addEventListener('change',reset);metric.addEventListener('change',reset);reset();
      if(editable){root.append(el('p','목표값은 기획 제안입니다. 성장 수식·CSV의 자동 변경이 아니며 확정 후 구현 검토가 필요합니다.'));SFHBalanceConfirm(root,()=>valid?{model:'growth',sources:c.sources,input:structuredClone(input)}:null);}
      let width=graph.clientWidth;const observer=new ResizeObserver(()=>{if(!root.isConnected){observer.disconnect();return;}if(width!==graph.clientWidth){width=graph.clientWidth;if(rendered)SFHBalanceView.draw(graph,rendered,false,true);}});observer.observe(graph);
    }catch(e){root.textContent=e.message;const retry=el('button','성장 원본 다시 불러오기');retry.addEventListener('click',()=>{delete root.dataset.mounted;mount(root);});root.append(retry);}
  }
  const init=()=>document.querySelectorAll('[data-sfh-growth-lab]').forEach(mount);
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();if(typeof document$!=='undefined')document$.subscribe(init);
})();
