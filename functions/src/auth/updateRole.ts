import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin } from '../utils/security';
import { isValidRole } from '../utils/validation';

export const updateUserRole = functions.https.onCall(async (data, context) => {
    assertAdmin(context);

    const userId = (data.userId as string)?.trim();
    const newRole = (data.newRole as string)?.toLowerCase();

    if (!userId || !newRole) {
        throw new functions.https.HttpsError('invalid-argument', 'User ID and new role are required.');
    }

    if (!isValidRole(newRole)) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid role.');
    }

    try {
        // CRITICAL FIX: Verify user exists in Auth
        try {
            await admin.auth().getUser(userId);
        } catch (error) {
            throw new functions.https.HttpsError('not-found', 'User not found in Auth.');
        }

        // Prevent removing the last admin
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        if (userDoc.exists && userDoc.data()?.role === 'admin' && newRole !== 'admin') {
             const adminsSnapshot = await admin.firestore().collection('users').where('role', '==', 'admin').get();
             if (adminsSnapshot.size <= 1) {
                 throw new functions.https.HttpsError('failed-precondition', 'Cannot demote the last administrator.');
             }
        }

        // CRITICAL FIX: Set custom claims FIRST (immediate update)
        await admin.auth().setCustomUserClaims(userId, { role: newRole });

        // Then update Firestore
        await admin.firestore().collection('users').doc(userId).update({
            role: newRole,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Audit Log
        await admin.firestore().collection('audit_logs').add({
            action: 'ROLE_UPDATED_CALLABLE',
            targetUserId: userId,
            newRole: newRole,
            performedBy: context.auth!.uid, // ADDED: Audit trail
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { success: true };
    } catch (error: any) {
        console.error('Error updating role:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
