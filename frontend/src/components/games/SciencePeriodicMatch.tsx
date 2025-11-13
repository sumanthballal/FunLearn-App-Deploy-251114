import React, { useMemo, useState } from "react";

export default function SciencePeriodicMatch(){
  const pairs = useMemo(()=> shuffle([
    {s:'H', n:'Hydrogen'}, {s:'O', n:'Oxygen'}, {s:'C', n:'Carbon'}, {s:'N', n:'Nitrogen'},
    {s:'Na', n:'Sodium'}, {s:'Cl', n:'Chlorine'}, {s:'Fe', n:'Iron'}, {s:'Ca', n:'Calcium'},
  ]), []);
  const [sel, setSel] = useState<string[]>([]);
  const [ok, setOk] = useState<Record<string,boolean>>({});

  function click(id:string){
    if (ok[id]) return;
    const s=[...sel, id];
    if (s.length===2){
      const [a,b]=s; setSel([]);
      const get=(x:string)=> x.startsWith('s:')? pairs.find(p=>p.s===x.slice(2)) : pairs.find(p=>p.n===x.slice(2));
      const pa=get(a), pb=get(b);
      if (pa && pb && (pa.s===pb.s || pa.n===pb.n)){
        setOk(m=>({...m, [a]:true, [b]:true}));
      }
    } else setSel(s);
  }
  const done = Object.keys(ok).length>=pairs.length*2;

  return (
    <div className="p-6 bg-white rounded-xl border shadow w-full">
      <div className="font-semibold mb-2">Periodic Table Match</div>
      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-2">
          {pairs.map(p=> (
            <button key={'s:'+p.s} onClick={()=>click('s:'+p.s)} className={`w-full px-4 py-3 rounded text-lg ${ok['s:'+p.s] ? 'bg-emerald-100 text-emerald-700' : sel.includes('s:'+p.s) ? 'bg-indigo-100':'bg-blue-100 text-blue-700'}`}>{p.s}</button>
          ))}
        </div>
        <div className="space-y-2">
          {shuffle(pairs).map(p=> (
            <button key={'n:'+p.n} onClick={()=>click('n:'+p.n)} className={`w-full px-4 py-3 rounded text-lg ${ok['n:'+p.n] ? 'bg-emerald-100 text-emerald-700' : sel.includes('n:'+p.n) ? 'bg-indigo-100':'bg-amber-100 text-amber-700'}`}>{p.n}</button>
          ))}
        </div>
      </div>
      {done && <div className="mt-2 text-emerald-600 font-semibold">Elemental! 🎉</div>}
    </div>
  );
}
function shuffle<T>(arr:T[]):T[]{ const a=arr.slice(); for(let i=a.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [a[i],a[j]]=[a[j],a[i]]; } return a; }
