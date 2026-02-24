import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin } from '../utils/security';
import { isValidPassword } from '../utils/validation';

export const resetUserPassword = functions.https.onCall(async (data, context) => {
    assertAdmin(context);

    const userId = (data.userId as string).trim();
    const newPassword = data.newPassword;

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

        // Audit Log
        await admin.firestore().collection('audit_logs').add({
            action: 'PASSWORD_RESET',
            targetUserId: userId,
            performedBy: context.auth!.uid,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { success: true };
    } catch (error: any) {
        console.error('Error resetting password:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
