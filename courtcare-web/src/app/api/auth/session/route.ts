import { NextRequest, NextResponse } from 'next/server'
import { adminAuth } from '@/core/firebase/admin'

export async function POST(req: NextRequest) {
  const { idToken } = await req.json()
  try {
    await adminAuth.verifyIdToken(idToken)
    const res = NextResponse.json({ ok: true })
    res.cookies.set('session', idToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
      maxAge: 60 * 60 * 24 * 7,
    })
    return res
  } catch {
    return NextResponse.json({ error: 'invalid_token' }, { status: 401 })
  }
}

export async function DELETE() {
  const res = NextResponse.json({ ok: true })
  res.cookies.delete('session')
  return res
}
