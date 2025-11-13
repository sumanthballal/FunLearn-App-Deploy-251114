import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import WebcamEmotion from "../components/WebcamEmotion";

export default function Dashboard(){
  const nav = useNavigate();
  const [emotion, setEmotion] = useState<string>("neutral");
  const [ts, setTs] = useState<string>("");

  return (
    <div className="min-h-screen bg-gradient-to-b from-sky-50 to-sky-100 p-6">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-4xl md:text-5xl font-bold text-sky-700 mb-2">Welcome to FunLearn - Learn with Your Emotions!</h1>
        <p className="text-gray-600 mb-6">Emotion-aware, multi-sensory learning for kids</p>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="bg-white rounded-2xl shadow p-6">
            <h2 className="text-2xl font-semibold text-sky-700 mb-3">Live Emotion</h2>
            <WebcamEmotion
              user="local-user"
              onEmotion={(e)=>{ setEmotion(e.emotion); setTs(e.timestamp); }}
              intervalMs={10000}
            />
            <div className="mt-4">
              <span className="font-semibold">Current:</span> {emotion}
              {ts && <span className="ml-2 text-xs text-gray-500">Last: {new Date(ts).toLocaleTimeString()}</span>}
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow p-6">
            <h2 className="text-2xl font-semibold text-sky-700 mb-4">Start Learning</h2>
            <div className="grid grid-cols-1 gap-4">
              <button onClick={()=>nav('/learn')} className="p-5 rounded-xl bg-sky-500 text-white hover:bg-sky-600 transition">Learning Paths</button>
            </div>
          </div>
        </div>

        {emotion === 'sad' && (
          <div className="mt-4 text-rose-600 font-semibold">Don't worry, try again! You can do it!</div>
        )}
      </div>
    </div>
  );
}


