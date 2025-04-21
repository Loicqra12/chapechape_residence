import axios from 'axios';

/**
 * Service API sécurisé avec gestion des tokens CSRF
 * Ce service assure que toutes les requêtes vers les endpoints CSRF protégés
 * envoient le token CSRF approprié dans les headers
 */
class ApiService {
    constructor() {
        // Création de l'instance axios
        this.client = axios.create({
            baseURL: process.env.REACT_APP_API_URL || 'http://localhost:4000/api',
            withCredentials: true, // Permet l'envoi de cookies cross-origin
            timeout: 30000 // Timeout de 30 secondes
        });

        // Stockage du token CSRF
        this.csrfToken = null;

        // Intercepteurs
        this._setupInterceptors();
    }

    /**
     * Configure les intercepteurs axios pour la gestion des tokens
     * @private
     */
    _setupInterceptors() {
        // Intercepteur de requête
        this.client.interceptors.request.use(
            async (config) => {
                // Ajouter le token d'authentification
                const token = localStorage.getItem('auth_token');
                if (token) {
                    config.headers['Authorization'] = `Bearer ${token}`;
                }

                // Ajouter le token CSRF pour les méthodes mutatives
                if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(config.method.toUpperCase())) {
                    // Si on n'a pas de token CSRF ou s'il est expiré, en demander un nouveau
                    if (!this.csrfToken) {
                        await this._fetchCsrfToken();
                    }
                    
                    // Ajouter le token aux headers
                    if (this.csrfToken) {
                        config.headers['X-CSRF-Token'] = this.csrfToken;
                    }
                }

                return config;
            },
            (error) => Promise.reject(error)
        );

        // Intercepteur de réponse
        this.client.interceptors.response.use(
            (response) => {
                // Vérifier si on reçoit un nouveau token CSRF
                const newCsrfToken = response.headers['x-csrf-token'];
                if (newCsrfToken) {
                    this.csrfToken = newCsrfToken;
                }
                return response;
            },
            (error) => {
                // Gérer les erreurs CSRF spécifiquement
                if (error.response && error.response.status === 403 && 
                    error.response.data.errorCode === 'GENERAL_CSRF_ERROR') {
                    // Récupérer un nouveau token et réessayer
                    return this._fetchCsrfToken()
                        .then(() => {
                            // Réessayer la requête originale
                            const originalRequest = error.config;
                            originalRequest.headers['X-CSRF-Token'] = this.csrfToken;
                            return this.client(originalRequest);
                        });
                }
                return Promise.reject(error);
            }
        );
    }

    /**
     * Récupère un token CSRF frais depuis le serveur
     * @private
     */
    async _fetchCsrfToken() {
        try {
            const response = await axios.get(
                `${process.env.REACT_APP_API_URL || 'http://localhost:4000/api'}/csrf-token`, 
                { withCredentials: true }
            );
            this.csrfToken = response.data.csrfToken;
            return this.csrfToken;
        } catch (error) {
            console.error('Erreur lors de la récupération du token CSRF:', error);
            return null;
        }
    }

    /**
     * Effectue une requête GET
     * @param {string} url - URL relative de l'endpoint
     * @param {Object} params - Paramètres de requête
     * @returns {Promise} - Promesse avec les données de réponse
     */
    async get(url, params = {}) {
        try {
            const response = await this.client.get(url, { params });
            return response.data;
        } catch (error) {
            this._handleError(error);
            throw error;
        }
    }

    /**
     * Effectue une requête POST
     * @param {string} url - URL relative de l'endpoint
     * @param {Object} data - Données à envoyer
     * @returns {Promise} - Promesse avec les données de réponse
     */
    async post(url, data = {}) {
        try {
            const response = await this.client.post(url, data);
            return response.data;
        } catch (error) {
            this._handleError(error);
            throw error;
        }
    }

    /**
     * Effectue une requête PUT
     * @param {string} url - URL relative de l'endpoint
     * @param {Object} data - Données à envoyer
     * @returns {Promise} - Promesse avec les données de réponse
     */
    async put(url, data = {}) {
        try {
            const response = await this.client.put(url, data);
            return response.data;
        } catch (error) {
            this._handleError(error);
            throw error;
        }
    }

    /**
     * Effectue une requête DELETE
     * @param {string} url - URL relative de l'endpoint
     * @param {Object} params - Paramètres de requête
     * @returns {Promise} - Promesse avec les données de réponse
     */
    async delete(url, params = {}) {
        try {
            const response = await this.client.delete(url, { params });
            return response.data;
        } catch (error) {
            this._handleError(error);
            throw error;
        }
    }

    /**
     * Effectue une requête PATCH
     * @param {string} url - URL relative de l'endpoint
     * @param {Object} data - Données à envoyer
     * @returns {Promise} - Promesse avec les données de réponse
     */
    async patch(url, data = {}) {
        try {
            const response = await this.client.patch(url, data);
            return response.data;
        } catch (error) {
            this._handleError(error);
            throw error;
        }
    }

    /**
     * Gère les erreurs API de manière centralisée
     * @param {Error} error - Erreur de la requête
     * @private
     */
    _handleError(error) {
        // Log l'erreur
        console.error('API Error:', error);

        // Si erreur d'authentification, déconnecter l'utilisateur
        if (error.response && error.response.status === 401) {
            // Rediriger vers la page de login si nécessaire
            if (window.location.pathname !== '/login') {
                localStorage.removeItem('auth_token');
                localStorage.removeItem('user');
                window.location.href = '/login';
            }
        }
    }
}

// Exporter une instance unique
export default new ApiService();
