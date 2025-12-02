import axios from 'axios';
import { API_URL } from '../config';

class MarketingService {
  async getPromotions() {
    try {
      // TODO: Implémenter l'endpoint dans le backend
      const mockPromotions = [
        {
          id: '1',
          title: 'Été 2025',
          description: 'Réduction de 20% sur les villas avec piscine',
          startDate: '2025-06-01',
          endDate: '2025-08-31',
          discountType: 'percentage',
          discountValue: 20,
          status: 'active',
          residenceTypes: ['vacation'],
          conditions: ['pool'],
          minimumStay: 7
        },
        {
          id: '2',
          title: 'Week-end en ville',
          description: 'Offre spéciale sur les appartements',
          startDate: '2025-04-01',
          endDate: '2025-05-31',
          discountType: 'fixed',
          discountValue: 100,
          status: 'scheduled',
          residenceTypes: ['standard'],
          conditions: [],
          minimumStay: 2
        }
      ];

      return {
        success: true,
        data: mockPromotions
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des promotions'
      };
    }
  }

  async getCampaigns() {
    try {
      // TODO: Implémenter l'endpoint dans le backend
      const mockCampaigns = [
        {
          id: '1',
          name: 'Campagne Été 2025',
          type: 'email',
          status: 'active',
          startDate: '2025-06-01',
          endDate: '2025-08-31',
          audience: {
            total: 5000,
            filters: ['previous_guests', 'newsletter_subscribers']
          },
          metrics: {
            sent: 4800,
            opened: 2400,
            clicked: 800,
            converted: 120
          }
        },
        {
          id: '2',
          name: 'Réseaux Sociaux - Printemps',
          type: 'social',
          status: 'scheduled',
          startDate: '2025-04-01',
          endDate: '2025-05-31',
          platforms: ['instagram', 'facebook'],
          budget: 5000,
          metrics: {
            impressions: 50000,
            engagement: 2500,
            clicks: 1000,
            conversions: 50
          }
        }
      ];

      return {
        success: true,
        data: mockCampaigns
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des campagnes'
      };
    }
  }

  async getReviews() {
    try {
      const response = await axios.get(`${API_URL}/reviews`);
      // Le backend retourne déjà { success: true, data: [...], pagination: {...} }
      return response.data;
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des avis'
      };
    }
  }
}

export const marketingService = new MarketingService();
