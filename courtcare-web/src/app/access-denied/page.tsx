'use client'
import { useRouter } from 'next/navigation'

export default function AccessDeniedPage() {
  const router = useRouter()
  return (
    <div className="min-h-screen flex flex-col items-center justify-center gap-4 bg-zinc-50 dark:bg-zinc-950 p-4">
      <div className="text-6xl">🚫</div>
      <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-100">Acces refuse</h1>
      <p className="text-zinc-500 text-center max-w-sm">
        Vous n&apos;avez pas les permissions necessaires pour acceder a cette page.
      </p>
      <button
        onClick={() => router.push('/')}
        className="mt-4 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white px-6 py-2 font-semibold transition-colors"
      >
        Retour a l&apos;accueil
      </button>
    </div>
  )
}
