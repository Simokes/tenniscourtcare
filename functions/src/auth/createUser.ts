import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin } from '../utils/security';
import { isValidEmail, isValidPassword, isValidName, isValidRole } from '../utils/validation';

export const createUser = functions.https.onCall(async (data, context) => {
    assertAdmin(context);

    // Sanitize input
    const email = (data.email as string).trim().toLowerCase();
    const name = (data.name as string).trim();
    const password = data.password;
    const role = (data.role as string).toLowerCase();

    if (!isValidEmail(email)) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid email address.');
    }
    if (!isValidPassword(password)) {
        throw new functions.https.HttpsError('invalid-argument', 'Password must be at least 12 characters.');
    }
    if (!isValidName(name)) {
        throw new functions.https.HttpsError('invalid-argument', 'Name must be at least 2 characters.');
    }
    if (!isValidRole(role)) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid role.');
    }

    // CRITICAL: Check email uniqueness first
    try {
      await admin.auth().getUserByEmail(email);
      throw new functions.https.HttpsError('invalid-argument', 'Email already in use.');
    } catch (error: any) {
      if (error.code !== 'auth/user-not-found') {
        throw error;
      }
    }

    let userRecord: admin.auth.UserRecord | undefined;

    try {
        // CRITICAL: Create Auth user FIRST to get the UID
        userRecord = await admin.auth().createUser({
            email: email,
            password: password,
            displayName: name,
        });

        const uid = userRecord.uid;

        // CRITICAL: Create Firestore doc with SAME UID
        await admin.firestore().collection('users').doc(uid).set({
            uid: uid,
            email: email,
            name: name,
            role: role,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Set custom claims
        await admin.auth().setCustomUserClaims(uid, { role });

        return { uid: uid };
    } catch (error: any) {
        // CRITICAL: Cleanup if fails
        if (userRecord?.uid) {
            try {
                await admin.auth().deleteUser(userRecord.uid);
                // Also try to delete firestore doc if it was created?
                // The transaction above is not atomic across Auth and Firestore.
                // Best effort cleanup.
                await admin.firestore().collection('users').doc(userRecord.uid).delete();
            } catch (cleanupError) {
                console.error('Cleanup failed:', cleanupError);
            }
        }
        console.error('Error creating user:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
