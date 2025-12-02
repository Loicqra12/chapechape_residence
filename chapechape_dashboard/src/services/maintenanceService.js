import axios from 'axios';
import { API_URL } from '../config';

class MaintenanceService {
  /**
   * Get system status (CPU, RAM, Disk, DB, etc.)
   */
  async getSystemStatus() {
    try {
      const response = await axios.get(`${API_URL}/maintenance/status`);
      return {
        success: true,
        data: response.data.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération du statut système'
      };
    }
  }

  /**
   * Get all backups
   */
  async getBackups() {
    try {
      const response = await axios.get(`${API_URL}/maintenance/backups`);
      return {
        success: true,
        data: response.data.data,
        count: response.data.count
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des sauvegardes'
      };
    }
  }

  /**
   * Create a new backup
   */
  async createBackup(name = null) {
    try {
      const payload = name ? { name } : {};
      const response = await axios.post(`${API_URL}/maintenance/backup`, payload);
      return {
        success: true,
        data: response.data.data,
        message: response.data.message
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la création de la sauvegarde'
      };
    }
  }

  /**
   * Delete a backup
   */
  async deleteBackup(backupId) {
    try {
      const response = await axios.delete(`${API_URL}/maintenance/backup/${backupId}`);
      return {
        success: true,
        message: response.data.message
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la suppression de la sauvegarde'
      };
    }
  }

  /**
   * Restore from backup
   */
  async restoreBackup(backupId) {
    try {
      const response = await axios.post(`${API_URL}/maintenance/backup/${backupId}/restore`);
      return {
        success: true,
        data: response.data.data,
        message: response.data.message
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la restauration de la sauvegarde'
      };
    }
  }

  /**
   * Cleanup cache, logs, sessions, or temp files
   */
  async cleanup(type) {
    try {
      const response = await axios.post(`${API_URL}/maintenance/cleanup/${type}`);
      return {
        success: true,
        data: response.data.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || `Erreur lors du nettoyage ${type}`
      };
    }
  }

  /**
   * Toggle maintenance mode
   */
  async toggleMaintenanceMode(enabled) {
    try {
      const response = await axios.put(`${API_URL}/maintenance/mode`, { enabled });
      return {
        success: true,
        data: response.data.data,
        message: response.data.message
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors du changement du mode maintenance'
      };
    }
  }

  /**
   * Get maintenance mode status (public endpoint)
   */
  async getMaintenanceMode() {
    try {
      const response = await axios.get(`${API_URL}/maintenance/mode`);
      return {
        success: true,
        data: response.data.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération du mode maintenance'
      };
    }
  }
}

export const maintenanceService = new MaintenanceService();
