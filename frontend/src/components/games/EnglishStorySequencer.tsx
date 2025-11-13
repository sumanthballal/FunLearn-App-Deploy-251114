import React, { useState } from "react";

export default function EnglishStorySequencer(){
  const parts = [
    { id: 1, text: 'Ria found an old map in the attic.' },
    { id: 2, text: 'She packed water, a torch, and a notebook.' },
    { id: 3, text: 'The map led her to a quiet forest trail.' },
    { id: 4, text: 'She crossed a stream and climbed a small hill.' },
    { id: 5, text: 'Behind vines, she discovered a tiny wooden door.' },
    { id: 6, text: 'Inside was a message: "Curiosity is the greatest treasure."' },
  ];
  const [order, setOrder] = useState<number[]>([]);

  function add(id:number){ if (order.includes(id)) return; setOrder(o=>[...o,id]); }
  function reset(){ setOrder([]); }
  const correct = order.length===parts.length && order.every((v,i)=>v===parts[i].id);

  return (
    <div className="p-6 bg-white rounded-xl border shadow w-full max-w-3xl">
      <div className="font-semibold mb-2">Story Sequencer</div>
      <div className="text-sm mb-3">Tap sentences in the correct story order.</div>
      <div className="space-y-2 mb-3">
        {parts.map(p=> (
          <button key={p.id} onClick={()=>add(p.id)} className={`w-full text-left px-4 py-3 rounded text-lg ${order.includes(p.id)?'bg-slate-200 text-slate-400':'bg-purple-100 text-purple-700 hover:bg-purple-200'}`}>{p.text}</button>
        ))}
      </div>
      <div className="mb-2 text-sm">Your order:</div>
      <ol className="list-decimal ml-5 space-y-1 mb-2 text-lg">
        {order.map(id=> <li key={id}>{parts.find(p=>p.id===id)?.text}</li>)}
      </ol>
      {correct && <div className="text-emerald-600 font-semibold mb-2">Great sequence! 🎉</div>}
      <button onClick={reset} className="px-4 py-2 rounded bg-purple-500 text-white">Reset</button>
    </div>
  );
}
