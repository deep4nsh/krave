// ─── Orders Page ──────────────────────────────────────────────────────────────
import { db } from '../firebase-config.js';
import {
  collection, query, orderBy, onSnapshot,
  doc, updateDoc, serverTimestamp, getDocs, where
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";
import { registerListener, showToast, formatDate, formatCurrency, statusBadge, exportToCSV, debounce } from '../utils.js';

const ORDER_STATUSES = ['Pending', 'Preparing', 'Ready for Pickup', 'Completed', 'Cancelled'];

export async function loadOrders() {
  const main = document.getElementById('main-content');
  main.innerHTML = `
    <div class="page-header">
      <div class="page-header-left">
        <h1>All Orders</h1>
        <p>Real-time order management across all canteens.</p>
      </div>
      <button class="btn btn-ghost" id="export-btn">⬇️ Export CSV</button>
    </div>
    <div class="filters-bar">
      <div class="search-box">
        <span>🔍</span>
        <input type="text" id="order-search" placeholder="Search token, payment ID...">
      </div>
      <select class="filter-select" id="status-filter">
        <option value="">All Statuses</option>
        ${ORDER_STATUSES.map(s => `<option value="${s}">${s}</option>`).join('')}
      </select>
      <div class="filters-spacer"></div>
      <div id="orders-count"></div>
    </div>
    <div class="card">
      <div class="table-wrapper">
        <table>
          <thead><tr>
            <th>Token</th><th>Items</th><th>Amount</th><th>Status</th>
            <th>Payment ID</th><th>Time</th><th>Update</th>
          </tr></thead>
          <tbody id="orders-tbody">
            <tr><td colspan="7"><div class="page-loading"><div class="spinner"></div></div></td></tr>
          </tbody>
        </table>
      </div>
    </div>
  `;

  let allOrders = [];

  const q = query(collection(db, 'Orders'), orderBy('timestamp', 'desc'));
  const unsub = onSnapshot(q, snap => {
    allOrders = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    updateCount(allOrders.length);
    renderOrders(allOrders);
  });
  registerListener(unsub);

  const doFilter = () => {
    const q = document.getElementById('order-search').value.toLowerCase();
    const status = document.getElementById('status-filter').value;
    const filtered = allOrders.filter(o =>
      ((o.tokenNumber||'').toLowerCase().includes(q) || (o.paymentId||'').toLowerCase().includes(q))
      && (!status || o.status === status)
    );
    updateCount(filtered.length);
    renderOrders(filtered);
  };

  document.getElementById('order-search').addEventListener('input', debounce(doFilter));
  document.getElementById('status-filter').addEventListener('change', doFilter);
  document.getElementById('export-btn').addEventListener('click', () => {
    exportToCSV('krave_orders.csv',
      ['Token', 'Amount', 'Status', 'Canteen ID', 'Payment ID', 'Timestamp'],
      allOrders.map(o => [o.tokenNumber, o.totalAmount, o.status, o.canteenId, o.paymentId, o.timestamp?.toDate?.()?.toISOString() || ''])
    );
  });

  window.updateOrderStatus = async (orderId, status) => {
    try {
      await updateDoc(doc(db, 'Orders', orderId), { status, updatedAt: serverTimestamp() });
      showToast(`Order status updated to "${status}"`, 'success');
    } catch (e) {
      showToast(`Failed: ${e.message}`, 'error');
    }
  };
}

function updateCount(n) {
  const el = document.getElementById('orders-count');
  if (el) el.innerHTML = `<span class="badge badge-muted" style="font-size:13px;padding:5px 12px">${n} orders</span>`;
}

function renderOrders(orders) {
  const tbody = document.getElementById('orders-tbody');
  if (!tbody) return;
  if (!orders.length) {
    tbody.innerHTML = `<tr><td colspan="7"><div class="empty-state" style="padding:40px"><div class="empty-icon">📦</div><p>No orders found</p></div></td></tr>`;
    return;
  }
  tbody.innerHTML = orders.map(o => {
    const itemsText = (o.items || []).slice(0, 2).map(i => i.name || '?').join(', ') + (o.items?.length > 2 ? ` +${o.items.length-2}` : '');
    return `<tr>
      <td><code style="color:var(--accent);font-weight:700">${o.tokenNumber || '—'}</code></td>
      <td style="max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:var(--text-secondary);font-size:13px">${itemsText || '—'}</td>
      <td style="font-weight:700">${formatCurrency(o.totalAmount)}</td>
      <td>${statusBadge(o.status)}</td>
      <td style="color:var(--text-muted);font-family:monospace;font-size:11px">${o.paymentId ? o.paymentId.substring(0,18)+'…' : '—'}</td>
      <td style="color:var(--text-muted);font-size:12px">${formatDate(o.timestamp)}</td>
      <td>
        <select class="order-status-select" onchange="updateOrderStatus('${o.id}', this.value)">
          ${ORDER_STATUSES.map(s => `<option value="${s}" ${o.status===s?'selected':''}>${s}</option>`).join('')}
        </select>
      </td>
    </tr>`;
  }).join('');
}
