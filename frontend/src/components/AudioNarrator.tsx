import React, { useEffect, useRef } from "react";

export default function AudioNarrator({ text, auto = false }: { text: string; auto?: boolean }){
  const lastSpoken = useRef<string>("");
  const speak = (t: string) => {
    try{
      const synth = window.speechSynthesis;
      if (!synth) return;
      const utt = new SpeechSynthesisUtterance(t);
      utt.lang = 'en-US';
      synth.cancel();
      synth.speak(utt);
    }catch(e){ /* ignore */ }
  };

  useEffect(()=>{
    if (auto && text && text !== lastSpoken.current){
      lastSpoken.current = text;
      speak(text);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [text, auto]);

  return (
    <div className="flex items-center gap-2">
      <button onClick={()=>speak(text)} className="px-3 py-1 rounded bg-emerald-500 text-white hover:bg-emerald-600">Play narration</button>
      <span className="text-sm text-gray-600">Audio narration</span>
    </div>
  );
}
