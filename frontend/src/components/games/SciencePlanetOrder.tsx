import React, { useMemo, useState } from "react";

export default function SciencePlanetOrder(){
  const planets = useMemo(()=>['Mercury','Venus','Earth','Mars','Jupiter','Saturn','Uranus','Neptune'],[]);
  const [pool, setPool] = useState<string[]>(()=>shuffle(planets));
  const [order, setOrder] = useState<string[]>([]);

  function add(p:string){ if (order.includes(p)) return; setOrder(o=>[...o,p]); }
  function reset(){ setOrder([]); setPool(shuffle(planets)); }
  const correct = order.length===planets.length && order.every((p,i)=>p===planets[i]);

  return (
    <div className="p-4 bg-white rounded-xl border shadow w-full">
      <div className="font-semibold mb-2">Order the Planets (Sun → Out)</div>
      <div className="flex flex-wrap gap-2 mb-3">
        {pool.map(p=> (
          <button key={p} onClick={()=>add(p)} className={`px-3 py-2 rounded ${order.includes(p)?'bg-slate-200 text-slate-400':'bg-indigo-100 text-indigo-700 hover:bg-indigo-200'}`}>{p}</button>
        ))}
      </div>
      <div className="mb-2 text-sm">Your order:</div>
      <div className="grid grid-cols-4 gap-2">
        {order.map((p,i)=>(<div key={i} className="px-3 py-2 rounded bg-indigo-50 border">{i+1}. {p}</div>))}
      </div>
      {correct && <div className="mt-3 text-emerald-600 font-semibold">Excellent! 🎉</div>}
      <button onClick={reset} className="mt-3 px-3 py-1 rounded bg-indigo-500 text-white">Reset</button>
    </div>
  );
}
function shuffle<T>(arr:T[]):T[]{ const a=arr.slice(); for(let i=a.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [a[i],a[j]]=[a[j],a[i]]; } return a; }
