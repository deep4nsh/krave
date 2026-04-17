import { db } from '../firebase-config.js';
import { collection, query, onSnapshot, where, doc, updateDoc, serverTimestamp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";
import { COLLECTIONS } from '../constants.js';
import { registerListener, showToast, formatCurrency } from '../utils.js';

export async function loadMenuManagement(canteenId) {
  const main = document.getElementById('main-content');
  if (!canteenId) {
    main.innerHTML = `<div class="empty-state"><h3>Select a canteen to manage menu</h3></div>`;
    return;
  }

  main.innerHTML = `
    <div class="page-header">
      <div class="page-header-left">
        <h1>Menu Control Console</h1>
        <p>Live toggles for item availability and stock management.</p>
      </div>
    </div>

    <div id="menu-items-grid" class="menu-mgmt-grid">
      <div class="page-loading"><div class="spinner"></div></div>
    </div>
  `;

  const q = query(collection(db, COLLECTIONS.CANTEENS, canteenId, 'MenuItems'));
  const unsub = onSnapshot(q, snap => {
    const items = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    renderMenuItems(canteenId, items);
  });
  registerListener(unsub);

  window.toggleItemAvailability = async (cId, itemId, currentStatus) => {
    try {
      await updateDoc(doc(db, COLLECTIONS.CANTEENS, cId, 'MenuItems', itemId), {
        available: !currentStatus,
        updatedAt: serverTimestamp()
      });
      showToast(`Item is now ${!currentStatus ? 'Available' : 'Unavailable'}`, 'success');
    } catch (e) {
      showToast(`Failed to update item: ${e.message}`, 'error');
    }
  };
}

function renderMenuItems(cId, items) {
  const grid = document.getElementById('menu-items-grid');
  if (!grid) return;

  if (items.length === 0) {
    grid.innerHTML = `<div class="empty-state" style="grid-column:1/-1"><h3>No items found</h3><p>Add items to your canteen menu to manage them here.</p></div>`;
    return;
  }

  grid.innerHTML = items.map(item => `
    <div class="card menu-mgmt-card ${item.available ? '' : 'disabled-item'}">
      <div style="display:flex; justify-content:space-between; align-items:start">
        <div style="flex:1">
          <div style="display:flex; align-items:center; gap:8px">
            <span style="font-size:12px">${item.isVeg ? '🟢' : '🔴'}</span>
            <div style="font-weight:700; font-size:16px">${item.name}</div>
          </div>
          <div style="color:var(--text-muted); font-size:13px; margin-top:4px">${item.category || 'Main Course'}</div>
          <div style="margin-top:12px; font-weight:700; color:var(--accent)">${formatCurrency(item.price)}</div>
        </div>
        
        <label class="switch">
          <input type="checkbox" ${item.available ? 'checked' : ''} onchange="toggleItemAvailability('${cId}', '${item.id}', ${item.available})">
          <span class="slider round"></span>
        </label>
      </div>
      
      <div style="margin-top:16px; font-size:11px; color:var(--text-muted)">
        ${item.available ? '🟢 Live in app' : '🛑 Hidden from students'}
      </div>
    </div>
  `).join('');
}
