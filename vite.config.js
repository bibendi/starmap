import { defineConfig } from 'vite'
import RailsPlugin from 'vite-plugin-rails'
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [
    tailwindcss({
      // Явное указание источников для сканирования в Rails + HAML проекте
      scan: {
        dirs: ['app'],
        fileExtensions: ['.html', '.haml', '.erb']
      }
    }),
    RailsPlugin(),
  ],
  build: { sourcemap: false },
})
