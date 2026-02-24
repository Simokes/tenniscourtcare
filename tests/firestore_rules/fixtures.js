// Test users
const fixtures = {
  adminUser: {
    uid: 'admin123',
    email: 'admin@test.com',
    role: 'admin',
  },
  agentUser: {
    uid: 'agent123',
    email: 'agent@test.com',
    role: 'agent',
  },
  secretaryUser: {
    uid: 'secretary123',
    email: 'secretary@test.com',
    role: 'secretary',
  },
  otherUser: {
    uid: 'other123',
    email: 'other@test.com',
    role: 'agent',
  },
};

// Helper: Create test user in Firestore
async function createTestUser(db, userData) {
  await db.collection('users').doc(userData.uid).set({
    uid: userData.uid,
    email: userData.email,
    name: userData.email.split('@')[0],
    role: userData.role,
    createdAt: new Date(),
    isActive: true,
  });
  return userData.uid;
}

// Helper: Expect permission denied
async function expectPermissionDenied(promise) {
  try {
    await promise;
    throw new Error('Expected permission denied but succeeded');
  } catch (error) {
    if (error.message === 'Expected permission denied but succeeded') {
      throw error;
    }
    // Expected: permission-denied error
    // Check for code or message containing permission denied
    const isPermissionDenied =
      (error.code && (error.code.includes('permission-denied') || error.code.includes('PERMISSION_DENIED'))) ||
      (error.message && (error.message.includes('PERMISSION_DENIED') || error.message.includes('Missing or insufficient permissions') || error.message.includes('false for \'list\'') || error.message.includes('false for \'get\'') || error.message.includes('false for \'update\'')));

    if (isPermissionDenied) {
      return;
    }
    throw error;
  }
}

module.exports = {
  fixtures,
  createTestUser,
  expectPermissionDenied,
};
