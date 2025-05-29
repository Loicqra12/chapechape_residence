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
    return userStr ? JSON.parse(userStr) : null;
  } catch (error) {
    logout();
    return null;
  }
};

export const isAuthenticated = () => {
  const token = localStorage.getItem('token');
  const user = getCurrentUser();
  
  if (!token || !user) return false;
  
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
  const user = getCurrentUser();
  if (!user) return false;
  
  // Normalisation des rôles pour la comparaison
  const userRole = user.role.toLowerCase();
  const requiredRoleNormalized = requiredRole.toLowerCase().replace('_', '');
  
  return userRole === requiredRoleNormalized;
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
