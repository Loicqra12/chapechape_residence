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

  // === GESTION DES CLIENTS ===
  async getAllClients() {
    try {
      const response = await axios.get(`${API_URL}/admin/users`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des clients'
      };
    }
  }

  async getClientById(id) {
    try {
      const response = await axios.get(`${API_URL}/admin/users/${id}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération du client'
      };
    }
  }

  async updateClient(id, clientData) {
    try {
      const response = await axios.put(`${API_URL}/admin/users/${id}`, clientData, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la mise à jour du client'
      };
    }
  }

  async deleteClient(id) {
    try {
      const response = await axios.delete(`${API_URL}/admin/users/${id}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la suppression du client'
      };
    }
  }

  // === GESTION DES PARTENAIRES ===
  async getAllPartners() {
    try {
      const response = await axios.get(`${API_URL}/admin/partners`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des partenaires'
      };
    }
  }

  async getPartnerById(id) {
    try {
      const response = await axios.get(`${API_URL}/admin/partners/${id}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération du partenaire'
      };
    }
  }

  async updatePartner(id, partnerData) {
    try {
      const response = await axios.put(`${API_URL}/admin/partners/${id}`, partnerData, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la mise à jour du partenaire'
      };
    }
  }

  async deletePartner(id) {
    try {
      const response = await axios.delete(`${API_URL}/admin/partners/${id}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la suppression du partenaire'
      };
    }
  }

  async verifyPartner(id) {
    try {
      const response = await axios.put(`${API_URL}/admin/partners/${id}/verify`, {}, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la vérification du partenaire'
      };
    }
  }

  // === MÉTHODES UTILITAIRES POUR LES UTILISATEURS ===
  async getUsersStats() {
    try {
      const [clientsResponse, partnersResponse] = await Promise.all([
        this.getAllClients(),
        this.getAllPartners()
      ]);
      
      if (clientsResponse.success && partnersResponse.success) {
        const clients = clientsResponse.data;
        const partners = partnersResponse.data;
        
        return {
          success: true,
          data: {
            totalClients: clients.length,
            totalPartners: partners.length,
            verifiedClients: clients.filter(c => c.isVerified || c.verified).length,
            verifiedPartners: partners.filter(p => p.verificationStatus === 'verified' || p.verified).length,
            activeClients: clients.filter(c => c.status === 'active').length,
            activePartners: partners.filter(p => p.status === 'active').length
          }
        };
      }
      
      return {
        success: false,
        error: 'Erreur lors du calcul des statistiques utilisateurs'
      };
    } catch (error) {
      return {
        success: false,
        error: error.message || 'Erreur lors du calcul des statistiques utilisateurs'
      };
    }
  }

  // === GESTION DES RÉSIDENCES/PROPERTIES ===
  async getAllProperties(queryParams = {}) {
    try {
      const params = new URLSearchParams(queryParams).toString();
      const response = await axios.get(`${API_URL}/admin/residences${params ? `?${params}` : ''}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      return {
        success: true,
        data: response.data.data || response.data,
        pagination: response.data.pagination
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des propriétés'
      };
    }
  }

  async getPropertyById(id) {
    try {
      const response = await axios.get(`${API_URL}/admin/residences/${id}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération de la propriété'
      };
    }
  }

  async updateProperty(id, propertyData) {
    try {
      const response = await axios.put(`${API_URL}/admin/residences/${id}`, propertyData, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la mise à jour de la propriété'
      };
    }
  }

  async deleteProperty(id) {
    try {
      const response = await axios.delete(`${API_URL}/admin/residences/${id}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la suppression de la propriété'
      };
    }
  }

  async validateProperty(id) {
    try {
      const response = await axios.put(`${API_URL}/admin/residences/${id}/validate`, {}, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la validation de la propriété'
      };
    }
  }

  async rejectProperty(id, reason) {
    try {
      const response = await axios.put(`${API_URL}/admin/residences/${id}/reject`, { reason }, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors du rejet de la propriété'
      };
    }
  }

  async verifyProperty(id) {
    try {
      const response = await axios.put(`${API_URL}/admin/residences/${id}/verify`, {}, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la vérification de la propriété'
      };
    }
  }

  async getPendingProperties() {
    try {
      const response = await axios.get(`${API_URL}/admin/residences/pending`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      return {
        success: true,
        data: response.data.data || response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des propriétés en attente'
      };
    }
  }

  // === MÉTHODES UTILITAIRES POUR LES PROPERTIES ===
  async getPropertiesStats() {
    try {
      const response = await this.getAllProperties();
      
      if (response.success) {
        const properties = response.data;
        
        return {
          success: true,
          data: {
            totalProperties: properties.length,
            availableProperties: properties.filter(p => p.status === 'available').length,
            pendingProperties: properties.filter(p => p.status === 'pending').length,
            verifiedProperties: properties.filter(p => p.status === 'verified').length,
            rejectedProperties: properties.filter(p => p.status === 'rejected').length
          }
        };
      }
      
      return {
        success: false,
        error: 'Erreur lors du calcul des statistiques des propriétés'
      };
    } catch (error) {
      return {
        success: false,
        error: error.message || 'Erreur lors du calcul des statistiques des propriétés'
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

  // ===== GESTION DES AMENITIES =====
  
  async getAllAmenities() {
    try {
      const response = await this.makeRequest('/admin/amenities', {
        method: 'GET'
      });
      return response;
    } catch (error) {
      console.error('Erreur lors de la récupération des amenities:', error);
      throw error;
    }
  }

  async getAmenityById(amenityId) {
    try {
      const response = await this.makeRequest(`/admin/amenities/${amenityId}`, {
        method: 'GET'
      });
      return response;
    } catch (error) {
      console.error(`Erreur lors de la récupération de l'amenity ${amenityId}:`, error);
      throw error;
    }
  }

  async createAmenity(amenityData) {
    try {
      const response = await this.makeRequest('/admin/amenities', {
        method: 'POST',
        body: JSON.stringify(amenityData)
      });
      return response;
    } catch (error) {
      console.error('Erreur lors de la création de l\'amenity:', error);
      throw error;
    }
  }

  async updateAmenity(amenityId, amenityData) {
    try {
      const response = await this.makeRequest(`/admin/amenities/${amenityId}`, {
        method: 'PUT',
        body: JSON.stringify(amenityData)
      });
      return response;
    } catch (error) {
      console.error(`Erreur lors de la mise à jour de l'amenity ${amenityId}:`, error);
      throw error;
    }
  }

  async deleteAmenity(amenityId) {
    try {
      const response = await this.makeRequest(`/admin/amenities/${amenityId}`, {
        method: 'DELETE'
      });
      return response;
    } catch (error) {
      console.error(`Erreur lors de la suppression de l'amenity ${amenityId}:`, error);
      throw error;
    }
  }

  async getAmenitiesStats() {
    try {
      const response = await this.makeRequest('/admin/amenities/stats', {
        method: 'GET'
      });
      return response;
    } catch (error) {
      console.error('Erreur lors de la récupération des stats amenities:', error);
      throw error;
    }
  }

  // ===== GESTION DES PROPERTY TYPES =====
  
  async getAllPropertyTypes() {
    try {
      const response = await this.makeRequest('/admin/property-types', {
        method: 'GET'
      });
      return response;
    } catch (error) {
      console.error('Erreur lors de la récupération des types de propriétés:', error);
      throw error;
    }
  }

  async createPropertyType(typeData) {
    try {
      const response = await this.makeRequest('/admin/property-types', {
        method: 'POST',
        body: JSON.stringify(typeData)
      });
      return response;
    } catch (error) {
      console.error('Erreur lors de la création du type de propriété:', error);
      throw error;
    }
  }

  async updatePropertyType(typeId, typeData) {
    try {
      const response = await this.makeRequest(`/admin/property-types/${typeId}`, {
        method: 'PUT',
        body: JSON.stringify(typeData)
      });
      return response;
    } catch (error) {
      console.error(`Erreur lors de la mise à jour du type ${typeId}:`, error);
      throw error;
    }
  }

  async deletePropertyType(typeId) {
    try {
      const response = await this.makeRequest(`/admin/property-types/${typeId}`, {
        method: 'DELETE'
      });
      return response;
    } catch (error) {
      console.error(`Erreur lors de la suppression du type ${typeId}:`, error);
      throw error;
    }
  }
}

export const adminService = new AdminService();
