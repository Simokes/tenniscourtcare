import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin } from '../utils/security';
import { isValidPassword } from '../utils/validation';

export const resetUserPassword = functions.https.onCall(async (data, context) => {
    assertAdmin(context);

    const { userId, newPassword } = data;

    if (!userId || !newPassword) {
        throw new functions.https.HttpsError('invalid-argument', 'User ID and new password are required.');
    }

    if (!isValidPassword(newPassword)) {
        throw new functions.https.HttpsError('invalid-argument', 'Password must be at least 12 characters.');
    }

    try {
        await admin.auth().updateUser(userId, {
            password: newPassword,
        });

        // Log to audit logs?
        // We can do that in the Cloud Function or the client.
        // Client side logs are easier to integrate with existing AuditRepository,
        // but server side is more secure.
        // The prompt asked for "Function 2... Log action in auditLogs".
        // That was for onUpdate.
        // For this callable, we can log to a Firestore collection 'audit_logs'.

        return { success: true };
    } catch (error: any) {
        console.error('Error resetting password:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
