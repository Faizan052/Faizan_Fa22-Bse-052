import { defineConfig } from 'vite'

export default defineConfig({
  root: '.',
  server: {
    port: 5173,
    // Proxy API requests to the backend during development so `fetch('/api/...')` works
    proxy: {
      '/api': 'http://localhost:3000'
    }
  }
})
