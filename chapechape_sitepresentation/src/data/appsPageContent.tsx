import type { ReactNode } from 'react'
import type { AppFeature, AppScreenSlide } from '../components/apps/AppProductSection'

type FeatureDef = Omit<AppFeature, 'icon'> & { icon: ReactNode }

const iconClass = 'h-6 w-6'

export const clientFeatures: FeatureDef[] = [
  {
    title: 'Recherche avancée',
    description: 'Filtrez les résidences selon vos critères spécifiques : localisation, prix, commodités, etc.',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={iconClass}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
      </svg>
    ),
  },
  {
    title: 'Réservation instantanée',
    description: 'Réservez votre résidence en quelques clics et recevez une confirmation immédiate.',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={iconClass}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5" />
      </svg>
    ),
  },
  {
    title: 'Paiement sécurisé',
    description: 'Utilisez plusieurs méthodes de paiement sécurisées, incluant mobile money et cartes bancaires.',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={iconClass}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5z" />
      </svg>
    ),
  },
  {
    title: 'Communication directe',
    description: 'Discutez avec les propriétaires via notre messagerie intégrée pour toute question ou demande.',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={iconClass}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M8.625 12a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H8.25m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H12m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0h-.375M21 12c0 4.556-4.03 8.25-9 8.25a9.764 9.764 0 01-2.555-.337A5.972 5.972 0 015.41 20.97a5.969 5.969 0 01-.474-.065 4.48 4.48 0 00.978-2.025c.09-.457-.133-.901-.467-1.226C3.93 16.178 3 14.189 3 12c0-4.556 4.03-8.25 9-8.25s9 3.694 9 8.25z" />
      </svg>
    ),
  },
]

export const partnerFeatures: FeatureDef[] = [
  {
    title: 'Gestion des propriétés',
    description: 'Gérez facilement toutes vos résidences, leurs disponibilités et leurs tarifs depuis une seule interface.',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={iconClass}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008z" />
      </svg>
    ),
  },
  {
    title: 'Suivi des réservations',
    description: 'Visualisez et gérez toutes vos réservations en temps réel avec notifications instantanées.',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={iconClass}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25z" />
      </svg>
    ),
  },
  {
    title: 'Analyse de performance',
    description: "Accédez à des statistiques détaillées sur vos propriétés : taux d'occupation, revenus, avis clients, etc.",
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={iconClass}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z" />
      </svg>
    ),
  },
  {
    title: 'Support prioritaire',
    description: "Bénéficiez d'un support dédié pour vous accompagner dans la gestion de vos résidences.",
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={iconClass}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9.879 7.519c1.171-1.025 3.071-1.025 4.242 0 1.172 1.025 1.172 2.687 0 3.712-.203.179-.43.326-.67.442-.745.361-1.45.999-1.45 1.827v.75M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9 5.25h.008v.008H12v-.008z" />
      </svg>
    ),
  },
]

export const clientScreenshots: AppScreenSlide[] = [
  {
    src: '/assets/apps/client/client-01.jpeg',
    label: 'Accueil & catégories',
    caption: 'Accédez aux types de séjour et démarrez votre recherche depuis l’accueil.',
  },
  {
    src: '/assets/apps/client/client-02.jpeg',
    label: 'Carte & annonces',
    caption: 'Explorez les résidences sur la carte avec les prix en temps réel.',
  },
  {
    src: '/assets/apps/client/client-03.jpeg',
    label: 'Fiche logement',
    caption: 'Consultez les détails, photos et réservez en quelques clics.',
  },
  {
    src: '/assets/apps/client/client-04.jpeg',
    label: 'Mes réservations',
    caption: 'Suivez vos séjours, statuts de paiement et actions à effectuer.',
  },
  {
    src: '/assets/apps/client/client-05.jpeg',
    label: 'Paiement sécurisé',
    caption: 'Réglez en toute sécurité via Wave et bientôt d’autres moyens locaux.',
  },
]

export const partnerScreenshots: AppScreenSlide[] = [
  {
    src: '/assets/apps/partner/partner-01.jpeg',
    label: 'Tableau de bord',
    caption: 'Vue d’ensemble de vos résidences, réservations et indicateurs clés.',
  },
  {
    src: '/assets/apps/partner/partner-02.jpeg',
    label: 'Gestion des biens',
    caption: 'Pilotez chaque résidence, tarifs et disponibilités depuis une fiche détaillée.',
  },
  {
    src: '/assets/apps/partner/partner-03.jpeg',
    label: 'Nouvelle résidence',
    caption: 'Publiez un bien en quelques étapes avec photos et informations essentielles.',
  },
  {
    src: '/assets/apps/partner/partner-04.jpeg',
    label: 'Réservations',
    caption: 'Gérez les demandes, paiements en attente et coordonnées locataires.',
  },
  {
    src: '/assets/apps/partner/partner-05.jpeg',
    label: 'Profil partenaire',
    caption: 'Paramétrez votre compte et suivez la performance de votre parc.',
  },
]
