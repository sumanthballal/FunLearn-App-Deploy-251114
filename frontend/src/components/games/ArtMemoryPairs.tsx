import React, { useMemo, useState } from "react";

type Card = { id: number; emoji: string; revealed: boolean; matched: boolean };

export default function ArtMemoryPairs(){
  const deck = useMemo(()=>{
    const em = ['🔴','🔵','🟡','🟢','🟣','🟠','🟥','🟦','🟨','🟩','⭐','❤️','⚪','⚫','🔺','🔻','🔶','🔷'];
    const cards: Card[] = []; let id=1;
    em.forEach(e=>{ cards.push({id:id++, emoji:e, revealed:false, matched:false}); cards.push({id:id++, emoji:e, revealed:false, matched:false}); });
    return shuffle(cards).slice(0, 36); // 18 pairs = 36 cards
  },[]);
  const [cards, setCards] = useState<Card[]>(deck);
  const [sel, setSel] = useState<number[]>([]);

  function flip(idx: number){
    setCards(cs=>{
      const copy = cs.map(c=>({...c}));
      const c = copy[idx]; if (c.matched || c.revealed) return cs;
      c.revealed = true; const chosen = [...sel, idx]; setSel(chosen);
      if (chosen.length===2){
        const [a,b]=chosen; const ca=copy[a], cb=copy[b];
        if (ca.emoji===cb.emoji){ ca.matched=cb.matched=true; setSel([]); }
        else {
          setTimeout(()=>{
            setCards(xx=>{ const yy=xx.map(z=>({...z})); yy[a].revealed=false; yy[b].revealed=false; return yy; });
            setSel([]);
          }, 650);
        }
      }
      return copy;
    });
  }

  const done = cards.every(c=>c.matched);

  return (
    <div className="p-6 bg-white rounded-xl border shadow w-full max-w-3xl">
      <div className="font-semibold mb-2">Memory Pairs</div>
      <div className="grid grid-cols-6 gap-2">
        {cards.map((c, i)=> (
          <button key={c.id} onClick={()=>flip(i)} className={`h-16 rounded text-xl ${c.matched ? 'bg-emerald-100 text-emerald-700' : c.revealed ? 'bg-amber-50' : 'bg-slate-200'}`}>
            {c.revealed || c.matched ? c.emoji : ''}
          </button>
        ))}
      </div>
      {done && <div className="mt-2 text-emerald-600 font-semibold">You matched all pairs! 🎉</div>}
    </div>
  );
}

function shuffle<T>(arr:T[]):T[]{
  const a=arr.slice(); for(let i=a.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [a[i],a[j]]=[a[j],a[i]]; } return a;
}
