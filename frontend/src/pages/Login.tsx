import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

export default function Login(){
  const nav = useNavigate();
  const [user, setUser] = useState( localStorage.getItem('funlearn_user') || '');
  const [passw, setPassw] = useState( localStorage.getItem('funlearn_pass') || '');
  const [remember, setRemember] = useState(!!localStorage.getItem('funlearn_user'));

  useEffect(()=>{
    // if already stored creds, you might auto-login — keep user on learn page
    if (localStorage.getItem('funlearn_user') && localStorage.getItem('funlearn_pass')){
      // don't auto navigate — let user submit when ready
    }
  },[]);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) { alert('Please enter a user id'); return; }
    if (!passw) { alert('Please enter a password'); return; }
    if (remember){
      localStorage.setItem('funlearn_user', user);
      localStorage.setItem('funlearn_pass', passw);
    } else {
      localStorage.removeItem('funlearn_user');
      localStorage.removeItem('funlearn_pass');
    }
    // For a smooth demo experience, create a local session immediately and navigate
    const sid = 'demo-' + Date.now().toString(36);
    localStorage.setItem('funlearn_session', sid);
    nav('/dashboard');

    // Fire backend login in the background (best-effort only)
    try{
      const API = (import.meta as any).env?.VITE_API_URL || '';
      const url = API ? `${API}/login` : `/api/login`;
      fetch(url, {
        method:'POST',
        headers:{'Content-Type':'application/json'},
        body: JSON.stringify({ email: user, password: passw })
      }).catch(() => {});
    }catch(err){ /* ignore */ }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-sky-50 p-6">
      <div className="w-full max-w-md bg-white rounded-xl shadow-lg p-6">
        <h1 className="text-2xl font-semibold mb-4 text-blue-700">Welcome back</h1>
        <p className="text-sm text-gray-600 mb-6">Sign in to continue your learning journey.</p>
        <form onSubmit={submit} className="space-y-4">
          <div>
            <label className="block text-sm text-gray-700 mb-1">User ID</label>
            <input value={user} onChange={e=>setUser(e.target.value)} className="w-full px-3 py-2 border rounded" />
          </div>
          <div>
            <label className="block text-sm text-gray-700 mb-1">Password</label>
            <input type="password" value={passw} onChange={e=>setPassw(e.target.value)} className="w-full px-3 py-2 border rounded" />
          </div>
          <div className="flex items-center justify-between">
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" checked={remember} onChange={e=>setRemember(e.target.checked)} />
              Remember me
            </label>
            <button type="button" className="text-sm text-sky-600" onClick={()=>{ setUser('guest'); setPassw('guest'); }}>Use guest</button>
          </div>
          <div className="flex items-center gap-4">
            <button type="submit" className="flex-1 bg-blue-600 text-white px-4 py-2 rounded">Sign in</button>
            <button type="button" className="px-4 py-2 rounded border" onClick={()=>nav('/')}>Back</button>
          </div>
        </form>
      </div>
    </div>
  );
}
