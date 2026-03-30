import axios from 'axios';
import { jwtDecode } from 'jwt-decode';
import { API_URL } from '../config';

// Configuration d'Axios avec l'URL de base
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Intercepteur pour ajouter le token aux requêtes
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

export const login = async (email, password) => {
  try {
    const response = await api.post('/auth/login', {
      email,
      password,
    });

    const { token, user } = response.data;
    
    // Vérification des rôles en ignorant la casse
    const role = user.role.toLowerCase();
    if (token && (role === 'admin' || role === 'superadmin')) {
      localStorage.setItem('token', token);
      localStorage.setItem('user', JSON.stringify(user));
      return user;
    } else {
      throw new Error('Accès non autorisé. Seuls les administrateurs peuvent se connecter.');
    }
  } catch (error) {
    if (error.response?.data?.message) {
      throw new Error(error.response.data.message);
    } else if (error.message) {
      throw new Error(error.message);
    } else {
      throw new Error('Erreur lors de la connexion');
    }
  }
};

export const logout = () => {
  localStorage.removeItem('token');
  localStorage.removeItem('user');
  localStorage.removeItem('remember_email');
};

export const getCurrentUser = () => {
  try {
    const userStr = localStorage.getItem('user');
    const token = localStorage.getItem('token');
    const decoded = token ? (() => { try { return jwtDecode(token); } catch { return null; } })() : null;

    if (!userStr) {
      // Si user en localStorage est absent, on reconstruit minimalement à partir du JWT.
      if (decoded?.role) {
        return { id: decoded.id, role: decoded.role, permissions: [] };
      }
      return null;
    }

    const parsed = JSON.parse(userStr);
    // Synchroniser le rôle avec le JWT (localStorage peut être stale).
    if (decoded?.role && parsed?.role && parsed.role !== decoded.role) {
      parsed.role = decoded.role;
      localStorage.setItem('user', JSON.stringify(parsed));
    }
    return parsed;
  } catch (error) {
    logout();
    return null;
  }
};

export const isAuthenticated = () => {
  const token = localStorage.getItem('token');
  if (!token) return false;
  
  try {
    const decoded = jwtDecode(token);
    const isValid = decoded.exp * 1000 > Date.now();
    
    if (!isValid) {
      logout();
      return false;
    }
    
    return true;
  } catch (error) {
    logout();
    return false;
  }
};

export const hasRole = (requiredRole) => {
  const token = localStorage.getItem('token');
  if (!token) return false;

  try {
    const decoded = jwtDecode(token);
    const userRole = decoded?.role;
    if (!userRole) return false;

    const userRoleNormalized = String(userRole).toLowerCase().replace('_', '');
    const requiredRoleNormalized = requiredRole.toLowerCase().replace('_', '');

    return userRoleNormalized === requiredRoleNormalized;
  } catch {
    return false;
  }
};

export const isAdmin = () => hasRole('admin');
export const isSuperAdmin = () => hasRole('superadmin');

export const forgotPassword = async (email) => {
  try {
    const response = await api.post('/auth/forgot-password', { email });
    return response.data;
  } catch (error) {
    throw new Error(error.response?.data?.message || 'Erreur lors de la réinitialisation du mot de passe');
  }
};

export const resetPassword = async (resetToken, newPassword) => {
  try {
    const response = await api.put(`/auth/reset-password/${resetToken}`, {
      password: newPassword
    });
    return response.data;
  } catch (error) {
    throw new Error(error.response?.data?.message || 'Erreur lors de la réinitialisation du mot de passe');
  }
};
