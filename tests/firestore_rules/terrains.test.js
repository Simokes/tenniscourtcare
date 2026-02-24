const { getTestEnv } = require('./setup');
const {
  fixtures,
  createTestUser,
  createTerrain,
  expectPermissionDenied,
} = require('./fixtures');

describe('Terrains Collection - Access Control Tests', () => {

  beforeEach(async () => {
    await getTestEnv().clearFirestore();

    // Create test users and terrains as admin (security rules bypassed or admin context)
    // Using withSecurityRulesDisabled is safest for setup to avoid rule interference
    await getTestEnv().withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await createTestUser(db, fixtures.adminUser);
      await createTestUser(db, fixtures.agentUser);
      await createTerrain(db, fixtures.terrain1);
      await createTerrain(db, fixtures.terrain2);
    });
  });

  describe('Read Access', () => {

    test('1. Unauthenticated user can read terrains (public)', async () => {
      const db = getTestEnv().unauthenticatedContext().firestore();
      const snap = await db.collection('terrains').get();

      // Should be able to read (public)
      expect(snap.size).toBe(2);
    });

    test('2. Agent can read terrains (public)', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();
      const snap = await db.collection('terrains').doc('terrain1').get();

      expect(snap.exists).toBe(true);
      expect(snap.data().name).toBe('Court Central');
    });

    test('3. Admin can read terrains (public)', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();
      const snap = await db.collection('terrains').get();

      expect(snap.size).toBe(2);
    });
  });

  describe('Write Access', () => {

    test('4. Agent cannot create terrain', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('terrains').doc('terrain3').set({
          name: 'New Court',
          type: 'tennis',
          hourlyRate: 50,
        })
      );
    });

    test('5. Agent cannot update terrain', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('terrains').doc('terrain1').update({
          hourlyRate: 100,
        })
      );
    });

    test('6. Agent cannot delete terrain', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('terrains').doc('terrain1').delete()
      );
    });

    test('7. Admin can create terrain', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('terrains').doc('terrain3').set({
        name: 'Court 3',
        type: 'tennis',
        hourlyRate: 45,
      });

      const snap = await db.collection('terrains').doc('terrain3').get();
      expect(snap.exists).toBe(true);
    });

    test('8. Admin can update terrain', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('terrains').doc('terrain1').update({
        hourlyRate: 60,
      });

      const snap = await db.collection('terrains').doc('terrain1').get();
      expect(snap.data().hourlyRate).toBe(60);
    });

    test('9. Admin can deactivate terrain', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('terrains').doc('terrain1').update({
        isActive: false,
      });

      const snap = await db.collection('terrains').doc('terrain1').get();
      expect(snap.data().isActive).toBe(false);
    });

    test('10. Admin can delete terrain', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('terrains').doc('terrain1').delete();

      const snap = await db.collection('terrains').doc('terrain1').get();
      expect(snap.exists).toBe(false);
    });
  });

});
