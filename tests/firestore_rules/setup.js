const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

let testEnv;

beforeAll(async () => {
  // Load Firestore rules from file (relative to this test file)
  const rules = fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8');

  // Initialize emulator
  testEnv = await initializeTestEnvironment({
    projectId: 'test-project',
    firestore: {
      host: 'localhost',
      port: 8080,
      rules: rules,
    },
  });

  console.log('✅ Firestore emulator initialized');
});

afterAll(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
  console.log('✅ Cleanup complete');
});

// Export a getter
module.exports = {
  getTestEnv: () => testEnv
};
