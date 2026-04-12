'use client'
import { Permission } from '@/domain/enums/permission'
import { usePermission } from '@/core/hooks/usePermission'
import { useAuth } from '@/core/hooks/useAuth'

interface Props {
  permission: Permission
  children: React.ReactNode
  fallback?: React.ReactNode
}

export function PermissionGate({ permission, children, fallback = null }: Props) {
  const { isLoading } = useAuth()
  const can = usePermission(permission)
  if (isLoading) return null
  return can ? <>{children}</> : <>{fallback}</>
}
