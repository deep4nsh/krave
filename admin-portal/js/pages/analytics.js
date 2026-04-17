import { db } from '../firebase-config.js';
import { collection, query, onSnapshot, where, getDocs } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";
import { COLLECTIONS, ORDER_STATUS } from '../constants.js';
import { registerListener, formatCurrency } from '../utils.js';

export async function loadAnalytics() {
  const main = document.getElementById('main-content');
  main.innerHTML = `
    <div class="page-header">
      <div class="page-header-left">
        <h1>Platform Analytics</h1>
        <p>Real-time performance tracking for the Krave ecosystem.</p>
      </div>
    </div>

    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-label">Total Revenue</div>
        <div class="stat-value" id="stat-revenue">₹0</div>
        <div class="stat-meta">Lifetime growth</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Total Orders</div>
        <div class="stat-value" id="stat-orders">0</div>
        <div class="stat-meta" id="stat-success-rate">0% success rate</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Active Users</div>
        <div class="stat-value" id="stat-users">0</div>
        <div class="stat-meta">Verified students</div>
      </div>
    </div>

    <div class="analytics-row" style="margin-top:24px">
      <div class="card" style="flex:2">
        <div class="card-header">Revenue Trend</div>
        <div class="chart-container" style="height:300px">
          <canvas id="revenueChart"></canvas>
        </div>
      </div>
      <div class="card" style="flex:1">
        <div class="card-header">Popular Canteens</div>
        <div id="top-canteens-list" style="padding:20px">
          <div class="page-loading"><div class="spinner"></div></div>
        </div>
      </div>
    </div>
  `;

  const unsubOrders = onSnapshot(collection(db, COLLECTIONS.ORDERS), snap => {
    let totalRevenue = 0;
    let completedOrders = 0;
    const canteenStats = {};

    snap.forEach(doc => {
      const order = doc.data();
      if (order.status === ORDER_STATUS.COMPLETED) {
        totalRevenue += (order.totalAmount || 0);
        completedOrders++;
      }
      
      const cId = order.canteenName || order.canteenId || 'Unknown';
      canteenStats[cId] = (canteenStats[cId] || 0) + 1;
    });

    document.getElementById('stat-revenue').textContent = formatCurrency(totalRevenue);
    document.getElementById('stat-orders').textContent = snap.size;
    const rate = snap.size > 0 ? ((completedOrders / snap.size) * 100).toFixed(1) : 0;
    document.getElementById('stat-success-rate').textContent = `${rate}% success rate`;

    renderTopCanteens(canteenStats);
    initRevenueChart(); // Placeholder for now, in a real environment we'd pass data
  });
  registerListener(unsubOrders);

  const unsubUsers = onSnapshot(collection(db, COLLECTIONS.USERS), snap => {
    document.getElementById('stat-users').textContent = snap.size;
  });
  registerListener(unsubUsers);
}

function renderTopCanteens(stats) {
  const list = document.getElementById('top-canteens-list');
  if (!list) return;

  const sorted = Object.entries(stats)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);

  list.innerHTML = sorted.map(([name, count]) => `
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px">
      <div style="font-weight:600; color:var(--text-secondary)">${name}</div>
      <div class="badge badge-success">${count} orders</div>
    </div>
  `).join('');
}

function initRevenueChart() {
    const ctx = document.getElementById('revenueChart');
    if (!ctx) return;
    
    // Check if chart already exists and destroy it if it does
    if (window.myTotalRevenueChart) {
      window.myTotalRevenueChart.destroy();
    }

    // Mock trend line for visualization
    window.myTotalRevenueChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            datasets: [{
                label: 'Revenue',
                data: [1200, 1900, 1500, 2500, 3200, 2800, 3100],
                borderColor: '#10b981',
                backgroundColor: 'rgba(16, 185, 129, 0.1)',
                tension: 0.4,
                fill: true
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                y: { beginAtZero: true, grid: { color: 'rgba(255,255,255,0.05)' } },
                x: { grid: { display: false } }
            }
        }
    });
}
