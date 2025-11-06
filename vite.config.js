import { defineConfig } from 'vite'
import RailsPlugin from 'vite-plugin-rails'
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [
    tailwindcss(),
    RailsPlugin(),
  ],
  build: { sourcemap: false },
})
