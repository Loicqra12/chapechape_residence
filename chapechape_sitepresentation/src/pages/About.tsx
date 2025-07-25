import { motion } from 'framer-motion'
import AboutSection from '../components/home/AboutSection'
import Coverage from '../components/home/Coverage'
import Stats from '../components/home/Stats'
import Contact from '../components/home/Contact'
import Partners from '../components/home/Partners'

export default function About() {
  // Variantes d'animation pour les titres et textes
  const textVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { 
      opacity: 1, 
      y: 0, 
      transition: { duration: 0.6 }
    }
  }

  return (
    <div className="bg-secondary-50 dark:bg-secondary-900">
      {/* Hero section */}
      <div className="relative isolate overflow-hidden bg-gradient-to-br from-secondary-900 via-secondary-800 to-secondary-900 dark:from-secondary-800 dark:via-secondary-900 dark:to-secondary-800 py-24 sm:py-32">
        {/* Grille d'arrière-plan animée */}
        <motion.div 
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.3 }}
          transition={{ duration: 1.5 }}
          className="absolute inset-0 bg-grid-white/5 dark:bg-grid-white/10 bg-[linear-gradient(to_right,#161616_1px,transparent_1px),linear-gradient(to_bottom,#161616_1px,transparent_1px)] bg-[size:4rem_4rem] z-0"
        />
        
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl lg:mx-0">
            <motion.h1 
              variants={textVariants}
              initial="hidden"
              animate="visible"
              className="text-4xl font-bold tracking-tight text-primary-300 dark:text-primary-200 sm:text-6xl font-display"
            >
              À Propos de ChapeChape Residence
            </motion.h1>
            <motion.p 
              variants={textVariants}
              initial="hidden"
              animate="visible"
              transition={{ delay: 0.2 }}
              className="mt-6 text-lg leading-8 text-primary-100 dark:text-primary-200"
            >
              Découvrez notre histoire, notre mission et ce qui fait de ChapeChape Residence le partenaire idéal pour votre expérience résidentielle en Afrique de l'Ouest.
            </motion.p>
          </div>
        </div>
      </div>

      {/* Section principale About */}
      <AboutSection />

      {/* Nos Valeurs - Section Premium */}
      <div className="relative py-24 sm:py-32 bg-gradient-to-br from-white via-primary-50/30 to-white dark:from-secondary-900 dark:via-secondary-800/50 dark:to-secondary-900 overflow-hidden">
        {/* Background Elements */}
        <div className="absolute inset-0">
          <motion.div 
            className="absolute top-20 left-10 w-72 h-72 bg-gradient-to-br from-primary-200/20 to-primary-300/20 rounded-full blur-3xl"
            animate={{ 
              scale: [1, 1.2, 1],
              rotate: [0, 180, 360],
              opacity: [0.3, 0.5, 0.3]
            }}
            transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
          />
          <motion.div 
            className="absolute bottom-20 right-10 w-96 h-96 bg-gradient-to-br from-primary-300/20 to-primary-400/20 rounded-full blur-3xl"
            animate={{ 
              scale: [1.2, 1, 1.2],
              rotate: [360, 180, 0],
              opacity: [0.2, 0.4, 0.2]
            }}
            transition={{ duration: 25, repeat: Infinity, ease: "linear" }}
          />
        </div>

        <div className="relative mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-3xl lg:text-center">
            {/* Badge Premium */}
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, type: "spring", stiffness: 100 }}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-gradient-to-r from-primary-100 to-primary-200 dark:from-primary-900/30 dark:to-primary-800/30 border border-primary-200 dark:border-primary-700 mb-8"
            >
              <motion.div 
                className="w-2 h-2 bg-primary-400 rounded-full"
                animate={{ scale: [1, 1.2, 1] }}
                transition={{ duration: 2, repeat: Infinity }}
              />
              <span className="text-sm font-semibold text-primary-600 dark:text-primary-300">Nos Valeurs</span>
            </motion.div>

            <motion.h2 
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8, type: "spring", stiffness: 100 }}
              className="text-4xl font-bold tracking-tight text-secondary-900 dark:text-white sm:text-5xl lg:text-6xl font-display bg-gradient-to-r from-secondary-900 via-primary-600 to-secondary-900 dark:from-white dark:via-primary-300 dark:to-white bg-clip-text text-transparent"
            >
              Ce qui nous guide chaque jour
            </motion.h2>
            <motion.p 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.3 }}
              className="mt-6 text-xl leading-8 text-secondary-600 dark:text-secondary-300 max-w-2xl mx-auto"
            >
              Chez ChapeChape Residence, nos valeurs fondamentales façonnent chaque interaction et guident notre mission de transformer l'expérience résidentielle en Afrique de l'Ouest.
            </motion.p>
          </div>

          <div className="mx-auto mt-20 max-w-7xl">
            <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3 xl:gap-12">
              {[
                {
                  name: 'Accessibilité',
                  description: 'Rendre la location de résidences meublées simple et rapide pour tous.',
                  color: 'from-blue-400 to-blue-600',
                  bgColor: 'from-blue-50/50 to-blue-100/50 dark:from-blue-900/20 dark:to-blue-800/20',
                  shadowColor: 'group-hover:shadow-blue-400/25',
                  icon: (
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-8 h-8">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.17 0-4.207-.576-5.963-1.584A6.062 6.062 0 016 18.719m12 0a5.971 5.971 0 00-.941-3.197m0 0A5.995 5.995 0 0012 12.75a5.995 5.995 0 00-5.058 2.772m0 0a3 3 0 00-4.681 2.72 8.986 8.986 0 003.74.477m.94-3.197a5.971 5.971 0 00-.94 3.197M15 6.75a3 3 0 11-6 0 3 3 0 016 0zm6 3a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0zm-13.5 0a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z" />
                    </svg>
                  ),
                },
                {
                  name: 'Confiance',
                  description: 'Garantir des transactions sécurisées et des hébergements conformes aux attentes.',
                  color: 'from-green-400 to-green-600',
                  bgColor: 'from-green-50/50 to-green-100/50 dark:from-green-900/20 dark:to-green-800/20',
                  shadowColor: 'group-hover:shadow-green-400/25',
                  icon: (
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-8 h-8">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.623 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
                    </svg>
                  ),
                },
                {
                  name: 'Innovation',
                  description: 'Intégrer des technologies avancées pour améliorer l\'expérience utilisateur.',
                  color: 'from-purple-400 to-purple-600',
                  bgColor: 'from-purple-50/50 to-purple-100/50 dark:from-purple-900/20 dark:to-purple-800/20',
                  shadowColor: 'group-hover:shadow-purple-400/25',
                  icon: (
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-8 h-8">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
                    </svg>
                  ),
                },
                {
                  name: 'Responsabilité',
                  description: 'Agir de manière éthique envers nos clients, partenaires et la communauté.',
                  color: 'from-orange-400 to-orange-600',
                  bgColor: 'from-orange-50/50 to-orange-100/50 dark:from-orange-900/20 dark:to-orange-800/20',
                  shadowColor: 'group-hover:shadow-orange-400/25',
                  icon: (
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-8 h-8">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M18 18.72a9.094 9.094 0 003.741-.479 3 3 0 00-4.682-2.72m.94 3.198l.001.031c0 .225-.012.447-.037.666A11.944 11.944 0 0112 21c-2.17 0-4.207-.576-5.963-1.584A6.062 6.062 0 016 18.719m12 0a5.971 5.971 0 00-.941-3.197m0 0A5.995 5.995 0 0012 12.75a5.995 5.995 0 00-5.058 2.772m0 0a3 3 0 00-4.681 2.72 8.986 8.986 0 003.74.477m.94-3.197a5.971 5.971 0 00-.94 3.197M15 6.75a3 3 0 11-6 0 3 3 0 016 0zm6 3a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0zm-13.5 0a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z" />
                    </svg>
                  ),
                },
                {
                  name: 'Excellence',
                  description: 'Offrir un service de qualité supérieure à chaque étape du processus.',
                  color: 'from-primary-400 to-primary-600',
                  bgColor: 'from-primary-50/50 to-primary-100/50 dark:from-primary-900/20 dark:to-primary-800/20',
                  shadowColor: 'group-hover:shadow-primary-400/25',
                  icon: (
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-8 h-8">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
                    </svg>
                  ),
                },
              ].map((item, index) => (
                <motion.div 
                  key={item.name}
                  initial={{ opacity: 0, y: 30, scale: 0.9 }}
                  whileInView={{ opacity: 1, y: 0, scale: 1 }}
                  viewport={{ once: true }}
                  transition={{ 
                    duration: 0.6, 
                    delay: index * 0.1,
                    type: "spring",
                    stiffness: 100
                  }}
                  whileHover={{ 
                    y: -8, 
                    scale: 1.02,
                    transition: { duration: 0.2 }
                  }}
                  className="group relative bg-white dark:bg-secondary-800 p-8 rounded-2xl shadow-lg hover:shadow-2xl transition-all duration-500 border border-secondary-100 dark:border-secondary-700 overflow-hidden cursor-pointer"
                >
                  {/* Gradient overlay on hover */}
                  <div className={`absolute inset-0 bg-gradient-to-br ${item.bgColor} opacity-0 group-hover:opacity-100 transition-opacity duration-500`} />
                  
                  {/* Floating particles effect */}
                  <motion.div 
                    className="absolute top-4 right-4 w-2 h-2 bg-current rounded-full opacity-20"
                    animate={{ 
                      y: [0, -10, 0],
                      opacity: [0.2, 0.5, 0.2]
                    }}
                    transition={{ 
                      duration: 3, 
                      repeat: Infinity, 
                      delay: index * 0.5 
                    }}
                  />
                  
                  <div className="relative">
                    {/* Icon with premium animations */}
                    <motion.div 
                      className="flex items-center justify-center mb-6"
                      whileHover={{ 
                        rotate: [0, -10, 10, 0],
                        scale: 1.1
                      }}
                      transition={{ duration: 0.6, type: "spring", stiffness: 300 }}
                    >
                      <div className={`flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br ${item.color} text-white shadow-lg ${item.shadowColor} transition-all duration-300`}>
                        {item.icon}
                      </div>
                    </motion.div>
                    
                    {/* Title with slide animation */}
                    <motion.h3 
                      className="text-xl font-bold text-secondary-900 dark:text-white mb-4 text-center"
                      whileHover={{ x: 5 }}
                      transition={{ type: "spring", stiffness: 400, damping: 10 }}
                    >
                      {item.name}
                    </motion.h3>
                    
                    {/* Description with fade effect */}
                    <motion.p 
                      className="text-secondary-600 dark:text-secondary-300 text-center leading-relaxed"
                      whileHover={{ opacity: 0.8 }}
                      transition={{ duration: 0.2 }}
                    >
                      {item.description}
                    </motion.p>
                    
                    {/* Decorative bottom accent */}
                    <motion.div 
                      className={`mt-6 h-1 bg-gradient-to-r ${item.color} rounded-full mx-auto`}
                      initial={{ width: 0 }}
                      whileInView={{ width: "60%" }}
                      viewport={{ once: true }}
                      transition={{ duration: 0.8, delay: index * 0.1 + 0.5 }}
                    />
                  </div>
                </motion.div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Qui sommes-nous ? - Section Premium */}
      <div className="relative py-24 sm:py-32 bg-white dark:bg-secondary-900 overflow-hidden">
        {/* Background Elements */}
        <div className="absolute inset-0">
          <motion.div 
            className="absolute top-32 right-20 w-64 h-64 bg-gradient-to-br from-primary-200/15 to-primary-300/15 rounded-full blur-2xl"
            animate={{ 
              scale: [1, 1.3, 1],
              x: [0, 30, 0],
              opacity: [0.3, 0.6, 0.3]
            }}
            transition={{ duration: 15, repeat: Infinity, ease: "easeInOut" }}
          />
          <motion.div 
            className="absolute bottom-32 left-20 w-80 h-80 bg-gradient-to-br from-secondary-200/10 to-secondary-300/10 rounded-full blur-3xl"
            animate={{ 
              scale: [1.2, 1, 1.2],
              x: [0, -20, 0],
              opacity: [0.2, 0.5, 0.2]
            }}
            transition={{ duration: 18, repeat: Infinity, ease: "easeInOut" }}
          />
        </div>

        <div className="relative mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-3xl text-center mb-20">
            {/* Badge Premium */}
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, type: "spring", stiffness: 100 }}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-gradient-to-r from-secondary-100 to-secondary-200 dark:from-secondary-800/50 dark:to-secondary-700/50 border border-secondary-200 dark:border-secondary-600 mb-8"
            >
              <motion.div 
                className="w-2 h-2 bg-secondary-500 rounded-full"
                animate={{ scale: [1, 1.2, 1] }}
                transition={{ duration: 2, repeat: Infinity }}
              />
              <span className="text-sm font-semibold text-secondary-600 dark:text-secondary-300">Qui sommes-nous ?</span>
            </motion.div>

            <motion.h2 
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8, type: "spring", stiffness: 100 }}
              className="text-4xl font-bold tracking-tight text-secondary-900 dark:text-white sm:text-5xl lg:text-6xl font-display"
            >
              Les visionnaires derrière ChapeChape
            </motion.h2>
            <motion.p 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.3 }}
              className="mt-6 text-xl leading-8 text-secondary-600 dark:text-secondary-300 max-w-2xl mx-auto"
            >
              ChapeChape Residence est le fruit de la collaboration entre deux entrepreneurs passionnés par la transformation digitale du secteur immobilier en Afrique.
            </motion.p>
          </div>

          {/* Profils des fondateurs */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 max-w-6xl mx-auto">
            {[
              {
                name: 'Adams Diaby',
                role: 'CEO & Co-fondateur',
                initial: 'A',
                description: 'Fondateur de Onlouta, une plateforme de location d\'équipements. Adams est un visionnaire du numérique en Afrique de l\'Ouest. Il apporte son expertise en gestion de projets technologiques et sa connaissance approfondie du marché ivoirien.',
                color: 'from-blue-500 to-blue-700',
                bgColor: 'from-blue-50/50 to-blue-100/50 dark:from-blue-900/20 dark:to-blue-800/20',
                shadowColor: 'group-hover:shadow-blue-500/25',
              },
              {
                name: 'Sidney Jordan',
                role: 'CTO & Co-fondateur',
                initial: 'S',
                description: 'Fondateur de Soutrali Deals, une plateforme numérique ivoirienne qui valorise les produits, services et talents issus de l\'économie informelle et artisanale. Sidney est responsable de la stratégie technologique et du développement de la plateforme.',
                color: 'from-primary-500 to-primary-700',
                bgColor: 'from-primary-50/50 to-primary-100/50 dark:from-primary-900/20 dark:to-primary-800/20',
                shadowColor: 'group-hover:shadow-primary-500/25',
              },
            ].map((founder, index) => (
              <motion.div 
                key={founder.name}
                initial={{ opacity: 0, y: 40, scale: 0.9 }}
                whileInView={{ opacity: 1, y: 0, scale: 1 }}
                viewport={{ once: true }}
                transition={{ 
                  duration: 0.8, 
                  delay: index * 0.2,
                  type: "spring",
                  stiffness: 100
                }}
                whileHover={{ 
                  y: -10, 
                  scale: 1.02,
                  transition: { duration: 0.3 }
                }}
                className="group relative bg-white dark:bg-secondary-800 p-10 rounded-3xl shadow-xl hover:shadow-2xl transition-all duration-500 border border-secondary-100 dark:border-secondary-700 overflow-hidden"
              >
                {/* Gradient overlay on hover */}
                <div className={`absolute inset-0 bg-gradient-to-br ${founder.bgColor} opacity-0 group-hover:opacity-100 transition-opacity duration-500`} />
                
                {/* Floating elements */}
                <motion.div 
                  className="absolute top-6 right-6 w-3 h-3 bg-current rounded-full opacity-20"
                  animate={{ 
                    scale: [1, 1.5, 1],
                    opacity: [0.2, 0.6, 0.2]
                  }}
                  transition={{ 
                    duration: 4, 
                    repeat: Infinity, 
                    delay: index * 1 
                  }}
                />
                <motion.div 
                  className="absolute bottom-6 left-6 w-2 h-2 bg-current rounded-full opacity-15"
                  animate={{ 
                    y: [0, -15, 0],
                    opacity: [0.15, 0.4, 0.15]
                  }}
                  transition={{ 
                    duration: 5, 
                    repeat: Infinity, 
                    delay: index * 1.5 
                  }}
                />
                
                <div className="relative">
                  {/* Avatar avec initiale */}
                  <motion.div 
                    className="flex items-center justify-center mb-8"
                    whileHover={{ 
                      rotate: [0, -5, 5, 0],
                      scale: 1.1
                    }}
                    transition={{ duration: 0.6, type: "spring", stiffness: 300 }}
                  >
                    <div className={`flex h-24 w-24 items-center justify-center rounded-full bg-gradient-to-br ${founder.color} text-white shadow-2xl ${founder.shadowColor} transition-all duration-300 text-3xl font-bold`}>
                      {founder.initial}
                    </div>
                  </motion.div>
                  
                  {/* Nom et rôle */}
                  <div className="text-center mb-6">
                    <motion.h3 
                      className="text-2xl font-bold text-secondary-900 dark:text-white mb-2"
                      whileHover={{ scale: 1.05 }}
                      transition={{ type: "spring", stiffness: 400, damping: 10 }}
                    >
                      {founder.name}
                    </motion.h3>
                    <motion.p 
                      className={`text-lg font-semibold bg-gradient-to-r ${founder.color} bg-clip-text text-transparent`}
                      whileHover={{ scale: 1.05 }}
                      transition={{ type: "spring", stiffness: 400, damping: 10 }}
                    >
                      {founder.role}
                    </motion.p>
                  </div>
                  
                  {/* Description */}
                  <motion.p 
                    className="text-secondary-600 dark:text-secondary-300 leading-relaxed text-center"
                    whileHover={{ opacity: 0.9 }}
                    transition={{ duration: 0.2 }}
                  >
                    {founder.description}
                  </motion.p>
                  
                  {/* Decorative accent */}
                  <motion.div 
                    className={`mt-8 h-1 bg-gradient-to-r ${founder.color} rounded-full mx-auto`}
                    initial={{ width: 0 }}
                    whileInView={{ width: "80%" }}
                    viewport={{ once: true }}
                    transition={{ duration: 1, delay: index * 0.2 + 0.8 }}
                  />
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>

      {/* Coverage Section */}
      <Coverage />

      {/* Stats Section */}
      <Stats />

      {/* Partners Section */}
      <Partners />

      {/* Contact Section */}
      <Contact />
    </div>
  )
} 