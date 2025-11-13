import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

const MODULE_ICONS: Record<string, { label: string; color: string }> = {
  Math: { label: "M", color: "from-blue-500 to-blue-400" },
  Science: { label: "S", color: "from-green-500 to-green-400" },
  Reading: { label: "R", color: "from-purple-500 to-purple-400" },
  Art: { label: "A", color: "from-pink-500 to-pink-400" }
};

export default function Learn(){
  const nav = useNavigate();
  const [modules, setModules] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(()=> {
    let mounted = true;
    (async ()=>{
      try {
        const res = await fetch("/api/modules");
        if (!res.ok) throw new Error("bad modules");
        const data = await res.json();
        if (mounted && data.modules) setModules(data.modules);
      } catch {
        if (mounted) setModules(["Math","Science","Reading","Art"]);
      } finally { if (mounted) setLoading(false); }
    })();
    return ()=>{ mounted = false; };
  },[]);

  return (
    <div className="min-h-screen bg-gradient-to-b from-sky-50 to-sky-100 p-4 md:p-8">
      <div className="max-w-7xl mx-auto">
        <h1 className="font-display text-6xl bg-gradient-to-r from-sky-600 to-blue-600 bg-clip-text text-transparent text-center mb-12">
          Choose a module
        </h1>
        {loading ? (
          <div className="font-heading text-2xl text-center text-sky-600">Loading modules...</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-8 max-w-5xl mx-auto">
            {modules.map((m) => {
              const moduleConfig = MODULE_ICONS[m] || { label: "?", color: "from-gray-500 to-gray-400" } as any;
              return (
                <button
                  key={m}
                  onClick={() => nav(`/lesson/${encodeURIComponent(m.toLowerCase())}`)}
                  className={`bg-gradient-to-br ${moduleConfig.color} p-12 rounded-3xl shadow-lg 
                    hover:shadow-xl transform hover:scale-105 transition-all duration-300
                    flex flex-col items-center justify-center min-h-[300px] group`}
                >
                  <span className="text-8xl mb-6 transform group-hover:scale-110 transition-transform duration-300">
                    {moduleConfig.label}
                  </span>
                  <span className="font-heading text-4xl font-bold text-white tracking-wide">{m}</span>
                </button>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
