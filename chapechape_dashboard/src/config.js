// Détermine si on utilise HTTPS ou HTTP (défaut: HTTP)
// Pour activer HTTPS en développement, définir REACT_APP_USE_HTTPS=true
const useHttps = process.env.REACT_APP_USE_HTTPS === 'true';

// Domaine de l'API (défaut: localhost en développement, api.chapechaperesidence.com en production)
const apiDomain = process.env.REACT_APP_API_DOMAIN || 
  (process.env.NODE_ENV === 'production' ? 'api.chapechaperesidence.com' : 'localhost:4000');

// Construction de l'URL de l'API
const protocol = useHttps ? 'https' : 'http';
const wsProtocol = useHttps ? 'wss' : 'ws';

// URL de base de l'API
export const API_URL = process.env.REACT_APP_API_URL || `${protocol}://${apiDomain}/api`;

// URL de base pour les WebSockets
export const WS_URL = process.env.REACT_APP_WS_URL || `${wsProtocol}://${apiDomain}/ws`;

// URL de base pour les médias
export const MEDIA_URL = process.env.REACT_APP_MEDIA_URL || `${protocol}://${apiDomain}/media`;

// Configuration d'environnement
export const APP_ENV = process.env.NODE_ENV || 'development';

// Version de l'application
export const APP_VERSION = process.env.REACT_APP_VERSION || '1.0.0';

// Fonction pour basculer entre HTTP et HTTPS (pour la console de développement)
export const toggleHttps = () => {
  const currentValue = localStorage.getItem('use_https') === 'true';
  const newValue = !currentValue;
  localStorage.setItem('use_https', newValue);
  console.log(`Protocole changé : ${newValue ? 'HTTPS' : 'HTTP'}. Rafraîchissez la page pour appliquer.`);
  return newValue;
};
