"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupStaleTokens = exports.sendQueuedPushNotifications = exports.onAnnouncementCreated = void 0;
const admin = require("firebase-admin");
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const v2_1 = require("firebase-functions/v2");
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
const REGION = "europe-west1";
// ─────────────────────────────────────────────────────────────
// 1. ANNOUNCEMENT PUSH — fires when a new announcement is created
//    Sends FCM to the "announcements" topic → ALL subscribed devices
// ─────────────────────────────────────────────────────────────
exports.onAnnouncementCreated = (0, firestore_1.onDocumentCreated)({ document: "announcements/{announcementId}", region: REGION }, async (event) => {
    var _a, _b, _c;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const title = (_b = data === null || data === void 0 ? void 0 : data.title) !== null && _b !== void 0 ? _b : "New Announcement";
    const body = (_c = data === null || data === void 0 ? void 0 : data.message) !== null && _c !== void 0 ? _c : "";
    const message = {
        topic: "announcements",
        notification: { title, body },
        android: {
            priority: "high",
            notification: {
                channelId: "carekudos_default",
                sound: "default",
            },
        },
        apns: {
            payload: {
                aps: { sound: "default", badge: 1 },
            },
        },
        data: {
            type: "announcement",
            announcementId: event.data.id,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
    };
    try {
        const response = await messaging.send(message);
        v2_1.logger.info(`Announcement sent to topic. Message ID: ${response}`);
    }
    catch (error) {
        v2_1.logger.error("Failed to send announcement:", error);
    }
});
// ─────────────────────────────────────────────────────────────
// 2. QUEUED PUSH NOTIFICATIONS — processes push_notifications collection
//    Handles individual notifications (stars, approvals, rejections)
// ─────────────────────────────────────────────────────────────
exports.sendQueuedPushNotifications = (0, firestore_1.onDocumentCreated)({ document: "push_notifications/{notifId}", region: REGION }, async (event) => {
    var _a, _b, _c;
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    if (!data || data.status !== "pending")
        return;
    const recipientId = data.recipientId;
    const title = data.title;
    const body = data.body;
    const extraData = (_a = data.data) !== null && _a !== void 0 ? _a : {};
    // Mark as processing to prevent duplicates
    await snap.ref.update({ status: "processing" });
    try {
        // Get recipient's FCM tokens
        const userDoc = await db.collection("users").doc(recipientId).get();
        if (!userDoc.exists) {
            await snap.ref.update({ status: "failed", error: "User not found" });
            return;
        }
        const fcmTokens = (_c = (_b = userDoc.data()) === null || _b === void 0 ? void 0 : _b.fcmTokens) !== null && _c !== void 0 ? _c : [];
        if (fcmTokens.length === 0) {
            await snap.ref.update({ status: "no_token" });
            return;
        }
        // Send to each device token
        const messages = fcmTokens.map((token) => ({
            token,
            notification: { title, body },
            android: {
                priority: "high",
                notification: {
                    channelId: "carekudos_default",
                    sound: "default",
                },
            },
            apns: {
                payload: { aps: { sound: "default", badge: 1 } },
            },
            data: Object.assign(Object.assign({}, extraData), { click_action: "FLUTTER_NOTIFICATION_CLICK" }),
        }));
        const batchResponse = await messaging.sendEach(messages);
        const successCount = batchResponse.responses.filter((r) => r.success).length;
        // Clean up invalid tokens
        const invalidTokens = [];
        batchResponse.responses.forEach((resp, idx) => {
            var _a;
            if (!resp.success) {
                const code = (_a = resp.error) === null || _a === void 0 ? void 0 : _a.code;
                if (code === "messaging/invalid-registration-token" ||
                    code === "messaging/registration-token-not-registered") {
                    invalidTokens.push(fcmTokens[idx]);
                }
            }
        });
        if (invalidTokens.length > 0) {
            await db.collection("users").doc(recipientId).update({
                fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
            });
        }
        await snap.ref.update({
            status: "sent",
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount,
            failCount: fcmTokens.length - successCount,
        });
        v2_1.logger.info(`Push sent to ${recipientId}: ${successCount}/${fcmTokens.length} succeeded`);
    }
    catch (error) {
        v2_1.logger.error("Failed to send queued push:", error);
        await snap.ref.update({ status: "failed", error: String(error) });
    }
});
// ─────────────────────────────────────────────────────────────
// 3. TOKEN CLEANUP — removes stale FCM tokens periodically
// ─────────────────────────────────────────────────────────────
exports.cleanupStaleTokens = (0, scheduler_1.onSchedule)({ schedule: "every 168 hours", region: REGION }, async () => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 60);
    const staleUsers = await db
        .collection("users")
        .where("lastTokenRefresh", "<", cutoff)
        .get();
    const batch = db.batch();
    staleUsers.docs.forEach((doc) => {
        batch.update(doc.ref, { fcmTokens: [] });
    });
    await batch.commit();
    v2_1.logger.info(`Cleaned tokens for ${staleUsers.size} stale users`);
});
//# sourceMappingURL=index.js.map