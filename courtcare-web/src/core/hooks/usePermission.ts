import { useMemo } from 'react';
import { Permission } from '@/domain/enums/permission';
import { hasPermission } from '@/domain/logic/permission-resolver';
import { useAuthStore } from '@/core/stores/auth.store';

export function usePermission(permission: Permission): boolean {
  const role = useAuthStore((state) => state.role);

  return useMemo(() => {
    if (!role) {
      return false;
    }
    return hasPermission(role, permission);
  }, [role, permission]);
}

export function useHasAnyPermission(permissions: Permission[]): boolean {
  const role = useAuthStore((state) => state.role);

  return useMemo(() => {
    if (!role) {
      return false;
    }
    return permissions.some((p) => hasPermission(role, p));
  }, [role, permissions]);
}
