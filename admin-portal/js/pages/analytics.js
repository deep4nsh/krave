// ─── Analytics Page ───────────────────────────────────────────────────────────
import { db } from '../firebase-config.js';
import {
  collection, getDocs, query, where, orderBy
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";
import { formatCurrency } from '../utils.js';

// Track chart instances so we can destroy them on re-navigation
const chartRegistry = {};
function destroyChart(id) {
  if (chartRegistry[id]) { chartRegistry[id].destroy(); delete chartRegistry[id]; }
}

export async function loadAnalytics() {
  const main = document.getElementById('main-content');
  main.innerHTML = `
    <div class="page-header">
      <div class="page-header-left">
        <h1>Analytics</h1>
        <p>Platform-wide revenue, orders, and performance insights.</p>
      </div>
    </div>

    <div class="stats-grid">
      <div class="stat-card" style="--card-accent:#f59e0b">
        <div class="stat-icon">💰</div>
        <div class="stat-value" id="a-revenue">—</div>
        <div class="stat-label">Total Revenue</div>
      </div>
      <div class="stat-card" style="--card-accent:#10b981">
        <div class="stat-icon">✅</div>
        <div class="stat-value" id="a-completed">—</div>
        <div class="stat-label">Completed Orders</div>
      </div>
      <div class="stat-card" style="--card-accent:#ef4444">
        <div class="stat-icon">❌</div>
        <div class="stat-value" id="a-cancelled">—</div>
        <div class="stat-label">Cancelled Orders</div>
      </div>
      <div class="stat-card" style="--card-accent:#8b5cf6">
        <div class="stat-icon">📊</div>
        <div class="stat-value" id="a-avg">—</div>
        <div class="stat-label">Avg. Order Value</div>
      </div>
    </div>

    <div class="analytics-grid">
      <div class="card">
        <div class="card-header">
          <div class="card-title">Revenue — Last 7 Days</div>
        </div>
        <div class="card-body">
          <div class="chart-container">
            <canvas id="chart-revenue"></canvas>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-title">Orders by Status</div>
        </div>
        <div class="card-body">
          <div class="chart-container" style="height:200px">
            <canvas id="chart-status"></canvas>
          </div>
          <div id="status-legend" style="margin-top:16px;display:flex;flex-wrap:wrap;gap:10px"></div>
        </div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-title">Orders by Canteen</div>
        </div>
        <div class="card-body">
          <div id="canteen-bars"></div>
        </div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-title">Top Menu Items</div>
        </div>
        <div class="card-body">
          <div id="top-items"></div>
        </div>
      </div>
    </div>
  `;

  try {
    const [ordersSnap, canteensSnap] = await Promise.all([
      getDocs(collection(db, 'Orders')),
      getDocs(query(collection(db, 'Canteens'), where('approved', '==', true))),
    ]);

    const orders = ordersSnap.docs.map(d => ({ id: d.id, ...d.data() }));
    const canteens = canteensSnap.docs.map(d => ({ id: d.id, ...d.data() }));
    const canteenMap = Object.fromEntries(canteens.map(c => [c.id, c.name]));

    // Summary stats — real Firestore statuses: 'Pending', 'Preparing', 'Ready for Pickup', 'Completed', 'Cancelled'
    const isCompletedStatus = s => s === 'Completed' || s === 'Ready for Pickup' || s === 'Ready';
    const completed = orders.filter(o => isCompletedStatus(o.status));
    const cancelled = orders.filter(o => o.status === 'Cancelled');
    const totalRevenue = completed.reduce((s, o) => s + (o.totalAmount || 0), 0);
    const avgValue = completed.length ? Math.round(totalRevenue / completed.length) : 0;

    document.getElementById('a-revenue').textContent = formatCurrency(totalRevenue);
    document.getElementById('a-completed').textContent = completed.length;
    document.getElementById('a-cancelled').textContent = cancelled.length;
    document.getElementById('a-avg').textContent = formatCurrency(avgValue);

    // Revenue last 7 days
    const days = getLast7Days();
    const revenueByDay = days.map(day => {
      return orders.filter(o => {
        const d = o.timestamp?.toDate?.();
        return d && d.toDateString() === day.date.toDateString() && isCompletedStatus(o.status);
      }).reduce((s, o) => s + (o.totalAmount || 0), 0);
    });

    renderRevenueChart(days.map(d => d.label), revenueByDay);

    // Orders by status
    const statusCounts = {};
    orders.forEach(o => { statusCounts[o.status || 'Unknown'] = (statusCounts[o.status || 'Unknown'] || 0) + 1; });
    renderStatusChart(statusCounts);

    // Orders by canteen
    const byCanteen = {};
    orders.forEach(o => {
      const name = canteenMap[o.canteenId] || o.canteenId?.substring(0,8) || 'Unknown';
      byCanteen[name] = (byCanteen[name] || 0) + 1;
    });
    renderCanteenBars(byCanteen);

    // Top menu items
    const itemCounts = {};
    orders.forEach(o => (o.items || []).forEach(i => {
      const name = i.name || 'Unknown';
      itemCounts[name] = (itemCounts[name] || 0) + (i.quantity || 1);
    }));
    renderTopItems(itemCounts);

  } catch (e) {
    console.error('Analytics error:', e);
    main.querySelector('.analytics-grid').innerHTML = `<div class="error-state"><h2>Failed to load analytics</h2><p>${e.message}</p></div>`;
  }
}

function getLast7Days() {
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - (6 - i));
    return { date: d, label: d.toLocaleDateString('en-IN', { weekday: 'short', month: 'short', day: 'numeric' }) };
  });
}

