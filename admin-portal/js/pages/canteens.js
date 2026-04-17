import { COLLECTIONS, VENUE_TYPE } from '../constants.js';

export async function loadCanteens() {
  const main = document.getElementById('main-content');
  main.innerHTML = `
    <div class="page-header">
      <div class="page-header-left">
        <h1>Manage Venues</h1>
        <p>View, edit timings, and manage campus canteens and restaurants.</p>
      </div>
      <div id="canteens-count"></div>
    </div>
    <div class="filters-bar">
      <div class="search-box">
        <span>🔍</span>
        <input type="text" id="canteen-search" placeholder="Search venues...">
      </div>
    </div>
    <div id="canteens-container">
      <div class="page-loading"><div class="spinner"></div></div>
    </div>
  `;

  let allVenues = [];

  const q = query(collection(db, COLLECTIONS.CANTEENS), where('approved', '==', true));
  const unsub = onSnapshot(q, async snap => {
    allVenues = await Promise.all(snap.docs.map(async d => {
      const data = d.data();
      const ordersSnap = await getDocs(query(collection(db, COLLECTIONS.ORDERS), where('canteenId', '==', d.id)));
      return { id: d.id, ...data, orderCount: ordersSnap.size };
    }));

    const counter = document.getElementById('canteens-count');
    if (counter) counter.innerHTML = `<span class="badge badge-success" style="font-size:14px;padding:6px 14px">${allVenues.length} Active Venues</span>`;

    renderVenues(allVenues);
  });
  registerListener(unsub);

  document.getElementById('canteen-search').addEventListener('input', e => {
    const q = e.target.value.toLowerCase();
    renderVenues(allVenues.filter(c => (c.name||'').toLowerCase().includes(q)));
  });

  window.saveTimings = async (canteenId) => {
    const open = document.getElementById(`open-${canteenId}`).value;
    const close = document.getElementById(`close-${canteenId}`).value;
    if (!open || !close) { showToast('Please fill both times.', 'warning'); return; }
    try {
      await updateDoc(doc(db, COLLECTIONS.CANTEENS, canteenId), {
        opening_time: open, closing_time: close, updatedAt: serverTimestamp()
      });
      showToast('Timings updated!', 'success');
    } catch (e) { showToast(`Failed: ${e.message}`, 'error'); }
  };

  window.revokeCanteen = (canteenId, canteenName, ownerId) => {
    showConfirmModal({
      title: 'Revoke Venue',
      message: `Remove "${canteenName}"? The owner will revert to pending status.`,
      confirmText: 'Revoke',
      confirmClass: 'btn-danger',
      onConfirm: () => doRevoke(canteenId, ownerId, canteenName),
    });
  };
}

function renderVenues(venues) {
  const container = document.getElementById('canteens-container');
  if (!container) return;

  if (venues.length === 0) {
    container.innerHTML = `<div class="empty-state"><div class="empty-icon">🏪</div><h3>No venues found</h3><p>No active venues match your search.</p></div>`;
    return;
  }

  container.innerHTML = venues.map(v => {
    const isRestaurant = v.type === VENUE_TYPE.RESTAURANT;
    const icon = isRestaurant ? '🍽️' : '🍱';
    const typeLabel = isRestaurant ? 'Restaurant' : 'Canteen';
    
    return `
    <div class="canteen-card">
      <div class="canteen-header">
        <div class="canteen-icon">${icon}</div>
        <div style="flex:1">
          <div class="canteen-name">${v.name || 'Unnamed'}</div>
          <div class="canteen-meta">
            ${typeLabel} • ${v.deliveryRadius}m Radius
          </div>
        </div>
        <span class="badge badge-success">Active</span>
      </div>

      <div class="canteen-stats">
        <div class="canteen-stat">
          <div class="canteen-stat-val">${v.orderCount ?? '—'}</div>
          <div class="canteen-stat-lbl">Orders</div>
        </div>
        <div class="canteen-stat">
          <div class="canteen-stat-val" style="font-size:11px">${v.latitude.toFixed(4)}, ${v.longitude.toFixed(4)}</div>
          <div class="canteen-stat-lbl">Location</div>
        </div>
        <div class="canteen-stat">
          <div class="canteen-stat-val">${v.opening_time || '—'}</div>
          <div class="canteen-stat-lbl">Hours</div>
        </div>
      </div>

      <div class="canteen-actions">
        <div class="timing-inputs">
          <input id="open-${v.id}" class="timing-input" type="text" placeholder="Open" value="${v.opening_time||''}" />
          <span style="color:var(--text-muted)">→</span>
          <input id="close-${v.id}" class="timing-input" type="text" placeholder="Close" value="${v.closing_time||''}" />
          <button class="btn btn-ghost btn-sm" onclick="saveTimings('${v.id}')">💾</button>
        </div>
        <div style="flex:1"></div>
        <button class="btn btn-danger btn-sm" onclick="revokeCanteen('${v.id}','${(v.name||'').replace(/'/g,"\\'")}','${v.ownerId}')">
          🚫 Revoke
        </button>
      </div>
    </div>`;
  }).join('');
}

async function doRevoke(canteenId, ownerId, canteenName) {
  try {
    await deleteDoc(doc(db, COLLECTIONS.CANTEENS, canteenId));
    await updateDoc(doc(db, COLLECTIONS.OWNERS, ownerId), {
      status: 'pending', canteen_id: null, revokedAt: serverTimestamp()
    });
    await updateDoc(doc(db, COLLECTIONS.USERS, ownerId), { role: 'pendingOwner' });
    showToast(`"${canteenName}" has been revoked.`, 'info');
  } catch (e) {
    showToast(`Failed: ${e.message}`, 'error');
  }
}
