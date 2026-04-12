import { NextRequest, NextResponse } from 'next/server'
import { adminAuth, adminDb } from '@/core/firebase/admin'
import { FieldValue } from 'firebase-admin/firestore'

export async function POST(req: NextRequest) {
  const { name, email, password, role } = await req.json()
  try {
    const fbUser = await adminAuth.createUser({ email, password, displayName: name })
    const ref = await adminDb.collection('users').add({
      name, email, role,
      status: 'inactive',
      firestoreUid: fbUser.uid,
      firebaseId: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      lastLoginAt: null,
      avatarUrl: null,
      approvedAt: null,
      approvedBy: null,
      createdBy: null,
      modifiedBy: null,
    })
    await ref.update({ firebaseId: ref.id })
    return NextResponse.json({ ok: true })
  } catch (e: unknown) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : 'Erreur inattendue' },
      { status: 400 }
    )
  }
}
