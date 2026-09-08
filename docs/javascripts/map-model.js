/* Pure regional topology, kept equivalent to RegionalDistrictPlan by Godot fixtures. */
(function(root){
  'use strict';
  function build(config, region, seed, facilities) {
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
    return {version:1,region,seed,count,columns,rows,stride,buildings,streets,passages,start:0,exits};
  }
  function proposal(catalog, region, tier, seed, facilities, notes, source) {
    const original=new Map(catalog.facilities.map(r=>[r.facility_id,r]));
    const changed=facilities.filter(r=>JSON.stringify(r)!==JSON.stringify(original.get(r.facility_id)));
    return `[임시 · 오너 판단 요청] 지역 맵 피스 제안\n원본 CSV: ${catalog.version}\n지역: ${region} / 규모: ${tier} / 시드: ${seed}\n상태: 제안 작성, 승인·게임 적용 아님\n근거 Notion: ${source||'작성 필요'}\n목적·기대 경험·확인 기준: ${notes||'작성 필요'}\n불변 조건: 시작 1, 출구 2, 순환 도로, 건물 출입구 2, 선택 금고 1\n변경 피스:\n${changed.length?changed.map(r=>JSON.stringify(r)).join('\n'):'변경 없음 (현행 배치 의견)'}\n적·장애물·전리품 위치는 이 미리보기의 검증 범위가 아닙니다.`;
  }
  root.SFHMapModel={build,proposal};
  if(typeof module!=='undefined')module.exports=root.SFHMapModel;
})(typeof window==='undefined'?globalThis:window);
