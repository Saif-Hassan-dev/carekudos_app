import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const REGION = "europe-west1";

// ─────────────────────────────────────────────────────────────
// 1. ANNOUNCEMENT PUSH — fires when a new announcement is created
//    Sends FCM to the "announcements" topic → ALL subscribed devices
// ─────────────────────────────────────────────────────────────
export const onAnnouncementCreated = onDocumentCreated(
  { document: "announcements/{announcementId}", region: REGION },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

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
        announcementId: event.data!.id,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    try {
      const response = await messaging.send(message);
      logger.info(`Announcement sent to topic. Message ID: ${response}`);
    } catch (error) {
      logger.error("Failed to send announcement:", error);
    }
  }
);

// ─────────────────────────────────────────────────────────────
// 2. QUEUED PUSH NOTIFICATIONS — processes push_notifications collection
//    Handles individual notifications (stars, approvals, rejections)
// ─────────────────────────────────────────────────────────────
export const sendQueuedPushNotifications = onDocumentCreated(
  { document: "push_notifications/{notifId}", region: REGION },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

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

      logger.info(`Push sent to ${recipientId}: ${successCount}/${fcmTokens.length} succeeded`);
    } catch (error) {
      logger.error("Failed to send queued push:", error);
      await snap.ref.update({ status: "failed", error: String(error) });
    }
  }
);

// ─────────────────────────────────────────────────────────────
// 3. ADMIN CREATE USER — callable function to create Auth + Firestore user
//    Only callable by admins. Creates Firebase Auth account and Firestore doc.
// ─────────────────────────────────────────────────────────────
export const adminCreateUser = onCall(
  { region: REGION },
  async (request) => {
    // Must be signed in
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    // Must be admin
    const callerDoc = await db.collection("users").doc(request.auth.uid).get();
    if (callerDoc.data()?.role !== "admin") {
      throw new HttpsError("permission-denied", "Only admins can create users.");
    }

    const { email, password, firstName, lastName, role, organizationId } = request.data as {
      email: string;
      password: string;
      firstName: string;
      lastName: string;
      role: string;
      organizationId: string;
    };

    if (!email || !password || !firstName || !lastName) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }

    // Create Firebase Auth user
    let userRecord: admin.auth.UserRecord;
    try {
      userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: `${firstName} ${lastName}`,
      });
    } catch (err: unknown) {
      const code = (err as { code?: string }).code;
      if (code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "A user with this email already exists.");
      }
      throw new HttpsError("internal", `Failed to create auth user: ${String(err)}`);
    }

    // Create Firestore user document with the real UID
    await db.collection("users").doc(userRecord.uid).set({
      firstName,
      lastName,
      email,
      role: role ?? "care_worker",
      organizationId: organizationId ?? "",
      gdprConsentGiven: false,
      gdprTrainingCompleted: false,
      totalStars: 0,
      starsThisMonth: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info(`Admin created user: ${userRecord.uid} (${email})`);
    return { uid: userRecord.uid };
  }
);

// ─────────────────────────────────────────────────────────────
// 4. TOKEN CLEANUP — removes stale FCM tokens periodically
// ─────────────────────────────────────────────────────────────
export const cleanupStaleTokens = onSchedule(
  { schedule: "every 168 hours", region: REGION },
  async () => {
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
    logger.info(`Cleaned tokens for ${staleUsers.size} stale users`);
  }
);
