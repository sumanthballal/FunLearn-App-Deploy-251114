import React, { useMemo, useState } from "react";

export default function MathSortNumbers(){
  const [nums, setNums] = useState<number[]>(()=>shuffle(Array.from({length: 10}, ()=> Math.floor(Math.random()*90)+10)));
  const [answer, setAnswer] = useState<number[]>([]);
  const [descending, setDescending] = useState(false);
  const correct = useMemo(()=>{
    const arr=[...nums].sort((a,b)=>a-b);
    return descending ? arr.reverse() : arr;
  }, [nums, descending]);

  function pick(n:number){ if (answer.includes(n)) return; setAnswer(a=>[...a,n]); }
  function reset(){ setNums(shuffle(Array.from({length: 10}, ()=> Math.floor(Math.random()*90)+10))); setAnswer([]); }
  const success = answer.length===nums.length && answer.every((v,i)=>v===correct[i]);

  return (
    <div className="p-6 bg-white rounded-xl border shadow w-full max-w-2xl">
      <div className="flex items-center justify-between mb-2">
        <div className="font-semibold">Sort Numbers</div>
        <label className="text-sm flex items-center gap-2"><input type="checkbox" checked={descending} onChange={e=>setDescending(e.target.checked)} /> Descending</label>
      </div>
      <div className="text-sm mb-2">Tap numbers in the correct order.</div>
      <div className="flex flex-wrap gap-2 mb-3">
        {nums.map(n=> (
          <button key={n} onClick={()=>pick(n)} className={`px-4 py-3 rounded text-lg ${answer.includes(n)?'bg-slate-200 text-slate-400':'bg-blue-100 text-blue-700 hover:bg-blue-200'}`}>{n}</button>
        ))}
      </div>
      <div className="flex flex-wrap gap-2 mb-2">
        {answer.map((n,i)=>(<div key={i} className="px-3 py-2 rounded bg-emerald-100 text-emerald-700 text-lg">{n}</div>))}
      </div>
      {success && <div className="text-emerald-600 font-semibold mb-2">Great! Sorted correctly 🎉</div>}
      <button onClick={reset} className="px-4 py-2 rounded bg-blue-500 text-white">New Set</button>
    </div>
  );
}
function shuffle<T>(arr:T[]):T[]{
  const a=arr.slice(); for(let i=a.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [a[i],a[j]]=[a[j],a[i]]; } return a;
}
