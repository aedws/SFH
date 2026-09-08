/* Editable planner trial, immutable confirmation export, implemented-only developer view. */
(() => {
  'use strict';
  const el=(tag,text)=>{const n=document.createElement(tag);if(text!==undefined)n.textContent=text;return n;};
  const label=(text,node)=>{const n=el('label',text);node.setAttribute('aria-label',text);n.append(node);return n;};
  async function mount(root){
    if(root.dataset.mounted)return;root.dataset.mounted='true';
    try{
      const response=await fetch(new URL(root.dataset.catalog,location.href),{credentials:'same-origin',cache:'no-cache'});
      if(!response.ok)throw Error('현재 무기 원본을 읽지 못했습니다.');const catalog=await response.json();
      const editable=root.hasAttribute('data-editable');root.replaceChildren();root.classList.add('dps-lab');
      const select=el('select');for(const w of catalog.weapons){const o=el('option',w.name);o.value=w.id;select.append(o);}
      root.append(label('거리 곡선 무기',select),el('p',editable?'시험값은 저장 전까지 이 화면에만 존재합니다. 확정본에는 곡선과 계산 조건이 함께 보관됩니다.':'현재 게임에 적용된 거리 곡선만 표시합니다. 기획 시험·확정안은 이 그래프를 바꾸지 않습니다.'));
      let input,valid=false,activeGraph;const controls=el('div'),graph=el('div'),status=el('p');status.setAttribute('role','status');root.append(controls,status,graph);
      function render(){
        try{activeGraph=SFHBalance.calculate('distance',catalog,input);SFHBalanceView.draw(graph,activeGraph);valid=true;
          status.textContent=`${editable?'시험':'현행 구현'} · 사거리 ${SFHDps.resolve(catalog,input).range.toFixed(0)} px · ${input.distanceCurve}`;
          if(!editable)root.dataset.source='implemented';root.dataset.ready='true';
        }catch(e){valid=false;activeGraph=null;graph.replaceChildren();status.textContent=e.message;}
      }
      function reset(){input=SFHDps.defaults(catalog,select.value);controls.replaceChildren();
        if(editable){const field=el('input');field.type='text';field.value=input.distanceCurve;field.maxLength=512;
          controls.append(label('거리:피해 배율 제어점',field),el('p','거리 0~1, 배율 0~3. 예: 0:1;0.5:1.2;1:0.6 · 0%에서 100%, 2~16점 선형 연결. 숫자를 바꾸면 그래프가 즉시 갱신됩니다.'));
          field.addEventListener('input',()=>{input.distanceCurve=field.value;render();});
          const editor=globalThis.SFHLoadoutUI.mount(controls,catalog,select.value,()=>{input.loadout=editor.read();render();});
        }render();}
      select.addEventListener('change',reset);reset();
      let width=graph.clientWidth;const resized=new ResizeObserver(()=>{if(!root.isConnected){resized.disconnect();return;}if(width!==graph.clientWidth){width=graph.clientWidth;if(activeGraph)SFHBalanceView.draw(graph,activeGraph);}});resized.observe(graph);
      if(editable){SFHBalanceConfirm(root,()=>valid?{model:'distance',sources:catalog.sources,input:structuredClone(input)}:null);
        root.addEventListener('sfh-confirmed',event=>{const record=event.detail;if(record.submission?.model!=='distance')return;
          root.querySelector('[data-distance-export]')?.remove();const box=el('div');box.dataset.distanceExport='true';
          box.append(el('p','저장된 확정 곡선 전달 파일. 이후 화면을 수정해도 이 파일은 변경되지 않습니다. 오너 승인 후 CSV 적용·테스트·배포가 필요합니다.'));
          const a=el('a','확정 곡선 JSON 다운로드');const blob=new Blob([JSON.stringify(record,null,2)],{type:'application/json'});const url=URL.createObjectURL(blob);a.href=url;a.download=`weapon-distance-${record.id}.json`;box.append(a);root.append(box);
        });
      }
    }catch(e){root.textContent=e.message;}
  }
  const init=()=>document.querySelectorAll('[data-sfh-distance-lab]').forEach(mount);
  if(typeof document!=='undefined'){document.readyState==='loading'?document.addEventListener('DOMContentLoaded',init):init();document.addEventListener('sfh-workspace-ready',init);if(typeof document$!=='undefined')document$.subscribe(init);}
})();
