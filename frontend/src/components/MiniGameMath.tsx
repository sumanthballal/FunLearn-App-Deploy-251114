import React, { useMemo, useState } from "react";

export default function MiniGameMath(){
  const [a, setA] = useState(()=>1+Math.floor(Math.random()*9));
  const [b, setB] = useState(()=>1+Math.floor(Math.random()*9));
  const [ans, setAns] = useState("");
  const [score, setScore] = useState(0);
  const correct = useMemo(()=> (a+b).toString(), [a,b]);

  const submit = () => {
    if (ans.trim() === correct){
      setScore(s=>s+1);
      // new question
      setA(1+Math.floor(Math.random()*9));
      setB(1+Math.floor(Math.random()*9));
      setAns("");
    } else {
      // shake or feedback could be added
    }
  };

  return (
    <div className="p-4 bg-white rounded-xl shadow border">
      <div className="text-lg font-semibold mb-2">Quick Math</div>
      <div className="mb-2">What is <b>{a}</b> + <b>{b}</b>?</div>
      <div className="flex gap-2">
        <input value={ans} onChange={e=>setAns(e.target.value)} className="px-3 py-2 border rounded w-24" placeholder="Answer" />
        <button onClick={submit} className="px-4 py-2 bg-blue-500 text-white rounded">Check</button>
      </div>
      <div className="mt-2 text-sm text-gray-600">Score: {score}</div>
    </div>
  );
}
