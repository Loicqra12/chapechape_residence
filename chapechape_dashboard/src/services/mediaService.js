import axios from 'axios';
import { API_URL } from '../config';

export const mediaService = {
  // Upload une ou plusieurs images
  upload: async (files) => {
    const formData = new FormData();
    files.forEach((file) => {
      formData.append('files', file);
    });

    try {
      const response = await axios.post(`${API_URL}/media/upload`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      return response.data;
    } catch (error) {
      throw new Error(error.response?.data?.message || 'Erreur lors de l\'upload');
    }
  },

  // Récupérer la liste des médias
  getAll: async () => {
    try {
      const response = await axios.get(`${API_URL}/media`);
      return response.data;
    } catch (error) {
      throw new Error(error.response?.data?.message || 'Erreur lors de la récupération des médias');
    }
  },

  // Supprimer un média
  delete: async (id) => {
    try {
      await axios.delete(`${API_URL}/media/${id}`);
    } catch (error) {
      throw new Error(error.response?.data?.message || 'Erreur lors de la suppression');
    }
  },

  // Mettre à jour les informations d'un média
  update: async (id, data) => {
    try {
      const response = await axios.put(`${API_URL}/media/${id}`, data);
      return response.data;
    } catch (error) {
      throw new Error(error.response?.data?.message || 'Erreur lors de la mise à jour');
    }
  }
};

export default mediaService;
