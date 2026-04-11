// Used by proxy.ts for JWT verification
// jose createRemoteJWKSet handles cache and TTL automatically
import { createRemoteJWKSet } from "jose";

const FIREBASE_JWKS_URL = new URL(
  "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"
);

// Pass getJwks directly to jwtVerify() — do NOT await it
export const getJwks = createRemoteJWKSet(FIREBASE_JWKS_URL);
