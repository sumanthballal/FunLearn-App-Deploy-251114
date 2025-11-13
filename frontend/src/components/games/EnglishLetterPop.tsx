import React, { useMemo, useState } from "react";

export default function EnglishLetterPop(){
  const target = "ELEPHANT";
  const pool = useMemo(()=> shuffle([...'ELEPHANTJUNGLEANIMALSCHOOLFRIEND']), []);
  const [picked, setPicked] = useState<string[]>([]);
  const goal = target.split('');

  function pop(ch:string){ if (picked.length>=goal.length) return; setPicked(p=>[...p, ch]); }
  const success = picked.join('')===target;

  return (
    <div className="p-6 bg-white rounded-xl border shadow w-full max-w-2xl">
      <div className="font-semibold mb-2">Letter Pop</div>
      <div className="text-sm mb-2">Pop letters to spell: <b>{target}</b></div>
      <div className="flex flex-wrap gap-2 mb-3">
        {pool.map((c,i)=> (
          <button key={i} onClick={()=>pop(c)} className="w-12 h-12 rounded-full bg-pink-100 text-pink-700 font-bold text-lg">{c}</button>
        ))}
      </div>
      <div className="text-2xl mb-2 tracking-widest">{picked.join('')}</div>
      {success && <div className="text-emerald-600 font-semibold">Great spelling! 🎉</div>}
    </div>
  );
}
function shuffle<T>(arr:T[]):T[]{
  const a=arr.slice(); for(let i=a.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [a[i],a[j]]=[a[j],a[i]]; } return a;
}
