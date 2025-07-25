import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';

// Configuration Google Analytics
const GA_MEASUREMENT_ID = (import.meta as any).env?.VITE_GA_MEASUREMENT_ID || 'G-XXXXXXXXXX';

// Interface pour les événements personnalisés
interface GAEvent {
  action: string;
  category: string;
  label?: string;
  value?: number;
}

// Déclaration TypeScript pour gtag
declare global {
  interface Window {
    gtag: (
      command: 'config' | 'event' | 'js',
      targetId: string | Date,
      config?: any
    ) => void;
    dataLayer: any[];
  }
}

// Initialiser Google Analytics
export const initGA = () => {
  if (typeof window !== 'undefined' && !window.gtag) {
    // Créer le script GA4
    const script = document.createElement('script');
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtag/js?id=${GA_MEASUREMENT_ID}`;
    document.head.appendChild(script);

    // Initialiser gtag
    window.dataLayer = window.dataLayer || [];
    window.gtag = function() {
      window.dataLayer.push(arguments);
    };
    
    window.gtag('js', new Date());
    window.gtag('config', GA_MEASUREMENT_ID, {
      page_title: document.title,
      page_location: window.location.href,
      // Configuration RGPD
      anonymize_ip: true,
      // Configuration pour les SPA
      send_page_view: false
    });
  }
};

// Tracking des pages pour les SPA
export const trackPageView = (path: string, title?: string) => {
  if (typeof window !== 'undefined' && window.gtag) {
    window.gtag('config', GA_MEASUREMENT_ID, {
      page_path: path,
      page_title: title || document.title,
      page_location: window.location.href
    });
  }
};

// Tracking des événements personnalisés
export const trackEvent = ({ action, category, label, value }: GAEvent) => {
  if (typeof window !== 'undefined' && window.gtag) {
    window.gtag('event', action, {
      event_category: category,
      event_label: label,
      value: value
    });
  }
};

// Événements prédéfinis pour ChapeChape
export const trackContactForm = (formType: 'contact' | 'newsletter') => {
  trackEvent({
    action: 'form_submission',
    category: 'engagement',
    label: formType
  });
};

export const trackDownload = (appType: 'client' | 'partner', platform: 'ios' | 'android') => {
  trackEvent({
    action: 'app_download_click',
    category: 'conversion',
    label: `${appType}_${platform}`
  });
};

export const trackNavigation = (section: string) => {
  trackEvent({
    action: 'navigation_click',
    category: 'user_interaction',
    label: section
  });
};

export const trackServiceView = (serviceType: string) => {
  trackEvent({
    action: 'service_view',
    category: 'content_engagement',
    label: serviceType
  });
};

// Composant React pour le tracking automatique des pages
const GoogleAnalytics: React.FC = () => {
  const location = useLocation();

  useEffect(() => {
    // Initialiser GA4 au premier chargement
    if (GA_MEASUREMENT_ID && GA_MEASUREMENT_ID !== 'G-XXXXXXXXXX') {
      initGA();
    }
  }, []);

  useEffect(() => {
    // Tracker les changements de page dans le SPA
    if (GA_MEASUREMENT_ID && GA_MEASUREMENT_ID !== 'G-XXXXXXXXXX') {
      trackPageView(location.pathname + location.search);
    }
  }, [location]);

  return null; // Ce composant ne rend rien visuellement
};

export default GoogleAnalytics;
