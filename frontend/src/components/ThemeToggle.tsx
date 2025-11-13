import React, { useEffect, useState } from "react";

export default function ThemeToggle(){
  const [theme, setTheme] = useState<string>(localStorage.getItem('funlearn_theme') || 'light');

  useEffect(()=>{
    apply(theme);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  },[]);

  function apply(t: string){
    const el = document.documentElement;
    if (t === 'dark') el.classList.add('dark'); else el.classList.remove('dark');
    localStorage.setItem('funlearn_theme', t);
    setTheme(t);
  }

  return (
    <button aria-label="Toggle theme" onClick={()=>apply(theme === 'dark' ? 'light' : 'dark')}
      className="px-3 py-1 rounded border bg-white/60 dark:bg-gray-800/60">
      {theme === 'dark' ? '🌙 Dark' : '☀️ Light'}
    </button>
  );
}
