import React, { useMemo, useState } from "react";

export default function MathPrimeFinder(){
  const [pool, setPool] = useState<number[]>(()=> genPool());
  const [chosen, setChosen] = useState<Record<number, boolean>>({});
  const primes = useMemo(()=> pool.filter(isPrime), [pool]);
  const correct = useMemo(()=> Object.keys(chosen).map(Number).every(n=> isPrime(n)), [chosen]);

  function toggle(n:number){ setChosen(c=> ({...c, [n]: !c[n]})); }
  function reset(){ setPool(genPool()); setChosen({}); }

  const done = primes.length>0 && Object.keys(chosen).length===primes.length && correct;

  return (
    <div className="p-6 bg-white rounded-xl border shadow w-full max-w-2xl">
      <div className="font-semibold mb-2">Prime Finder</div>
      <div className="text-sm mb-2">Select all prime numbers.</div>
      <div className="grid grid-cols-6 gap-2">
        {pool.map(n=> (
          <button key={n} onClick={()=>toggle(n)} className={`h-14 rounded text-lg font-semibold ${chosen[n]? (isPrime(n)?'bg-emerald-200 text-emerald-900':'bg-rose-200 text-rose-900') : 'bg-violet-100 text-violet-700 hover:bg-violet-200'}`}>{n}</button>
        ))}
      </div>
      {done && <div className="mt-3 text-emerald-600 font-semibold">Nice! You found them all 🎉</div>}
      <button onClick={reset} className="mt-3 px-4 py-2 rounded bg-violet-500 text-white">New Set</button>
    </div>
  );
}

function genPool(){
  const arr = new Set<number>();
  while(arr.size<18){ arr.add(Math.floor(Math.random()*90)+10); }
  return Array.from(arr);
}
function isPrime(n:number){
  if (n<2) return false; for(let i=2;i*i<=n;i++){ if (n%i===0) return false; } return true;
}
