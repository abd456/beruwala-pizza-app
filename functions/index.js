const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

// ── Status labels for customer notifications ─────────────────────────────────

const STATUS_MESSAGES = {
  preparing: {
    title: "Your order is being prepared! 👨‍🍳",
    body: "Order #{orderNumber} is now in the kitchen.",
  },
  ready: {
    title: "Your order is ready! 🍕",
    body: "Order #{orderNumber} is ready for {type}.",
  },
  delivered: {
    title: "Order complete! ✅",
    body: "Order #{orderNumber} has been delivered. Enjoy your meal!",
  },
};

// ── 1. Notify CUSTOMER when their order status changes ───────────────────────

exports.onOrderStatusChange = onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  // Only fire when status actually changed
  if (before.status === after.status) return;

  const template = STATUS_MESSAGES[after.status];
  if (!template) return; // no notification for "received" (they just placed it)

  // Get customer FCM token
  const customerId = after.customerId;
  if (!customerId) return;

  const userDoc = await db.collection("users").doc(customerId).get();
  const fcmToken = userDoc.data()?.fcmToken;
  if (!fcmToken) return;

  const typeLabel = after.type === "delivery" ? "delivery" : "pickup";
  const title = template.title;
  const body = template.body
    .replace("{orderNumber}", after.orderNumber)
    .replace("{type}", typeLabel);

  try {
    await getMessaging().send({
      token: fcmToken,
      notification: { title, body },
      data: {
        type: "order_status",
        orderId: event.params.orderId,
        status: after.status,
      },
    });
  } catch (err) {
    // Token may be stale — log but don't crash
    console.error("Failed to send notification:", err.message);
  }
});

// ── 2. Notify ALL ADMINS when a new order is placed ──────────────────────────

exports.onNewOrder = onDocumentCreated("orders/{orderId}", async (event) => {
  const order = event.data.data();

  // Find all admin users with FCM tokens
  const adminsSnap = await db
    .collection("users")
    .where("role", "==", "admin")
    .get();

  const tokens = adminsSnap.docs
    .map((doc) => doc.data().fcmToken)
    .filter(Boolean);

  if (tokens.length === 0) return;

  const title = "New order received! 🔔";
  const body = `Order #${order.orderNumber} — ${order.customerName} (${order.type})`;

  const messages = tokens.map((token) => ({
    token,
    notification: { title, body },
    data: {
      type: "new_order",
      orderId: event.params.orderId,
    },
  }));

  const results = await Promise.allSettled(
    messages.map((msg) => getMessaging().send(msg))
  );

  results.forEach((r, i) => {
    if (r.status === "rejected") {
      console.error(`Failed to notify admin token ${tokens[i]}:`, r.reason?.message);
    }
  });
});
