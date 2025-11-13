import React, { useEffect, useState } from 'react';
import { getActivities } from '@/lib/api';

type Activity = {
  id: string;
  module: string;
  title: string;
  description?: string;
  media?: { type: string; src: string };
};

export default function LessonShell({ moduleName }: { moduleName?: string | null }) {
  const [activities, setActivities] = useState<Activity[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const mod = moduleName || (window.location.pathname.split('/').pop() || 'Math');

  useEffect(() => {
    setActivities(null); setError(null);
    getActivities(mod)
      .then((data) => {
        if (!Array.isArray(data)) {
          console.warn('Unexpected activities payload', data);
          setActivities([]);
        } else {
          setActivities(data);
        }
      })
      .catch((err) => {
        console.error('getActivities error', err);
        setError(err?.message || String(err) || 'Failed to load activities');
        setActivities([]);
      });
  }, [mod]);

  if (activities === null) return <div style={{padding:20}}>Loading activities…</div>;
  if (error) return <div style={{padding:20,color:'crimson'}}>Error loading activities: {error}</div>;
  if (activities.length === 0) return <div style={{padding:20}}>No activities found for {mod}.</div>;

  return (
    <div style={{padding:20,display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(280px,1fr))',gap:16}}>
      {activities.map((a) => (
        <div key={a.id} style={{background:'#fff',padding:18,borderRadius:12,boxShadow:'0 1px 3px rgba(0,0,0,0.06)'}}>
          <h3 style={{margin:0}}>{a.title}</h3>
          <p style={{color:'#444'}}>{a.description || 'No description available.'}</p>
          {a.media && a.media.type === 'image' && <img src={a.media.src} alt={a.title} style={{width:'100%',borderRadius:8}}/>}
          {a.media && a.media.type === 'video' && (
            <div style={{marginTop:10}}>
              <a href={a.media.src} target='_blank' rel='noreferrer'>Watch Video</a>
            </div>
          )}
          <div style={{marginTop:10}}>
            <button onClick={() => { window.location.href = '/activity/' + encodeURIComponent(a.id); }} style={{background:'#00AEEF',color:'#fff',border:'none',padding:'8px 12px',borderRadius:8}}>Open</button>
          </div>
        </div>
      ))}
    </div>
  );
}
