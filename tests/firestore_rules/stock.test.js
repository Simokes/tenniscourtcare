const { getTestEnv } = require('./setup');
const {
  fixtures,
  createTestUser,
  createStockItem,
  expectPermissionDenied,
} = require('./fixtures');

describe('Stock Collection - Access Control Tests', () => {

  beforeEach(async () => {
    await getTestEnv().clearFirestore();

    // Create test users and stock items with rules disabled
    await getTestEnv().withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await createTestUser(db, fixtures.adminUser);
      await createTestUser(db, fixtures.agentUser);
      await createStockItem(db, fixtures.stockItem1);
    });
  });

  describe('Read Access - SENSITIVE DATA', () => {

    test('1. Unauthenticated user cannot read stock', async () => {
      const db = getTestEnv().unauthenticatedContext().firestore();

      await expectPermissionDenied(
        db.collection('stock').get()
      );
    });

    test('2. Agent cannot read stock (admin only)', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('stock').doc('stock1').get()
      );
    });

    test('3. Secretary cannot read stock (admin only)', async () => {
      const db = getTestEnv().authenticatedContext('secretary123', { role: 'secretary' }).firestore();

      await expectPermissionDenied(
        db.collection('stock').get()
      );
    });

    test('4. Admin can read stock', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      const snap = await db.collection('stock').get();
      expect(snap.size).toBeGreaterThan(0);
    });
  });

  describe('Write Access - ADMIN ONLY', () => {

    test('5. Agent cannot create stock', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('stock').doc('stock2').set({
          name: 'New Item',
          quantity: 50,
        })
      );
    });

    test('6. Agent cannot update stock', async () => {
      const db = getTestEnv().authenticatedContext('agent123', { role: 'agent' }).firestore();

      await expectPermissionDenied(
        db.collection('stock').doc('stock1').update({
          quantity: 200,
        })
      );
    });

    test('7. Admin can create stock', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('stock').doc('stock2').set({
        name: 'Rackets',
        quantity: 30,
        minQuantity: 5,
      });

      const snap = await db.collection('stock').doc('stock2').get();
      expect(snap.exists).toBe(true);
    });

    test('8. Admin can update stock quantity', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('stock').doc('stock1').update({
        quantity: 150,
      });

      const snap = await db.collection('stock').doc('stock1').get();
      expect(snap.data().quantity).toBe(150);
    });

    test('9. Admin can delete stock', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      await db.collection('stock').doc('stock1').delete();

      const snap = await db.collection('stock').doc('stock1').get();
      expect(snap.exists).toBe(false);
    });

    test('10. Stock must have required fields on create', async () => {
      const db = getTestEnv().authenticatedContext('admin123', { role: 'admin' }).firestore();

      // Should succeed - all required fields
      await db.collection('stock').doc('stock3').set({
        name: 'Valid Item',
        quantity: 100,
        minQuantity: 10,
      });

      const snap = await db.collection('stock').doc('stock3').get();
      expect(snap.exists).toBe(true);
    });
  });

});
