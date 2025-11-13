import React, { useEffect, useRef, useState } from "react";

const SCRIPTS: Record<string,string> = {
  math: "Welcome to Math! For the next minute, we will think about numbers, shapes, and patterns. Math is like a puzzle. We add, subtract, sort, and discover. Keep your eyes on the screen and try the games. You can do it! Remember: take your time, think clearly, and have fun learning.",
  science: "Welcome to Science! For the next minute, imagine the world around you: plants, water, air, and animals. Science helps us ask questions and test ideas. Try the games and explore how the water cycle works and how our amazing bodies are labeled. Stay curious and have fun!",
  reading: "Welcome to English and Reading! For the next minute, listen and play with words and sounds. We will match words, listen to sounds, and build a tiny story. Reading is an adventure; each word is a step. Keep going and enjoy the journey!",
  art: "Welcome to Art! For the next minute, think about shapes, colors, and patterns. Art lets you create your own world using bright colors and fun shapes. Be creative and playful as you explore!"
};

export default function SubjectAudio({ subject }: { subject: string }){
  const [playing, setPlaying] = useState(false);
  const timerRef = useRef<number|undefined>(undefined);
  const synthRef = useRef<SpeechSynthesisUtterance|null>(null);
  const key = (subject||'').toLowerCase();
  const text = SCRIPTS[key] || SCRIPTS.math;

  const speakStart = () => {
    try{
      const synth = window.speechSynthesis; if (!synth) return;
      if (synth.speaking) synth.cancel();
      const utt = new SpeechSynthesisUtterance(text);
      utt.lang = 'en-US';
      utt.onend = () => setPlaying(false);
      synthRef.current = utt;
      synth.speak(utt);
      setPlaying(true);
    }catch(e){ /* ignore */ }
  };
  const stop = () => {
    try{ window.speechSynthesis?.cancel(); }catch(e){}
    if (timerRef.current) window.clearTimeout(timerRef.current);
    setPlaying(false);
  };

  useEffect(()=>()=>{ if (timerRef.current) window.clearTimeout(timerRef.current); try{ window.speechSynthesis?.cancel(); }catch(e){} },[]);

  return (
    <div className="flex items-center gap-2">
      {!playing ? (
        <button onClick={speakStart} className="px-3 py-1 rounded bg-violet-500 text-white hover:bg-violet-600">Play audio</button>
      ) : (
        <button onClick={stop} className="px-3 py-1 rounded bg-rose-500 text-white hover:bg-rose-600">Stop</button>
      )}
      <span className="text-sm text-gray-600">Subject narration (plays once)</span>
    </div>
  );
}
