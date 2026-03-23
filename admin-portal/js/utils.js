// ─── Utility Functions ────────────────────────────────────────────────────────

let toastTimeout = null;

export function showToast(message, type = 'success') {
  const existing = document.getElementById('toast');
  if (existing) existing.remove();
  if (toastTimeout) clearTimeout(toastTimeout);

  const toast = document.createElement('div');
  toast.id = 'toast';
  toast.className = `toast toast-${type}`;

  const icons = { success: '✓', error: '✕', info: 'ℹ', warning: '⚠' };
  toast.innerHTML = `<span class="toast-icon">${icons[type] || icons.info}</span><span>${message}</span>`;
  document.body.appendChild(toast);

  requestAnimationFrame(() => toast.classList.add('show'));
  toastTimeout = setTimeout(() => {
    toast.classList.remove('show');
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

export function formatDate(timestamp) {
  if (!timestamp) return '—';
  const d = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

export function formatDateShort(timestamp) {
  if (!timestamp) return '—';
  const d = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
}

export function formatCurrency(amount) {
  if (amount === undefined || amount === null) return '—';
  return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(amount);
}

export function formatAmount(paise) {
  return formatCurrency(paise / 100);
}

export function capitalize(str) {
  if (!str) return '';
  return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
}

export function statusBadge(status) {
  const map = {
    'Pending':          { class: 'badge-warning', label: 'Pending' },
    'Preparing':        { class: 'badge-info',    label: 'Preparing' },
    'Ready':            { class: 'badge-success', label: 'Ready' },
    'Ready for Pickup': { class: 'badge-success', label: '🟢 Ready for Pickup' },
    'Completed':        { class: 'badge-muted',   label: 'Completed' },
    'Cancelled':        { class: 'badge-error',   label: 'Cancelled' },
    'approved':         { class: 'badge-success', label: 'Approved' },
    'pending':          { class: 'badge-warning', label: 'Pending' },
    'rejected':         { class: 'badge-error',   label: 'Rejected' },
  };
  const info = map[status] || { class: 'badge-muted', label: status || 'Unknown' };
  return `<span class="badge ${info.class}">${info.label}</span>`;
}

export function roleBadge(role) {
  const map = {
    'user':           { class: 'badge-info',    label: 'User' },
    'approvedOwner':  { class: 'badge-success', label: 'Owner' },
    'pendingOwner':   { class: 'badge-warning', label: 'Pending Owner' },
    'admin':          { class: 'badge-purple',  label: 'Admin' },
  };
  const info = map[role] || { class: 'badge-muted', label: role || 'Unknown' };
  return `<span class="badge ${info.class}">${info.label}</span>`;
}

export function showConfirmModal({ title, message, confirmText = 'Confirm', confirmClass = 'btn-danger', onConfirm }) {
  const modal = document.getElementById('confirm-modal');
  document.getElementById('confirm-modal-title').textContent = title;
  document.getElementById('confirm-modal-message').textContent = message;
  const btn = document.getElementById('confirm-modal-btn');
  btn.textContent = confirmText;
  btn.className = `btn ${confirmClass}`;
  modal.classList.add('open');

  const newBtn = btn.cloneNode(true);
  btn.parentNode.replaceChild(newBtn, btn);
  newBtn.addEventListener('click', () => {
    modal.classList.remove('open');
    onConfirm();
  });
}

export function hideConfirmModal() {
  document.getElementById('confirm-modal').classList.remove('open');
}

export function showLoadingInElement(el, rows = 4) {
  el.innerHTML = Array(rows).fill(0).map(() => `
    <div class="skeleton-row">
      <div class="skeleton" style="width:30%"></div>
      <div class="skeleton" style="width:20%"></div>
      <div class="skeleton" style="width:15%"></div>
      <div class="skeleton" style="width:10%"></div>
    </div>`).join('');
}

export function exportToCSV(filename, headers, rows) {
  const csvContent = [
    headers.join(','),
    ...rows.map(row => row.map(cell => `"${String(cell ?? '').replace(/"/g, '""')}"`).join(','))
  ].join('\n');

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
  showToast(`Exported ${rows.length} rows to ${filename}`, 'success');
}

export function debounce(fn, delay = 300) {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
}

// Unsubscribe registry for Firestore listeners
const activeListeners = [];
export function registerListener(unsub) {
  activeListeners.push(unsub);
}
export function clearAllListeners() {
  activeListeners.forEach(fn => fn());
  activeListeners.length = 0;
}
