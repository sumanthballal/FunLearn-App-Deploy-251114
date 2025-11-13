# ===============================
# FunLearn Frontend Setup Script
# ===============================
# This replaces the default Vite starter with FunLearn app (Home, Learn, LessonShell)
# Make sure backend (Flask) runs on http://127.0.0.1:5000

Write-Host "🚀 Setting up FunLearn frontend..." -ForegroundColor Cyan

Set-Location "C:\Users\balla\Desktop\Funlearn\frontend"

# --- Ensure folders ---
if (-not (Test-Path .\src)) { mkdir src | Out-Null }
if (-not (Test-Path .\src\pages)) { mkdir src\pages | Out-Null }
if (-not (Test-Path .\src\components)) { mkdir src\components | Out-Null }
if (-not (Test-Path .\src\lib)) { mkdir src\lib | Out-Null }

# --- index.css ---
@'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  background-color: #E6F4FF;
  font-family: "Nunito", sans-serif;
}
'@ | Out-File -Encoding utf8 src\index.css -Force

# --- main.tsx ---
@'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
'@ | Out-File -Encoding utf8 src\main.tsx -Force

# --- App.tsx ---
@'
import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Home from "./pages/Home";
import Learn from "./pages/Learn";
import LessonShell from "./pages/LessonShell";

export default function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/learn" element={<Learn />} />
        <Route path="/lesson/:module" element={<LessonShell />} />
      </Routes>
    </Router>
  );
}
'@ | Out-File -Encoding utf8 src\App.tsx -Force

# --- Home.tsx ---
@'
import React from "react";
import { motion } from "framer-motion";
import { useNavigate } from "react-router-dom";

export default function Home() {
  const navigate = useNavigate();
  return (
    <div className="h-screen flex flex-col justify-center items-center text-center bg-gradient-to-b from-sky-100 to-sky-200">
      <motion.h1
        className="text-5xl font-extrabold text-sky-700 mb-4"
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
      >
        🎓 Welcome to FunLearn
      </motion.h1>
      <motion.p
        className="text-lg text-gray-700 mb-6"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2 }}
      >
        Learn with Emotions — Smart, Fun, and Interactive
      </motion.p>
      <motion.button
        onClick={() => navigate("/learn")}
        className="bg-sky-500 hover:bg-sky-600 text-white px-6 py-3 rounded-2xl font-semibold shadow-lg"
        whileHover={{ scale: 1.05 }}
      >
        Start Learning 🚀
      </motion.button>
    </div>
  );
}
'@ | Out-File -Encoding utf8 src\pages\Home.tsx -Force

# --- Learn.tsx ---
@'
import React from "react";
import { useNavigate } from "react-router-dom";

const modules = ["Math", "Science", "Reading", "Art"];

export default function Learn() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-sky-100 p-8">
      <h1 className="text-4xl font-bold text-center text-sky-700 mb-8">Choose a Module</h1>
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-6 max-w-4xl mx-auto">
        {modules.map((mod) => (
          <div
            key={mod}
            onClick={() => navigate(`/lesson/${mod.toLowerCase()}`)}
            className="bg-white/70 hover:bg-sky-200 cursor-pointer text-center rounded-2xl p-6 font-semibold shadow-md transition"
          >
            {mod}
          </div>
        ))}
      </div>
    </div>
  );
}
'@ | Out-File -Encoding utf8 src\pages\Learn.tsx -Force

# --- LessonShell.tsx ---
@'
import React, { useState } from "react";
import { useParams } from "react-router-dom";
import fallbackRecs from "@/lib/fallbacks";

export default function LessonShell() {
  const { module } = useParams();
  const [emotion, setEmotion] = useState("happy");

  const recommendations = fallbackRecs[emotion] || [];

  return (
    <div className="min-h-screen bg-sky-50 p-8">
      <h1 className="text-3xl font-bold text-sky-700 mb-4">📘 {module} Lessons</h1>
      <p className="text-gray-600 mb-6">
        Current detected emotion: <span className="font-semibold">{emotion}</span>
      </p>
      <div className="bg-white rounded-2xl p-6 shadow-md mb-6">
        <h2 className="text-xl font-semibold mb-2">Recommended Activities</h2>
        <ul className="list-disc ml-6">
          {recommendations.map((r, i) => (
            <li key={i}>{r.title}</li>
          ))}
        </ul>
      </div>
      <button
        onClick={() => setEmotion(emotion === "happy" ? "sad" : "happy")}
        className="bg-sky-500 text-white px-5 py-2 rounded-xl shadow hover:bg-sky-600"
      >
        Toggle Emotion 😀/😢
      </button>
    </div>
  );
}
'@ | Out-File -Encoding utf8 src\pages\LessonShell.tsx -Force

# --- fallbacks.ts ---
@'
export const fallbackRecs = {
  happy: [{ title: "Fun Math Game" }, { title: "Science Quiz" }],
  sad: [{ title: "Cheerful Art Project" }],
  confused: [{ title: "Step-by-Step Lesson" }],
  frustrated: [{ title: "Easy Puzzle" }],
  neutral: [{ title: "Challenge Activity" }]
};
export default fallbackRecs;
'@ | Out-File -Encoding utf8 src\lib\fallbacks.ts -Force

Write-Host "✅ All FunLearn frontend files created!"

# --- Remove old vite cache if any ---
if (Test-Path node_modules\.vite) {
  Remove-Item -Recurse -Force node_modules\.vite
  Write-Host "🧹 Cleared Vite cache"
}

# --- Start the frontend ---
Write-Host "⚙️  Starting frontend server..." -ForegroundColor Yellow
npm run dev
