import React, { useMemo, useState } from "react";

interface Item { id: string; label: string; }

export default function MiniGameScience(){
  const options: Item[] = useMemo(()=>[
    { id: 'sun', label: 'Sun' },
    { id: 'earth', label: 'Earth' },
    { id: 'moon', label: 'Moon' },
  ],[]);
  const [placed, setPlaced] = useState<Record<string,string>>({});
  const [dragId, setDragId] = useState<string|undefined>();

  const onDragStart = (id: string)=>()=> setDragId(id);
  const onDrop = (slot: string)=> (e: React.DragEvent)=>{
    e.preventDefault();
    if (!dragId) return;
    setPlaced(p=>({ ...p, [slot]: dragId }));
    setDragId(undefined);
  };
  const onAllow = (e: React.DragEvent)=> e.preventDefault();

  const correct = (slot: string)=> placed[slot] === slot;

  return (
    <div className="p-4 bg-white rounded-xl shadow border">
      <div className="text-lg font-semibold mb-3">Label the Solar System</div>
      <div className="grid grid-cols-3 gap-4 mb-4">
        {options.map(op=> (
          <div key={op.id}
               draggable
               onDragStart={onDragStart(op.id)}
               className="px-3 py-2 rounded bg-amber-100 border cursor-move text-center">
            {op.label}
          </div>
        ))}
      </div>
      <div className="grid grid-cols-3 gap-4">
        {['sun','earth','moon'].map(slot=> (
          <div key={slot}
               onDragOver={onAllow}
               onDrop={onDrop(slot)}
               className={`h-20 rounded flex items-center justify-center border-2 ${correct(slot)?'border-emerald-500 bg-emerald-50':'border-dashed border-gray-300'}`}>
            {placed[slot] ? options.find(o=>o.id===placed[slot])?.label : `Drop ${slot} here`}
          </div>
        ))}
      </div>
    </div>
  );
}
