const functions = require("firebase-functions");
const admin = require("firebase-admin");
const Razorpay = require("razorpay");
const crypto = require("crypto");

admin.initializeApp();

// Initialize Razorpay instance safely using environment configuration
const razorpay = new Razorpay({
  key_id: functions.config().razorpay.key_id,
  key_secret: functions.config().razorpay.key_secret,
});

// --- Cloud Functions for User Management ---

exports.onOwnerDelete = functions.firestore
    .document("Owners/{ownerId}")
    .onDelete(async (snap, context) => {
      const ownerId = context.params.ownerId;
      console.log(`--- Deleting auth user for ownerId: ${ownerId} ---`);
      try {
        await admin.auth().deleteUser(ownerId);
        console.log(`Successfully deleted auth user: ${ownerId}`);
      } catch (error) {
        console.error(`Error deleting auth user ${ownerId}:`, error);
      }
    });


// --- Cloud Functions for Notifications ---

// 1. Notify owner when a new order is placed
exports.onOrderCreated = functions.firestore
  .document("Orders/{orderId}")
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const ownerId = order.canteenId; // Assuming canteenId is the owner's UID

    const ownerDoc = await admin.firestore().collection("Owners").doc(ownerId).get();
    const fcmToken = ownerDoc.data().fcmToken;

    if (fcmToken) {
      const payload = {
        notification: {
          title: "New Order Received!",
          body: `Order #${order.tokenNumber} has been placed.`,
          sound: "default",
        },
      };
      await admin.messaging().sendToDevice(fcmToken, payload);
    }
  });

// 2. Notify user when order status changes
exports.onOrderStatusUpdate = functions.firestore
  .document("Orders/{orderId}")
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();

    if (newValue.status !== previousValue.status) {
      const userId = newValue.userId;
      const userDoc = await admin.firestore().collection("Users").doc(userId).get();
      const fcmToken = userDoc.data().fcmToken;

      if (fcmToken) {
        const payload = {
          notification: {
            title: "Order Status Updated",
            body: `Your order #${newValue.tokenNumber} is now ${newValue.status}.`,
            sound: "default",
          },
        };
        await admin.messaging().sendToDevice(fcmToken, payload);
      }
    }
  });

// 3. Notify admins of new owner approval requests
exports.onOwnerCreated = functions.firestore
  .document("Owners/{ownerId}")
  .onCreate(async (snap, context) => {
    const adminsSnapshot = await admin.firestore().collection("Admins").get();
    const tokens = adminsSnapshot.docs.map(doc => doc.data().fcmToken).filter(token => token);

    if (tokens.length > 0) {
      const payload = {
        notification: {
          title: "New Owner Request",
          body: "A new canteen owner is awaiting approval.",
          sound: "default",
        },
      };
      await admin.messaging().sendToDevice(tokens, payload);
    }
  });


// --- Cloud Functions for Payments ---

exports.createRazorpayOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }
  // ... (rest of the function)
});

exports.confirmRazorpayPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }
  // ... (rest of the function)
});
