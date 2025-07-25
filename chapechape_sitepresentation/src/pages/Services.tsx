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

export default function Services() {
  return (
    <div className="bg-secondary-50 dark:bg-secondary-900">
      {/* Hero section - Style Stripe Premium */}
      <div className="relative isolate overflow-hidden bg-gradient-to-br from-secondary-900 via-secondary-800 to-secondary-900 dark:from-secondary-800 dark:via-secondary-900 dark:to-secondary-800 py-24 sm:py-32">
        {/* Background premium avec motifs */}
        <div className="absolute inset-0">
          <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_left,rgba(212,175,55,0.1),transparent_50%),radial-gradient(ellipse_at_bottom_right,rgba(168,85,247,0.06),transparent_50%)]" />
          <div className="absolute inset-0 bg-[linear-gradient(135deg,rgba(212,175,55,0.02)_1px,transparent_1px),linear-gradient(45deg,rgba(168,85,247,0.01)_1px,transparent_1px)] bg-[size:80px_80px]" />
        </div>
        
        <div className="relative mx-auto max-w-7xl px-6 lg:px-8">
          <motion.div 
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, ease: "easeOut" }}
            className="text-center"
          >
            {/* Badge premium */}
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="inline-flex items-center px-4 py-2 rounded-full bg-gradient-to-r from-primary-100 to-secondary-100 text-primary-700 text-sm font-medium mb-8 border border-primary-200"
            >
              <span className="w-2 h-2 bg-primary-500 rounded-full mr-2 animate-pulse"></span>
              Solutions Premium
            </motion.div>
            
            <h1 className="text-6xl md:text-7xl font-bold bg-gradient-to-r from-white via-primary-200 to-secondary-200 bg-clip-text text-transparent mb-8 font-display leading-tight">
              Nos Services
              <motion.div
                initial={{ width: 0 }}
                animate={{ width: "100%" }}
                transition={{ duration: 1, delay: 0.8 }}
                className="h-1 bg-gradient-to-r from-primary-500 to-secondary-500 rounded-full mx-auto mt-4 max-w-md"
              />
            </h1>
            
            <motion.p 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.4 }}
              className="mt-8 max-w-3xl mx-auto text-xl text-primary-100 leading-relaxed"
            >
              Des solutions complètes et personnalisées pour les 
              <span className="text-primary-300 font-medium"> propriétaires</span> et 
              <span className="text-secondary-300 font-medium"> locataires</span>.
            </motion.p>
          </motion.div>
        </div>
      </div>

      {/* Main content */}
      <div className="mx-auto max-w-7xl px-6 lg:px-8 py-16 sm:py-24">
        {/* Services Cards - Grid Layout avec Stagger Effect */}
        <div className="space-y-16">
          {services.map((service, index) => (
            <motion.div
              key={service.id}
              initial={{ opacity: 0, y: 80, rotateX: 15 }}
              whileInView={{ opacity: 1, y: 0, rotateX: 0 }}
              viewport={{ once: true, margin: "-100px" }}
              transition={{ 
                duration: 0.8, 
                delay: index * 0.2, // Stagger effect 0.2s
                ease: "easeOut"
              }}
              className={`flex flex-col ${index % 2 === 0 ? 'md:flex-row' : 'md:flex-row-reverse'} gap-8 lg:gap-16`}
            >
              <div className="md:w-1/2">
                <motion.div 
                  whileHover={{ 
                    scale: 1.02,
                    rotateY: 5,
                    rotateX: -2
                  }}
                  transition={{ duration: 0.3, ease: "easeOut" }}
                  className="bg-white/90 dark:bg-secondary-800/90 backdrop-blur-sm p-10 rounded-3xl h-full flex flex-col justify-center shadow-xl border border-gray-100 dark:border-secondary-700 hover:shadow-2xl hover:shadow-primary-500/20 hover:border-primary-300/50 transition-all duration-500 group relative overflow-hidden"
                  style={{
                    transformStyle: 'preserve-3d'
                  }}
                >
                  {/* Glow doré au hover */}
                  <div className="absolute inset-0 bg-gradient-to-br from-primary-400/10 via-transparent to-secondary-400/10 opacity-0 group-hover:opacity-100 transition-opacity duration-500 rounded-3xl" />
                  
                  {/* Micro-animations des icônes spécifiques */}
                  <motion.div 
                    initial={{ scale: 0.8, opacity: 0 }}
                    whileInView={{ scale: 1, opacity: 1 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.6, delay: index * 0.2 + 0.3 }}
                    whileHover={{
                      scale: service.id === 'tenants' ? 1.1 : 1.05,
                      rotate: service.id === 'owners' ? 5 : 0,
                      y: service.id === 'concierge' ? -5 : 0
                    }}
                    className="text-primary-500 dark:text-primary-400 mb-8 group-hover:scale-110 transition-transform duration-300 relative z-10"
                  >
                    {service.icon}
                  </motion.div>
                  
                  <h3 className="text-3xl font-bold bg-gradient-to-r from-gray-900 dark:from-white to-primary-600 dark:to-primary-400 bg-clip-text text-transparent mb-6 font-display group-hover:scale-105 transition-transform duration-300">
                    {service.title}
                  </h3>
                  
                  <p className="text-gray-700 dark:text-gray-300 mb-10 text-lg leading-relaxed">
                    {service.description}
                  </p>
                  
                  <ul className="space-y-4">
                    {service.features.map((feature, i) => (
                      <motion.li 
                        key={i} 
                        initial={{ opacity: 0, x: -20 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.5, delay: (index * 0.2) + (i * 0.1) }}
                        className="flex items-start group/item"
                      >
                        <div className="w-6 h-6 rounded-full bg-gradient-to-r from-primary-500 to-secondary-500 flex items-center justify-center mr-4 mt-0.5 group-hover/item:scale-110 transition-transform duration-200">
                          <svg className="h-3 w-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="3">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                          </svg>
                        </div>
                        <span className="text-gray-700 dark:text-gray-300 font-medium group-hover/item:text-primary-600 dark:group-hover/item:text-primary-400 transition-colors duration-200">
                          {feature}
                        </span>
                      </motion.li>
                    ))}
                  </ul>
                  
                  <div className="mt-10">
                    <motion.a 
                      href={`/services/${service.id}`} 
                      initial={{ opacity: 0, y: 20 }}
                      whileInView={{ opacity: 1, y: 0 }}
                      viewport={{ once: true }}
                      transition={{ duration: 0.5, delay: (index * 0.2) + 0.3 }}
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      className="inline-flex items-center px-6 py-3 rounded-2xl bg-gradient-to-r from-primary-500 to-secondary-500 text-white font-medium hover:from-primary-600 hover:to-secondary-600 transition-all duration-300 shadow-lg hover:shadow-xl group/btn"
                    >
                      En savoir plus
                      <motion.svg 
                        className="ml-2 h-4 w-4"
                        fill="none" 
                        viewBox="0 0 24 24" 
                        stroke="currentColor"
                        whileHover={{ x: 5 }}
                        transition={{ duration: 0.2 }}
                      >
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5l7 7-7 7" />
                      </motion.svg>
                    </motion.a>
                  </div>
                </motion.div>
              </div>
              
              <div className="md:w-1/2 flex items-center justify-center">
                <motion.div 
                  initial={{ opacity: 0, scale: 0.9, rotate: -2 }}
                  whileInView={{ opacity: 1, scale: 1, rotate: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.8, delay: index * 0.2 }}
                  whileHover={{ scale: 1.05, rotate: 1 }}
                  className="relative w-full aspect-video rounded-3xl overflow-hidden shadow-2xl group/image"
                >
                  <img 
                    src={`/assets/services/${service.id}.jpg`}
                    alt={service.title}
                    className="w-full h-full object-cover group-hover/image:scale-110 transition-transform duration-500"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-gray-900/80 via-gray-900/20 to-transparent group-hover/image:from-primary-900/80">
                    <div className="absolute bottom-6 left-6 right-6">
                      <h4 className="text-2xl font-bold text-white mb-2 group-hover/image:scale-105 transition-transform duration-300">
                        {service.title}
                      </h4>
                      <p className="text-primary-200 font-medium">ChapeChape Residence</p>
                    </div>
                  </div>
                  
                  {/* Overlay premium */}
                  <div className="absolute inset-0 bg-gradient-to-br from-primary-500/10 to-secondary-500/10 opacity-0 group-hover/image:opacity-100 transition-opacity duration-300" />
                </motion.div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Appel à l'action - Style Premium */}
        <motion.div 
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8 }}
          className="mt-32 bg-gradient-to-br from-gray-900 via-primary-900 to-secondary-900 dark:from-secondary-800 dark:via-secondary-900 dark:to-primary-900 rounded-3xl p-12 sm:p-16 text-center relative overflow-hidden"
        >
          {/* Background pattern */}
          <div className="absolute inset-0 bg-[linear-gradient(135deg,rgba(255,255,255,0.1)_1px,transparent_1px),linear-gradient(45deg,rgba(255,255,255,0.05)_1px,transparent_1px)] bg-[size:60px_60px]" />
          
          <motion.div 
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="relative z-10"
          >
            {/* Badge */}
            <div className="inline-flex items-center px-4 py-2 rounded-full bg-white/10 backdrop-blur-sm text-primary-200 text-sm font-medium mb-8 border border-white/20">
              <span className="w-2 h-2 bg-primary-400 rounded-full mr-2 animate-pulse"></span>
              Service Personnalisé
            </div>
            
            <h2 className="text-4xl md:text-5xl font-bold text-white mb-6 font-display">
              Besoin d'un service 
              <span className="bg-gradient-to-r from-primary-400 to-secondary-400 bg-clip-text text-transparent"> personnalisé</span> ?
            </h2>
            
            <p className="text-xl text-gray-300 mb-12 max-w-3xl mx-auto leading-relaxed">
              Notre équipe est disponible pour discuter de vos besoins spécifiques et vous 
              proposer des solutions adaptées à votre situation unique.
            </p>
            
            <motion.a
              href="/contact"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="inline-flex items-center px-8 py-4 rounded-2xl bg-gradient-to-r from-primary-500 to-secondary-500 text-white font-semibold text-lg hover:from-primary-400 hover:to-secondary-400 transition-all duration-300 shadow-2xl hover:shadow-primary-500/25 group"
            >
              Demander un devis
              <motion.svg 
                className="ml-3 h-5 w-5" 
                fill="none" 
                viewBox="0 0 24 24" 
                stroke="currentColor"
                whileHover={{ x: 5 }}
                transition={{ duration: 0.2 }}
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 8l4 4m0 0l-4 4m4-4H3" />
              </motion.svg>
            </motion.a>
          </motion.div>
        </motion.div>
      </div>
    </div>
  )
}
