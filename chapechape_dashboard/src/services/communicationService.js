import axios from 'axios';
import { API_URL } from '../config';

class CommunicationService {
  // Notifications
  async getNotifications(page = 1, limit = 10) {
    try {
      const response = await axios.get(`${API_URL}/notifications`, {
        params: { page, limit }
      });
      return {
        success: true,
        data: response.data.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des notifications'
      };
    }
  }

  async markNotificationAsRead(notificationId) {
    try {
      const response = await axios.put(`${API_URL}/notifications/${notificationId}/read`);
      return {
        success: true,
        data: response.data.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors du marquage de la notification'
      };
    }
  }

  async markAllNotificationsAsRead() {
    try {
      const response = await axios.put(`${API_URL}/notifications/read-all`);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors du marquage des notifications'
      };
    }
  }

  async deleteNotification(notificationId) {
    try {
      const response = await axios.delete(`${API_URL}/notifications/${notificationId}`);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la suppression de la notification'
      };
    }
  }

  async deleteReadNotifications() {
    try {
      const response = await axios.delete(`${API_URL}/notifications/read`);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la suppression des notifications'
      };
    }
  }

  // Messages
  async getMessages(page = 1, limit = 10, folder = 'inbox') {
    try {
      const response = await axios.get(`${API_URL}/messages`, {
        params: { page, limit, folder }
      });
      return {
        success: true,
        data: response.data.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des messages'
      };
    }
  }

  async sendMessage(messageData) {
    try {
      const formData = new FormData();
      
      // Ajouter les données du message
      formData.append('to', JSON.stringify(messageData.to));
      formData.append('subject', messageData.subject);
      formData.append('content', messageData.content);
      formData.append('priority', messageData.priority);

      // Ajouter les pièces jointes
      if (messageData.attachments?.length > 0) {
        messageData.attachments.forEach(file => {
          formData.append('attachments', file);
        });
      }

      const response = await axios.post(`${API_URL}/messages`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });

      return {
        success: true,
        data: response.data.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de l\'envoi du message'
      };
    }
  }

  async deleteMessage(messageId) {
    try {
      const response = await axios.delete(`${API_URL}/messages/${messageId}`);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la suppression du message'
      };
    }
  }

  async toggleMessageStar(messageId) {
    try {
      const response = await axios.put(`${API_URL}/messages/${messageId}/star`);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la modification du message'
      };
    }
  }

  // Support Tickets
  async getSupportTickets(page = 1, limit = 10, filters = {}) {
    try {
      const response = await axios.get(`${API_URL}/support/tickets`, {
        params: { page, limit, ...filters }
      });
      return {
        success: true,
        data: response.data.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des tickets'
      };
    }
  }

  async createSupportTicket(ticketData) {
    try {
      const formData = new FormData();
      
      // Ajouter les données du ticket
      formData.append('subject', ticketData.subject);
      formData.append('category', ticketData.category);
      formData.append('priority', ticketData.priority);
      formData.append('description', ticketData.description);

      // Ajouter les pièces jointes
      if (ticketData.attachments?.length > 0) {
        ticketData.attachments.forEach(file => {
          formData.append('attachments', file);
        });
      }

      const response = await axios.post(`${API_URL}/support/tickets`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });

      return {
        success: true,
        data: response.data.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la création du ticket'
      };
    }
  }

  async replyToTicket(ticketId, message) {
    try {
      const response = await axios.post(`${API_URL}/support/tickets/${ticketId}/reply`, {
        message
      });
      return {
        success: true,
        data: response.data.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de l\'envoi de la réponse'
      };
    }
  }

  async closeTicket(ticketId) {
    try {
      const response = await axios.put(`${API_URL}/support/tickets/${ticketId}/close`);
      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la fermeture du ticket'
      };
    }
  }
}

export const communicationService = new CommunicationService();
