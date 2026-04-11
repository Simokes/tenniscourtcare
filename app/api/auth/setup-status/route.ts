import { NextResponse } from 'next/server';
import { adminDb } from '@/core/firebase/admin';

export async function GET() {
  try {
    const adminSnapshot = await adminDb
      .collection('users')
      .where('role', '==', 'admin')
      .limit(1)
      .get();

    return NextResponse.json({ setupDone: !adminSnapshot.empty });
  } catch (error) {
    console.error('Error checking setup status:', error);
    return NextResponse.json(
      { error: 'Internal server error', setupDone: false },
      { status: 500 }
    );
  }
}
