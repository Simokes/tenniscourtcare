'use client'

import { useMemo } from 'react'
import { useFirestoreCollection } from '@/core/hooks/useFirestoreCollection'
import { firestoreUserRepository } from '@/data/repositories/user.repository'
import { User } from '@/domain/entities/user'
import { UserStatus } from '@/domain/enums/user-status'

export function useAdmin(): {
  users: User[]
  active: User[]
  pending: User[]
  rejected: User[]
  isLoading: boolean
  error: Error | null
} {
  const { data: users, isLoading, error } = useFirestoreCollection(
    firestoreUserRepository.subscribe
  )

  const active = useMemo(() => (users || []).filter(u => u.status === UserStatus.ACTIVE), [users])
  const pending = useMemo(() => (users || []).filter(u => u.status === UserStatus.INACTIVE), [users])
  const rejected = useMemo(() => (users || []).filter(u => u.status === UserStatus.REJECTED), [users])

  return { users, active, pending, rejected, isLoading, error }
}
