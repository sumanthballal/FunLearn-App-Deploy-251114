import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "../index.css";

// Initialize theme quickly to avoid flash
try{
  const t = localStorage.getItem('funlearn_theme') || 'light';
  if (t === 'dark') document.documentElement.classList.add('dark'); else document.documentElement.classList.remove('dark');
}catch(e){ /* ignore */ }

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>
);
