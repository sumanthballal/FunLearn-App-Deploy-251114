$frontend = "C:\Users\balla\Desktop\Funlearn\frontend"
$vite = Join-Path $frontend "vite.config.js"

@'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  resolve: { alias: { "@": path.resolve(__dirname, "src") } },
  server: {
    port: 5173,
    proxy: {
      "/api": {
        target: "http://localhost:5000",
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/api/, ""),
      },
    },
  },
});
'@ | Set-Content $vite -Encoding UTF8

$pages = Join-Path $frontend "src\pages"
New-Item -ItemType Directory -Force -Path $pages | Out-Null

@'
export default function Home(){return <h1>Welcome to FunLearn Home!</h1>;}
'@ | Set-Content (Join-Path $pages "Home.tsx") -Encoding UTF8
@'
export default function Learn(){return <h1>Learning Page</h1>;}
'@ | Set-Content (Join-Path $pages "Learn.tsx") -Encoding UTF8
@'
export default function LessonShell(){return <h1>Lesson Shell</h1>;}
'@ | Set-Content (Join-Path $pages "LessonShell.tsx") -Encoding UTF8

Write-Host "✅ Alias fixed and placeholder pages created. Restart frontend with: npm run dev"
