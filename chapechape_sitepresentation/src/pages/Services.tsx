import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Link } from 'react-router-dom';
import SEOHead from '../components/seo/SEOHead';

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com';

// Données des services
const services = [
  {
    id: 'owners',
    title: 'Propriétaires',
    subtitle: 'Maximisez votre investissement',
    description: 'Une gestion locative complète et transparente pour valoriser votre patrimoine sans les contraintes du quotidien.',
    image: '/assets/services/owners.jpg',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
      </svg>
    ),
    features: [
      { title: 'Gestion Locative', desc: 'Recherche de locataires, états des lieux, encaissement des loyers.' },
      { title: 'Maintenance', desc: 'Suivi des travaux et entretien régulier de votre bien.' },
      { title: 'Juridique & Fiscal', desc: 'Conseils et gestion des obligations légales et fiscales.' },
      { title: 'Valorisation', desc: 'Conseils pour augmenter la valeur locative de votre bien.' }
    ]
  },
  {
    id: 'tenants',
    title: 'Locataires',
    subtitle: 'Votre confort avant tout',
    description: 'Trouvez le logement idéal et profitez d\'une expérience de location sereine avec nos services dédiés.',
    image: '/assets/services/tenants.jpg',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
      </svg>
    ),
    features: [
      { title: 'Recherche Personnalisée', desc: 'Accès à des biens exclusifs correspondant à vos critères.' },
      { title: 'Emménagement Facile', desc: 'Assistance pour les démarches administratives et logistiques.' },
      { title: 'Support 24/7', desc: 'Une équipe disponible pour répondre à vos urgences.' },
      { title: 'Services Connectés', desc: 'Application mobile pour gérer votre location et vos paiements.' }
    ]
  },
  {
    id: 'concierge',
    title: 'Conciergerie',
    subtitle: 'L\'excellence au quotidien',
    description: 'Des services haut de gamme pour faciliter votre vie quotidienne et celle de vos locataires.',
    image: '/assets/services/concierge.jpg',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
      </svg>
    ),
    features: [
      { title: 'Ménage & Entretien', desc: 'Services de nettoyage professionnels à la demande.' },
      { title: 'Blanchisserie', desc: 'Collecte et livraison de votre linge.' },
      { title: 'Chauffeur Privé', desc: 'Réservation de véhicules avec chauffeur pour vos déplacements.' },
      { title: 'Événements', desc: 'Organisation de réceptions et réservations exclusives.' }
    ]
  }
];

