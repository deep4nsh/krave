import { COLLECTIONS, VENUE_TYPE } from '../constants.js';

export async function loadApprovals() {
  const main = document.getElementById('main-content');
  main.innerHTML = `
    <div class="page-header">
      <div class="page-header-left">
        <h1>Owner Approvals</h1>
        <p>Review and manage pending canteen/restaurant applications.</p>
      </div>
      <div id="approvals-count"></div>
    </div>
    <div id="approvals-container">
      <div class="page-loading"><div class="spinner"></div></div>
    </div>
  `;

  const q = query(collection(db, COLLECTIONS.OWNERS), where('status', '==', 'pending'));
  const unsub = onSnapshot(q, snap => {
    const counter = document.getElementById('approvals-count');
    if (counter) {
      counter.innerHTML = snap.empty ? '' : `<span class="badge badge-warning" style="font-size:14px;padding:6px 14px">${snap.size} Pending</span>`;
    }

    const container = document.getElementById('approvals-container');
    if (!container) return;

    if (snap.empty) {
      container.innerHTML = `
        <div class="empty-state">
          <div class="empty-icon">✅</div>
          <h3>All caught up!</h3>
          <p>No pending applications at this time.</p>
        </div>`;
      return;
    }

    container.innerHTML = `<div class="approval-grid">${snap.docs.map(d => {
      const o = d.data();
      const initials = (o.name || 'U').charAt(0).toUpperCase();
      return `
        <div class="approval-card" id="card-${d.id}">
          <div class="approval-card-header">
            <div class="approval-avatar">${initials}</div>
            <div>
              <div class="approval-name">${o.name || 'Unknown'}</div>
              <div class="approval-email">${o.email || '—'}</div>
            </div>
          </div>
          <div class="info-row"><span class="info-label">🏪 Venue</span><span class="info-value">${o.canteen_name || 'N/A'}</span></div>
          <div class="info-row"><span class="info-label">📅 Applied</span><span class="info-value">${formatDateShort(o.createdAt)}</span></div>
          <div class="info-row"><span class="info-label">🆔 Owner ID</span><span class="info-value" style="font-family:monospace;font-size:11px;color:var(--text-muted)">${d.id}</span></div>
          <div class="approval-actions">
            <button class="btn btn-danger" onclick="handleReject('${d.id}', '${(o.name||'').replace(/'/g,"\\'")}')">
              ✕ Reject
            </button>
            <button class="btn btn-success" onclick="showApprovalForm('${d.id}', '${(o.canteen_name||'').replace(/'/g,"\\'")}', '${(o.name||'').replace(/'/g,"\\'")}')">
              ✓ Approve
            </button>
          </div>
        </div>`;
    }).join('')}</div>`;
  }, err => {
    console.error(err);
    document.getElementById('approvals-container').innerHTML = `<div class="error-state"><h2>Failed to load approvals</h2><p>${err.message}</p></div>`;
  });
  registerListener(unsub);

  // Expose handlers globally
  window.showApprovalForm = (ownerId, venueName, ownerName) => {
    const modalId = 'approval-form-modal';
    const modalHtml = `
      <div class="modal-overlay" id="${modalId}-overlay">
        <div class="modal-content" style="max-width:500px">
          <div class="modal-header">
            <h2>Approve Venue: ${venueName}</h2>
            <button class="close-modal">✕</button>
          </div>
          <div class="modal-body">
            <form id="approval-form" class="admin-form">
              <div class="form-group">
                <label>Venue Type</label>
                <select id="v-type" required>
                  <option value="${VENUE_TYPE.CANTEEN}">Campus Canteen</option>
                  <option value="${VENUE_TYPE.RESTAURANT}">External Restaurant</option>
                </select>
              </div>
              <div class="form-group">
                <label>Latitude</label>
                <input type="number" step="any" id="v-lat" placeholder="e.g. 28.7041" required>
              </div>
              <div class="form-group">
                <label>Longitude</label>
                <input type="number" step="any" id="v-lng" placeholder="e.g. 77.1025" required>
              </div>
              <div class="form-group">
                <label>Delivery Radius (meters)</label>
                <input type="number" id="v-radius" value="1500" required>
                <small>Students beyond this radius won't see this venue.</small>
              </div>
              <div class="form-actions" style="margin-top:24px">
                <button type="button" class="btn btn-secondary close-modal">Cancel</button>
                <button type="submit" class="btn btn-success">Complete Approval</button>
              </div>
            </form>
          </div>
        </div>
      </div>
    `;

    document.body.insertAdjacentHTML('beforeend', modalHtml);
    const overlay = document.getElementById(`${modalId}-overlay`);
    const form = document.getElementById('approval-form');

    const close = () => overlay.remove();
    overlay.querySelectorAll('.close-modal').forEach(b => b.onclick = close);

    form.onsubmit = async (e) => {
      e.preventDefault();
      const type = document.getElementById('v-type').value;
      const lat = parseFloat(document.getElementById('v-lat').value);
      const lng = parseFloat(document.getElementById('v-lng').value);
      const radius = parseFloat(document.getElementById('v-radius').value);

      await approveOwner(ownerId, venueName, { type, lat, lng, radius });
      close();
    };
  };

  window.handleReject = (ownerId, ownerName) => {
    showConfirmModal({
      title: 'Reject Application',
      message: `Reject and permanently delete "${ownerName}"'s account? This cannot be undone.`,
      confirmText: 'Reject',
      confirmClass: 'btn-danger',
      onConfirm: () => rejectOwner(ownerId),
    });
  };
}

async function approveOwner(ownerId, venueName, details) {
  try {
    const ownerRef = doc(db, COLLECTIONS.OWNERS, ownerId);
    const ownerSnap = await getDoc(ownerRef);
    if (!ownerSnap.exists()) throw new Error('Owner not found');

    // 1. Create venue
    const canteenRef = await addDoc(collection(db, COLLECTIONS.CANTEENS), {
      name: venueName,
      ownerId,
      approved: true,
      type: details.type,
      latitude: details.lat,
      longitude: details.lng,
      deliveryRadius: details.radius,
      opening_time: '9:00 AM',
      closing_time: '5:00 PM',
      createdAt: serverTimestamp(),
    });

    // 2. Update owner
    await updateDoc(ownerRef, {
      status: 'approved',
      canteen_id: canteenRef.id,
      approvedAt: serverTimestamp(),
    });

    // 3. Update Users collection
    await updateDoc(doc(db, COLLECTIONS.USERS, ownerId), { role: 'approvedOwner' });

    showToast(`✅ ${venueName} approved successfully!`, 'success');
  } catch (e) {
    console.error(e);
    showToast(`Failed: ${e.message}`, 'error');
  }
}

async function rejectOwner(ownerId) {
  try {
    await deleteDoc(doc(db, COLLECTIONS.OWNERS, ownerId));
    await deleteDoc(doc(db, COLLECTIONS.USERS, ownerId));
    showToast('Owner rejected and account removed.', 'info');
  } catch (e) {
    console.error(e);
    showToast(`Failed: ${e.message}`, 'error');
  }
}
