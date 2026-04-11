const logger = {
  firestore: (label: string, message: string): void => {
    console.log(`[Firestore] ${label}: ${message}`);
  },
  info: (label: string, message: string): void => {
    console.log(`[INFO] ${label}: ${message}`);
  },
  warn: (label: string, message: string): void => {
    console.warn(`[WARN] ${label}: ${message}`);
  },
  error: (label: string, message: string, error?: unknown): void => {
    console.error(`[ERROR] ${label}: ${message}`, error);
  },
};

export default logger;
