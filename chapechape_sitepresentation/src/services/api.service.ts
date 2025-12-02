// Configuration de l'API
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:4000/api';

// Types pour les requêtes
export interface ContactFormData {
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  company?: string;
  subject?: string;
  message: string;
}

export interface NewsletterData {
  email: string;
  firstName?: string;
  lastName?: string;
}

export interface Residence {
  _id: string;
  title: string;
  description: string;
  price: number;
  address: string;
  city: string;
  country: string;
  images: string[];
  amenities: string[];
  bedrooms: number;
  bathrooms: number;
  surface: number;
  type: 'apartment' | 'villa' | 'studio' | 'penthouse';
  status: 'available' | 'rented' | 'maintenance';
  isPopular?: boolean;
  rating?: number;
  reviewsCount?: number;
}

export interface ApiResponse<T = any> {
  success: boolean;
  message?: string;
  data?: T;
  error?: string;
  meta?: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

export interface SearchParams {
  page?: number;
  limit?: number;
  city?: string;
  type?: string;
  minPrice?: number;
  maxPrice?: number;
  bedrooms?: number;
}

// Classe pour gérer les appels API
class ApiService {
  private async makeRequest<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    try {
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
          ...options.headers,
        },
        ...options,
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || data.message || `HTTP error! status: ${response.status}`);
      }

      return data;
    } catch (error) {
      console.error('API Request Error:', error);
      throw error;
    }
  }

  // --- Residences ---

  // Récupérer toutes les résidences (avec pagination et filtres)
  async getResidences(params: SearchParams = {}): Promise<ApiResponse<Residence[]>> {
    const queryParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        queryParams.append(key, value.toString());
      }
    });

    return this.makeRequest<Residence[]>(`/residences?${queryParams.toString()}`);
  }

  // Rechercher des résidences
  async searchResidences(params: SearchParams = {}): Promise<ApiResponse<Residence[]>> {
    const queryParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        queryParams.append(key, value.toString());
      }
    });

    return this.makeRequest<Residence[]>(`/residences/search?${queryParams.toString()}`);
  }

  // Récupérer une résidence par son ID
  async getResidenceById(id: string): Promise<ApiResponse<Residence>> {
    return this.makeRequest<Residence>(`/residences/${id}`);
  }

  // Récupérer les résidences populaires
  async getPopularResidences(): Promise<ApiResponse<Residence[]>> {
    return this.makeRequest<Residence[]>('/residences/popular');
  }

  // --- Website / Contact ---

  // Soumettre le formulaire de contact
  async submitContactForm(formData: ContactFormData): Promise<ApiResponse> {
    return this.makeRequest('/website/contact', {
      method: 'POST',
      body: JSON.stringify(formData),
    });
  }

  // S'inscrire à la newsletter
  async subscribeNewsletter(newsletterData: NewsletterData): Promise<ApiResponse> {
    return this.makeRequest('/website/newsletter', {
      method: 'POST',
      body: JSON.stringify(newsletterData),
    });
  }

  // Récupérer les statistiques du site (pour admin)
  async getWebsiteStats(token: string): Promise<ApiResponse> {
    return this.makeRequest('/website/stats', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    });
  }
}

// Instance singleton du service API
export const apiService = new ApiService();

// Utilitaires pour la gestion des erreurs
export const getErrorMessage = (error: any): string => {
  if (error?.message) {
    return error.message;
  }
  if (typeof error === 'string') {
    return error;
  }
  return 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
};

// Validation côté client
export const validateEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

export const validatePhone = (phone: string): boolean => {
  const phoneRegex = /^[+]?[0-9\s-()]+$/;
  return phoneRegex.test(phone);
};

export const validateContactForm = (data: ContactFormData): string[] => {
  const errors: string[] = [];

  if (!data.firstName.trim()) {
    errors.push('Le prénom est requis');
  }
  if (!data.lastName.trim()) {
    errors.push('Le nom est requis');
  }
  if (!data.email.trim()) {
    errors.push('L\'email est requis');
  } else if (!validateEmail(data.email)) {
    errors.push('Format d\'email invalide');
  }
  if (!data.message.trim()) {
    errors.push('Le message est requis');
  } else if (data.message.trim().length < 10) {
    errors.push('Le message doit contenir au moins 10 caractères');
  }
  if (data.phone && !validatePhone(data.phone)) {
    errors.push('Format de téléphone invalide');
  }

  return errors;
};

export const validateNewsletterForm = (data: NewsletterData): string[] => {
  const errors: string[] = [];

  if (!data.email.trim()) {
    errors.push('L\'email est requis');
  } else if (!validateEmail(data.email)) {
    errors.push('Format d\'email invalide');
  }

  return errors;
};
