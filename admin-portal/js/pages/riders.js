// ─── Manage Riders Page ───────────────────────────────────────────────────────
import { db } from '../firebase-config.js';
import { collection, onSnapshot, doc, updateDoc, deleteDoc } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";
import { registerListener, debounce, showToast, showConfirmModal } from '../utils.js';

export async function loadRiders() {
  const main = document.getElementById('main-content');
  main.innerHTML = `
    <div class="page-header">
      <div class="page-header-left">
        <h1>Manage Riders</h1>
        <p>View and manage delivery riders and their activation status.</p>
      </div>
      <div style="display:flex;gap:12px;align-items:center">
        <div id="riders-count"></div>
        <button class="btn btn-primary" id="add-rider-btn">➕ Add Rider</button>
      </div>
    </div>
    <div class="filters-bar">
      <div class="search-box">
        <span>🔍</span>
        <input type="text" id="rider-search" placeholder="Search name or email...">
      </div>
      <div class="filters-spacer"></div>
    </div>
    <div class="card">
      <div class="table-wrapper">
        <table>
          <thead><tr>
            <th>Rider</th><th>Contact</th><th>Status</th><th>Actions</th>
          </tr></thead>
          <tbody id="riders-tbody">
            <tr><td colspan="4"><div class="page-loading"><div class="spinner"></div></div></td></tr>
          </tbody>
        </table>
      </div>
    </div>
  `;

  let allRiders = [];

  const unsub = onSnapshot(collection(db, 'Riders'), snap => {
    allRiders = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    document.getElementById('riders-count').innerHTML = `<span class="badge badge-info" style="font-size:14px;padding:6px 14px">${allRiders.length} Riders</span>`;
    renderRiders(allRiders);
  });
  registerListener(unsub);

  const doFilter = () => {
    const q = document.getElementById('rider-search').value.toLowerCase();
    renderRiders(allRiders.filter(r =>
      (r.name||'').toLowerCase().includes(q) || (r.email||'').toLowerCase().includes(q)
    ));
  };

  const searchInput = document.getElementById('rider-search');
  if (searchInput) {
    searchInput.addEventListener('input', debounce(doFilter));
  }

  // Add Rider Modal
  document.getElementById('add-rider-btn').addEventListener('click', () => {
    showRiderModal();
  });
}

function showRiderModal(rider = null) {
  const isEdit = !!rider;
  const modalId = 'rider-modal';
  
  // Create modal HTML
  const modalHtml = `
    <div class="modal-overlay" id="${modalId}-overlay">
      <div class="modal-content" style="max-width:500px">
        <div class="modal-header">
          <h2>${isEdit ? 'Edit Rider' : 'Add New Rider'}</h2>
          <button class="close-modal">✕</button>
        </div>
        <div class="modal-body">
          <form id="rider-form" class="admin-form">
            <div class="form-group">
              <label>User UID (from Firebase Auth)</label>
              <input type="text" id="rider-uid" value="${rider?.id || ''}" placeholder="Paste UID here..." required ${isEdit ? 'readonly' : ''}>
              <small style="color:var(--text-secondary);margin-top:4px;display:block">Riders must first sign up in the app to get a UID.</small>
            </div>
            <div class="form-group">
              <label>Full Name</label>
              <input type="text" id="rider-name" value="${rider?.name || ''}" placeholder="e.g. John Doe" required>
            </div>
            <div class="form-group">
              <label>Email Address</label>
              <input type="email" id="rider-email" value="${rider?.email || ''}" placeholder="john@example.com" required>
            </div>
            <div class="form-group">
              <label>Phone Number</label>
              <input type="tel" id="rider-phone" value="${rider?.phone || ''}" placeholder="+91 98765 43210" required>
            </div>
            <div class="form-actions" style="margin-top:24px">
              <button type="button" class="btn btn-secondary close-modal">Cancel</button>
              <button type="submit" class="btn btn-primary">${isEdit ? 'Save Changes' : 'Create Rider'}</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  `;

  document.body.insertAdjacentHTML('beforeend', modalHtml);
  const overlay = document.getElementById(`${modalId}-overlay`);
  const form = document.getElementById('rider-form');

  const close = () => overlay.remove();
  overlay.querySelectorAll('.close-modal').forEach(b => b.onclick = close);

  form.onsubmit = async (e) => {
    e.preventDefault();
    const uid = document.getElementById('rider-uid').value.trim();
    const data = {
      name: document.getElementById('rider-name').value.trim(),
      email: document.getElementById('rider-email').value.trim(),
      phone: document.getElementById('rider-phone').value.trim(),
      isActive: true, // Default to active
      updatedAt: new Date()
    };
    if (!isEdit) data.createdAt = new Date();

    try {
      if (isEdit) {
        await updateDoc(doc(db, 'Riders', uid), data);
      } else {
        // Use setDoc instead of addDoc because we have the UID
        const { setDoc } = await import("https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js");
        await setDoc(doc(db, 'Riders', uid), data);
      }
      showToast(`Rider ${isEdit ? 'updated' : 'added'} successfully`, 'success');
      close();
    } catch (err) {
      console.error(err);
      showToast('Error saving rider: ' + err.message, 'error');
    }
  };
}

