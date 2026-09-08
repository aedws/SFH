/* DOM adapter only. Catalog is fetched behind wiki authentication; trials stay in memory. */
(() => {
  'use strict';
  const groups = [
    ['무기 시험값', [['damage','탄환 기본 피해'],['distancePx','표적 거리 (px)'],['interval','마지막 발사 후 대기 (초)'],['crit','치명 확률 (0~1)'],['critMultiplier','치명 배율']]],
    ['스킬 시험값', [['skillDamage','1회 / 틱 기본 피해'],['skillCooldown','쿨타임 (초)'],['skillDuration','지속 시간 (초)'],['skillTick','틱 간격 (초)'],['skillCost','시전 AP'],['charges','최대 충전 수'],['recharge','충전 회복 (초)']]],
    ['적과 비교 조건', [['hp','적 체력'],['armor','적 방어막 (피해 흡수량)'],['enemyDamage','적 접촉 피해'],['enemyInterval','적 접촉 공격 간격 (초)'],['targetTime','목표 처치 시간 (초)'],['horizon','관측 시간 (초 · 정수)'],['hitRate','탄환 명중 비율 (0~1)'],['coverage','스킬 적중 / 체류 비율 (0~1)']]],
    ['고급 · 장비와 자원', [['burst','점사 발수'],['burstInterval','점사 내 발사 간격 (초)'],['projectiles','발사당 탄환 수'],['damageAdd','추가 피해 합'],['damageMultiplier','피해 보정 곱'],['intervalMultiplier','발사 간격 보정 곱'],['level','내부 무기 레벨'],['skillMultiplier','스킬 피해 보정 곱'],['energy','시작 AP'],['maxEnergy','최대 AP'],['regen','AP 초당 회복'],['regenDelay','AP 사용 후 회복 지연 (초)']]],
  ];
  const switches = [['fixedOptions','무기 고정 옵션 적용'],['innate','무기 고유 기능 · 주 대상 피해 포함'],['resourceLimits','AP·충전 제한 적용'],['shock','매 시전 직전 감전 상태가 있다고 가정']];
  const scenarioKeys=['distancePx','hp','armor','enemyDamage','enemyInterval','targetTime','horizon','hitRate','coverage','energy','maxEnergy','regen','regenDelay','resourceLimits','shock'];
  const f = value => Number(value).toLocaleString('ko-KR',{maximumFractionDigits:2});
  const el = (tag, text, cls) => { const n=document.createElement(tag); if(text!==undefined)n.textContent=text; if(cls)n.className=cls; return n; };
  const option=(value,label)=>{const n=el('option',label);n.value=value;return n;};
  const ttk=(r,h)=>r.ttk===null?`${h}초 내 미처치`:r.ttk===0?'첫 타격에 처치':`${f(r.ttk)}초`;
  async function mount(root) {
    if(root.dataset.mounted)return;
    root.dataset.mounted='true';
    const E=globalThis.SFHDps;
    root.textContent='확정 데이터 읽는 중…';
    try {
      const response=await fetch(new URL(root.dataset.catalog,location.href),{credentials:'same-origin',cache:'no-cache'});
      if(!response.ok || !(response.headers.get('content-type')||'').includes('json'))throw Error('로그인 상태 또는 데이터 배포를 확인하세요.');
      const catalog=await response.json();
      if(catalog.schema!==1 || !catalog.weapons?.length || !catalog.skills?.length)throw Error('지원하지 않는 데이터 형식입니다.');
      root.textContent='';
      const toolbar=el('div',undefined,'dps-toolbar');
      const weapon=el('select'), skill=el('select'), difficulty=el('select');
      for(const w of catalog.weapons)weapon.append(option(w.id,w.name));
      skill.append(option('','스킬 없이 무기만'));
      for(const s of catalog.skills)skill.append(option(s.skill_id,s.display_name));
      difficulty.append(option('custom','직접 입력'));
      for(const d of catalog.difficulties)difficulty.append(option(d.difficulty_id,`${d.display_name} · 기본 적`));
      const labelled=(name,node)=>{const label=el('label',name);node.setAttribute('aria-label',name);label.append(node);return label;};
      toolbar.append(labelled('무기 원본',weapon),labelled('스킬 원본',skill),labelled('적 기본값 불러오기',difficulty));
      const reset=el('button','현재 원본으로 초기화');reset.type='button';toolbar.append(reset);root.append(toolbar);
      const info=el('p',undefined,'dps-source');root.append(info);
      let equipmentEditor;
      if(catalog.loadout)equipmentEditor=SFHLoadoutUI.mount(root,catalog,weapon.value,()=>update());
      const error=el('p',undefined,'dps-error');error.setAttribute('role','alert');error.hidden=true;root.append(error);
      const result=el('section',undefined,'dps-results');result.setAttribute('aria-label','DPS 비교 결과');
      const summary=el('div',undefined,'dps-kpis');summary.setAttribute('aria-live','polite');summary.setAttribute('aria-atomic','true');result.append(summary);
      const graph=el('div',undefined,'dps-graph');result.append(graph);
      const extraGraphs=el('details',undefined,'dps-extra-graphs');extraGraphs.append(el('summary','스킬별 피해 · 캐릭터 생존 그래프'));const extraBody=el('div');extraGraphs.append(extraBody);result.append(extraGraphs);
      const warning=el('p',undefined,'dps-note');result.append(warning);root.append(result);
      const form=el('form',undefined,'dps-inputs');form.addEventListener('submit',e=>e.preventDefault());
      const controls={};
      for(const [name,fields]of groups) {
        const panel=el('details');panel.open=name==='적과 비교 조건';panel.append(el('summary',name));
        const grid=el('div',undefined,'dps-fields');
        for(const [key,label]of fields) {
          const input=el('input');input.type='number';input.name=key;
          input.min=E.limits[key][0];input.max=E.limits[key][1];input.step=['burst','charges','projectiles','level','horizon'].includes(key)?'1':'any';
          input.required=true;controls[key]=input;grid.append(labelled(label,input));
        }
        panel.append(grid);form.append(panel);
      }
      const flags=el('div',undefined,'dps-flags');
      for(const [key,label]of switches){const input=el('input');input.type='checkbox';input.name=key;controls[key]=input;flags.append(labelled(label,input));}
      form.append(flags);root.append(form);
      const samples=el('details');samples.append(el('summary','그래프 수치 표 · 시간별 피해 확인'));const sampleBody=el('div',undefined,'dps-table-scroll');samples.append(sampleBody);root.append(samples);
      const catalogDetails=el('details');catalogDetails.append(el('summary',`현재 무기 ${catalog.weapons.length}종 · 스킬 ${catalog.skills.length}종 전체 수치`));
      const catalogBody=el('div',undefined,'dps-table-scroll');catalogDetails.append(catalogBody);root.append(catalogDetails);
      function table(headers,rows,caption) {
        const t=el('table');t.append(el('caption',caption));const head=el('thead'),tr=el('tr');
        for(const h of headers){const th=el('th',h);th.scope='col';tr.append(th);}head.append(tr);t.append(head);
        const body=el('tbody');for(const row of rows){const r=el('tr');row.forEach(v=>r.append(el('td',String(v))));body.append(r);}t.append(body);return t;
      }
      function renderCatalog(){
        catalogBody.replaceChildren(table(['무기','탄환 기대 피해','점사 주기 (초)','장기 DPS¹','원본'],catalog.weapons.map(w=>{
          const x=E.resolve(catalog,E.defaults(catalog,w.id));return[w.name,f(x.hit),f(x.cycle),f(x.sustainedWeapon),w.source_mode==='locked_csv'?'확정 CSV':'런타임 대체값 · 기획 확인'];
        }),'고정 옵션·고유 기능 포함, 내부 무기 레벨 1, 명중 100%, 단일 대상'));
        catalogBody.append(table(['스킬','기본 1회/틱 피해','기본 1시전 피해','쿨타임 기준 DPS²','쿨타임 (초)','AP / 충전 / 회복 (초)','요구 태그'],catalog.skills.map(s=>{
          const p=s.parameters,d=p.path_damage?.damage??p.tick_damage??0,ticks=s.kind==='field'?Math.ceil(p.duration_seconds/p.tick_interval_seconds-1e-9):1;
          return[s.display_name,f(d),f(d*ticks),f(d*ticks/s.cooldown_seconds),f(s.cooldown_seconds),`${f(s.energy_cost)} / ${s.maximum_charges} / ${f(s.charge_recovery_seconds)}`,s.required_combat_tags.join(', ')||'제한 없음'];
        }),'Resource 기본값 · 무기별 스킬 보정 전. ²쿨타임 기준은 AP·충전 무제한 상한. 기동 가속은 직접 피해 0.'));
      }
      function draw(now,base,i){
        graph.textContent='';const ns='http://www.w3.org/2000/svg';
        const width=Math.max(280,graph.clientWidth-18),end=width-18;
        const svg=document.createElementNS(ns,'svg');svg.setAttribute('viewBox',`0 0 ${width} 310`);svg.setAttribute('role','img');
        const title=document.createElementNS(ns,'title');title.textContent=`${i.horizon}초 누적 피해. 시험 ${f(now.total)}, 원본 ${f(base.total)}. 처치 기준 ${f(i.hp+i.armor)}.`;svg.append(title);
        const desc=document.createElementNS(ns,'desc');desc.textContent='청록 시험 합계, 회색 점선 현재 원본, 파랑 무기, 보라 스킬. 주황 수평선은 적 체력과 방어막 합입니다. 하단 표에서 수치를 확인할 수 있습니다.';svg.append(desc);
        const max=Math.max(1,now.total,base.total,i.hp+i.armor)*1.1;
        const X=t=>54+t/i.horizon*(end-54),Y=d=>260-d/max*226;
        const line=(x1,y1,x2,y2,cls)=>{const n=document.createElementNS(ns,'line');Object.entries({x1,y1,x2,y2,class:cls}).forEach(([k,v])=>n.setAttribute(k,v));svg.append(n);};
        const text=(x,y,value)=>{const n=document.createElementNS(ns,'text');n.setAttribute('x',x);n.setAttribute('y',y);n.textContent=value;svg.append(n);};
        for(let k=0;k<=4;k++){const value=max*k/4;line(54,Y(value),end,Y(value),'dps-gridline');text(3,Y(value)+4,value>=10000?value.toExponential(1):f(value));text(X(i.horizon*k/4)-12,282,`${f(i.horizon*k/4)}s`);}
        text(54,18,'누적 피해');line(54,Y(i.hp+i.armor),end,Y(i.hp+i.armor),'dps-threshold');
        const path=(points,key,cls)=>{const n=document.createElementNS(ns,'path');let d='';points.forEach((p,j)=>{d+=j?`H${X(p.time)}V${Y(p[key])}`:`M${X(p.time)},${Y(p[key])}`;});n.setAttribute('d',d);n.setAttribute('class',cls);svg.append(n);};
        path(base.points,'total','dps-line dps-base');path(now.points,'weapon','dps-line dps-weapon');path(now.points,'skill','dps-line dps-skill');path(now.points,'total','dps-line dps-total');
        graph.append(svg);const legend=el('div',undefined,'dps-legend');
        for(const [cls,label]of [['total','시험 합계'],['base','원본 합계 (점선)'],['weapon','시험 무기'],['skill','시험 스킬'],['threshold','체력 + 방어막']])legend.append(el('span',label,`dps-${cls}`));graph.append(legend);
      }
      function update(){
        try {
          const input=E.defaults(catalog,weapon.value,skill.value);
          if(equipmentEditor)input.loadout=equipmentEditor.read();
          for(const [key,control]of Object.entries(controls))input[key]=control.type==='checkbox'?control.checked:control.value===''?NaN:Number(control.value);
          const current=E.defaults(catalog,weapon.value,skill.value);for(const key of scenarioKeys)current[key]=input[key];
          const now=E.simulate(catalog,input),base=E.simulate(catalog,current),x=now.resolved;
          error.hidden=true;result.hidden=false;summary.textContent='';
          const metric=(name,value,detail)=>{const card=el('div');card.append(el('span',name),el('strong',value),el('small',detail));summary.append(card);};
          metric('관측 구간 합산 DPS',f(now.dps),`원본 ${f(base.dps)} · ${input.horizon}초 누적 ${f(now.total)}`);
          metric('예상 처치 시간',ttk(now,input.horizon),`원본 ${ttk(base,input.horizon)}`);
          metric('목표 시간 대비',now.ttk===null?'구간 내 미처치':now.ttk<=input.targetTime?'목표 이내':'목표 초과',`기획자 목표 ${f(input.targetTime)}초 · 난이도 등급 아님`);
          metric('무기 장기 DPS¹',f(x.sustainedWeapon),`스킬 1시전 ${f(x.perCast)} · ${now.casts}회 시전`);
          metric('관측 구간 스킬 DPS',f(now.skillDamage/input.horizon),`원본 ${f(base.skillDamage/input.horizon)} · 무기 DPS ${f(now.weaponDamage/input.horizon)}`);
          metric('적 접촉 DPS',f(now.enemyDps),'연속 접촉·플레이어 방어 미적용');
          metric('플레이어 HP / 방어',`${f(now.player.max_health)} / ${f(now.player.defense)}`,`이동 속도 ${f(now.player.movement_speed)} · 피격 1회 ${f(now.receivedHit)}`);
          metric('연속 피격 생존 시간',`${f(now.survivalTime)}초`,'0초부터 피격 · 회피/회복 없이 방어력 차감, 최소 피해 1');
          const notices=[];
          if(!x.allowed)notices.push(`스킬 사용 불가: ${x.skill.required_combat_tags.join(', ')} 태그 필요. 스킬 피해 0으로 계산.`);
          if(x.weapon.source_mode==='runtime_fallback')notices.push('이 무기는 확정 무기 CSV 행이 없어 실제 런타임 대체 발사값을 사용합니다. 의도된 무기 밸런스 확정값이 아닙니다.');
          if(x.skill?.kind==='utility')notices.push('기동 가속은 이동 기능입니다. 직접 피해 0은 누락이 아닙니다.');
          if(x.loadout){notices.push(x.loadout.costs.map(c=>`${c.name} 모듈 비용 ${c.used}/${c.capacity}`).join(' · '));notices.push(...x.loadout.notes);}
          if(!input.resourceLimits)notices.push('AP·충전 무제한: 실제 전투가 아닌 쿨타임 기준 상한 실험입니다.');
          notices.push('같은 적·명중률·AP 조건에서 원본과 시험값 비교. 단일 적 / 무기 1개 + 스킬 1개 / 처치 후에도 누적 피해 그래프는 계속됩니다.');
          warning.textContent=notices.join(' ');
          info.textContent=`${x.weapon.name} · ${x.weapon.source_mode==='locked_csv'?'확정 CSV':'런타임 대체값'} + 스킬 Resource · 시험값은 이 화면에서만 적용됩니다. 원본·시트·게임 저장 변경 없음.`;
          draw(now,base,input);
          extraBody.replaceChildren();
          const bundle=SFHBalance.calculate('combat',catalog,input);
          for(const series of bundle.series){const detail=el('details');detail.append(el('summary',series.title));const host=el('div');detail.append(host);extraBody.append(detail);SFHBalanceView.draw(host,{...series,xLabel:'시간 (초)',yLabel:series.title,note:'각 스킬은 같은 초기 AP에서 독립 계산합니다. 여러 스킬의 동시 사용 DPS를 합한 결과가 아닙니다.'});}
          const stride=Math.max(1,Math.floor(now.points.length/12));
          sampleBody.replaceChildren(table(['시간 (초)','시험 합계','원본 합계','무기','스킬','적 잔여 HP','적 잔여 방어막'],now.points.filter((p,j)=>j%stride===0||j===now.points.length-1).map(p=>{
            const b=base.points.find(q=>q.time===p.time);return[f(p.time),f(p.total),f(b.total),f(p.weapon),f(p.skill),f(p.hp),f(p.armor)];
          }),'처치 기준은 체력 + 방어막. 피해선은 상한 없이 누적, 잔여량은 0에서 멈춥니다.'));
          root.dataset.ready='true';
          root.sfhBalanceTrial={model:'combat',sources:catalog.sources,input:structuredClone(input)};
          document.dispatchEvent(new Event('sfh-balance-trial'));
        }catch(e){root.sfhBalanceTrial=null;error.textContent=`계산 중단: ${e.message}`;error.hidden=false;result.hidden=true;sampleBody.textContent='유효한 수치를 입력하면 다시 계산합니다.';}
      }
      function load(){equipmentEditor?.weapon(weapon.value);const i=E.defaults(catalog,weapon.value,skill.value);for(const [key,node]of Object.entries(controls)){if(node.type==='checkbox')node.checked=i[key];else node.value=i[key];}difficulty.value='custom';update();}
      // Responsive axes keep real 12px labels instead of shrinking a desktop SVG on phones.
      let lastWidth=root.clientWidth;
      const observer=new ResizeObserver(()=>{if(!root.isConnected){observer.disconnect();return;}if(root.clientWidth!==lastWidth){lastWidth=root.clientWidth;update();}});
      observer.observe(root);
      weapon.addEventListener('change',load);skill.addEventListener('change',load);reset.addEventListener('click',()=>{equipmentEditor?.reset();load();});
      form.addEventListener('input',()=>{difficulty.value='custom';update();});
      difficulty.addEventListener('change',()=>{const d=catalog.difficulties.find(d=>d.difficulty_id===difficulty.value);if(!d)return;const m=d.enemy_modifiers;controls.hp.value=catalog.enemy.hp*m.health_multiplier;controls.armor.value=catalog.enemy.armor*m.armor_multiplier;controls.enemyDamage.value=catalog.enemy.damage*m.damage_multiplier;controls.enemyInterval.value=catalog.enemy.interval;update();});
      weapon.value=catalog.weapons.some(w=>w.id==='assault_rifle')?'assault_rifle':catalog.weapons[0].id;skill.value='magnetic_field';renderCatalog();load();
    }catch(e){root.textContent=`계산기 데이터를 불러오지 못했습니다. ${e.message} `;const retry=el('button','다시 불러오기');retry.type='button';retry.addEventListener('click',()=>{delete root.dataset.mounted;mount(root);});root.append(retry);root.setAttribute('role','status');}
  }
  const init=()=>document.querySelectorAll('[data-sfh-dps-lab]').forEach(mount);
  if(typeof document$!=='undefined')document$.subscribe(init);
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
})();
