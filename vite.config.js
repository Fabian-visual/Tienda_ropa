import { defineConfig, loadEnv } from 'vite';
import { resolve } from 'path';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  return {
    plugins: [
      {
        name: 'html-transform',
        transformIndexHtml(html) {
          return html
            .replace(/%VITE_SUPABASE_URL%/g, env.VITE_SUPABASE_URL)
            .replace(/%VITE_SUPABASE_ANON_KEY%/g, env.VITE_SUPABASE_ANON_KEY);
        }
      }
    ],
    build: {
      rollupOptions: {
        input: {
          main: resolve(__dirname, 'index.html'),
          admin: resolve(__dirname, 'admin.html'),
          checkout: resolve(__dirname, 'checkout.html'),
          personalizador: resolve(__dirname, 'personalizador.html'),
          politicas: resolve(__dirname, 'politicas.html'),
          profile: resolve(__dirname, 'profile.html'),
          test_supabase: resolve(__dirname, 'test_supabase.html'),
          nosotros: resolve(__dirname, 'nosotros.html'),
          contacto: resolve(__dirname, 'contacto.html'),
        }
      }
    }
  };
});