function renderRiders(riders) {
  const tbody = document.getElementById('riders-tbody');
  if (!tbody) return;
  if (!riders.length) {
    tbody.innerHTML = `<tr><td colspan="4"><div class="empty-state" style="padding:40px"><div class="empty-icon">🛵</div><p>No riders found</p></div></td></tr>`;
    return;
  }
  tbody.innerHTML = riders.map(r => {
    const initials = (r.name || 'R').charAt(0).toUpperCase();
    const isActive = r.isActive === true;
    return `<tr>
      <td>
        <div style="display:flex;align-items:center;gap:10px">
          <div style="width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#10b981,#3b82f6);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;flex-shrink:0;color:white">${initials}</div>
          <div>
            <div class="td-name">${r.name || 'Unknown'}</div>
            <div class="td-sub" style="font-family:monospace">${r.id.substring(0,12)}…</div>
          </div>
        </div>
      </td>
      <td>
        <div style="color:var(--text-secondary)">${r.email || '—'}</div>
        <div class="td-sub">${r.phone || ''}</div>
      </td>
      <td>
        <span class="badge badge-${isActive ? 'success' : 'muted'}">${isActive ? 'Active' : 'Disabled'}</span>
      </td>
      <td>
        <div class="action-btns">
          <button class="btn btn-secondary btn-icon-only toggle-rider-btn" data-id="${r.id}" data-active="${isActive}" title="${isActive ? 'Disable' : 'Enable'} Rider">
            ${isActive ? '🚫' : '✅'}
          </button>
          <button class="btn btn-secondary btn-icon-only edit-rider-btn" data-id="${r.id}" title="Edit Rider">✏️</button>
          <button class="btn btn-secondary btn-icon-only delete-rider-btn" data-id="${r.id}" title="Delete Rider">🗑️</button>
        </div>
      </td>
    </tr>`;
  }).join('');

  // Attach event listeners
  tbody.querySelectorAll('.toggle-rider-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      const id = btn.dataset.id;
      const wasActive = btn.dataset.active === 'true';
      try {
        await updateDoc(doc(db, 'Riders', id), { isActive: !wasActive });
        showToast(`Rider ${wasActive ? 'disabled' : 'enabled'} successfully`, 'success');
      } catch (err) {
        showToast('Error updating rider status', 'error');
      }
    });
  });

  tbody.querySelectorAll('.edit-rider-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const id = btn.dataset.id;
      const rider = riders.find(r => r.id === id);
      showRiderModal(rider);
    });
  });

  tbody.querySelectorAll('.delete-rider-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const id = btn.dataset.id;
      showConfirmModal({
        title: 'Delete Rider?',
        message: 'This action cannot be undone. The rider will lose access to the app.',
        confirmText: 'Delete',
        onConfirm: async () => {
          try {
            await deleteDoc(doc(db, 'Riders', id));
            showToast('Rider deleted successfully', 'success');
          } catch (err) {
            showToast('Error deleting rider', 'error');
          }
        }
      });
    });
  });
}
