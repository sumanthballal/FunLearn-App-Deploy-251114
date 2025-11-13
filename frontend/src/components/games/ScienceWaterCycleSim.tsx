import React, { useState } from "react";

export default function ScienceWaterCycleSim(){
  const [stage, setStage] = useState<'evap'|'cond'|'precip'>('evap');
  return (
    <div className="p-4 bg-white rounded-xl border shadow w-full max-w-md">
      <div className="font-semibold mb-2">Water Cycle Simulator</div>
      <div className="text-sm mb-3">Click through the stages: Evaporation → Condensation → Precipitation.</div>
      <div className="h-28 rounded bg-sky-50 flex items-center justify-center mb-3">
        {stage==='evap' && <div>Sun heats water ☀️ → vapor rises</div>}
        {stage==='cond' && <div>Vapor forms clouds ☁️</div>}
        {stage==='precip' && <div>Rain falls 🌧️ → water returns</div>}
      </div>
      <div className="flex gap-2">
        <button onClick={()=>setStage('evap')} className={`px-3 py-1 rounded ${stage==='evap'?'bg-emerald-500 text-white':'bg-emerald-100 text-emerald-700'}`}>Evaporation</button>
        <button onClick={()=>setStage('cond')} className={`px-3 py-1 rounded ${stage==='cond'?'bg-indigo-500 text-white':'bg-indigo-100 text-indigo-700'}`}>Condensation</button>
        <button onClick={()=>setStage('precip')} className={`px-3 py-1 rounded ${stage==='precip'?'bg-blue-500 text-white':'bg-blue-100 text-blue-700'}`}>Precipitation</button>
      </div>
    </div>
  );
}
