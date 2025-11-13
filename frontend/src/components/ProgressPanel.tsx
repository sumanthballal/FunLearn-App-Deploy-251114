import React, { useEffect, useState } from 'react';

export default function ProgressPanel({ user = 'local-user' }: { user?: string }){
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [deleting, setDeleting] = useState(false);

  const load = async ()=>{
    setLoading(true);
    try {
      const res = await fetch(`/api/progress/${encodeURIComponent(user)}`);
      if (!res.ok) throw new Error('failed');
      const j = await res.json();
      setItems(j.progress || []);
    } catch {
      setItems([]);
    } finally { setLoading(false); }
  };

  const clearAll = async ()=>{
    setDeleting(true);
    try{
      await fetch(`/api/progress/${encodeURIComponent(user)}`, { method: 'DELETE' });
      await load();
    } finally { setDeleting(false); }
  };

  useEffect(()=>{ load(); },[user]);

  return (
    <div className="bg-white p-4 rounded shadow">
      <div className="flex items-center justify-between mb-2">
        <div className="font-semibold">Progress</div>
        <div className="flex items-center gap-3">
          <button onClick={load} className="text-sm text-sky-600">Refresh</button>
          <button onClick={clearAll} disabled={deleting} className="text-sm text-red-600">
            {deleting ? 'Deleting…' : 'Delete'}
          </button>
        </div>
      </div>
      {loading ? <div className="text-sm text-gray-500">Loading...</div> : (
        <div>
          {items.length===0 ? <div className="text-sm text-gray-500">No progress yet</div> : (
            <ul className="text-sm space-y-2">
              {items.slice().reverse().map((it,idx)=> (
                <li key={idx} className="flex items-center justify-between">
                  <div>
                    <div className="font-medium">{it.activity}</div>
                    <div className="text-xs text-gray-500">{it.module} • {new Date(it.timestamp).toLocaleString()}</div>
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
