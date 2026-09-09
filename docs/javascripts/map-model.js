/* Pure regional topology, kept equivalent to RegionalDistrictPlan by Godot fixtures. */
(function(root){
  'use strict';
  function build(config, region, seed, facilities, difficulty={}) {
    if (!Number.isInteger(seed) || seed < 0 || seed > 2147483646) throw Error('시드는 0~2147483646 정수입니다.');
    let state=seed%2147483646+1;
    const next=()=>{state=state*16807%2147483647;return (state-1)/2147483646;};
    const integer=(a,b)=>a+Math.floor(next()*(b-a+1));
    const count=Math.floor((config.minimum_rooms+config.maximum_rooms)/2), columns=Math.max(3,Math.ceil(Math.sqrt(count))), rows=Math.ceil(count/columns);
    const stride=config.maximum_size.map(v=>v+28), exits=[count-1,columns-1], assigned=new Map();
    const sorted=facilities.slice().sort((a,b)=>a.facility_id<b.facility_id?-1:a.facility_id>b.facility_id?1:0);
    const required=sorted.filter(r=>r.required_regions.split('|').some(v=>v==='*'||v===region));
    const filler=sorted.filter(r=>r.encounter!=='objective'&&r.random_weight>0);
    if(!filler.length||required.length>count-3) throw Error('필수 피스 공간 또는 보조 후보가 부족합니다.');
    const anchors={west:[0,.5],east:[1,.5],north:[.5,0],south:[.5,1],center:[.5,.5]};
    for(const r of required){
      const t=anchors[r.anchor_zone];let chosen=-1,distance=Infinity;
      for(let i=0;i<count;i++){
        if(i===0||exits.includes(i)||assigned.has(i))continue;
        const score=(i%columns-t[0]*(columns-1))**2+(Math.floor(i/columns)-t[1]*(rows-1))**2;
        if(score<distance){chosen=i;distance=score;}
      }assigned.set(chosen,r);
    }
    const streets=[],passages=[],buildings=[];
    for(let y=0;y<=rows;y++)for(let x=0;x<columns;x++)streets.push([x*stride[0],y*stride[1],stride[0]+8,8]);
    for(let x=0;x<=columns;x++)for(let y=0;y<rows;y++)streets.push([x*stride[0],y*stride[1],8,stride[1]+8]);
    for(let i=0;i<count;i++){
      const fixed=assigned.has(i);let r=assigned.get(i);
      if(!fixed){let choice=next()*filler.reduce((n,v)=>n+v.random_weight,0);r=filler.at(-1);for(const c of filler){choice-=c.random_weight;if(choice<0){r=c;break;}}}
      const size=config.minimum_size.map((v,a)=>fixed?v+Math.floor((config.maximum_size[a]-v)*(a===0?r.shape_x:r.shape_y)):integer(v,config.maximum_size[a]));
      const plot=[i%columns,Math.floor(i/columns)];
      let x=plot[0]*stride[0]+Math.floor((stride[0]-size[0])/2),y=plot[1]*stride[1]+Math.floor((stride[1]-size[1])/2);
      if(!fixed){x+=integer(-3,3);y+=integer(-3,3);}
      const axis=fixed?r.entrance_axis:integer(0,1)===0?'horizontal':'vertical',cx=x+Math.floor(size[0]/2),cy=y+Math.floor(size[1]/2);
      if(axis==='horizontal')passages.push([plot[0]*stride[0],cy-1,x-plot[0]*stride[0],3],[x+size[0],cy-1,(plot[0]+1)*stride[0]+8-x-size[0],3]);
      else passages.push([cx-1,plot[1]*stride[1],3,y-plot[1]*stride[1]],[cx-1,y+size[1],3,(plot[1]+1)*stride[1]+8-y-size[1]]);
      buildings.push({index:i,plot,rect:[x,y,...size],axis,facility_id:r.facility_id,required:fixed});
    }
    const plan={version:1,region,seed,count,columns,rows,stride,buildings,streets,passages,start:0,exits};
    if(config.urban_enabled===false)return plan;
    urban(plan,config);
    return config.compound_enabled?compound(plan,difficulty):plan;
  }
  function urban(plan,config){
    const o={avenue_width:14,local_width:10,sidewalk_width:3,entrance_width:5,...config.urban};
    const clamp=(v,a,b)=>Math.min(b,Math.max(a,Math.trunc(v)));
    const main=clamp(o.avenue_width,8,20),local=clamp(o.local_width,6,14),sidewalk=clamp(o.sidewalk_width,2,5),door=clamp(o.entrance_width,3,7);
    const phase=plan.region==='industrial_district'?1:plan.region==='research_complex'?2:0,xs=[0],ys=[0],xw=[],yw=[];
    for(let x=0;x<=plan.columns;x++){xw.push(x%3===0?main:local);if(x<plan.columns)xs.push(xs.at(-1)+config.maximum_size[0]+xw.at(-1)+sidewalk*2+8+(x+phase)%3*6);}
    for(let y=0;y<=plan.rows;y++){yw.push(y%3===0?main:local);if(y<plan.rows)ys.push(ys.at(-1)+config.maximum_size[1]+yw.at(-1)+sidewalk*2+8+(y+phase+1)%3*5);}
    plan.streets=[];plan.passages=[];plan.yards=[];plan.street_axes=[];
    for(let y=0;y<=plan.rows;y++){for(let x=0;x<plan.columns;x++)plan.streets.push([xs[x],ys[y],xs[x+1]-xs[x]+xw[x+1],yw[y]]);plan.street_axes.push({axis:'horizontal',at:ys[y],width:yw[y]});}
    for(let x=0;x<=plan.columns;x++){for(let y=0;y<plan.rows;y++)plan.streets.push([xs[x],ys[y],xw[x],ys[y+1]-ys[y]+yw[y+1]]);plan.street_axes.push({axis:'vertical',at:xs[x],width:xw[x]});}
    for(const b of plan.buildings){
      const [px,py]=b.plot,lot=[xs[px]+xw[px],ys[py]+yw[py],xs[px+1],ys[py+1]],w=b.rect[2],h=b.rect[3],horizontal=b.axis==='horizontal';
      const x=horizontal?lot[0]+sidewalk+2:lot[0]+Math.floor((lot[2]-lot[0]-w)/2),y=horizontal?lot[1]+Math.floor((lot[3]-lot[1]-h)/2):lot[1]+sidewalk+2;
      b.rect=[x,y,w,h];b.lot=[lot[0],lot[1],lot[2]-lot[0],lot[3]-lot[1]];
      plan.yards.push(...[[lot[0],lot[1],lot[2]-lot[0],y-lot[1]-1],[lot[0],y+h+1,lot[2]-lot[0],lot[3]-y-h-1],[lot[0],y-1,x-lot[0]-1,h+2],[x+w+1,y-1,lot[2]-x-w-1,h+2]].filter(r=>r[2]>0&&r[3]>0));
      const cx=x+Math.floor(w/2),cy=y+Math.floor(h/2),half=Math.floor(door/2);
      if(horizontal)plan.passages.push([lot[0],cy-half,x-lot[0],door],[x+w,cy-half,lot[2]-x-w,door]);
      else plan.passages.push([cx-half,lot[1],door,y-lot[1]],[cx-half,y+h,door,lot[3]-y-h]);
    }
    plan.version=2;plan.urban_settings={avenue_width:main,local_width:local,sidewalk_width:sidewalk,entrance_width:door};plan.extent=[xs.at(-1)+xw.at(-1),ys.at(-1)+yw.at(-1)];return plan;
  }
  function proposal(catalog, region, tier, seed, facilities, notes, source) {
    const original=new Map(catalog.facilities.map(r=>[r.facility_id,r]));
    const changed=facilities.filter(r=>JSON.stringify(r)!==JSON.stringify(original.get(r.facility_id)));
    return `[임시 · 오너 판단 요청] 지역 맵 피스 제안\n원본 CSV: ${catalog.version}\n지역: ${region} / 규모: ${tier} / 시드: ${seed}\n상태: 제안 작성, 승인·게임 적용 아님\n근거 Notion: ${source||'작성 필요'}\n목적·기대 경험·확인 기준: ${notes||'작성 필요'}\n불변 조건: 시작 1, 출구 2, 구역 연결 도로, 제한된 구역 입구, 선택 금고 1\n변경 피스:\n${changed.length?changed.map(r=>JSON.stringify(r)).join('\n'):'변경 없음 (현행 배치 의견)'}\n적·장애물·전리품 위치는 이 미리보기의 검증 범위가 아닙니다.`;
  }
  function compound(plan,difficulty){
    const xs=plan.street_axes.filter(a=>a.axis==='vertical').map(a=>a.at),ys=plan.street_axes.filter(a=>a.axis==='horizontal').map(a=>a.at);
    const retained=(list,index)=>index%2===0||index===list.length-1;
    plan.streets=plan.streets.filter(r=>{const v=r[3]>r[2],a=v?xs:ys;return retained(a,a.indexOf(v?r[0]:r[1]));});
    plan.street_axes=plan.street_axes.filter(a=>{const list=a.axis==='vertical'?xs:ys;return retained(list,list.indexOf(a.at));});
    plan.yards=[];plan.passages=[];const routes=[],groups=new Map(),ratio=Math.max(0,Math.min(1,difficulty.polygon_ratio||0));
    const center=i=>{const r=plan.buildings[i].rect;return[r[0]+Math.floor(r[2]/2),r[1]+Math.floor(r[3]/2)];};
    const carve=(a,b)=>plan.passages.push([Math.min(a[0],b[0])-2,Math.min(a[1],b[1])-2,Math.abs(a[0]-b[0])+5,Math.abs(a[1]-b[1])+5]);
    const street=(i,x)=>{const c=center(i);carve(c,[x,c[1]]);routes.push({from:-1,to:i,kind:'front',width:5});};
    const link=(a,b,alt=false)=>{const s=center(a),e=center(b),p=alt?[s[0],e[1]]:[e[0],s[1]];carve(s,p);carve(p,e);routes.push({from:a,to:b,kind:alt?'rear':'interior',width:5});};
    for(const b of plan.buildings){const key=`${Math.floor(b.plot[0]/2)},${Math.floor(b.plot[1]/2)}`;if(!groups.has(key))groups.set(key,[]);groups.get(key).push(b.index);const shapeSeed=b.required?0:plan.seed;b.shape_variant=(b.index+shapeSeed)%4;b.polygonal=b.index!==0&&!plan.exits.includes(b.index)&&(b.index*7919+shapeSeed)%1000/1000<ratio;}
    for(const [key,members] of groups){const x=Number(key.split(',')[0]);members.sort((a,b)=>{const av=plan.buildings[a].facility_id==='vault',bv=plan.buildings[b].facility_id==='vault';return av===bv?a-b:av?1:-1;});const front=members[0];street(front,xs[x*2]+2);for(let i=1;i<members.length;i++)link(members[i-1],members[i]);if(members.length>2)link(front,members.at(-1),true);for(const i of members)if((i===0||plan.exits.includes(i))&&i!==front)street(i,xs[Math.min(x*2+2,xs.length-1)]+2);}
    plan.compound_count=groups.size;plan.polygon_ratio=ratio;plan.compound_routes=routes;return plan;
  }
  function occupied(b,x,y){
    const w=b.rect[2],h=b.rect[3],px=x+.5,py=y+.5;
    if(Math.abs(px-w*.5)<2.5||Math.abs(py-h*.5)<2.5)return true;
    if(b.polygonal){const p=[[0,h*.18],[w*.23,0],[w*.82,0],[w,h*.24],[w*.92,h],[w*.17,h],[0,h*.76]];let inside=false;for(let i=0,j=p.length-1;i<p.length;j=i++)if((p[i][1]>py)!==(p[j][1]>py)&&px<(p[j][0]-p[i][0])*(py-p[i][1])/(p[j][1]-p[i][1])+p[i][0])inside=!inside;return inside;}
    switch(b.shape_variant){case 0:return !(px>w*.65&&py<h*.35);case 1:return !(py>h*.66&&(px<w*.25||px>w*.75));case 2:return !(px>w*.3&&px<w*.7&&py<h*.32);case 3:return !(px>w*.62&&px<w*.83&&py>h*.15&&py<h*.37);default:return true;}
  }
  function shapePath(b){let d='';for(let y=0;y<b.rect[3];y++){let start=-1;for(let x=0;x<=b.rect[2];x++){const yes=x<b.rect[2]&&occupied(b,x,y);if(yes&&start<0)start=x;if(!yes&&start>=0){d+=`M${b.rect[0]+start} ${b.rect[1]+y}h${x-start}v1h${start-x}z`;start=-1;}}}return d;}
  root.SFHMapModel={build,proposal,shapePath,occupied};
  if(typeof module!=='undefined')module.exports=root.SFHMapModel;
})(typeof window==='undefined'?globalThis:window);
