import React, { useEffect } from "react";
import { HashRouter as Router, Routes, Route, Link, useNavigate } from "react-router-dom";
import Home from "./pages/Home";
import Learn from "./pages/Learn";
import LessonShell from "./pages/LessonShell";
import ActivityDetail from "./pages/ActivityDetail";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";

export default function App(){
  const hasSession = typeof window !== 'undefined' && !!localStorage.getItem('funlearn_session');
  return (
    <Router>
      <div className="p-4 relative">
        {/* Fixed blue back/forward arrows */}
        <ArrowNav />
        <div className="container flex items-center justify-end">
          {!hasSession && <Link to="/login" className="text-sm font-semibold">Login</Link>}
        </div>
      </div>
      <Routes>
        <Route path="/" element={<Home/>} />
        <Route path="/login" element={<Login/>} />
        <Route path="/dashboard" element={<RequireSession><Dashboard/></RequireSession>} />
        <Route path="/learn" element={<RequireSession><Learn/></RequireSession>} />
        <Route path="/lesson/:module" element={<RequireSession><LessonShell/></RequireSession>} />
        <Route path="/activity/:id" element={<ActivityDetail/>} />
      </Routes>
    </Router>
  );
}

function RequireSession({children}:{children: React.ReactElement}){
  const nav = useNavigate();
  const has = typeof window !== 'undefined' && !!localStorage.getItem('funlearn_session');
  useEffect(()=>{ if (!has) nav('/login'); }, [has, nav]);
  return has ? children : <div className="p-6">Redirecting to login...</div>;
}

function ArrowNav(){
  const nav = useNavigate();
  return (
    <div style={{position:'fixed', left:12, top:12, zIndex:60}}>
      <div className="flex flex-row gap-2">
        <button
          aria-label="Go back"
          onClick={()=>nav(-1)}
          className="w-8 h-8 flex items-center justify-center rounded bg-blue-500 text-white shadow"
          title="Back"
        >
          {"<"}
        </button>
        <button
          aria-label="Go forward"
          onClick={()=>nav(1)}
          className="w-8 h-8 flex items-center justify-center rounded bg-blue-500 text-white shadow"
          title="Forward"
        >
          {">"}
        </button>
      </div>
    </div>
  );
}

