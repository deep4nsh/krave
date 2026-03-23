// ─── Manage Canteens Page ─────────────────────────────────────────────────────
import { db } from '../firebase-config.js';
import {
  collection, query, where, getDocs, onSnapshot,
  doc, updateDoc, deleteDoc, serverTimestamp
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";
import { registerListener, showToast, showConfirmModal, formatDateShort } from '../utils.js';

export async function loadCanteens() {
  const main = document.getElementById('main-content');
  main.innerHTML = `
    <div class="page-header">
      <div class="page-header-left">
        <h1>Manage Canteens</h1>
        <p>View, edit timings, and revoke approved canteens.</p>
      </div>
      <div id="canteens-count"></div>
    </div>
    <div class="filters-bar">
      <div class="search-box">
        <span>🔍</span>
        <input type="text" id="canteen-search" placeholder="Search canteens...">
      </div>
    </div>
    <div id="canteens-container">
      <div class="page-loading"><div class="spinner"></div></div>
    </div>
  `;

  let allCanteens = [];

  const q = query(collection(db, 'Canteens'), where('approved', '==', true));
  const unsub = onSnapshot(q, async snap => {
    allCanteens = await Promise.all(snap.docs.map(async d => {
      const data = d.data();
      // Fetch order count for this canteen
      const ordersSnap = await getDocs(query(collection(db, 'Orders'), where('canteenId', '==', d.id)));
      return { id: d.id, ...data, orderCount: ordersSnap.size };
    }));

    const counter = document.getElementById('canteens-count');
    if (counter) counter.innerHTML = `<span class="badge badge-success" style="font-size:14px;padding:6px 14px">${allCanteens.length} Active</span>`;

    renderCanteens(allCanteens);
  });
  registerListener(unsub);

  document.getElementById('canteen-search').addEventListener('input', e => {
    const q = e.target.value.toLowerCase();
    renderCanteens(allCanteens.filter(c => (c.name||'').toLowerCase().includes(q)));
  });

  window.saveTimings = async (canteenId) => {
    const open = document.getElementById(`open-${canteenId}`).value;
    const close = document.getElementById(`close-${canteenId}`).value;
    if (!open || !close) { showToast('Please fill both times.', 'warning'); return; }
    try {
      await updateDoc(doc(db, 'Canteens', canteenId), {
        opening_time: open, closing_time: close, updatedAt: serverTimestamp()
      });
      showToast('Timings updated!', 'success');
    } catch (e) { showToast(`Failed: ${e.message}`, 'error'); }
  };

  window.revokeCanteen = (canteenId, canteenName, ownerId) => {
    showConfirmModal({
      title: 'Revoke Canteen',
      message: `Remove "${canteenName}"? The owner will revert to pending status.`,
      confirmText: 'Revoke',
      confirmClass: 'btn-danger',
      onConfirm: () => doRevoke(canteenId, ownerId, canteenName),
    });
  };
}

function renderCanteens(canteens) {
  const container = document.getElementById('canteens-container');
  if (!container) return;

  if (canteens.length === 0) {
    container.innerHTML = `<div class="empty-state"><div class="empty-icon">🏪</div><h3>No canteens found</h3><p>No approved canteens match your search.</p></div>`;
    return;
  }

  container.innerHTML = canteens.map(c => `
    <div class="canteen-card">
      <div class="canteen-header">
        <div class="canteen-icon">🍽️</div>
        <div style="flex:1">
          <div class="canteen-name">${c.name || 'Unnamed'}</div>
          <div class="canteen-meta">Owner ID: <code style="color:var(--text-muted);font-size:11px">${c.ownerId}</code></div>
        </div>
        <span class="badge badge-success">Active</span>
      </div>

      <div class="canteen-stats">
        <div class="canteen-stat">
          <div class="canteen-stat-val">${c.orderCount ?? '—'}</div>
          <div class="canteen-stat-lbl">Total Orders</div>
        </div>
        <div class="canteen-stat">
          <div class="canteen-stat-val">${c.opening_time || '—'}</div>
          <div class="canteen-stat-lbl">Opens</div>
        </div>
        <div class="canteen-stat">
          <div class="canteen-stat-val">${c.closing_time || '—'}</div>
          <div class="canteen-stat-lbl">Closes</div>
        </div>
      </div>

      <div class="canteen-actions">
        <div class="timing-inputs">
          <input id="open-${c.id}" class="timing-input" type="text" placeholder="Open" value="${c.opening_time||''}" />
          <span style="color:var(--text-muted)">→</span>
          <input id="close-${c.id}" class="timing-input" type="text" placeholder="Close" value="${c.closing_time||''}" />
          <button class="btn btn-ghost btn-sm" onclick="saveTimings('${c.id}')">💾 Save</button>
        </div>
        <div style="flex:1"></div>
        <button class="btn btn-danger btn-sm" onclick="revokeCanteen('${c.id}','${(c.name||'').replace(/'/g,"\\'")}','${c.ownerId}')">
          🚫 Revoke
        </button>
      </div>
    </div>
  `).join('');
}

async function doRevoke(canteenId, ownerId, canteenName) {
  try {
    await deleteDoc(doc(db, 'Canteens', canteenId));
    await updateDoc(doc(db, 'Owners', ownerId), {
      status: 'pending', canteen_id: null, revokedAt: serverTimestamp()
    });
    await updateDoc(doc(db, 'Users', ownerId), { role: 'pendingOwner' });
    showToast(`"${canteenName}" has been revoked.`, 'info');
  } catch (e) {
    showToast(`Failed: ${e.message}`, 'error');
  }
}
