import { NextRequest, NextResponse } from 'next/server'

const AUTH_PAGES = ['/login', '/signup', '/admin-setup', '/access-denied']

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  if (
    AUTH_PAGES.some(p => pathname === p || pathname.startsWith(p + '/')) ||
    pathname.startsWith('/api/')
  ) {
    return NextResponse.next()
  }
  const session = request.cookies.get('session')?.value
  if (!session) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }
  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\..*).*)',]
}
