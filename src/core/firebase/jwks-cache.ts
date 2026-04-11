import * as jose from 'jose';
import { JwtPayload } from '../types';

interface JwksCache {
  keys: any;
  expiresAt: number;
}

let jwksCache: JwksCache | null = null;
const JWKS_URL = 'https://www.googleapis.com/robot/v1/metadata/jwks/securetoken@system.gserviceaccount.com';
const CACHE_TTL_MS = 3600 * 1000; // 1 hour

export async function getJwks() {
  if (jwksCache && Date.now() < jwksCache.expiresAt) {
    return jwksCache.keys;
  }

  try {
    const response = await fetch(JWKS_URL);
    if (!response.ok) {
      throw new Error(`Failed to fetch JWKS: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    jwksCache = {
      keys: jose.createRemoteJWKSet(new URL(JWKS_URL)), // Return JWKS function compatible with jose
      expiresAt: Date.now() + CACHE_TTL_MS,
    };

    return jwksCache.keys;
  } catch (error) {
    console.error('Error fetching JWKS:', error);
    throw error;
  }
}

export async function verifyJwt(token: string, projectId: string): Promise<JwtPayload | null> {
  try {
    const jwks = await getJwks();
    const { payload } = await jose.jwtVerify(token, jwks, {
      issuer: `https://securetoken.google.com/${projectId}`,
      audience: projectId,
    });
    return payload as JwtPayload;
  } catch (error) {
    console.error('JWT verification failed:', error);
    return null;
  }
}
