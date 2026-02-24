import * as admin from 'firebase-admin';

admin.initializeApp();

export * from './auth/createUser';
export * from './auth/deleteUser';
export * from './auth/resetPassword';
export * from './auth/updateRole';
export * from './triggers/onCreateUser';
export * from './triggers/onUpdateUser';
