import axios from 'axios';
import { API_URL } from '../config';

class SettingsService {
  /**
   * Get all system settings
   */
  async getSettings(category = null) {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get(`${API_URL}/superadmin/settings`, {
        headers: token ? { Authorization: `Bearer ${token}` } : undefined
      });

      if (response.data.success && response.data.data) {
        // Group settings by category
        const grouped = {};
        response.data.data.forEach(setting => {
          if (!grouped[setting.category]) {
            grouped[setting.category] = {};
          }
          grouped[setting.category][setting.key] = {
            value: setting.value,
            type: setting.type,
            description: setting.description
          };
        });

        return {
          success: true,
          data: category ? { [category]: grouped[category] || {} } : grouped
        };
      }

      return {
        success: true,
        data: {}
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des paramètres'
      };
    }
  }

  /**
   * Update multiple settings at once
   */
  async updateSettings(settingsArray) {
    try {
      // Convert array to object format expected by backend
      const settingsObj = {};
      settingsArray.forEach(setting => {
        settingsObj[setting.key] = setting.value;
      });

      const token = localStorage.getItem('token');
      const response = await axios.put(
        `${API_URL}/superadmin/settings`,
        settingsObj,
        {
          headers: token ? { Authorization: `Bearer ${token}` } : undefined
        }
      );
      return {
        success: true,
        data: response.data.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la mise à jour des paramètres'
      };
    }
  }
}

export const settingsService = new SettingsService();
