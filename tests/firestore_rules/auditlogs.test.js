const { getTestEnv } = require('./setup');
const {
  fixtures,
  createTestUser,
  createAuditLog,
  expectPermissionDenied,
} = require('./fixtures');

describe('AuditLogs Collection - Access Control Tests', () => {

  beforeEach(async () => {
    await getTestEnv().clearFirestore();

    // Create users and audit logs with rules disabled
    await getTestEnv().withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await createTestUser(db, fixtures.adminUser);
      await createTestUser(db, fixtures.agentUser);
      await createAuditLog(db, fixtures.auditLog1);
    });
  });

  describe('Read Access - SENSITIVE AUDIT TRAIL', () => {

    test('1. Unauthenticated user cannot read audit logs', async () => {
      const db = getTestEnv().unauthenticatedContext().firestore();

      await expectPermissionDenied(
        db.collection('auditLogs').get()
      );
    });

    test('2. Agent cannot read audit logs', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('auditLogs').get()
      );
    });

    test('3. Admin can read audit logs', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      const snap = await db.collection('auditLogs').get();
      expect(snap.size).toBeGreaterThan(0);
    });
  });

  describe('Write Access - CLOUD FUNCTIONS ONLY', () => {

    test('4. Agent cannot write to audit logs', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('auditLogs').doc('audit2').set({
          action: 'USER_CREATED',
          targetUserId: 'user123',
          performedBy: 'agent123',
          timestamp: new Date(),
        })
      );
    });

    test('5. Admin cannot directly write to audit logs (Cloud Functions only)', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      // Even admin cannot write - must go through Cloud Functions
      await expectPermissionDenied(
        db.collection('auditLogs').doc('audit2').set({
          action: 'USER_CREATED',
          targetUserId: 'user123',
          performedBy: 'admin123',
          timestamp: new Date(),
        })
      );
    });
  });

});
