// ─── Dashboard Page ────────────────────────────────────────────────────────────
import { db } from '../firebase-config.js';
import {
  collection, query, where, orderBy, limit,
  getDocs, onSnapshot, Timestamp
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";
import { registerListener, formatDate, formatCurrency, statusBadge } from '../utils.js';

export async function loadDashboard() {
  const main = document.getElementById('main-content');
  main.innerHTML = `
    <div class="page-header">
      <div class="page-header-left">
        <h1>Welcome back, Admin 👋</h1>
        <p>Here's what's happening in your platform today.</p>
      </div>
    </div>

    <div class="stats-grid" id="stats-grid">
      ${['bg-users','bg-canteens','bg-pending','bg-orders','bg-revenue'].map(id => `
        <div class="stat-card" style="--card-accent:${statColor(id)}">
          <div class="stat-icon">${statIcon(id)}</div>
          <div class="stat-value skeleton" style="height:32px;width:80px;margin-bottom:8px">&nbsp;</div>
          <div class="stat-label skeleton" style="width:120px">&nbsp;</div>
        </div>`).join('')}
    </div>

    <div class="dashboard-grid">
      <div class="card">
        <div class="card-header">
          <div>
            <div class="card-title">Recent Orders</div>
            <div class="card-subtitle">Last 10 orders across all canteens</div>
          </div>
          <a href="#orders" class="btn btn-ghost btn-sm">View all</a>
        </div>
        <div class="table-wrapper">
          <table>
            <thead><tr>
              <th>Token</th><th>Canteen</th><th>Amount</th><th>Status</th><th>Time</th>
            </tr></thead>
            <tbody id="recent-orders-body">
              <tr><td colspan="5" style="textAlign:center;padding:40px;color:var(--text-muted)">
                <div class="spinner" style="margin:0 auto"></div>
              </td></tr>
            </tbody>
          </table>
        </div>
      </div>

      <div class="card">
        <div class="card-header">
          <div>
            <div class="card-title">Pending Approvals</div>
            <div class="card-subtitle">New canteen owners awaiting review</div>
          </div>
          <a href="#approvals" class="btn btn-ghost btn-sm">Manage</a>
        </div>
        <div id="pending-list" class="card-body">
          <div class="spinner" style="margin:60px auto;display:block"></div>
        </div>
      </div>
    </div>
  `;

  await loadStats();
  loadRecentOrders();
  loadPendingList();
}

function statColor(id) {
  const m = { 'bg-users':'#3b82f6','bg-canteens':'#10b981','bg-pending':'#f59e0b','bg-orders':'#8b5cf6','bg-revenue':'#f59e0b' };
  return m[id] || '#f59e0b';
}
function statIcon(id) {
  const m = { 'bg-users':'👥','bg-canteens':'🏪','bg-pending':'⏳','bg-orders':'📦','bg-revenue':'💰' };
  return m[id] || '📊';
}

async function loadStats() {
  const grid = document.getElementById('stats-grid');
  // Fetch each collection independently so one failure doesn't block others
  const safeGet = async (q, label) => {
    try { return await getDocs(q); }
    catch (e) { console.warn(`Stats: ${label} failed —`, e.message); return null; }
  };

  const [usersSnap, canteensSnap, pendingSnap, ordersSnap] = await Promise.all([
    safeGet(collection(db, 'Users'),  'Users'),
    safeGet(query(collection(db, 'Canteens'), where('approved', '==', true)), 'Canteens'),
    safeGet(query(collection(db, 'Owners'), where('status', '==', 'pending')), 'Owners'),
    safeGet(collection(db, 'Orders'), 'Orders'),
  ]);

  const totalRevenue = ordersSnap ? ordersSnap.docs.reduce((sum, d) => {
    const status = d.data().status;
    const isDone = status === 'Completed' || status === 'Ready for Pickup' || status === 'Ready';
    return isDone ? sum + (d.data().totalAmount || 0) : sum;
  }, 0) : 0;

  const stats = [
    { label: 'Total Users',      value: usersSnap    ? usersSnap.size    : '—', color: '#3b82f6', icon: '👥' },
    { label: 'Active Canteens',  value: canteensSnap ? canteensSnap.size : '—', color: '#10b981', icon: '🏪' },
    { label: 'Pending Approvals',value: pendingSnap  ? pendingSnap.size  : '—', color: '#f59e0b', icon: '⏳' },
    { label: 'Total Orders',     value: ordersSnap   ? ordersSnap.size   : '—', color: '#8b5cf6', icon: '📦' },
    { label: 'Revenue Collected',value: ordersSnap   ? formatCurrency(totalRevenue) : '—', color: '#f59e0b', icon: '💰' },
  ];

  if (!grid) return;
  grid.innerHTML = stats.map(s => `
    <div class="stat-card" style="--card-accent:${s.color}">
      <div class="stat-icon">${s.icon}</div>
      <div class="stat-value">${s.value}</div>
      <div class="stat-label">${s.label}</div>
    </div>`).join('');
}

function loadRecentOrders() {
  const q = query(collection(db, 'Orders'), orderBy('timestamp', 'desc'), limit(10));
  const unsub = onSnapshot(q, snap => {
    const tbody = document.getElementById('recent-orders-body');
    if (!tbody) return;
    if (snap.empty) {
      tbody.innerHTML = `<tr><td colspan="5"><div class="empty-state" style="padding:30px"><div class="empty-icon">📦</div><p>No orders yet</p></div></td></tr>`;
      return;
    }
    tbody.innerHTML = snap.docs.map(d => {
      const o = d.data();
      return `<tr>
        <td><code style="color:var(--accent);font-size:12px">${o.tokenNumber || '—'}</code></td>
        <td class="td-name">${o.canteenId?.substring(0,8) || '—'}</td>
        <td>${formatCurrency(o.totalAmount)}</td>
        <td>${statusBadge(o.status)}</td>
        <td style="color:var(--text-muted);font-size:12px">${formatDate(o.timestamp)}</td>
      </tr>`;
    }).join('');
  });
  registerListener(unsub);
}

function loadPendingList() {
  const q = query(collection(db, 'Owners'), where('status', '==', 'pending'));
  const unsub = onSnapshot(q, snap => {
    const el = document.getElementById('pending-list');
    if (!el) return;
    if (snap.empty) {
      el.innerHTML = `<div class="empty-state" style="padding:30px"><div class="empty-icon">✅</div><h3>All clear!</h3><p>No pending approvals.</p></div>`;
      return;
    }
    el.innerHTML = `<div class="activity-feed">${snap.docs.map(d => {
      const o = d.data();
      return `<div class="activity-item">
        <div class="activity-dot" style="background:var(--warning)"></div>
        <div class="activity-content">
          <div class="activity-title">${o.name || 'Unknown'} — ${o.canteen_name || 'N/A'}</div>
          <div class="activity-time">${o.email} · ${formatDate(o.createdAt)}</div>
        </div>
        <a href="#approvals" class="btn btn-ghost btn-sm">Review</a>
      </div>`;
    }).join('')}</div>`;
  });
  registerListener(unsub);
}
