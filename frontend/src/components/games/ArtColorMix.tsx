import React, { useState } from "react";

export default function ArtColorMix(){
  const palette = [
    '#ff0000','#0000ff','#ffff00','#00ff00','#ff00ff','#00ffff','#ffa500','#800080','#8b4513','#000000'
  ];
  const [a,setA] = useState<string>(palette[0]);
  const [b,setB] = useState<string>(palette[1]);
  function mixColor(c1:string, c2:string){
    const n1 = hexToRgb(c1); const n2 = hexToRgb(c2);
    const r = Math.round((n1.r+n2.r)/2), g=Math.round((n1.g+n2.g)/2), b=Math.round((n1.b+n2.b)/2);
    return rgbToHex(r,g,b);
  }
  const result = mixColor(a,b);
  const txt = getTextColor(result);
  const name = nearestColorName(result);
  return (
    <div className="p-6 bg-white rounded-xl border shadow w-full max-w-2xl">
      <div className="font-semibold mb-3">Color Mix</div>
      <div className="grid grid-cols-2 gap-4 mb-4">
        <Palette value={a} onPick={setA} title="Color A" colors={palette} />
        <Palette value={b} onPick={setB} title="Color B" colors={palette} />
      </div>
      <div className="h-20 rounded flex items-center justify-center text-lg font-semibold border" style={{backgroundColor: result, color: txt, borderColor: txt}}>
        {name}
      </div>
    </div>
  );
}

function Palette({value, onPick, title, colors}:{value:string; onPick:(c:string)=>void; title:string; colors:string[]}){
  return (
    <div>
      <div className="text-sm text-gray-600 mb-2">{title}</div>
      <div className="flex flex-wrap gap-2">
        {colors.map(c=> (
          <button key={c} onClick={()=>onPick(c)} className={`w-10 h-10 rounded-full border ${value===c? 'ring-2 ring-pink-500':''}`} style={{backgroundColor:c}} />
        ))}
      </div>
    </div>
  );
}

function hexToRgb(hex:string){
  const h = hex.replace('#','');
  const bigint = parseInt(h, 16);
  return { r: (bigint>>16)&255, g: (bigint>>8)&255, b: bigint&255 };
}
function componentToHex(c:number){ const h=c.toString(16).padStart(2,'0'); return h; }
function rgbToHex(r:number,g:number,b:number){ return `#${componentToHex(r)}${componentToHex(g)}${componentToHex(b)}`; }
function getTextColor(hex:string){ const {r,g,b}=hexToRgb(hex); const lum=(0.299*r+0.587*g+0.114*b); return lum>160 ? '#111111' : '#ffffff'; }
function hexToRgbStr(hex:string){ const {r,g,b}=hexToRgb(hex); return `rgb(${r},${g},${b})`; }

// Simple nearest color name lookup for common results
const NAMED: Record<string,string> = {
  '#ff0000': 'Red',
  '#00ff00': 'Lime',
  '#0000ff': 'Blue',
  '#ffff00': 'Yellow',
  '#ff00ff': 'Magenta',
  '#00ffff': 'Cyan',
  '#ffa500': 'Orange',
  '#800080': 'Purple',
  '#8b4513': 'Brown',
  '#000000': 'Black',
  '#ffffff': 'White',
  '#808080': 'Gray',
  '#800000': 'Maroon',
  '#008000': 'Green',
  '#000080': 'Navy',
  '#808000': 'Olive',
  '#008080': 'Teal',
  '#c0c0c0': 'Silver'
};

function nearestColorName(hex:string){
  // Exact match
  const h = hex.toLowerCase();
  if (NAMED[h]) return NAMED[h];
  const target = hexToRgb(h);
  let bestKey = '#000000';
  let bestDist = Number.POSITIVE_INFINITY;
  for (const [k,v] of Object.entries(NAMED)){
    const c = hexToRgb(k);
    const d = (c.r-target.r)**2 + (c.g-target.g)**2 + (c.b-target.b)**2;
    if (d < bestDist){ bestDist = d; bestKey = k; }
  }
  return NAMED[bestKey];
}
