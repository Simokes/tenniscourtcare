const { getTestEnv } = require('./setup');
const { fixtures, createTestUser, expectPermissionDenied } = require('./fixtures');

describe('Users Collection - RBAC Tests', () => {

  // Clean database before each test
  beforeEach(async () => {
    await getTestEnv().clearFirestore();
  });

  // ============================================================================
  // AUTHENTICATION TESTS (3 tests)
  // ============================================================================

  describe('Authentication', () => {

    test('1. Non-authenticated user cannot read users collection', async () => {
      const db = getTestEnv().unauthenticatedContext().firestore();
      await expectPermissionDenied(
        db.collection('users').doc('someUser').get()
      );
    });

    test('2. Non-authenticated user cannot write to users collection', async () => {
      const db = getTestEnv().unauthenticatedContext().firestore();
      await expectPermissionDenied(
        db.collection('users').doc('test').set({ name: 'Test' })
      );
    });

    test('3. Authenticated user can read own profile', async () => {
      // Create user as admin (rules disabled)
      await getTestEnv().withSecurityRulesDisabled(async (context) => {
        await createTestUser(context.firestore(), fixtures.adminUser);
      });

      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      // Should succeed
      const snap = await db.collection('users').doc('admin123').get();
      expect(snap.exists).toBe(true);
      expect(snap.data().email).toBe('admin@test.com');
    });
  });

  // ============================================================================
  // AUTHORIZATION - AGENT TESTS (6 tests)
  // ============================================================================

  describe('Authorization - Agent Role', () => {

    beforeEach(async () => {
      // Create test users with security rules disabled
      await getTestEnv().withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await createTestUser(db, fixtures.agentUser);
        await createTestUser(db, fixtures.otherUser);
        await createTestUser(db, fixtures.adminUser);
      });
    });

    test('4. Agent can read own profile', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();
      const snap = await db.collection('users').doc('agent123').get();

      expect(snap.exists).toBe(true);
      expect(snap.data().role).toBe('agent');
    });

    test('5. Agent cannot read other agent profile', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();
      await expectPermissionDenied(
        db.collection('users').doc('other123').get()
      );
    });

    test('6. Agent cannot read admin profile', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();
      await expectPermissionDenied(
        db.collection('users').doc('admin123').get()
      );
    });

    test('7. Agent can update own name (not role)', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      // Should succeed - updating name
      await db.collection('users').doc('agent123').update({
        name: 'Updated Name',
      });

      const snap = await db.collection('users').doc('agent123').get();
      expect(snap.data().name).toBe('Updated Name');
    });

    test('8. Agent cannot update own role', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      // Should fail - trying to change role
      await expectPermissionDenied(
        db.collection('users').doc('agent123').update({
          role: 'admin',
        })
      );
    });

    test('9. Agent cannot update other user', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('users').doc('other123').update({
          name: 'Hacked Name',
        })
      );
    });
  });

  // ============================================================================
  // AUTHORIZATION - ADMIN TESTS (6 tests)
  // ============================================================================

  describe('Authorization - Admin Role', () => {

    beforeEach(async () => {
      await getTestEnv().withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await createTestUser(db, fixtures.adminUser);
        await createTestUser(db, fixtures.agentUser);
      });
    });

    test('10. Admin can read all users', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();
      const snap = await db.collection('users').get();

      expect(snap.size).toBeGreaterThan(0);
    });

    test('11. Admin can update any user name', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('users').doc('agent123').update({
        name: 'Admin Updated Name',
      });

      const snap = await db.collection('users').doc('agent123').get();
      expect(snap.data().name).toBe('Admin Updated Name');
    });

    test('12. Admin can change user role', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('users').doc('agent123').update({
        role: 'secretary',
      });

      const snap = await db.collection('users').doc('agent123').get();
      expect(snap.data().role).toBe('secretary');
    });

    test('13. Admin can deactivate user', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('users').doc('agent123').update({
        isActive: false,
      });

      const snap = await db.collection('users').doc('agent123').get();
      expect(snap.data().isActive).toBe(false);
    });

    test('14. Admin cannot delete user via rules (must use Cloud Function)', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      // Rules should deny delete (handled by Cloud Function)
      await expectPermissionDenied(
        db.collection('users').doc('agent123').delete()
      );
    });

    test('15. Admin can read own profile', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();
      const snap = await db.collection('users').doc('admin123').get();

      expect(snap.exists).toBe(true);
      expect(snap.data().role).toBe('admin');
    });
  });

});
