import React, { useEffect, useState } from 'react';
import { getActivity } from '@/lib/api';

export default function ActivityDetail({ id }: { id?: string }) {
  const [activity, setActivity] = useState<any | null>(null);
  const [error, setError] = useState<string | null>(null);
  const actId = id || (window.location.pathname.split('/').pop() || '');

  useEffect(() => {
    if (!actId) { setError('No activity id'); return; }
    getActivity(actId).then((data) => {
      setActivity(data);
    }).catch((err) => {
      console.error('getActivity error', err);
      setError(err?.message || String(err) || 'Failed to load activity');
    });
  }, [actId]);

  if (error) return <div style={{padding:20,color:'crimson'}}>Error: {error}</div>;
  if (!activity) return <div style={{padding:20}}>Loading activity…</div>;

  return (
    <div style={{padding:20}}>
      <h1>{activity.title || 'Untitled'}</h1>
      <p>{activity.description || 'No description'}</p>

      {activity.media && activity.media.type === 'image' && (
        <img src={activity.media.src} alt={activity.title} style={{maxWidth:'80%',borderRadius:12}} />
      )}
      {activity.media && activity.media.type === 'video' && (
        <div>
          <p><a href={activity.media.src} target='_blank' rel='noreferrer'>Open media</a></p>
        </div>
      )}

      <div style={{marginTop:20}}>
        <button onClick={() => {
          fetch('/api/progress', {
            method: 'POST',
            headers: {'Content-Type':'application/json'},
            body: JSON.stringify({ user: 'test-user', module: activity.module, activity: activity.id })
          }).then(r => r.json()).then(data => {
            console.log('progress saved', data);
            alert('Marked as done');
          }).catch(e => {
            console.error('progress error', e);
            alert('Failed to save progress');
          });
        }} style={{background:'#00AEEF',color:'#fff',border:'none',padding:'8px 12px',borderRadius:8}}>Mark as Done</button>
      </div>
    </div>
  );
}
