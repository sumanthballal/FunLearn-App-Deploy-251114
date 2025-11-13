import React, { useMemo, useState } from "react";

export default function EnglishWordMatch(){
  const pairs = useMemo(()=> shuffle([
    {w:'cat', p:'🐱'}, {w:'sun', p:'☀️'}, {w:'tree', p:'🌳'}, {w:'ball', p:'⚽'},
    {w:'fish', p:'🐟'}, {w:'bird', p:'🐦'}, {w:'car', p:'🚗'}, {w:'star', p:'⭐'},
    {w:'book', p:'📖'}, {w:'cake', p:'🎂'}, {w:'phone', p:'📱'}, {w:'rain', p:'🌧️'}
  ]), []);
  const [sel, setSel] = useState<string[]>([]);
  const [matches, setMatches] = useState<Record<string,boolean>>({});

  function click(id:string){
    if (matches[id]) return;
    const s=[...sel, id];
    if (s.length===2){
      const [a,b]=s;
      const aw = a.startsWith('w:')? a.slice(2) : a.slice(2);
      const bw = b.startsWith('w:')? b.slice(2) : b.slice(2);
      const aKey = a.slice(2), bKey = b.slice(2);
      const ok = (a.startsWith('w:') && pairs.find(x=>x.w===aKey)?.p===bKey) || (a.startsWith('p:') && pairs.find(x=>x.p===aKey)?.w===bKey);
      if (ok){ setMatches(m=>({...m, [a]:true, [b]:true})); }
      setSel([]);
    } else setSel(s);
  }
  const done = Object.keys(matches).length >= pairs.length*2;

  return (
    <div className="p-6 bg-white rounded-xl border shadow w-full max-w-3xl">
      <div className="font-semibold mb-2">Word Match</div>
      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-2">
          {pairs.map(x=> (
            <button key={'w:'+x.w} onClick={()=>click('w:'+x.w)} className={`w-full px-4 py-3 rounded text-lg ${matches['w:'+x.w]? 'bg-emerald-100 text-emerald-700' : sel.includes('w:'+x.w) ? 'bg-indigo-100' : 'bg-blue-100 text-blue-700'}`}>{x.w}</button>
          ))}
        </div>
        <div className="space-y-2">
          {shuffle(pairs).map(x=> (
            <button key={'p:'+x.p} onClick={()=>click('p:'+x.p)} className={`w-full px-4 py-3 rounded text-lg ${matches['p:'+x.p]? 'bg-emerald-100 text-emerald-700' : sel.includes('p:'+x.p) ? 'bg-indigo-100' : 'bg-amber-100 text-amber-700'}`}>{x.p}</button>
          ))}
        </div>
      </div>
      {done && <div className="mt-2 text-emerald-600 font-semibold">Awesome! 🎉</div>}
    </div>
  );
}
function shuffle<T>(arr:T[]):T[]{
  const a=arr.slice(); for(let i=a.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [a[i],a[j]]=[a[j],a[i]]; } return a;
}
