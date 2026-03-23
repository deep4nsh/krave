// ─── Manage Users Page ────────────────────────────────────────────────────────
import { db } from '../firebase-config.js';
import { collection, onSnapshot, orderBy, query } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";
import { registerListener, roleBadge, debounce } from '../utils.js';

export async function loadUsers() {
  const main = document.getElementById('main-content');
  main.innerHTML = `
    <div class="page-header">
      <div class="page-header-left">
        <h1>Manage Users</h1>
        <p>View all registered users across the platform.</p>
      </div>
      <div id="users-count"></div>
    </div>
    <div class="filters-bar">
      <div class="search-box">
        <span>🔍</span>
        <input type="text" id="user-search" placeholder="Search name or email...">
      </div>
      <select class="filter-select" id="role-filter">
        <option value="">All Roles</option>
        <option value="user">Users</option>
        <option value="approvedOwner">Owners</option>
        <option value="pendingOwner">Pending Owners</option>
        <option value="admin">Admins</option>
      </select>
      <div class="filters-spacer"></div>
    </div>
    <div class="card">
      <div class="table-wrapper">
        <table>
          <thead><tr>
            <th>User</th><th>Email</th><th>Role</th><th>Canteen ID</th>
          </tr></thead>
          <tbody id="users-tbody">
            <tr><td colspan="4"><div class="page-loading"><div class="spinner"></div></div></td></tr>
          </tbody>
        </table>
      </div>
    </div>
  `;

  let allUsers = [];

  const unsub = onSnapshot(collection(db, 'Users'), snap => {
    allUsers = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    document.getElementById('users-count').innerHTML = `<span class="badge badge-info" style="font-size:14px;padding:6px 14px">${allUsers.length} Users</span>`;
    renderUsers(allUsers);
  });
  registerListener(unsub);

  const doFilter = () => {
    const q = document.getElementById('user-search').value.toLowerCase();
    const role = document.getElementById('role-filter').value;
    renderUsers(allUsers.filter(u =>
      (u.name||'').toLowerCase().includes(q) || (u.email||'').toLowerCase().includes(q)
    ).filter(u => !role || u.role === role));
  };

  document.getElementById('user-search').addEventListener('input', debounce(doFilter));
  document.getElementById('role-filter').addEventListener('change', doFilter);
}

function renderUsers(users) {
  const tbody = document.getElementById('users-tbody');
  if (!tbody) return;
  if (!users.length) {
    tbody.innerHTML = `<tr><td colspan="4"><div class="empty-state" style="padding:40px"><div class="empty-icon">👥</div><p>No users found</p></div></td></tr>`;
    return;
  }
  tbody.innerHTML = users.map(u => {
    const initials = (u.name || 'U').charAt(0).toUpperCase();
    return `<tr>
      <td>
        <div style="display:flex;align-items:center;gap:10px">
          <div style="width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#3b82f6,#8b5cf6);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;flex-shrink:0">${initials}</div>
          <div>
            <div class="td-name">${u.name || 'Unknown'}</div>
            <div class="td-sub" style="font-family:monospace">${u.id.substring(0,12)}…</div>
          </div>
        </div>
      </td>
      <td style="color:var(--text-secondary)">${u.email || '—'}</td>
      <td>${roleBadge(u.role)}</td>
      <td style="color:var(--text-muted);font-family:monospace;font-size:12px">${u.canteenId ? u.canteenId.substring(0,12)+'…' : '—'}</td>
    </tr>`;
  }).join('');
}
