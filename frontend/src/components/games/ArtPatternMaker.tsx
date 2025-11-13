import React, { useMemo, useState } from "react";

const PALETTE = ['#ff0000','#0000ff','#ffff00','#00ff00','#ff00ff','#00ffff','#ffa500','#800080','#8b4513','#000000'];
type Shape = 'circle' | 'square' | 'triangle' | 'star';

export default function ArtPatternMaker(){
  const [colors, setColors] = useState<string[]>([]);
  const [shape, setShape] = useState<Shape>('circle');

  function addColor(c:string){ setColors(cs=> cs.length<8 ? [...cs, c] : cs); }
  function clear(){ setColors([]); }

  const tiles = useMemo(()=>{
    if (colors.length===0) return [] as string[];
    const repeatCount = 12;
    return Array.from({length: repeatCount}, (_,i)=> colors[i % colors.length]);
  }, [colors]);

  return (
    <div className="p-6 bg-white rounded-xl border shadow w-full max-w-3xl">
      <div className="font-semibold mb-3">Pattern Maker</div>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 items-start">
        <div>
          <div className="text-sm text-gray-600 mb-2">Pick up to 8 colors</div>
          <div className="flex flex-wrap gap-2 mb-2">
            {PALETTE.map(c=> (
              <button key={c} onClick={()=>addColor(c)} className="w-10 h-10 rounded-full border" style={{backgroundColor:c}} />
            ))}
          </div>
          <div className="text-sm text-gray-600 mb-1">Your sequence</div>
          <div className="flex flex-wrap gap-1 mb-3">
            {colors.map((c,i)=> <span key={i} className="w-6 h-6 rounded inline-block border" style={{backgroundColor:c}} />)}
          </div>
          <div className="flex gap-2">
            <button onClick={clear} className="px-3 py-1 rounded border">Clear</button>
          </div>
        </div>

        <div>
          <div className="text-sm text-gray-600 mb-2">Choose a shape</div>
          <div className="flex flex-wrap gap-2">
            {(['circle','square','triangle','star'] as Shape[]).map(s=> (
              <button key={s} onClick={()=>setShape(s)} className={`px-3 py-2 rounded ${shape===s? 'bg-pink-600 text-white':'bg-pink-100 text-pink-800'}`}>{s}</button>
            ))}
          </div>
        </div>

        <div className="lg:col-span-1">
          <div className="text-sm text-gray-600 mb-2">Preview</div>
          <ShapePreview shape={shape} tiles={tiles} />
        </div>
      </div>
    </div>
  );
}

function ShapePreview({shape, tiles}:{shape: Shape; tiles: string[]}){
  const size = 260;
  const clipId = `clip-${shape}`;
  const tileSize = 26;
  const cols = Math.ceil(size / tileSize);
  const rows = Math.ceil(size / tileSize);
  const all = Array.from({length: rows*cols}, (_,i)=> tiles.length? tiles[i % tiles.length] : '#eeeeee');
  return (
    <svg width={size} height={size} className="rounded border bg-white">
      <defs>
        {shape==='circle' && (
          <clipPath id={clipId}><circle cx={size/2} cy={size/2} r={size*0.45} /></clipPath>
        )}
        {shape==='square' && (
          <clipPath id={clipId}><rect x={size*0.1} y={size*0.1} width={size*0.8} height={size*0.8} rx={8} /></clipPath>
        )}
        {shape==='triangle' && (
          <clipPath id={clipId}>
            <polygon points={`${size/2},${size*0.1} ${size*0.9},${size*0.9} ${size*0.1},${size*0.9}`} />
          </clipPath>
        )}
        {shape==='star' && (
          <clipPath id={clipId}>
            <polygon points={starPoints(size/2, size/2, size*0.42, size*0.18, 5)} />
          </clipPath>
        )}
      </defs>
      <g clipPath={`url(#${clipId})`}>
        {all.map((c,i)=>{
          const x = (i % cols) * tileSize;
          const y = Math.floor(i / cols) * tileSize;
          return <rect key={i} x={x} y={y} width={tileSize} height={tileSize} fill={c}/>;
        })}
      </g>
      <rect x={1} y={1} width={size-2} height={size-2} fill="none" stroke="#ddd" />
    </svg>
  );
}

function starPoints(cx:number, cy:number, outerR:number, innerR:number, spikes:number){
  let rot = Math.PI / 2 * 3;
  let x = cx; let y = cy;
  const step = Math.PI / spikes;
  const pts:string[] = [];
  for (let i = 0; i < spikes; i++){
    x = cx + Math.cos(rot) * outerR; y = cy + Math.sin(rot) * outerR; pts.push(`${x},${y}`); rot += step;
    x = cx + Math.cos(rot) * innerR; y = cy + Math.sin(rot) * innerR; pts.push(`${x},${y}`); rot += step;
  }
  return pts.join(' ');
}
