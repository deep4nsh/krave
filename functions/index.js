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

/**
 * Creates a Razorpay order on the server.
 * Called by the app before opening the Razorpay checkout.
 */
exports.createRazorpayOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }

  const options = {
    amount: data.amount,
    currency: "INR",
    receipt: data.receipt,
    notes: data.notes,
  };

  try {
    const order = await razorpay.orders.create(options);
    return { orderId: order.id };
  } catch (error) {
    console.error("Razorpay order creation failed:", error);
    throw new functions.https.HttpsError("internal", "Failed to create Razorpay order.");
  }
});

/**
 * Verifies the Razorpay payment signature and creates the final order in Firestore.
 * Called by the app after a successful payment.
 */
exports.confirmRazorpayPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }

  // 1. Securely verify the payment signature
  const shasum = crypto.createHmac("sha256", functions.config().razorpay.key_secret);
  shasum.update(`${data.razorpay_order_id}|${data.razorpay_payment_id}`);
  const digest = shasum.digest("hex");

  if (digest !== data.razorpay_signature) {
    throw new functions.https.HttpsError("permission-denied", "Invalid payment signature.");
  }

  // 2. All checks passed. Create the order in Firestore.
  const orderRef = admin.firestore().collection("Orders").doc();
  // Re-use the scalable token generation logic from your app's service
  const today = new Date();
  const dateString = `${today.getFullYear()}-${today.getMonth() + 1}-${today.getDate()}`;
  const counterRef = admin.firestore().collection("Canteens").doc(data.canteenId).collection("Counters").doc(dateString);

  let newToken;
  await admin.firestore().runTransaction(async (transaction) => {
    const counterDoc = await transaction.get(counterRef);
    if (!counterDoc.exists) {
      newToken = 1;
      transaction.set(counterRef, { lastToken: newToken });
    } else {
      newToken = counterDoc.data().lastToken + 1;
      transaction.update(counterRef, { lastToken: newToken });
    }
  });

  await orderRef.set({
    userId: data.userId,
    canteenId: data.canteenId,
    items: data.items,
    totalAmount: data.totalAmount,
    tokenNumber: newToken.toString(),
    status: "Pending",
    paymentId: data.razorpay_payment_id,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { firestoreOrderId: orderRef.id };
});