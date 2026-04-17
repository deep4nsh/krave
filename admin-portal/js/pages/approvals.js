// ─── Owner Approvals Page ─────────────────────────────────────────────────────
import { db } from '../firebase-config.js';
import {
  collection, query, where, onSnapshot,
  doc, getDoc, addDoc, updateDoc, deleteDoc, serverTimestamp
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";
import { registerListener, showToast, showConfirmModal, formatDateShort } from '../utils.js';

import { COLLECTIONS } from '../constants.js';

export async function loadApprovals() {
  const main = document.getElementById('main-content');
  main.innerHTML = `
    <div class="page-header">
      <div class="page-header-left">
        <h1>Owner Approvals</h1>
        <p>Review and manage pending canteen owner applications.</p>
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
          <p>No pending owner applications at this time.</p>
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
          <div class="info-row"><span class="info-label">🏪 Canteen</span><span class="info-value">${o.canteen_name || 'N/A'}</span></div>
          <div class="info-row"><span class="info-label">📅 Applied</span><span class="info-value">${formatDateShort(o.createdAt)}</span></div>
          <div class="info-row"><span class="info-label">🆔 Owner ID</span><span class="info-value" style="font-family:monospace;font-size:11px;color:var(--text-muted)">${d.id}</span></div>
          <div class="approval-actions">
            <button class="btn btn-danger" onclick="handleReject('${d.id}', '${(o.name||'').replace(/'/g,"\\'")}')">
              ✕ Reject
            </button>
            <button class="btn btn-success" onclick="handleApprove('${d.id}', '${(o.canteen_name||'').replace(/'/g,"\\'")}', '${(o.name||'').replace(/'/g,"\\'")}')">
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
  window.handleApprove = (ownerId, canteenName, ownerName) => {
    showConfirmModal({
      title: 'Approve Owner',
      message: `Approve "${ownerName}" and create canteen "${canteenName}"? This will grant them full owner access.`,
      confirmText: 'Approve',
      confirmClass: 'btn-success',
      onConfirm: () => approveOwner(ownerId, canteenName),
    });
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

async function approveOwner(ownerId, canteenName) {
  try {
    const ownerRef = doc(db, COLLECTIONS.OWNERS, ownerId);
    const ownerSnap = await getDoc(ownerRef);
    if (!ownerSnap.exists()) throw new Error('Owner not found');

    // 1. Create canteen
    const canteenRef = await addDoc(collection(db, COLLECTIONS.CANTEENS), {
      name: canteenName,
      ownerId,
      approved: true,
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

    showToast(`✅ ${canteenName} approved successfully!`, 'success');
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
