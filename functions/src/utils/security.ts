import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

export const assertAdmin = (context: functions.https.CallableContext) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated.');
    }

    // CRITICAL FIX: Access role from customClaims, not token root
    const role = context.auth.token.customClaims?.role as string | undefined;

    if (role !== 'admin') {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can perform this action.');
    }
};
