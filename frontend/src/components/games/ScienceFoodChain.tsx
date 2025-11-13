import React, { useState } from "react";

export default function ScienceFoodChain(){
  const steps = ['Grass','Grasshopper','Frog','Snake','Eagle'];
  const [pool, setPool] = useState<string[]>(()=>shuffle(steps));
  const [order, setOrder] = useState<string[]>([]);
  function add(s:string){ if (order.includes(s)) return; setOrder(o=>[...o,s]); }
  function reset(){ setOrder([]); setPool(shuffle(steps)); }
  const correct = order.length===steps.length && order.every((v,i)=>v===steps[i]);

  return (
    <div className="p-6 bg-white rounded-xl border shadow w-full">
      <div className="font-semibold mb-2">Food Chain Builder</div>
      <div className="text-sm mb-2">Arrange from producer → apex predator.</div>
      <div className="flex flex-wrap gap-2 mb-3">
        {pool.map(s=> <button key={s} onClick={()=>add(s)} className={`px-4 py-3 rounded text-lg ${order.includes(s)?'bg-slate-200 text-slate-400':'bg-green-100 text-green-700 hover:bg-green-200'}`}>{s}</button>)}
      </div>
      <div className="grid grid-cols-5 gap-2">
        {order.map((s,i)=> <div key={i} className="px-3 py-2 rounded bg-green-50 border">{i+1}. {s}</div>)}
      </div>
      {correct && <div className="mt-3 text-emerald-600 font-semibold">Great chain! 🎉</div>}
      <button onClick={reset} className="mt-3 px-4 py-2 rounded bg-green-500 text-white">Reset</button>
    </div>
  );
}
function shuffle<T>(arr:T[]):T[]{ const a=arr.slice(); for(let i=a.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [a[i],a[j]]=[a[j],a[i]]; } return a; }
