'use client'
import { useEffect } from 'react'
import { useRouter, usePathname } from 'next/navigation'
import { useAuthListener, useAuth } from '@/core/hooks/useAuth'

const AUTH_PAGES = ['/login', '/signup', '/admin-setup', '/access-denied']

export function AuthProvider({ children }: { children: React.ReactNode }) {
  useAuthListener()
  const { user, isLoading, isSetupRequired } = useAuth()
  const router = useRouter()
  const pathname = usePathname()

  useEffect(() => {
    if (isLoading) return
    const isAuthPage = AUTH_PAGES.some(
      p => pathname === p || pathname.startsWith(p + '/')
    )
    if (isSetupRequired && !pathname.startsWith('/admin-setup')) {
      router.replace('/admin-setup')
      return
    }
    if (user && isAuthPage) {
      router.replace('/')
    }
  }, [user, isLoading, isSetupRequired, pathname, router])

  return <>{children}</>
}
