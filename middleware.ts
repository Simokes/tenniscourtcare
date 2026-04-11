import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { verifyJwt } from './src/core/firebase/jwks-cache';

export async function middleware(request: NextRequest) {
  const token = request.cookies.get('session')?.value || request.headers.get('Authorization')?.split('Bearer ')[1];
  const isLoginPage = request.nextUrl.pathname.startsWith('/login');
  const isSetupPage = request.nextUrl.pathname.startsWith('/admin-setup');
  const isApiAuthRoute = request.nextUrl.pathname.startsWith('/api/auth');

  // Allow unrestricted access to the login page and setup page
  if (isLoginPage || isSetupPage || isApiAuthRoute) {
    return NextResponse.next();
  }

  if (!token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  const projectId = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID;
  if (!projectId) {
    console.error('NEXT_PUBLIC_FIREBASE_PROJECT_ID is not set.');
    return NextResponse.redirect(new URL('/login', request.url));
  }

  const decodedToken = await verifyJwt(token, projectId);

  if (!decodedToken) {
    // Invalid or expired token
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // Token is valid, proceed with checking setup status
  try {
      const setupRes = await fetch(new URL('/api/auth/setup-status', request.url));
      const setupData = await setupRes.json();

      if (!setupData.setupDone) {
          return NextResponse.redirect(new URL('/admin-setup', request.url));
      }

  } catch (err) {
      console.error('Error fetching setup status in middleware:', err);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|public).*)'],
};
