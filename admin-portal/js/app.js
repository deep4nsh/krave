// ─── App Entry Point ──────────────────────────────────────────────────────────
import { initAuth, logout, currentUser, userRole } from './auth.js';
import { initRouter, registerRoute, navigate } from './router.js';
import { showToast, hideConfirmModal } from './utils.js';
import { loadDashboard } from './pages/dashboard.js';
import { loadApprovals } from './pages/approvals.js';
import { loadCanteens } from './pages/canteens.js';
import { loadUsers } from './pages/users.js';
import { loadOrders } from './pages/orders.js';
import { loadAnalytics } from './pages/analytics.js';
import { loadRiders } from './pages/riders.js';
import { loadMenuManagement } from './pages/menu_management.js';
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
    } catch (err) {
      errorEl.textContent = err.message || 'Login failed.';
      errorEl.classList.add('show');
      btn.disabled = false;
      btn.innerHTML = 'Sign In';
    }
  });
}

document.getElementById('confirm-modal-cancel').addEventListener('click', hideConfirmModal);
document.getElementById('logout-btn').addEventListener('click', async () => { await logout(); });

function showApp(user) {
  document.getElementById('auth-screen').style.display = 'none';
  document.getElementById('app').style.display = 'flex';

  // UI Masking based on Role
  const sidebar = document.getElementById('sidebar');
  if (userRole === 'owner') {
     // Hide SuperAdmin-only tabs
     sidebar.querySelectorAll('[data-superadmin="true"]').forEach(el => el.style.display = 'none');
     document.getElementById('owner-section').style.display = 'block';
  } else {
     sidebar.querySelectorAll('[data-superadmin="true"]').forEach(el => el.style.display = 'flex');
     document.getElementById('owner-section').style.display = 'none';
  }

  const email = user.email || '';
  document.getElementById('user-avatar-text').textContent = email.charAt(0).toUpperCase();
  document.getElementById('user-name-text').textContent = email.split('@')[0];
  document.getElementById('user-role-text').textContent = userRole.toUpperCase();

  updateClock();
  setInterval(updateClock, 1000);

  // Routes
  registerRoute('dashboard', loadDashboard);
  registerRoute('analytics', loadAnalytics);
  registerRoute('approvals', loadApprovals);
  registerRoute('canteens', loadCanteens);
  registerRoute('users', loadUsers);
  registerRoute('riders', loadRiders);
  registerRoute('orders', loadOrders);
  registerRoute('menu', () => loadMenuManagement(currentUser.canteenId));

  initRouter();
  showToast(`Logged in as ${userRole}! 👋`, 'success');
}

function showLogin() {
  document.getElementById('auth-screen').style.display = 'flex';
  document.getElementById('app').style.display = 'none';
}

function updateClock() {
  const el = document.getElementById('topbar-clock');
  if (el) el.textContent = new Date().toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true });
}

initAuth(showApp, showLogin);
