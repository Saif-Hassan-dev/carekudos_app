import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─────────────────────────────────────────────────────────────
// 1. ANNOUNCEMENT PUSH — fires when a new announcement is created
//    Sends FCM to the "announcements" topic → ALL subscribed devices
// ─────────────────────────────────────────────────────────────
export const onAnnouncementCreated = functions.firestore
  .document("announcements/{announcementId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    const title: string = data?.title ?? "New Announcement";
    const body: string = data?.message ?? "";

    const message: admin.messaging.Message = {
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
        announcementId: snap.id,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    try {
      const response = await messaging.send(message);
      functions.logger.info(`Announcement sent to topic. Message ID: ${response}`);
    } catch (error) {
      functions.logger.error("Failed to send announcement:", error);
    }
  });

// ─────────────────────────────────────────────────────────────
// 2. QUEUED PUSH NOTIFICATIONS — processes push_notifications collection
//    Handles individual notifications (stars, approvals, rejections)
// ─────────────────────────────────────────────────────────────
export const sendQueuedPushNotifications = functions.firestore
  .document("push_notifications/{notifId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    if (!data || data.status !== "pending") return;

    const recipientId: string = data.recipientId;
    const title: string = data.title;
    const body: string = data.body;
    const extraData: Record<string, string> = data.data ?? {};

    // Mark as processing to prevent duplicates
    await snap.ref.update({ status: "processing" });

    try {
      // Get recipient's FCM tokens
      const userDoc = await db.collection("users").doc(recipientId).get();
      if (!userDoc.exists) {
        await snap.ref.update({ status: "failed", error: "User not found" });
        return;
      }

      const fcmTokens: string[] = userDoc.data()?.fcmTokens ?? [];
      if (fcmTokens.length === 0) {
        await snap.ref.update({ status: "no_token" });
        return;
      }

      // Send to each device token
      const messages: admin.messaging.Message[] = fcmTokens.map((token) => ({
        token,
        notification: { title, body },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "carekudos_default",
            sound: "default",
          },
        },
        apns: {
          payload: { aps: { sound: "default", badge: 1 } },
        },
        data: {
          ...extraData,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      }));

      const batchResponse = await messaging.sendEach(messages);
      const successCount = batchResponse.responses.filter((r) => r.success).length;

      // Clean up invalid tokens
      const invalidTokens: string[] = [];
      batchResponse.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const code = resp.error?.code;
          if (
            code === "messaging/invalid-registration-token" ||
            code === "messaging/registration-token-not-registered"
          ) {
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

      functions.logger.info(
        `Push sent to ${recipientId}: ${successCount}/${fcmTokens.length} succeeded`
      );
    } catch (error) {
      functions.logger.error("Failed to send queued push:", error);
      await snap.ref.update({ status: "failed", error: String(error) });
    }
  });

// ─────────────────────────────────────────────────────────────
// 3. TOKEN CLEANUP — removes stale FCM tokens periodically
// ─────────────────────────────────────────────────────────────
export const cleanupStaleTokens = functions.pubsub
  .schedule("every 7 days")
  .onRun(async () => {
    // Remove users that haven't refreshed their token in 60 days
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
    functions.logger.info(`Cleaned tokens for ${staleUsers.size} stale users`);
  });
