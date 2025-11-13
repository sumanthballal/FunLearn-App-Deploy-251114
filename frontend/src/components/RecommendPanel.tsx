import React, { useEffect, useState } from "react";
import fallbackRecs from "../lib/fallbacks";

export default function RecommendPanel({ emotion="neutral", open=true }:{emotion?:string, open?:boolean}) {
  const [items,setItems] = useState<any[]>([]);
  useEffect(()=>{
    let mounted=true;
    (async ()=>{
      try {
        const res = await fetch("/api/recommend", { method:"POST", headers:{"Content-Type":"application/json"}, body: JSON.stringify({ emotion }) });
        if (res.ok) {
          const j = await res.json();
          if (mounted && Array.isArray(j)) setItems(j);
          else if (mounted) setItems(fallbackRecs[emotion] || []);
        } else { if (mounted) setItems(fallbackRecs[emotion]||[]); }
      } catch { if (mounted) setItems(fallbackRecs[emotion]||[]); }
    })();
    return ()=>{ mounted=false; };
  },[emotion]);
  if (!open) return <div />;
  return (
    <div className="bg-white p-4 rounded-lg shadow">
      <h3 className="font-bold mb-2">Recommended</h3>
      <ul className="space-y-2">
        {items.map((it:any,i:number)=><li key={i} className="flex justify-between items-center"><div>{it.title}</div><div className="text-sm text-gray-500">{it.duration ?? ""}</div></li>)}
      </ul>
    </div>
  );
}

