import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin } from '../utils/security';
import { isValidRole } from '../utils/validation';

export const updateUserRole = functions.https.onCall(async (data, context) => {
    assertAdmin(context);

    const { userId, newRole } = data;

    if (!userId || !newRole) {
        throw new functions.https.HttpsError('invalid-argument', 'User ID and new role are required.');
    }

    if (!isValidRole(newRole)) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid role.');
    }

    try {
        await admin.firestore().collection('users').doc(userId).update({
            role: newRole,
        });

        // The onUpdate trigger will handle the custom claims update.

        return { success: true };
    } catch (error: any) {
        console.error('Error updating role:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
