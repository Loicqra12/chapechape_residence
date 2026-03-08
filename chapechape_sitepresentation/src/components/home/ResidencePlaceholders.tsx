import React from 'react';

export type ResidencePlaceholderType =
  | 'apartment' | 'villa' | 'studio' | 'duplex' | 'traditional'
  | 'meuble' | 'hotel' | 'insolite' | 'colocation' | 'longue_duree' | 'economique';

interface ResidencePlaceholderProps {
  type: ResidencePlaceholderType;
  className?: string;
}

/**
 * Composant qui génère des placeholders visuels pour les résidences
 * En attendant que les vraies images soient générées, ce composant crée
 * des représentations stylisées des différents types de résidences.
 */
const ResidencePlaceholder: React.FC<ResidencePlaceholderProps> = ({ type, className = '' }) => {
  // Couleurs pour chaque type de résidence (6 catégories app + anciens types)
  const colors: Record<ResidencePlaceholderType, { bg: string; accent: string; text: string }> = {
    apartment: { bg: 'from-blue-100 to-blue-50', accent: 'bg-blue-500', text: 'text-blue-800' },
    villa: { bg: 'from-emerald-100 to-emerald-50', accent: 'bg-emerald-500', text: 'text-emerald-800' },
    studio: { bg: 'from-amber-100 to-amber-50', accent: 'bg-amber-500', text: 'text-amber-800' },
    duplex: { bg: 'from-violet-100 to-violet-50', accent: 'bg-violet-500', text: 'text-violet-800' },
    traditional: { bg: 'from-rose-100 to-rose-50', accent: 'bg-rose-500', text: 'text-rose-800' },
    meuble: { bg: 'from-sky-100 to-sky-50', accent: 'bg-sky-500', text: 'text-sky-800' },
    hotel: { bg: 'from-slate-100 to-slate-50', accent: 'bg-slate-500', text: 'text-slate-800' },
    insolite: { bg: 'from-green-100 to-green-50', accent: 'bg-green-500', text: 'text-green-800' },
    colocation: { bg: 'from-orange-100 to-orange-50', accent: 'bg-orange-500', text: 'text-orange-800' },
    longue_duree: { bg: 'from-teal-100 to-teal-50', accent: 'bg-teal-500', text: 'text-teal-800' },
    economique: { bg: 'from-amber-100 to-amber-50', accent: 'bg-amber-600', text: 'text-amber-800' }
  };

  // Icônes stylisées pour chaque type de résidence
  const renderIcon = () => {
    switch (type) {
      case 'apartment':
        return (
          <svg className="w-12 h-12 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <rect x="2" y="4" width="20" height="16" rx="2" strokeWidth="2" />
            <line x1="2" y1="8" x2="22" y2="8" strokeWidth="2" />
            <line x1="12" y1="8" x2="12" y2="20" strokeWidth="2" />
            <rect x="6" y="12" width="2" height="2" strokeWidth="0" fill="currentColor" />
            <rect x="16" y="12" width="2" height="2" strokeWidth="0" fill="currentColor" />
          </svg>
        );
      case 'villa':
        return (
          <svg className="w-12 h-12 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
            <path strokeLinecap="round" strokeWidth="2" d="M20 15a2 2 0 00-2 2v2H6v-2a2 2 0 00-2-2" />
          </svg>
        );
      case 'studio':
        return (
          <svg className="w-12 h-12 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <rect x="4" y="4" width="16" height="16" rx="2" strokeWidth="2" />
            <line x1="4" y1="12" x2="20" y2="12" strokeWidth="2" />
            <rect x="7" y="7" width="4" height="2" strokeWidth="0" fill="currentColor" />
            <rect x="7" y="15" width="2" height="2" strokeWidth="0" fill="currentColor" />
          </svg>
        );
      case 'duplex':
        return (
          <svg className="w-12 h-12 text-violet-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <rect x="3" y="3" width="18" height="18" rx="2" strokeWidth="2" />
            <line x1="3" y1="9" x2="21" y2="9" strokeWidth="2" />
            <line x1="9" y1="9" x2="9" y2="21" strokeWidth="2" />
            <path d="M9 15 L7 13 L9 11" strokeWidth="2" />
          </svg>
        );
      case 'traditional':
        return (
          <svg className="w-12 h-12 text-rose-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 12l9-9 9 9M5 10v10a1 1 0 001 1h12a1 1 0 001-1V10" />
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 21v-6a1 1 0 011-1h4a1 1 0 011 1v6" />
          </svg>
        );
      case 'meuble':
        return (
          <svg className="w-12 h-12 text-sky-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
        );
      case 'hotel':
        return (
          <svg className="w-12 h-12 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
          </svg>
        );
      case 'insolite':
        return (
          <svg className="w-12 h-12 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0h.5a2.5 2.5 0 002.5-2.5V3.935M12 12a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v3a4 4 0 01-4 4z" />
          </svg>
        );
      case 'colocation':
        return (
          <svg className="w-12 h-12 text-orange-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
        );
      case 'longue_duree':
        return (
          <svg className="w-12 h-12 text-teal-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
        );
      case 'economique':
        return (
          <svg className="w-12 h-12 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        );
    }
  };

  // Obtenir le nom du type en français
  const getTypeName = (): string => {
    const names: Record<ResidencePlaceholderType, string> = {
      apartment: 'Appartement',
      villa: 'Villa Luxueuse',
      studio: 'Studio',
      duplex: 'Duplex & Loft',
      traditional: 'Résidence Traditionnelle',
      meuble: 'Résidences meublées',
      hotel: 'Hôtels & hébergements',
      insolite: 'Hébergements insolites',
      colocation: 'Colocation & partagé',
      longue_duree: 'Longue durée',
      economique: 'Hébergements économiques'
    };
    return names[type];
  };

  return (
    <div className={`relative aspect-[4/3] overflow-hidden rounded-xl shadow-lg ${className}`}>
      <div className={`absolute inset-0 bg-gradient-to-br ${colors[type].bg} flex flex-col items-center justify-center p-6 text-center`}>
        {renderIcon()}
        <h3 className={`mt-4 text-lg font-semibold ${colors[type].text}`}>
          {getTypeName()}
        </h3>
        <div className="mt-2 text-xs text-secondary-500">Image à venir</div>
        
        {/* Éléments décoratifs */}
        <div className={`absolute bottom-0 left-0 w-full h-1/3 bg-gradient-to-t from-secondary-900/20 to-transparent`}></div>
        <div className={`absolute top-4 right-4 w-8 h-8 rounded-full ${colors[type].accent} opacity-20`}></div>
        <div className={`absolute bottom-4 left-4 w-12 h-12 rounded-full ${colors[type].accent} opacity-10`}></div>
      </div>
    </div>
  );
};

export default ResidencePlaceholder; 