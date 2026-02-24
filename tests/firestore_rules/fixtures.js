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

  // NEW - TERRAINS
  terrain1: {
    id: 'terrain1',
    name: 'Court Central',
    type: 'tennis',
    hourlyRate: 50,
    createdBy: 'admin123',
    isActive: true,
  },
  terrain2: {
    id: 'terrain2',
    name: 'Court 2',
    type: 'tennis',
    hourlyRate: 40,
    createdBy: 'admin123',
    isActive: false,
  },

  // NEW - STOCK ITEMS
  stockItem1: {
    id: 'stock1',
    name: 'Tennis Balls (Box of 12)',
    quantity: 100,
    minQuantity: 20,
    lastUpdated: new Date(),
    updatedBy: 'admin123',
  },

  // NEW - MAINTENANCE
  maintenance1: {
    id: 'maint1',
    terrainId: 'terrain1',
    description: 'Net repair',
    status: 'pending',
    createdBy: 'admin123',
    createdAt: new Date(),
  },

  // NEW - AUDIT LOG
  auditLog1: {
    id: 'audit1',
    action: 'USER_CREATED',
    targetUserId: 'agent123',
    performedBy: 'admin123',
    timestamp: new Date(),
  },

  // NEW - RESERVATIONS
  reservation1: {
    id: 'res1',
    terrainId: 'terrain1',
    userId: 'agent123',
    startTime: new Date(Date.now() + 86400000), // Tomorrow
    endTime: new Date(Date.now() + 86400000 + 3600000), // +1 hour
    status: 'pending',
    createdAt: new Date(),
    createdBy: 'agent123',
  },

  reservation2: {
    id: 'res2',
    terrainId: 'terrain1',
    userId: 'other123',
    startTime: new Date(Date.now() + 86400000 + 7200000), // Tomorrow +2 hours
    endTime: new Date(Date.now() + 86400000 + 10800000), // +3 hours
    status: 'confirmed',
    createdAt: new Date(),
    createdBy: 'admin123',
  },
};

// Helper: Create test user in Firestore (using admin context passed in)
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

// Helper: Create terrain (using admin context passed in)
async function createTerrain(db, terrainData) {
  await db.collection('terrains').doc(terrainData.id).set(terrainData);
  return terrainData.id;
}

// Helper: Create stock item (using admin context passed in)
async function createStockItem(db, stockData) {
  await db.collection('stock').doc(stockData.id).set(stockData);
  return stockData.id;
}

// Helper: Create maintenance (using admin context passed in)
async function createMaintenance(db, maintData) {
  await db.collection('maintenances').doc(maintData.id).set(maintData);
  return maintData.id;
}

// Helper: Create audit log (using admin context passed in)
async function createAuditLog(db, auditData) {
  // Note: In real app, only Cloud Functions write to auditLogs
  // For testing, use admin bypass (requires admin context)
  await db.collection('auditLogs').doc(auditData.id).set(auditData);
  return auditData.id;
}

// Helper: Create reservation
async function createReservation(db, resData) {
  await db.collection('reservations').doc(resData.id).set(resData);
  return resData.id;
}

// Helper: Get future timestamp
function getFutureTime(hoursFromNow = 24) {
  return new Date(Date.now() + hoursFromNow * 3600000);
}

// Helper: Get past timestamp
function getPastTime(hoursAgo = 1) {
  return new Date(Date.now() - hoursAgo * 3600000);
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
      (error.message && (error.message.includes('PERMISSION_DENIED') || error.message.includes('Missing or insufficient permissions') || error.message.includes('false for \'list\'') || error.message.includes('false for \'get\'') || error.message.includes('false for \'update\'') || error.message.includes('false for \'create\'') || error.message.includes('false for \'delete\'')));

    if (isPermissionDenied) {
      return;
    }
    throw error;
  }
}

module.exports = {
  fixtures,
  createTestUser,
  createTerrain,
  createStockItem,
  createMaintenance,
  createAuditLog,
  createReservation,
  expectPermissionDenied,
  getFutureTime,
  getPastTime,
};
