const { getTestEnv } = require('./setup');
const {
  fixtures,
  createTestUser,
  createTerrain,
  createReservation,
  expectPermissionDenied,
  getFutureTime,
  getPastTime,
} = require('./fixtures');

describe('Reservations Collection - Business Logic Tests', () => {

  beforeEach(async () => {
    await getTestEnv().clearFirestore();

    // Create users, terrain, and reservation with rules disabled
    await getTestEnv().withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await createTestUser(db, fixtures.adminUser);
      await createTestUser(db, fixtures.agentUser);
      await createTestUser(db, fixtures.otherUser);
      await createTerrain(db, fixtures.terrain1);
      await createReservation(db, fixtures.reservation1);
    });
  });

  describe('Read Access', () => {

    test('1. Unauthenticated cannot read reservations', async () => {
      const db = getTestEnv().unauthenticatedContext().firestore();

      await expectPermissionDenied(
        db.collection('reservations').get()
      );
    });

    test('2. User can read own reservation', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      const snap = await db.collection('reservations').doc('res1').get();
      expect(snap.exists).toBe(true);
      expect(snap.data().userId).toBe('agent123');
    });

    test('3. User cannot read other user reservation', async () => {
      const db = getTestEnv().authenticatedContext('other123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('reservations').doc('res1').get()
      );
    });

    test('4. Admin can read any reservation', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      const snap = await db.collection('reservations').doc('res1').get();
      expect(snap.exists).toBe(true);
    });
  });

  describe('Create Access - Time Validation', () => {

    test('5. User can create own future reservation', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      const startTime = getFutureTime(24);
      const endTime = getFutureTime(25);

      await db.collection('reservations').doc('res3').set({
        terrainId: 'terrain1',
        userId: 'agent123',
        startTime: startTime,
        endTime: endTime,
        status: 'pending',
        createdAt: new Date(),
        createdBy: 'agent123',
      });

      const snap = await db.collection('reservations').doc('res3').get();
      expect(snap.exists).toBe(true);
      expect(snap.data().status).toBe('pending');
    });

    test('6. User cannot create reservation for other user', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('reservations').doc('res4').set({
          terrainId: 'terrain1',
          userId: 'other123',  // Wrong user!
          startTime: getFutureTime(24),
          endTime: getFutureTime(25),
          status: 'pending',
          createdAt: new Date(),
          createdBy: 'agent123',
        })
      );
    });

    test('7. Cannot create past reservation', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('reservations').doc('res5').set({
          terrainId: 'terrain1',
          userId: 'agent123',
          startTime: getPastTime(1),  // 1 hour ago
          endTime: getFutureTime(1),
          status: 'pending',
          createdAt: new Date(),
          createdBy: 'agent123',
        })
      );
    });

    test('8. Cannot create if endTime before startTime', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      const startTime = getFutureTime(24);
      const endTime = getFutureTime(23);  // Before start!

      await expectPermissionDenied(
        db.collection('reservations').doc('res6').set({
          terrainId: 'terrain1',
          userId: 'agent123',
          startTime: startTime,
          endTime: endTime,
          status: 'pending',
          createdAt: new Date(),
          createdBy: 'agent123',
        })
      );
    });

    test('9. Cannot create without terrainId', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('reservations').doc('res7').set({
          userId: 'agent123',
          // Missing terrainId!
          startTime: getFutureTime(24),
          endTime: getFutureTime(25),
          status: 'pending',
          createdAt: new Date(),
          createdBy: 'agent123',
        })
      );
    });

    test('10. Cannot create with status != pending', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('reservations').doc('res8').set({
          terrainId: 'terrain1',
          userId: 'agent123',
          startTime: getFutureTime(24),
          endTime: getFutureTime(25),
          status: 'confirmed',  // Must be pending!
          createdAt: new Date(),
          createdBy: 'agent123',
        })
      );
    });

    test('11. Admin can create reservation for other user', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('reservations').doc('res9').set({
        terrainId: 'terrain1',
        userId: 'agent123',  // Admin creating for agent
        startTime: getFutureTime(24),
        endTime: getFutureTime(25),
        status: 'pending',
        createdAt: new Date(),
        createdBy: 'admin123',
      });

      const snap = await db.collection('reservations').doc('res9').get();
      expect(snap.exists).toBe(true);
    });
  });

  describe('Update Access - Status & Permissions', () => {

    test('12. User can cancel own reservation', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await db.collection('reservations').doc('res1').update({
        status: 'cancelled',
      });

      const snap = await db.collection('reservations').doc('res1').get();
      expect(snap.data().status).toBe('cancelled');
    });

    test('13. User cannot update own reservation status to confirmed', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('reservations').doc('res1').update({
          status: 'confirmed',  // Only admin can do this!
        })
      );
    });

    test('14. User cannot update other user reservation', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      // Need to create a reservation for otherUser first or use existing one if accessible?
      // Fixtures created res1 (agent123). Fixtures don't automatically create res2 in setup (only res1).
      // Let's create res2 for otherUser using admin context in this test or rely on correct setup.
      // Wait, beforeEach only creates res1. Let's create res2 here.

      await getTestEnv().withSecurityRulesDisabled(async (context) => {
        await createReservation(context.firestore(), fixtures.reservation2);
      });

      await expectPermissionDenied(
        db.collection('reservations').doc('res2').update({
          status: 'cancelled',
        })
      );
    });

    test('15. Admin can change any reservation status', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('reservations').doc('res1').update({
        status: 'confirmed',
      });

      const snap = await db.collection('reservations').doc('res1').get();
      expect(snap.data().status).toBe('confirmed');
    });
  });

  describe('Delete Access', () => {

    test('16. User cannot delete reservation (admin only)', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('reservations').doc('res1').delete()
      );
    });

    test('17. Admin can delete reservation', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('reservations').doc('res1').delete();

      const snap = await db.collection('reservations').doc('res1').get();
      expect(snap.exists).toBe(false);
    });
  });

});
