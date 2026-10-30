import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import { spawn } from 'child_process'

function autoStartBackendPlugin() {
  let backendProc = null;
  return {
    name: 'auto-start-backend',
    configureServer(server) {
      const checkAndStart = async () => {
        try {
          const res = await fetch('http://localhost:5000/api/health');
          if (res.ok) {
            console.log('\n[CampusX] ✅ Backend server is running on port 5000.\n');
            return;
          }
        } catch (e) {
          console.log('\n[CampusX] 🚀 Auto-starting CampusX MySQL backend server (port 5000)...\n');
          backendProc = spawn('node', ['server/index.js'], {
            stdio: 'inherit',
            shell: true
          });
        }
      };

      checkAndStart();

      server.httpServer?.on('close', () => {
        if (backendProc) {
          backendProc.kill();
          backendProc = null;
        }
      });
    }
  };
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), autoStartBackendPlugin()],
  base: './',
  server: {
    host: '0.0.0.0', // Exposes dev server to all devices on the network
    port: 5174,
    proxy: {
      '/api': {
        target: 'http://localhost:5000',
        changeOrigin: true,
        configure: (proxy) => {
          proxy.on('error', (err, req, res) => {
            if (!res.headersSent && typeof res.writeHead === 'function') {
              res.writeHead(503, { 'Content-Type': 'application/json' });
              res.end(JSON.stringify({
                success: false,
                error: {
                  code: 'BACKEND_OFFLINE',
                  message: 'CampusX Backend Server is offline or starting up. Please ensure MySQL is started in XAMPP.'
                }
              }));
            }
          });
        }
      }
    }
  }
})
