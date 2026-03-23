// ─── App Entry Point ──────────────────────────────────────────────────────────
import { initAuth, logout, currentUser } from './auth.js';
import { initRouter, registerRoute, navigate } from './router.js';
import { showToast, hideConfirmModal } from './utils.js';
import { loadDashboard } from './pages/dashboard.js';
import { loadApprovals } from './pages/approvals.js';
import { loadCanteens } from './pages/canteens.js';
import { loadUsers } from './pages/users.js';
import { loadOrders } from './pages/orders.js';
import { loadAnalytics } from './pages/analytics.js';

// ─── Login Handler ─────────────────────────────────────────────────────────────
import { login } from './auth.js';

const loginForm = document.getElementById('login-form');
if (loginForm) {
  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const btn = document.getElementById('login-btn');
    const errorEl = document.getElementById('auth-error');

    errorEl.classList.remove('show');
    btn.disabled = true;
    btn.innerHTML = `<div class="btn-spinner"></div> Signing in…`;

    try {
      await login(email, password);
      // Auth state change will handle the transition
    } catch (err) {
      errorEl.textContent = err.message || 'Login failed. Please try again.';
      errorEl.classList.add('show');
      btn.disabled = false;
      btn.innerHTML = 'Sign In as Admin';
    }
  });
}

// ─── Confirm Modal Close ───────────────────────────────────────────────────────
document.getElementById('confirm-modal-cancel').addEventListener('click', hideConfirmModal);
document.getElementById('confirm-modal').addEventListener('click', (e) => {
  if (e.target === e.currentTarget) hideConfirmModal();
});

// ─── Logout ───────────────────────────────────────────────────────────────────
document.getElementById('logout-btn').addEventListener('click', async () => {
  await logout();
});

// ─── Auth State ───────────────────────────────────────────────────────────────
function showApp(user) {
  document.getElementById('auth-screen').style.display = 'none';
  document.getElementById('app').style.display = 'flex';

  // Set user info in sidebar
  const email = user.email || '';
  const initials = email.charAt(0).toUpperCase();
  document.getElementById('user-avatar-text').textContent = initials;
  document.getElementById('user-name-text').textContent = email.split('@')[0];
  document.getElementById('user-role-text').textContent = 'Admin';

  // Set clock
  updateClock();
  setInterval(updateClock, 1000);

  // Register routes
  registerRoute('dashboard', loadDashboard);
  registerRoute('approvals', loadApprovals);
  registerRoute('canteens', loadCanteens);
  registerRoute('users', loadUsers);
  registerRoute('orders', loadOrders);
  registerRoute('analytics', loadAnalytics);

  // Init router
  initRouter();

  showToast('Welcome back! 👋', 'success');
}

function showLogin() {
  document.getElementById('auth-screen').style.display = 'flex';
  document.getElementById('app').style.display = 'none';
  const btn = document.getElementById('login-btn');
  if (btn) { btn.disabled = false; btn.innerHTML = 'Sign In as Admin'; }
}

function updateClock() {
  const el = document.getElementById('topbar-clock');
  if (el) {
    el.textContent = new Date().toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true });
  }
}

// Boot
initAuth(showApp, showLogin);

// Update pending badge in sidebar periodically
import { db } from './firebase-config.js';
import { collection, query, where, onSnapshot } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";

const pendingQ = query(collection(db, 'Owners'), where('status', '==', 'pending'));
onSnapshot(pendingQ, snap => {
  const badge = document.getElementById('nav-badge-approvals');
  if (badge) {
    badge.textContent = snap.size;
    badge.style.display = snap.size > 0 ? 'flex' : 'none';
  }
});
