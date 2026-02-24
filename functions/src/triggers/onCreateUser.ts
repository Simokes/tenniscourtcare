import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onCreateUser = functions.auth.user().onCreate(async (user) => {
    // Check if the user document already exists (created by admin)
    const userDocRef = admin.firestore().collection('users').doc(user.uid);
    const userDoc = await userDocRef.get();

    if (!userDoc.exists) {
        // If not, create it with default role 'agent'
        await userDocRef.set({
            uid: user.uid,
            email: user.email,
            name: user.displayName || 'New User',
            role: 'agent', // Default role
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Set default custom claim
        await admin.auth().setCustomUserClaims(user.uid, { role: 'agent' });

        console.log(`Created default user document for ${user.email} with role 'agent'.`);
    } else {
        console.log(`User document already exists for ${user.email}. Skipping default creation.`);
    }
});
