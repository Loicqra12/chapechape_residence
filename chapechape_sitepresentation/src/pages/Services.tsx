import { motion } from 'framer-motion'

// Données des services
const services = [
  {
    id: 'owners',
    title: 'Services aux Propriétaires',
    description: 'Des solutions complètes pour maximiser votre investissement immobilier.',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
      </svg>
    ),
    features: [
      'Gestion locative complète',
      'Marketing et mise en valeur de votre bien',
      'Sélection rigoureuse des locataires',
      'Gestion des contrats et des paiements',
      'Maintenance et suivi régulier',
      'Rapports financiers détaillés'
    ]
  },
  {
    id: 'tenants',
    title: 'Services aux Locataires',
    description: 'Une expérience de location sans tracas et personnalisée.',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
      </svg>
    ),
    features: [
      'Recherche personnalisée de logement',
      'Visites virtuelles et physiques',
      'Assistance pour les démarches administratives',
      'Service de conciergerie',
      'Accompagnement à l\'emménagement',
      'Support client disponible 24/7'
    ]
  },
  {
    id: 'management',
    title: 'Gestion Locative',
    description: 'Une gestion professionnelle de votre patrimoine immobilier.',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
      </svg>
    ),
    features: [
      'Évaluation précise du loyer',
      'Collecte des loyers et gestion des retards',
      'Gestion des dépôts de garantie',
      'Comptabilité détaillée',
      'Gestion des obligations fiscales',
      'Intervention rapide en cas de problème'
    ]
  },
  {
    id: 'concierge',
    title: 'Conciergerie',
    description: 'Des services exclusifs pour un confort optimal.',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
      </svg>
    ),
    features: [
      'Accueil personnalisé',
      'Service de ménage',
      'Blanchisserie',
      'Courses et livraisons',
      'Organisation d\'événements',
      'Réservations de restaurants et activités'
    ]
  }
]

const Services = () => {
  return (
    <div className="bg-white">
      {/* Hero section */}
      <div className="relative bg-secondary-900 py-24 px-6 sm:py-32 sm:px-12">
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-secondary-900 to-secondary-800 opacity-90" />
          <div 
            className="absolute inset-0 bg-cover bg-center opacity-20" 
            style={{ backgroundImage: 'url(/assets/services/hero-bg.jpg)' }}
          />
        </div>
        <div className="relative mx-auto max-w-7xl">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            <h1 className="text-4xl font-bold tracking-tight text-white sm:text-5xl lg:text-6xl">
              Nos Services
            </h1>
            <p className="mt-6 max-w-lg mx-auto text-xl text-primary-200">
              Des solutions complètes et personnalisées pour les propriétaires et locataires.
            </p>
          </motion.div>
        </div>
      </div>

      {/* Main content */}
      <div className="container-custom py-16 sm:py-24">
        {/* Introduction */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-3xl font-bold text-secondary-900 mb-6">
            Des Services Adaptés à Vos Besoins
          </h2>
          <p className="text-lg text-secondary-600">
            ChapeChape Residence met à votre disposition une gamme complète de services 
            pour faciliter la location et la gestion de biens immobiliers. Que vous soyez 
            propriétaire ou locataire, notre équipe professionnelle est là pour vous 
            offrir une expérience sans tracas.
          </p>
        </div>

        {/* Liste des services */}
        <div className="space-y-24">
          {services.map((service, index) => (
            <motion.div
              key={service.id}
              initial={{ opacity: 0, y: 50 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-100px" }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              className={`flex flex-col ${index % 2 === 0 ? 'md:flex-row' : 'md:flex-row-reverse'} gap-8 lg:gap-16`}
            >
              <div className="md:w-1/2">
                <div className="bg-primary-50 p-8 rounded-xl h-full flex flex-col justify-center">
                  <div className="text-primary-500 mb-6">
                    {service.icon}
                  </div>
                  <h3 className="text-2xl font-bold text-secondary-900 mb-4">{service.title}</h3>
                  <p className="text-secondary-600 mb-8">{service.description}</p>
                  <ul className="space-y-3">
                    {service.features.map((feature, i) => (
                      <li key={i} className="flex items-start">
                        <svg className="h-6 w-6 text-primary-400 mr-2 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7" />
                        </svg>
                        <span className="text-secondary-700">{feature}</span>
                      </li>
                    ))}
                  </ul>
                  <div className="mt-8">
                    <a 
                      href={`/services/${service.id}`} 
                      className="btn-secondary"
                    >
                      En savoir plus
                    </a>
                  </div>
                </div>
              </div>
              <div className="md:w-1/2 flex items-center justify-center">
                <div className="relative w-full aspect-video rounded-xl overflow-hidden shadow-xl">
                  <img 
                    src={`/assets/services/${service.id}.jpg`}
                    alt={service.title}
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/70 to-transparent">
                    <div className="absolute bottom-4 left-4 right-4">
                      <h4 className="text-xl font-bold text-white">{service.title}</h4>
                      <p className="text-sm text-primary-200">ChapeChape Residence</p>
                    </div>
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Appel à l'action */}
        <div className="mt-24 bg-secondary-900 rounded-2xl p-8 sm:p-12 text-center">
          <motion.div 
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
          >
            <h2 className="text-2xl font-bold text-white mb-4">
              Besoin d'un service personnalisé ?
            </h2>
            <p className="text-lg text-primary-200 mb-8 max-w-2xl mx-auto">
              Notre équipe est disponible pour discuter de vos besoins spécifiques et vous 
              proposer des solutions adaptées.
            </p>
            <a
              href="/contact"
              className="btn-primary bg-primary-300 hover:bg-primary-400 text-secondary-900"
            >
              Demander un devis
            </a>
          </motion.div>
        </div>
      </div>
    </div>
  )
}

export default Services 