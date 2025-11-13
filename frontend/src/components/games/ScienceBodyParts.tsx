import React, { useState } from "react";

export default function ScienceBodyParts(){
  const slots = ['Head','Arm','Leg'];
  const [drag, setDrag] = useState<string|undefined>();
  const [placed, setPlaced] = useState<Record<string,string>>({});
  const items = ['Head','Arm','Leg'];

  const done = slots.every(s=> placed[s]===s);

  return (
    <div className="p-4 bg-white rounded-xl border shadow w-full max-w-md">
      <div className="font-semibold mb-2">Label Body Parts</div>
      <div className="text-sm mb-3">Drag labels into the correct boxes.</div>
      <div className="flex gap-2 mb-4">
        {items.map(it=> (
          <div key={it}
               draggable
               onDragStart={()=>setDrag(it)}
               className="px-3 py-2 rounded bg-green-100 text-green-700 cursor-move">{it}</div>
        ))}
      </div>
      <div className="grid grid-cols-3 gap-3">
        {slots.map(s=> (
          <div key={s}
               onDragOver={(e)=>e.preventDefault()}
               onDrop={()=>{ if (drag){ setPlaced(p=>({...p, [s]: drag!})); setDrag(undefined);} }}
               className={`h-20 rounded border-2 flex items-center justify-center ${placed[s]===s?'border-emerald-500 bg-emerald-50':'border-dashed border-gray-300'}`}>
            {placed[s] || `Drop ${s}`}
          </div>
        ))}
      </div>
      {done && <div className="mt-2 text-emerald-600 font-semibold">Great job! 🎉</div>}
    </div>
  );
}
