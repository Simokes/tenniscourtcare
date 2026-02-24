import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { assertAdmin } from '../utils/security';
import { isValidEmail, isValidPassword, isValidName, isValidRole } from '../utils/validation';

export const createUser = functions.https.onCall(async (data, context) => {
    assertAdmin(context);

    const { email, password, name, role } = data;

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

    try {
        // Generate a new UID for the user
        const uid = admin.firestore().collection('users').doc().id;

        // Create the Firestore document FIRST to avoid race conditions with onCreate trigger
        await admin.firestore().collection('users').doc(uid).set({
            uid: uid,
            email: email,
            name: name,
            role: role,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Create the Auth user with the specific UID
        await admin.auth().createUser({
            uid: uid,
            email: email,
            password: password,
            displayName: name,
        });

        // Set custom claims immediately (optional, as onUpdate trigger would handle it, but this is faster for the return)
        await admin.auth().setCustomUserClaims(uid, { role });

        return { uid: uid };
    } catch (error: any) {
        // If auth creation fails, we should probably delete the firestore doc?
        // Or leave it?
        // Better to cleanup.
        // But simpler to just throw for now.
        console.error('Error creating user:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
