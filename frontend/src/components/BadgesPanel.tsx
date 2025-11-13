import React, { useEffect, useState } from 'react';

export default function BadgesPanel({ user = 'local-user' }: { user?: string }){
  const [badges, setBadges] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const load = async ()=>{
    setLoading(true);
    try {
      const res = await fetch(`/api/badges/${encodeURIComponent(user)}`);
      if (!res.ok) throw new Error('failed');
      const j = await res.json();
      setBadges(j.badges || []);
    } catch {
      setBadges([]);
    } finally { setLoading(false); }
  };

  useEffect(()=>{ load(); },[user]);

  return (
    <div className="bg-white p-4 rounded shadow">
      <div className="flex items-center justify-between mb-2">
        <div className="font-semibold">Badges</div>
        <button onClick={load} className="text-sm text-sky-600">Refresh</button>
      </div>
      {loading ? <div className="text-sm text-gray-500">Loading...</div> : (
        <div>
          {badges.length===0 ? <div className="text-sm text-gray-500">No badges yet</div> : (
            <ul className="space-y-3">
              {badges.map((b:any, i:number)=> (
                <li key={i} className="flex items-center gap-3">
                  <div className="w-12 h-12 flex-shrink-0 bg-sky-50 rounded-full flex items-center justify-center overflow-hidden">
                    <img
                      src={`/assets/badges/${b.id}.svg`}
                      alt={b.name}
                      className="w-10 h-10"
                      onError={(e:any)=>{
                        e.currentTarget.onerror=null;
                        e.currentTarget.style.display='none';
                        const sib = e.currentTarget.nextElementSibling as HTMLElement | null;
                        if (sib) sib.style.display = 'block';
                      }}
                    />
                    <div className="text-xl font-bold" style={{display: 'none'}}>*</div>
                  </div>
                  <div>
                    <div className="font-medium">{b.name}</div>
                    <div className="text-xs text-gray-500">{b.description}</div>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}
