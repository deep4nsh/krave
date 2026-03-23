// ─── Router ───────────────────────────────────────────────────────────────────
import { clearAllListeners } from './utils.js';

const routes = {};
let currentRoute = null;

export function registerRoute(hash, loader) {
  routes[hash] = loader;
}

export function navigate(hash) {
  window.location.hash = hash;
}

export function initRouter() {
  const handleHash = async () => {
    const hash = window.location.hash.replace('#', '') || 'dashboard';

    // Update sidebar active state
    document.querySelectorAll('.nav-link').forEach(link => {
      link.classList.toggle('active', link.dataset.route === hash);
    });

    // Update page title
    const titleEl = document.getElementById('page-title');
    const titles = {
      dashboard: '📊 Dashboard',
      approvals: '✅ Owner Approvals',
      canteens: '🏪 Manage Canteens',
      users: '👥 Manage Users',
      orders: '📦 Orders',
      analytics: '📈 Analytics',
    };
    if (titleEl) titleEl.textContent = titles[hash] || 'Dashboard';

    // Clear previous Firestore subscriptions
    clearAllListeners();

    // Load the page
    const loader = routes[hash];
    if (loader) {
      const main = document.getElementById('main-content');
      main.innerHTML = `<div class="page-loading"><div class="spinner"></div></div>`;
      try {
        await loader();
      } catch (e) {
        console.error('Route error:', e);
        main.innerHTML = `<div class="error-state"><h2>⚠️ Failed to load page</h2><p>${e.message}</p></div>`;
      }
    }
    currentRoute = hash;
  };

  window.addEventListener('hashchange', handleHash);
  handleHash(); // initial load
}