function renderRevenueChart(labels, data) {
  const ctx = document.getElementById('chart-revenue');
  if (!ctx) return;
  destroyChart('revenue');
  if (window.Chart) {
    chartRegistry['revenue'] = new window.Chart(ctx, {
      type: 'bar',
      data: {
        labels,
        datasets: [{
          label: 'Revenue (₹)',
          data,
          backgroundColor: 'rgba(245,158,11,0.25)',
          borderColor: '#f59e0b',
          borderWidth: 2,
          borderRadius: 6,
          hoverBackgroundColor: 'rgba(245,158,11,0.5)',
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { color: 'rgba(255,255,255,0.04)' }, ticks: { color: '#9ba3c2', font: { size: 11 } } },
          y: { grid: { color: 'rgba(255,255,255,0.04)' }, ticks: { color: '#9ba3c2', font: { size: 11 }, callback: v => '₹'+v } }
        }
      }
    });
  } else {
    ctx.parentElement.innerHTML = `<p style="color:var(--text-muted);text-align:center;padding:40px">Chart.js not loaded</p>`;
  }
}

function renderStatusChart(statusCounts) {
  const ctx = document.getElementById('chart-status');
  if (!ctx) return;
  destroyChart('status');
  const entries = Object.entries(statusCounts);
  const colorMap = { Pending:'#f59e0b', Preparing:'#3b82f6', 'Ready for Pickup':'#10b981', Ready:'#10b981', Completed:'#6b7280', Cancelled:'#ef4444', Unknown:'#5a6280' };
  const colors = entries.map(([k]) => colorMap[k] || '#8b5cf6');

  if (window.Chart) {
    chartRegistry['status'] = new window.Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: entries.map(([k]) => k),
        datasets: [{ data: entries.map(([,v]) => v), backgroundColor: colors, borderWidth: 0, hoverOffset: 6 }]
      },
      options: {
        responsive: true, maintainAspectRatio: false, cutout: '70%',
        plugins: { legend: { display: false } }
      }
    });
    const legend = document.getElementById('status-legend');
    if (legend) {
      legend.innerHTML = entries.map(([k, v], i) => `
        <div style="display:flex;align-items:center;gap:6px;font-size:12px;font-weight:600">
          <div style="width:10px;height:10px;border-radius:3px;background:${colors[i]};flex-shrink:0"></div>
          ${k} <span style="color:var(--text-muted);font-weight:400">${v}</span>
        </div>`).join('');
    }
  }
}

function renderCanteenBars(byCanteen) {
  const el = document.getElementById('canteen-bars');
  if (!el) return;
  const entries = Object.entries(byCanteen).sort((a,b)=>b[1]-a[1]).slice(0,8);
  const max = Math.max(...entries.map(([,v])=>v), 1);
  el.innerHTML = entries.map(([name, count]) => `
    <div style="margin-bottom:14px">
      <div style="display:flex;justify-content:space-between;font-size:13px;font-weight:600;margin-bottom:6px">
        <span>${name}</span><span style="color:var(--text-muted)">${count}</span>
      </div>
      <div style="height:8px;background:var(--bg-elevated);border-radius:99px;overflow:hidden">
        <div style="height:100%;width:${Math.round(count/max*100)}%;background:linear-gradient(90deg,#10b981,#3b82f6);border-radius:99px;transition:width 0.6s ease"></div>
      </div>
    </div>`).join('');
}

function renderTopItems(itemCounts) {
  const el = document.getElementById('top-items');
  if (!el) return;
  const entries = Object.entries(itemCounts).sort((a,b)=>b[1]-a[1]).slice(0,8);
  if (!entries.length) { el.innerHTML = `<p style="color:var(--text-muted);text-align:center;padding:40px">No item data yet</p>`; return; }
  const max = Math.max(...entries.map(([,v])=>v), 1);
  el.innerHTML = entries.map(([name, count], i) => `
    <div style="display:flex;align-items:center;gap:12px;margin-bottom:14px">
      <div style="width:24px;height:24px;border-radius:6px;background:var(--bg-elevated);display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;color:var(--text-muted);flex-shrink:0">${i+1}</div>
      <div style="flex:1">
        <div style="font-size:13px;font-weight:600;margin-bottom:4px">${name}</div>
        <div style="height:6px;background:var(--bg-elevated);border-radius:99px;overflow:hidden">
          <div style="height:100%;width:${Math.round(count/max*100)}%;background:linear-gradient(90deg,#f59e0b,#ef4444);border-radius:99px"></div>
        </div>
      </div>
      <div style="font-size:13px;font-weight:700;color:var(--text-muted)">${count}x</div>
    </div>`).join('');
}
