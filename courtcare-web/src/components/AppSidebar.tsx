'use client'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { signOut } from 'firebase/auth'
import { auth } from '@/core/firebase/client'
import { useAuthStore } from '@/core/stores/auth.store'
import { usePermission } from '@/core/hooks/usePermission'
import { Permission } from '@/domain/enums/permission'

const NAV_ITEMS = [
  { href: '/', label: 'Dashboard' },
  { href: '/terrain', label: 'Terrains' },
  { href: '/maintenance', label: 'Maintenance' },
  { href: '/stock', label: 'Inventaire' },
  { href: '/calendar', label: 'Calendrier' },
  { href: '/stats', label: 'Statistiques' },
  { href: '/settings', label: 'Parametres' },
]

export function AppSidebar() {
  const pathname = usePathname()
  const router = useRouter()
  const canManageUsers = usePermission(Permission.CAN_MANAGE_USERS)

  const handleSignOut = async () => {
    await fetch('/api/auth/session', { method: 'DELETE' })
    await signOut(auth)
    useAuthStore.getState().reset()
    router.push('/login')
  }

  return (
    <aside className="w-64 flex flex-col h-full bg-white dark:bg-zinc-900 border-r border-zinc-200 dark:border-zinc-800">
      <div className="px-6 py-5 border-b border-zinc-200 dark:border-zinc-800">
        <span className="text-xl font-bold text-emerald-600 dark:text-emerald-400">🎾 CourtCare</span>
      </div>
      <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-1">
        {NAV_ITEMS.map(item => (
          <Link
            key={item.href}
            href={item.href}
            className={`block rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
              pathname === item.href
                ? 'bg-emerald-50 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300'
                : 'text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800'
            }`}
          >
            {item.label}
          </Link>
        ))}
        {canManageUsers && (
          <Link
            href="/admin"
            className={`block rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
              pathname === '/admin' || pathname.startsWith('/admin/')
                ? 'bg-emerald-50 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300'
                : 'text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800'
            }`}
          >
            Administration
          </Link>
        )}
      </nav>
      <div className="px-3 py-4 border-t border-zinc-200 dark:border-zinc-800">
        <button
          onClick={handleSignOut}
          className="w-full rounded-lg px-3 py-2 text-sm font-medium text-zinc-600 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800 text-left transition-colors"
        >
          Se deconnecter
        </button>
      </div>
    </aside>
  )
}