export default function Services() {
  const [activeTab, setActiveTab] = useState(services[0].id);

  const activeService = services.find(s => s.id === activeTab) || services[0];

  return (
    <div className="bg-white min-h-screen">
      <SEOHead
        title="Nos services"
        description="Services propriétaires et locataires : gestion locative, maintenance, réservation et accompagnement. ChapeChape Residence, Côte d'Ivoire."
        url={`${siteUrl}/services`}
      />
      {/* Hero Section Harmonisé */}
      <section className="relative py-32 bg-secondary-900 overflow-hidden">
        <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-10 mix-blend-overlay" />
        <div className="absolute inset-0 bg-gradient-to-b from-secondary-900/50 via-secondary-900/80 to-white" />

        {/* Golden particles */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          {[...Array(6)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute rounded-full bg-primary-400/20 blur-xl"
              style={{
                width: Math.random() * 150 + 50 + 'px',
                height: Math.random() * 150 + 50 + 'px',
                left: Math.random() * 100 + '%',
                top: Math.random() * 100 + '%',
              }}
              animate={{
                y: [0, -100, 0],
                x: [0, Math.random() * 50 - 25, 0],
                opacity: [0, 0.4, 0],
              }}
              transition={{
                duration: Math.random() * 10 + 10,
                repeat: Infinity,
                ease: "easeInOut",
              }}
            />
          ))}
        </div>

        <div className="container mx-auto px-4 max-w-6xl relative z-10 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <span className="inline-block py-1 px-3 rounded-full bg-white/10 backdrop-blur-md border border-white/20 text-primary-300 text-xs font-bold tracking-widest uppercase mb-6">
              Expertise & Excellence
            </span>
            <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              Nos Services <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">Premium</span>
            </h1>
            <p className="text-xl text-gray-300 mb-10 max-w-2xl mx-auto font-light leading-relaxed">
              Une gamme complète de services sur-mesure conçus pour répondre aux exigences les plus élevées des propriétaires et des locataires.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Interactive Tabs Section */}
      <section className="py-20 px-4 -mt-20 relative z-20">
        <div className="container mx-auto max-w-6xl">
          {/* Tabs Navigation */}
          <div className="flex flex-wrap justify-center gap-4 mb-16">
            {services.map((service) => (
              <button
                key={service.id}
                onClick={() => setActiveTab(service.id)}
                className={`flex items-center px-8 py-4 rounded-full text-sm font-bold uppercase tracking-wide transition-all duration-300 shadow-lg ${activeTab === service.id
                    ? 'bg-primary-500 text-white transform scale-105 shadow-primary-500/30 ring-4 ring-primary-500/20'
                    : 'bg-white text-secondary-600 hover:bg-secondary-50 hover:text-primary-500'
                  }`}
              >
                <span className={`mr-3 ${activeTab === service.id ? 'text-white' : 'text-primary-500'}`}>
                  {service.icon}
                </span>
                {service.title}
              </button>
            ))}
          </div>

          {/* Content Display */}
          <AnimatePresence mode='wait'>
            <motion.div
              key={activeTab}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.5 }}
              className="bg-white rounded-3xl shadow-2xl overflow-hidden border border-gray-100"
            >
              <div className="grid grid-cols-1 lg:grid-cols-2">
                {/* Image Side */}
                <div className="relative h-96 lg:h-auto overflow-hidden">
                  <div className="absolute inset-0 bg-secondary-900/20 z-10" />
                  <img
                    src={activeService.image}
                    alt={activeService.title}
                    className="w-full h-full object-cover transform scale-105 transition-transform duration-1000 hover:scale-110"
                    onError={(e) => {
                      const target = e.target as HTMLImageElement;
                      target.src = '/assets/images/placeholder-luxury.jpg'; // Fallback image
                    }}
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/90 via-transparent to-transparent z-20" />
                  <div className="absolute bottom-0 left-0 p-10 z-30">
                    <h3 className="text-4xl font-bold text-white mb-2 font-display">{activeService.title}</h3>
                    <p className="text-primary-300 text-lg font-light">{activeService.subtitle}</p>
                  </div>
                </div>

                {/* Content Side */}
                <div className="p-10 lg:p-16 flex flex-col justify-center bg-white relative">
                  <div className="absolute top-0 right-0 p-10 opacity-5 pointer-events-none">
                    <svg className="w-64 h-64 text-primary-500" fill="currentColor" viewBox="0 0 24 24">
                      {activeService.icon.props.children}
                    </svg>
                  </div>

                  <p className="text-xl text-secondary-600 leading-relaxed mb-10 relative z-10">
                    {activeService.description}
                  </p>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-8 relative z-10">
                    {activeService.features.map((feature, idx) => (
                      <motion.div
                        key={idx}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: idx * 0.1 + 0.3 }}
                        className="group"
                      >
                        <div className="flex items-center mb-2">
                          <span className="w-2 h-2 rounded-full bg-primary-500 mr-3 group-hover:scale-150 transition-transform duration-300" />
                          <h4 className="font-bold text-secondary-900 group-hover:text-primary-600 transition-colors">
                            {feature.title}
                          </h4>
                        </div>
                        <p className="text-sm text-gray-500 pl-5 border-l border-gray-100 group-hover:border-primary-200 transition-colors">
                          {feature.desc}
                        </p>
                      </motion.div>
                    ))}
                  </div>

                  <div className="mt-12 pt-8 border-t border-gray-100 relative z-10">
                    <Link
                      to="/contact"
                      className="inline-flex items-center text-primary-600 font-bold hover:text-primary-700 transition-colors group"
                    >
                      En savoir plus sur ce service
                      <svg className="w-5 h-5 ml-2 transform group-hover:translate-x-1 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                      </svg>
                    </Link>
                  </div>
                </div>
              </div>
            </motion.div>
          </AnimatePresence>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24 bg-secondary-50 relative overflow-hidden">
        <div className="container mx-auto px-4 max-w-4xl text-center relative z-10">
          <h2 className="text-3xl md:text-4xl font-bold text-secondary-900 mb-6 font-display">
            Prêt à vivre l'expérience ChapeChape ?
          </h2>
          <p className="text-xl text-gray-600 mb-10">
            Que vous soyez propriétaire ou locataire, nous avons la solution adaptée à vos besoins.
          </p>
          <div className="flex flex-col sm:flex-row justify-center gap-4">
            <Link
              to="/contact"
              className="btn-primary"
            >
              Nous Contacter
            </Link>
            <Link
              to="/residences"
              className="btn-secondary"
            >
              Voir nos résidences
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
