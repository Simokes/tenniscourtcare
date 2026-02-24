import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin } from '../utils/security';

export const deleteUser = functions.https.onCall(async (data, context) => {
    assertAdmin(context);

    const userId = (data.userId as string)?.trim();

    if (!userId) {
        throw new functions.https.HttpsError('invalid-argument', 'User ID is required.');
    }

    // Prevent deleting self
    if (context.auth!.uid === userId) {
        throw new functions.https.HttpsError('invalid-argument', 'You cannot delete your own account.');
    }

    try {
        // Check if user exists and is not the last admin
        const userDoc = await admin.firestore().collection('users').doc(userId).get();

        if (userDoc.exists && userDoc.data()?.role === 'admin') {
             const adminsSnapshot = await admin.firestore().collection('users').where('role', '==', 'admin').get();
             if (adminsSnapshot.size <= 1) {
                 throw new functions.https.HttpsError('failed-precondition', 'Cannot delete the last administrator.');
             }
        }

        // CRITICAL FIX: Reverse delete order (Firestore first)
        // 1. Delete from Firestore
        await admin.firestore().collection('users').doc(userId).delete();

        // 2. Delete from Auth
        await admin.auth().deleteUser(userId);

        // Audit Log
        await admin.firestore().collection('audit_logs').add({
            action: 'USER_DELETED',
            targetUserId: userId,
            performedBy: context.auth!.uid, // ADDED: Audit trail
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { success: true };
    } catch (error: any) {
        console.error('Error deleting user:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
