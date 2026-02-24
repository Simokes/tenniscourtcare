import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin } from '../utils/security';

export const deleteUser = functions.https.onCall(async (data, context) => {
    assertAdmin(context);

    const { userId } = data;

    if (!userId) {
        throw new functions.https.HttpsError('invalid-argument', 'User ID is required.');
    }

    // Prevent deleting self
    if (context.auth!.uid === userId) {
        throw new functions.https.HttpsError('invalid-argument', 'You cannot delete your own account.');
    }

    try {
        // Check if user is the last admin?
        // This requires reading all users or keeping a counter.
        // For simplicity, we skip this check or implement it via a count query.
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        if (userDoc.exists && userDoc.data()?.role === 'admin') {
             const adminsSnapshot = await admin.firestore().collection('users').where('role', '==', 'admin').get();
             if (adminsSnapshot.size <= 1) {
                 throw new functions.https.HttpsError('failed-precondition', 'Cannot delete the last administrator.');
             }
        }

        await admin.auth().deleteUser(userId);
        await admin.firestore().collection('users').doc(userId).delete();

        return { success: true };
    } catch (error: any) {
        console.error('Error deleting user:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
