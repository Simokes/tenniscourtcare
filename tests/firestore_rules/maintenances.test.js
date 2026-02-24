const { getTestEnv } = require('./setup');
const {
  fixtures,
  createTestUser,
  createTerrain,
  createMaintenance,
  expectPermissionDenied,
} = require('./fixtures');

describe('Maintenances Collection - Access Control Tests', () => {

  beforeEach(async () => {
    await getTestEnv().clearFirestore();

    // Create users, terrain, and maintenance with rules disabled
    await getTestEnv().withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await createTestUser(db, fixtures.adminUser);
      await createTestUser(db, fixtures.agentUser);
      await createTestUser(db, fixtures.secretaryUser);
      await createTerrain(db, fixtures.terrain1);
      await createMaintenance(db, fixtures.maintenance1);
    });
  });

  describe('Read Access', () => {

    test('1. Unauthenticated user cannot read maintenances', async () => {
      const db = getTestEnv().unauthenticatedContext().firestore();

      await expectPermissionDenied(
        db.collection('maintenances').get()
      );
    });

    test('2. Agent can read maintenances (team access)', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      const snap = await db.collection('maintenances').get();
      expect(snap.size).toBeGreaterThan(0);
    });

    test('3. Secretary can read maintenances (team access)', async () => {
      const db = getTestEnv().authenticatedContext('secretary123', { role: 'secretary' }).firestore();

      const snap = await db.collection('maintenances').get();
      expect(snap.size).toBeGreaterThan(0);
    });

    test('4. Admin can read maintenances', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      const snap = await db.collection('maintenances').get();
      expect(snap.size).toBeGreaterThan(0);
    });
  });

  describe('Write Access', () => {

    test('5. Agent cannot create maintenance', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('maintenances').doc('maint2').set({
          terrainId: 'terrain1',
          description: 'New maintenance',
          status: 'pending',
        })
      );
    });

    test('6. Secretary cannot create maintenance', async () => {
      const db = getTestEnv().authenticatedContext('secretary123', { role: 'secretary' }).firestore();

      await expectPermissionDenied(
        db.collection('maintenances').doc('maint2').set({
          terrainId: 'terrain1',
          description: 'New maintenance',
          status: 'pending',
        })
      );
    });

    test('7. Admin can create maintenance', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('maintenances').doc('maint2').set({
        terrainId: 'terrain1',
        description: 'Court resurfacing',
        status: 'pending',
        createdBy: 'admin123',
        createdAt: new Date(),
      });

      const snap = await db.collection('maintenances').doc('maint2').get();
      expect(snap.exists).toBe(true);
    });

    test('8. Agent cannot update maintenance status', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('maintenances').doc('maint1').update({
          status: 'completed',
        })
      );
    });

    test('9. Admin can update maintenance status', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('maintenances').doc('maint1').update({
        status: 'in_progress',
      });

      const snap = await db.collection('maintenances').doc('maint1').get();
      expect(snap.data().status).toBe('in_progress');
    });

    test('10. Admin can delete maintenance', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('maintenances').doc('maint1').delete();

      const snap = await db.collection('maintenances').doc('maint1').get();
      expect(snap.exists).toBe(false);
    });
  });

});
