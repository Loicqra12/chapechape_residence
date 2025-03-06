import axios from 'axios';
import { API_URL } from '../config';

class AdminService {
  async getAdministrators() {
    try {
      const response = await axios.get(`${API_URL}/api/superadmin/administrators`);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des administrateurs'
      };
    }
  }

  async getRoles() {
    try {
      const response = await axios.get(`${API_URL}/api/superadmin/roles`);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des rôles'
      };
    }
  }

  async getPermissions() {
    try {
      const response = await axios.get(`${API_URL}/api/superadmin/permissions`);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des permissions'
      };
    }
  }

  async getLogs(filters = {}) {
    try {
      const response = await axios.get(`${API_URL}/api/superadmin/logs`, { params: filters });
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des logs'
      };
    }
  }

  // Gestion des administrateurs
  async createAdministrator(adminData) {
    try {
      const response = await axios.post(`${API_URL}/api/superadmin/administrators`, adminData);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la création de l\'administrateur'
      };
    }
  }

  async updateAdministrator(id, adminData) {
    try {
      const response = await axios.put(`${API_URL}/api/superadmin/administrators/${id}`, adminData);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la mise à jour de l\'administrateur'
      };
    }
  }

  async deleteAdministrator(id) {
    try {
      await axios.delete(`${API_URL}/api/superadmin/administrators/${id}`);
      return {
        success: true
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la suppression de l\'administrateur'
      };
    }
  }

  // Gestion des rôles
  async createRole(roleData) {
    try {
      const response = await axios.post(`${API_URL}/api/superadmin/roles`, roleData);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la création du rôle'
      };
    }
  }

  async updateRole(id, roleData) {
    try {
      const response = await axios.put(`${API_URL}/api/superadmin/roles/${id}`, roleData);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la mise à jour du rôle'
      };
    }
  }

  async deleteRole(id) {
    try {
      await axios.delete(`${API_URL}/api/superadmin/roles/${id}`);
      return {
        success: true
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la suppression du rôle'
      };
    }
  }

  // Gestion des permissions
  async createPermission(permissionData) {
    try {
      const response = await axios.post(`${API_URL}/api/superadmin/permissions`, permissionData);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la création de la permission'
      };
    }
  }

  async updatePermission(id, permissionData) {
    try {
      const response = await axios.put(`${API_URL}/api/superadmin/permissions/${id}`, permissionData);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la mise à jour de la permission'
      };
    }
  }

  async deletePermission(id) {
    try {
      await axios.delete(`${API_URL}/api/superadmin/permissions/${id}`);
      return {
        success: true
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la suppression de la permission'
      };
    }
  }
}

export const adminService = new AdminService();
