import React, { createContext, useContext, useState, useEffect } from 'react';
import { getCurrentUser, isAuthenticated } from '../services/auth';

const AuthContext = createContext(null);

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const initAuth = () => {
      if (isAuthenticated()) {
        setUser(getCurrentUser());
      }
      setLoading(false);
    };

    initAuth();
  }, []);

  const checkPermission = (permission) => {
    if (!user) return false;
    return user.permissions?.includes(permission) || user.role === 'superadmin';
  };

  const isSuperAdmin = () => user?.role === 'superadmin';
  const isAdmin = () => user?.role === 'admin' || user?.role === 'superadmin';

  const value = {
    user,
    setUser,
    loading,
    checkPermission,
    isSuperAdmin,
    isAdmin
  };

  if (loading) {
    return <div>Chargement...</div>;
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
