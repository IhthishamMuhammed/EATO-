// FILE: functions/index.js
// Firebase Functions v1 - Fixed version

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// ✅ Main Cloud Function that processes notification documents
exports.sendNotification = functions.firestore
  .document('notifications_to_send/{notificationId}')
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    const notificationId = context.params.notificationId;
    
    console.log('📱 Processing notification:', notificationId);
    
    try {
      const message = {
        token: notificationData.token,
        notification: {
          title: notificationData.title,
          body: notificationData.body,
        },
        data: notificationData.data || {},
        android: {
          priority: 'high',
          notification: {
            channel_id: notificationData.android?.channel_id || 'eato_notifications',
            color: notificationData.android?.color || '#6A1B9A',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: notificationData.ios?.badge || 1,
            },
          },
        },
      };

      // Send the notification
      const response = await admin.messaging().send(message);
      console.log('✅ Notification sent successfully:', response);

      // Mark notification as processed
      await snap.ref.update({
        processed: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response,
      });

    } catch (error) {
      console.error('❌ Error sending notification:', error);
      
      // Mark notification as failed
      await snap.ref.update({
        processed: true,
        failed: true,
        error: error.message,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

// ✅ Optional: Function to send test notifications
exports.sendTestNotification = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, message } = data;

  try {
    // Get user's FCM token
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError('failed-precondition', 'User has no FCM token');
    }

    // Send test notification
    const notificationMessage = {
      token: fcmToken,
      notification: {
        title: '🔔 Test Notification',
        body: message || 'This is a test notification from Eato!',
      },
      data: {
        type: 'test',
        timestamp: Date.now().toString(),
      },
    };

    const response = await admin.messaging().send(notificationMessage);
    console.log('✅ Test notification sent:', response);

    return { success: true, messageId: response };
  } catch (error) {
    console.error('❌ Error sending test notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// ✅ Simple HTTP function to manually clean up old notifications
exports.cleanupNotifications = functions.https.onRequest(async (req, res) => {
  // Add basic auth check (optional)
  const authHeader = req.headers.authorization;
  if (!authHeader || authHeader !== 'Bearer your-secret-key') {
    return res.status(401).send('Unauthorized');
  }

  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - 7); // Delete notifications older than 7 days

  try {
    const oldNotifications = await db
      .collection('notifications_to_send')
      .where('processed', '==', true)
      .where('processedAt', '<', cutoffDate)
      .limit(500)
      .get();

    if (oldNotifications.empty) {
      console.log('No old notifications to clean up');
      return res.status(200).send('No old notifications to clean up');
    }

    const batch = db.batch();
    oldNotifications.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`🧹 Cleaned up ${oldNotifications.size} old notifications`);
    
    res.status(200).send(`Cleaned up ${oldNotifications.size} old notifications`);
  } catch (error) {
    console.error('❌ Error cleaning up notifications:', error);
    res.status(500).send(`Error: ${error.message}`);
  }
});