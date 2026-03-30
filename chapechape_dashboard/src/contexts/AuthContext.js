import React, { createContext, useContext, useState, useEffect } from 'react';
import { getCurrentUser, isAuthenticated, hasRole } from '../services/auth';

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
    return user.permissions?.includes(permission) || hasRole('superadmin');
  };

  // On s'appuie sur le JWT pour éviter les incohérences localStorage (role stale).
  const isSuperAdmin = () => hasRole('superadmin');
  const isAdmin = () => hasRole('admin') || hasRole('superadmin');

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
