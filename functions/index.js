const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

// --- Cloud Functions for Notifications (THE MASTER HANDSHAKE) ---

// 1. Notify owner when a new order is placed
exports.onOrderCreated = functions.firestore
  .document("Orders/{orderId}")
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const canteenId = order.canteenId;

    // We need to find the owner associated with this canteen
    const ownersSnap = await admin.firestore().collection("Owners")
      .where("canteen_id", "==", canteenId)
      .limit(1)
      .get();

    if (!ownersSnap.empty) {
      const ownerData = ownersSnap.docs[0].data();
      const fcmToken = ownerData.fcmToken;

      if (fcmToken) {
        const payload = {
          notification: {
            title: "New Order! 🔔",
            body: `Order #${order.tokenNumber} just came in! Get the kitchen ready.`,
            sound: "default",
          },
          data: {
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
            orderId: context.params.orderId,
          }
        };
        await admin.messaging().sendToDevice(fcmToken, payload);
      }
    }
  });

// 2. Notify student when order status changes (SMART HANDSHAKE)
exports.onOrderStatusUpdate = functions.firestore
  .document("Orders/{orderId}")
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();

    if (newValue.status !== previousValue.status) {
      const userId = newValue.userId;
      const userDoc = await admin.firestore().collection("Users").doc(userId).get();
      
      if (!userDoc.exists) return;
      const fcmToken = userDoc.data().fcmToken;

      if (fcmToken) {
        const statusMsg = getFunkyMessage(newValue.status);
        
        const payload = {
          notification: {
            title: "Krave Update! 🍔",
            body: statusMsg,
            sound: "default",
          },
          data: {
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
            orderId: context.params.orderId,
            status: newValue.status,
          }
        };
        await admin.messaging().sendToDevice(fcmToken, payload);
      }
    }
  });

function getFunkyMessage(status) {
  switch (status) {
    case 'Preparing': return 'Chef is speed-running your order! 👨‍🍳';
    case 'Ready for Pickup': return 'Tokens Up! Your meal is waiting at the counter! 🍔';
    case 'Out for Delivery': return 'The Rider is zooming to your spot! 🛵';
    case 'Completed': return 'Order complete. Hope you enjoyed the treat! 🙌';
    case 'Cancelled': return 'Order cancelled. Refund initiated to your wallet. 💸';
    default: return `Your order status is now: ${status}`;
  }
}

// 3. Notify User on Wallet Transfer (SOCIAL HANDSHAKE)
exports.onTransactionCreated = functions.firestore
  .document("Transactions/{txId}")
  .onCreate(async (snap, context) => {
    const tx = snap.data();
    if (tx.type === 'credit') {
      const userDoc = await admin.firestore().collection("Users").doc(tx.userId).get();
      if (!userDoc.exists) return;
      const fcmToken = userDoc.data().fcmToken;

      if (fcmToken) {
        const payload = {
          notification: {
            title: "You got a Treat! 💸",
            body: `Someone just sent you ₹${tx.amount} in your Krave wallet!`,
            sound: "default",
          }
        };
        await admin.messaging().sendToDevice(fcmToken, payload);
      }
    }
  });
