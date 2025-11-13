import React, { useEffect, useMemo, useState } from "react";

type Grid = number[][];
const SIZE = 6;

function emptyGrid(): Grid { return Array.from({length: SIZE}, ()=> Array(SIZE).fill(0)); }
function randEmpty(grid: Grid): [number, number] | null {
  const empties: [number, number][] = [];
  for (let r=0;r<SIZE;r++) for (let c=0;c<SIZE;c++) if (!grid[r][c]) empties.push([r,c]);
  if (empties.length === 0) return null;
  return empties[Math.floor(Math.random()*empties.length)];
}
function spawn(grid: Grid){
  const spot = randEmpty(grid); if (!spot) return;
  const [r,c] = spot; grid[r][c] = Math.random() < 0.9 ? 2 : 4;
}
function clone(g: Grid): Grid { return g.map(row=>row.slice()); }
function compress(row: number[]): number[] { return row.filter(v=>v!==0); }
function pad(row: number[]): number[] { while(row.length<SIZE) row.push(0); return row; }
function merge(row: number[]): [number[], number] {
  let score = 0;
  for (let i=0;i<row.length-1;i++){
    if (row[i]!==0 && row[i]===row[i+1]){ row[i]*=2; score+=row[i]; row[i+1]=0; i++; }
  }
  return [pad(compress(row)), score];
}
function moveLeft(grid: Grid): [Grid, number, boolean]{
  let moved = false, total=0; const g = grid.map(row=>{ const before=row.join(','); const [m,s]=merge(pad(compress(row.slice()))); if (m.join(',')!==before) moved=true; total+=s; return m; });
  return [g,total,moved];
}
function rotate(grid: Grid): Grid { // rotate clockwise
  const g = emptyGrid();
  for (let r=0;r<SIZE;r++) for (let c=0;c<SIZE;c++) g[c][SIZE-1-r] = grid[r][c];
  return g;
}
function move(grid: Grid, dir: 'left'|'right'|'up'|'down'): [Grid, number, boolean]{
  let g = clone(grid); let total=0; let moved=false;
  if (dir==='left') return moveLeft(g);
  if (dir==='right'){
    g = g.map(row=>row.slice().reverse());
    const [gg, t, m] = moveLeft(g);
    g = gg.map(row=>row.slice().reverse()); total+=t; moved=m; return [g,total,moved];
  }
  if (dir==='up'){
    // rotate left, moveLeft, rotate right
    g = rotate(rotate(rotate(g)));
    const [gg, t, m] = moveLeft(g); total+=t; moved=m;
    g = rotate(gg);
    return [g,total,moved];
  }
  // down
  g = rotate(g);
  const [gg, t, m] = moveLeft(g); total+=t; moved=m;
  g = rotate(rotate(rotate(gg)));
  return [g,total,moved];
}
function hasMoves(grid: Grid){
  for (let r=0;r<SIZE;r++) for (let c=0;c<SIZE;c++){
    if (grid[r][c]===0) return true;
    if (r+1<SIZE && grid[r][c]===grid[r+1][c]) return true;
    if (c+1<SIZE && grid[r][c]===grid[r][c+1]) return true;
  }
  return false;
}

export default function Game2048(){
  const [grid, setGrid] = useState<Grid>(()=>{ const g=emptyGrid(); spawn(g); spawn(g); return g; });
  const [score, setScore] = useState(0);

  useEffect(()=>{
    const onKey = (e: KeyboardEvent)=>{
      const map: any = { ArrowLeft:'left', ArrowRight:'right', ArrowUp:'up', ArrowDown:'down' };
      const dir = map[e.key]; if (!dir) return;
      e.preventDefault();
      setGrid(g=>{
        const [ng, delta, moved] = move(g, dir);
        if (!moved) return g;
        spawn(ng); setScore(s=>s+delta);
        return ng;
      });
    };
    window.addEventListener('keydown', onKey);
    return ()=> window.removeEventListener('keydown', onKey);
  },[]);

  const over = useMemo(()=> !hasMoves(grid), [grid]);

  const reset = ()=>{ const g=emptyGrid(); spawn(g); spawn(g); setScore(0); setGrid(g); };

  return (
    <div className="p-4 bg-amber-50 rounded-xl border w-full max-w-2xl select-none">
      <div className="flex items-center justify-between mb-2">
        <div className="font-semibold">2048</div>
        <div className="text-sm">Score: {score}</div>
      </div>
      <div className="grid grid-cols-6 gap-2">
        {grid.flatMap((row,r)=> row.map((v,c)=> (
          <div key={`${r}-${c}`} className={`h-16 rounded flex items-center justify-center text-xl font-bold ${v? 'bg-amber-200 text-amber-900' : 'bg-amber-100 text-amber-400'}`}>{v||''}</div>
        )))}
      </div>
      <div className="mt-2 text-xs text-gray-600">Use arrow keys to move tiles. Merge to reach 2048!</div>
      {over && (
        <div className="mt-2 text-rose-600 font-semibold">Game Over</div>
      )}
      <button onClick={reset} className="mt-2 px-3 py-1 rounded bg-amber-500 text-white">Reset</button>
    </div>
  );
}
