export const logger = {
  firestore: (label: string, message: string) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] [Firestore] ${label}: ${message}`);
  },
};
