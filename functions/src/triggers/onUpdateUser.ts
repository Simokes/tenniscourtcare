import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onUpdateUser = functions.firestore
    .document('users/{userId}')
    .onUpdate(async (change, context) => {
        const newValue = change.after.data();
        const previousValue = change.before.data();

        // Check if role has changed
        if (newValue.role !== previousValue.role) {
            const role = newValue.role;
            const userId = context.params.userId;

            console.log(`Role updated for user ${userId} from ${previousValue.role} to ${role}. Updating custom claims.`);

            // Update custom claims
            await admin.auth().setCustomUserClaims(userId, { role });

             await admin.firestore().collection('audit_logs').add({
                action: 'ROLE_UPDATED',
                targetUserId: userId,
                newRole: role,
                previousRole: previousValue.role,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
             });
        }
    });
