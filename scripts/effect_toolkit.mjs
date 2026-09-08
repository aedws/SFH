// Offline/live-Sheet specification compiler. Always emits a review plan, never applies it.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import path from 'node:path';
import '../docs/javascripts/effect-toolkit-engine.js';
const E=globalThis.SFHEffectToolkit,args=process.argv.slice(2);
const get=k=>args[args.indexOf(k)+1];
try{
  if(!args.includes('--input')&&!args.includes('--sheet'))throw Error('Use --input EffectSpec.csv or --sheet; optional --output plan.json');
  const catalog=JSON.parse(await readFile(new URL('../docs/assets/effect-toolkit.json',import.meta.url),'utf8'));
  let text;
  if(args.includes('--sheet')){
    const url='https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/gviz/tq?tqx=out:csv&headers=1&sheet=EffectSpec';
    const r=await fetch(url,{signal:AbortSignal.timeout(30000)});if(!r.ok)throw Error(`Sheet HTTP ${r.status}`);text=await r.text();
  }else text=await readFile(get('--input'),'utf8');
  const plan=E.compile(E.parseCSV(text),catalog);
  // Verify the working tree, not just catalog self-consistency.
  const {createHash}=await import('node:crypto');
  for(const [file,hash] of Object.entries(catalog.sources)){
    const current=(await readFile(new URL('../'+file,import.meta.url),'utf8')).replace(/^\uFEFF/,'').replaceAll('\r\n','\n');
    if(createHash('sha256').update(current).digest('hex')!==hash)throw Error(`원본 변경: ${file}. 카탈로그 재생성 후 재검토하세요.`);
  }
  if(args.includes('--output')){const dest=path.resolve(get('--output'));const root=path.resolve('outputs');
    if(!dest.startsWith(root+path.sep))throw Error('출력은 outputs/ 아래 검토 산출물로만 저장합니다.');
    await mkdir(path.dirname(dest),{recursive:true});await writeFile(dest,JSON.stringify(plan,null,2)+'\n');}
  console.log(JSON.stringify(plan,null,2));
}catch(e){console.error('EFFECT_SPEC_ERROR '+e.message);process.exitCode=1;}
