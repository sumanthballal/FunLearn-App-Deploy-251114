import React from "react";
export default function HelpFAB({onClick}:{onClick?:()=>void}) {
  return <button onClick={onClick} className="fixed bottom-6 right-6 p-3 rounded-full bg-white shadow-lg">Help</button>;
}
