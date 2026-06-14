import { defineConfig } from "vite";
import { svelte } from "@sveltejs/vite-plugin-svelte";

export default defineConfig({
  plugins: [svelte()],
  server: {
    port: 7332,
    strictPort: true,
    proxy: {
      "/api": "http://127.0.0.1:7331",
    },
  },
  build: {
    outDir: "dist",
    emptyOutDir: true,
  },
});
