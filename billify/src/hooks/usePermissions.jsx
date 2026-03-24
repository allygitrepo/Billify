import { useMemo } from 'react';
import { useAuth } from './useAuth';
import { useDataContext } from './useDataContext';

export const usePermissions = () => {
  const { user } = useAuth();
  const { roles } = useDataContext();

  const permissions = useMemo(() => {
    if (!user) return null;
    if (user.role === 'Admin') return 'all';

    const userRole = roles.find(r => r.name === user.role);
    return userRole ? userRole.permissions : {};
  }, [user, roles]);

  const hasPermission = (module, action = 'view') => {
    if (!user) return false;
    if (permissions === 'all') return true;
    
    return !!(permissions?.[module]?.[action]);
  };

  const canView = (module) => {
    if (!user) return false;
    if (permissions === 'all') return true;
    
    // Check if any action is allowed for this module, or if 'view' is specifically allowed
    const modulePerms = permissions?.[module];
    if (!modulePerms) return false;
    
    return Object.values(modulePerms).some(val => val === true);
  };

  return { permissions, hasPermission, canView, role: user?.role };
};
