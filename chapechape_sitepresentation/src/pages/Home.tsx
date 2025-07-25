import { Link } from 'react-router-dom'
import { motion, useScroll, useTransform } from 'framer-motion'
import Partners from '../components/home/Partners'
import Testimonials from '../components/home/Testimonials'
import FAQ from '../components/home/FAQ'
import Stats from '../components/home/Stats'
import Process from '../components/home/Process'
import Blog from '../components/home/Blog'
import Coverage from '../components/home/Coverage'
import Contact from '../components/home/Contact'
import Pricing from '../components/home/Pricing'
import AboutSection from '../components/home/AboutSection'
import ResidenceTypes from '../components/home/ResidenceTypes'
import AppScreenshots from '../components/home/AppScreenshots'
import { useRef } from 'react'
import { useReducedMotion, createOptimizedVariants, optimizeTransition } from '../hooks/useReducedMotion'

const features = [
  {
    name: 'Application Client',
    description: 'Trouvez et réservez facilement votre résidence idéale avec notre application mobile dédiée aux clients.',
    href: '/apps',
    icon: 'mobile'
  },
  {
    name: 'Application Partenaire',
    description: 'Gérez efficacement vos résidences et vos réservations avec notre application mobile pour les partenaires.',
    href: '/apps',
    icon: 'building'
  },
  {
    name: 'Notre Équipe',
    description: 'Découvrez l\'équipe passionnée derrière ChapeChape Residence.',
    href: '/team',
    icon: 'users'
  },
]

export default function Home() {
  const heroRef = useRef(null)
  const { scrollY } = useScroll()
  const y = useTransform(scrollY, [0, 500], [0, -150])
  const opacity = useTransform(scrollY, [0, 300], [1, 0])
  const scale = useTransform(scrollY, [0, 300], [1, 0.9])
  const { prefersReducedMotion, isMobile, shouldReduceMotion } = useReducedMotion()
  
  // Variantes d'animation pour les éléments de la section Hero
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.3,
        delayChildren: 0.2,
        when: "beforeChildren"
      }
    }
  }
  
  const itemVariants = {
    hidden: { y: 20, opacity: 0 },
    visible: { 
      y: 0, 
      opacity: 1,
      transition: { 
        type: "spring", 
        stiffness: 100,
        damping: 10
      } 
    }
  }
  
  const goldGlowVariants = {
    initial: { 
      opacity: 0.5,
      scale: 1,
    },
    animate: {
      opacity: [0.5, 0.7, 0.5],
      scale: [1, 1.05, 1],
      transition: {
        duration: 5,
        repeat: Infinity,
        repeatType: "reverse" as const,
        ease: "easeInOut"
      }
    }
  }

  return (
    <div className="bg-secondary-50">
      {/* Hero section avec effets parallaxe et animations avancées - Style Stripe */}
      <div 
        ref={heroRef}
        className="relative isolate overflow-hidden bg-gradient-to-br from-secondary-25 via-white to-primary-50 min-h-screen flex items-center"
      >
        {/* Grille d'arrière-plan animée */}
        <motion.div 
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.3 }}
          transition={{ duration: 1.5 }}
          className="absolute inset-0 bg-grid-white/5 bg-[linear-gradient(to_right,#161616_1px,transparent_1px),linear-gradient(to_bottom,#161616_1px,transparent_1px)] bg-[size:4rem_4rem] z-0"
        />
        
        {/* Cercle lumineux doré avec effet de pulsation */}
        <motion.div 
          className="absolute left-0 right-0 top-0 -z-10 m-auto h-[60vh] w-full bg-secondary-950"
        >
          <motion.div 
            variants={goldGlowVariants}
            initial="initial"
            animate="animate"
            className="absolute inset-0 bg-[radial-gradient(circle_at_50%_120%,#D4AF37,transparent_70%)]"
          />
        </motion.div>

        {/* Particules dorées flottantes - Optimisées pour mobile */}
        {!shouldReduceMotion && (
          <div className="absolute inset-0 opacity-30 z-0 overflow-hidden">
            {[...Array(isMobile ? 5 : 15)].map((_, i) => (
              <motion.div
                key={i}
                className="absolute rounded-full bg-primary-300"
                style={{
                  width: Math.random() * 10 + 5 + 'px',
                  height: Math.random() * 10 + 5 + 'px',
                  left: Math.random() * 100 + '%',
                  top: Math.random() * 100 + '%',
                }}
                animate={{
                  y: [0, isMobile ? -50 : -100, 0],
                  x: [0, Math.random() * (isMobile ? 25 : 50) - (isMobile ? 12.5 : 25), 0],
                  opacity: [0, 0.7, 0],
                }}
                transition={{
                  duration: Math.random() * (isMobile ? 8 : 10) + (isMobile ? 8 : 10),
                  repeat: Infinity,
                  ease: "easeInOut",
                  delay: Math.random() * 5,
                }}
              />
            ))}
          </div>
        )}
        
        <div className="mx-auto max-w-7xl pb-24 pt-10 sm:pb-32 lg:grid lg:grid-cols-2 lg:gap-x-8 lg:px-8 lg:py-40">
          <motion.div 
            style={{ y, opacity }}
            className="px-6 lg:px-0 lg:pt-4 z-10"
          >
            <div className="mx-auto max-w-2xl">
              <div className="max-w-lg">
                <motion.div
                  variants={containerVariants}
                  initial="hidden"
                  animate="visible"
                >
                  {/* Badge nouveau style Stripe */}
                  <motion.div variants={itemVariants}>
                    <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/90 backdrop-blur-sm border border-primary-200/50 shadow-stripe mb-8">
                      <div className="w-2 h-2 rounded-full bg-accent-green animate-pulse" />
                      <span className="text-sm font-medium text-secondary-700">
                           Plateforme N°1 en Côte d'Ivoire
                      </span>
                    </div>
                  </motion.div>
                  
                  <motion.div variants={itemVariants}>
                    <h1 className="text-5xl sm:text-7xl lg:text-8xl font-display font-bold text-secondary-900 leading-[0.9] tracking-tight">
                      L'avenir de la
                      <br />
                      <span className="bg-gradient-to-r from-primary-700 via-primary-500 to-accent-blue bg-clip-text text-transparent">
                        location immobilière
                      </span>
                      <br />
                      <span className="text-secondary-600">en Afrique</span>
                    </h1>
                  </motion.div>
                  <motion.div variants={itemVariants}>
                    <p className="mt-8 text-xl lg:text-2xl leading-relaxed text-secondary-600 max-w-2xl">
                      ChapeChape Residence révolutionne l'expérience de location avec une plateforme 
                      intelligente qui connecte propriétaires et locataires en toute simplicité.
                    </p>
                  </motion.div>
                  <motion.div
                    variants={itemVariants}
                    className="mt-12 flex flex-col sm:flex-row gap-4 items-start"
                  >
                    <motion.div
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                    >
                      <Link
                        to="/apps"
                        className="group relative inline-flex items-center gap-3 px-8 py-4 min-h-[44px] min-w-[44px] bg-secondary-900 text-white rounded-2xl font-semibold text-lg shadow-stripe-lg hover:shadow-stripe transition-all duration-300 overflow-hidden touch-manipulation"
                      >
                        <motion.span 
                          className="absolute inset-0 bg-gradient-to-r from-primary-600 to-accent-blue opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                          layoutId="button-bg"
                        />
                        <span className="relative z-10">Découvrir nos apps</span>
                        <motion.svg 
                          className="w-5 h-5 relative z-10" 
                          fill="none" 
                          viewBox="0 0 24 24" 
                          stroke="currentColor"
                          animate={{ x: [0, 5, 0] }}
                          transition={{ duration: 2, repeat: Infinity }}
                        >
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                        </motion.svg>
                      </Link>
                    </motion.div>

                    <motion.div
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                    >
                      <Link
                        to="/about"
                        className="inline-flex items-center gap-3 px-8 py-4 bg-white/90 backdrop-blur-sm text-secondary-900 rounded-2xl font-semibold text-lg border border-secondary-200 hover:border-primary-300 shadow-stripe hover:shadow-stripe-lg transition-all duration-300"
                      >
                        <span>En savoir plus</span>
                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.828 14.828a4 4 0 01-5.656 0M9 10h1m4 0h1m-6 4h.01M19 10a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                      </Link>
                    </motion.div>
                  </motion.div>

                  {/* Trust indicators style Stripe */}
                  <motion.div variants={itemVariants} className="mt-16">
                    <p className="text-sm text-secondary-500 mb-6">Ils nous font confiance</p>
                    <div className="flex flex-wrap items-center gap-8">
                      {['Abidjan', 'Cocody', 'Plateau', 'Marcory', 'Yopougon'].map((location, index) => (
                        <motion.div
                          key={location}
                          className="text-secondary-700 dark:text-secondary-400 font-semibold text-sm px-3 py-1 bg-secondary-100 dark:bg-secondary-800 rounded-full border border-secondary-200 dark:border-secondary-700"
                          initial={{ opacity: 0, y: 20 }}
                          animate={{ opacity: 1, y: 0 }}
                          transition={{ delay: 1 + index * 0.1 }}
                        >
                          {location}
                        </motion.div>
                      ))}
                    </div>
                  </motion.div>
                </motion.div>
              </div>
            </div>
          </motion.div>
          <motion.div 
            style={{ scale }}
            className="mt-20 sm:mt-24 md:mx-auto md:max-w-2xl lg:mx-0 lg:mt-0 lg:w-screen z-10"
          >
            {/* Dashboard Immobilier intégré dans la zone hero - Responsive optimisé */}
            <div className="relative h-[16rem] xs:h-[18rem] sm:h-[24rem] lg:h-[32rem] w-full">
              <motion.div
                initial={{ opacity: 0, x: 100, scale: 0.9 }}
                animate={{ opacity: 1, x: 0, scale: 1 }}
                transition={{ duration: 0.8, ease: "easeOut", delay: 0.3 }}
                className="h-full w-full max-w-md mx-auto lg:max-w-lg"
              >
                {/* Container principal avec glassmorphism - Thème adaptatif */}
                <motion.div
                  whileHover={{ scale: 1.02, y: -5 }}
                  transition={{ duration: 0.3, ease: "easeOut" }}
                  className="bg-white/90 dark:bg-secondary-900/95 backdrop-blur-xl rounded-3xl shadow-2xl border border-primary-200/30 dark:border-primary-300/30 overflow-hidden group relative h-full"
                  style={{
                    boxShadow: '0 25px 50px -12px rgba(212, 175, 55, 0.25), 0 0 0 1px rgba(212, 175, 55, 0.2)'
                  }}
                >
                  {/* Gradient background subtil */}
                  <div className="absolute inset-0 bg-gradient-to-br from-primary-50/50 via-white to-secondary-50/30 dark:from-primary-400/10 dark:via-secondary-800 dark:to-primary-300/10 -z-10" />
                  
                  {/* Header avec logo ChapeChape */}
                  <div className="p-4 lg:p-6 border-b border-primary-100/50 dark:border-primary-300/20 relative">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <motion.div
                          whileHover={{ rotate: 360, scale: 1.1 }}
                          transition={{ duration: 0.6 }}
                          className="w-10 h-10 lg:w-12 lg:h-12 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-2xl flex items-center justify-center shadow-lg relative overflow-hidden"
                        >
                          <img 
                            src="/assets/logo.png" 
                            alt="ChapeChape Residence" 
                            className="w-6 h-6 lg:w-8 lg:h-8 object-contain"
                          />
                          {/* Effet de brillance */}
                          <motion.div
                            initial={{ x: '-100%' }}
                            whileHover={{ x: '100%' }}
                            transition={{ duration: 0.6 }}
                            className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent"
                          />
                        </motion.div>
                        <div>
                          <h3 className="text-base lg:text-lg font-bold bg-gradient-to-r from-primary-600 via-secondary-600 to-primary-700 dark:from-primary-300 dark:via-primary-200 dark:to-primary-400 bg-clip-text text-transparent">
                            Dashboard Immobilier
                          </h3>
                          <p className="text-xs lg:text-sm text-primary-600/70 dark:text-primary-200/90 font-medium">ChapeChape Residence</p>
                        </div>
                      </div>
                      <motion.div
                        whileHover={{ scale: 1.2 }}
                        className="flex items-center space-x-2"
                      >
                        <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                        <span className="text-xs text-green-600 dark:text-green-400 font-medium hidden sm:inline">En ligne</span>
                      </motion.div>
                    </div>
                  </div>

                  {/* Statistiques principales */}
                  <div className="p-4 lg:p-6 space-y-4 flex-1">
                    <div className="flex items-center justify-between">
                      <h4 className="text-xs lg:text-sm font-semibold text-primary-700 dark:text-primary-200 uppercase tracking-wide">
                        Performances du Mois
                      </h4>
                      <motion.div
                        whileHover={{ rotate: 180 }}
                        className="w-5 h-5 text-primary-500 dark:text-primary-300 cursor-pointer"
                      >
                        <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                        </svg>
                      </motion.div>
                    </div>
                    
                    <div className="grid grid-cols-2 gap-2 lg:gap-3">
                      {[
                        { label: 'Revenus Mensuels', value: '2,450,000', unit: 'FCFA', change: '+12.5%', positive: true },
                        { label: 'Propriétés Actives', value: '24', unit: 'biens', change: '+3', positive: true },
                        { label: 'Taux d\'Occupation', value: '94.2', unit: '%', change: '+2.1%', positive: true },
                        { label: 'Locataires Satisfaits', value: '4.8', unit: '/5', change: '+0.2', positive: true }
                      ].map((stat, index) => (
                        <motion.div
                          key={stat.label}
                          initial={{ opacity: 0, y: 20 }}
                          animate={{ opacity: 1, y: 0 }}
                          transition={{ duration: 0.5, delay: 0.5 + index * 0.1 }}
                          whileHover={{ 
                            scale: 1.05, 
                            backgroundColor: 'rgba(212, 175, 55, 0.08)'
                          }}
                          className="bg-gradient-to-br from-primary-25 to-secondary-25 dark:from-secondary-800/50 dark:to-secondary-700/50 rounded-xl lg:rounded-2xl p-2 lg:p-4 border border-primary-100/50 dark:border-primary-300/20 group/stat cursor-pointer"
                        >
                          <div className="flex items-center justify-between mb-1 lg:mb-2">
                            <span className="text-xs text-primary-600/70 dark:text-primary-200/70 font-medium">{stat.label}</span>
                            <motion.span
                              whileHover={{ scale: 1.1 }}
                              className={`text-xs px-1.5 py-0.5 lg:px-2 lg:py-1 rounded-full font-medium ${
                                stat.positive 
                                  ? 'bg-green-100 text-green-700 border border-green-200' 
                                  : 'bg-red-100 text-red-700 border border-red-200'
                              }`}
                            >
                              {stat.change}
                            </motion.span>
                          </div>
                          <div className="flex items-baseline space-x-1">
                            <span className="text-lg lg:text-xl font-bold bg-gradient-to-r from-primary-700 to-secondary-700 dark:from-primary-300 dark:to-primary-200 bg-clip-text text-transparent">
                              {stat.value}
                            </span>
                            <span className="text-xs lg:text-sm text-primary-500/70 dark:text-primary-300/70">{stat.unit}</span>
                          </div>
                        </motion.div>
                      ))}
                    </div>
                  </div>

                  {/* Graphique de revenus (mockup) */}
                  <div className="p-4 lg:p-6 border-t border-primary-100/50 dark:border-primary-300/20">
                    <h4 className="text-xs lg:text-sm font-semibold text-primary-700 dark:text-primary-200 uppercase tracking-wide mb-3 lg:mb-4">
                      Revenus des 6 Derniers Mois
                    </h4>
                    <div className="relative h-16 lg:h-24 bg-gradient-to-r from-primary-50 to-secondary-50 dark:from-secondary-800/30 dark:to-secondary-700/30 rounded-xl lg:rounded-2xl p-3 lg:p-4 overflow-hidden border border-primary-100/30 dark:border-primary-300/20">
                      {/* Graphique SVG mockup */}
                      <svg className="w-full h-full" viewBox="0 0 300 80">
                        <motion.path
                          initial={{ pathLength: 0 }}
                          animate={{ pathLength: 1 }}
                          transition={{ duration: 2, ease: "easeInOut", delay: 1 }}
                          d="M10,60 Q50,40 80,45 T150,35 T220,25 T290,20"
                          stroke="url(#chapechapeGradient)"
                          strokeWidth="3"
                          fill="none"
                          strokeLinecap="round"
                        />
                        <defs>
                          <linearGradient id="chapechapeGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                            <stop offset="0%" stopColor="#D4AF37" />
                            <stop offset="50%" stopColor="#B8860B" />
                            <stop offset="100%" stopColor="#8B4513" />
                          </linearGradient>
                        </defs>
                        {/* Points de données */}
                        {[10, 80, 150, 220, 290].map((x, i) => (
                          <motion.circle
                            key={i}
                            initial={{ scale: 0 }}
                            animate={{ scale: 1 }}
                            transition={{ duration: 0.5, delay: 1.2 + i * 0.2 }}
                            whileHover={{ scale: 1.5 }}
                            cx={x}
                            cy={[60, 45, 35, 25, 20][i]}
                            r="3"
                            fill="#D4AF37"
                            className="cursor-pointer drop-shadow-sm"
                          />
                        ))}
                      </svg>
                      
                      {/* Overlay avec effet de brillance */}
                      <motion.div
                        initial={{ x: '-100%' }}
                        animate={{ x: '100%' }}
                        transition={{ duration: 2, delay: 1.5 }}
                        className="absolute inset-0 bg-gradient-to-r from-transparent via-primary-200/30 dark:via-primary-400/20 to-transparent"
                      />
                    </div>
                  </div>
                </motion.div>
              </motion.div>
            </div>
          </motion.div>
        </div>
      </div>

      {/* Feature section avec animations améliorées */}
      <div className="mx-auto mt-32 max-w-7xl px-6 sm:mt-56 lg:px-8">
        <div className="mx-auto max-w-2xl lg:text-center">
          <motion.h2 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            viewport={{ once: true, margin: "-100px" }}
            className="text-base font-semibold leading-7 text-primary-500"
          >
            Tout ce dont vous avez besoin
          </motion.h2>
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.1 }}
            viewport={{ once: true, margin: "-100px" }}
            className="mt-2 text-3xl font-bold tracking-tight text-secondary-900 sm:text-4xl font-display"
          >
            Une expérience complète pour la gestion de résidences
          </motion.p>
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            viewport={{ once: true, margin: "-100px" }}
            className="mt-6 text-lg leading-8 text-secondary-600"
          >
            Découvrez nos solutions innovantes pour simplifier la gestion et la location de résidences.
          </motion.p>
        </div>
        <div className="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none">
          <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-16 lg:max-w-none lg:grid-cols-3">
            {features.map((feature, index) => (
              <motion.div
                key={feature.name}
                initial={{ opacity: 0, y: 50 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                viewport={{ once: true, margin: "-100px" }}
                whileHover={{ y: -10, transition: { duration: 0.2 } }}
                className="card flex flex-col p-6 bg-secondary-50 hover:bg-white shadow-sm hover:shadow-gold transition-all duration-300 rounded-xl"
              >
                <dt className="flex items-center gap-x-3 text-base font-semibold leading-7 text-secondary-900">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary-300 text-secondary-900">
                    {feature.icon === 'mobile' && (
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 006 3.75v16.5a2.25 2.25 0 002.25 2.25h7.5A2.25 2.25 0 0018 20.25V3.75a2.25 2.25 0 00-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3" />
                      </svg>
                    )}
                    {feature.icon === 'building' && (
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008z" />
                      </svg>
                    )}
                    {feature.icon === 'users' && (
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
                      </svg>
                    )}
                  </div>
                  {feature.name}
                </dt>
                <dd className="mt-4 flex flex-auto flex-col text-base leading-7 text-secondary-600">
                  <p className="flex-auto">{feature.description}</p>
                  <p className="mt-6">
                    <Link to={feature.href} className="text-sm font-semibold leading-6 text-primary-500 hover:text-primary-600 group inline-flex items-center">
                      En savoir plus 
                      <motion.span 
                        className="inline-block ml-1"
                        initial={{ x: 0 }}
                        whileHover={{ x: 5 }}
                        transition={{ duration: 0.2 }}
                      >
                        →
                      </motion.span>
                    </Link>
                  </p>
                </dd>
              </motion.div>
            ))}
          </dl>
        </div>
      </div>

      {/* About Section */}
      <AboutSection />

      {/* Residence Types section */}
      <ResidenceTypes />

      {/* Stats section */}
      <Stats />

      {/* Process section */}
      <Process />

      {/* Testimonials section */}
      <Testimonials />
      
      {/* Coverage section */}
      <Coverage />
      
      {/* App Screenshots section */}
      <AppScreenshots />

      {/* Partners section */}
      <Partners />

      {/* Pricing section */}
      <Pricing />

      {/* Blog section */}
      <Blog />

      {/* FAQ section */}
      <FAQ />

      {/* Contact section */}
      <Contact />

      {/* CTA Section avec animation améliorée */}
      <div className="mx-auto mt-32 max-w-7xl sm:mt-56 sm:px-6 lg:px-8">
        <motion.div 
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7 }}
          viewport={{ once: true, margin: "-100px" }}
          className="relative isolate overflow-hidden bg-secondary-900 px-6 py-24 text-center shadow-2xl sm:rounded-3xl sm:px-16"
        >
          <motion.div 
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 0.1, scale: 1 }}
            transition={{ duration: 1.5 }}
            viewport={{ once: true }}
            className="absolute inset-0 -z-10 bg-[linear-gradient(45deg,#D4AF37_25%,transparent_25%,transparent_50%,#D4AF37_50%,#D4AF37_75%,transparent_75%,transparent)] bg-[length:2rem_2rem]"
          />
          
          {/* Particules dorées en arrière-plan - Optimisées */}
          {!shouldReduceMotion && (
            <div className="absolute inset-0 opacity-20 z-0 overflow-hidden">
              {[...Array(isMobile ? 3 : 10)].map((_, i) => (
                <motion.div
                  key={i}
                  className="absolute rounded-full bg-primary-300"
                  style={{
                    width: Math.random() * 8 + 3 + 'px',
                    height: Math.random() * 8 + 3 + 'px',
                    left: Math.random() * 100 + '%',
                    top: Math.random() * 100 + '%',
                  }}
                  animate={{
                    y: [0, isMobile ? -35 : -70, 0],
                    x: [0, Math.random() * (isMobile ? 20 : 40) - (isMobile ? 10 : 20), 0],
                    opacity: [0, 0.8, 0],
                  }}
                  transition={{
                    duration: Math.random() * (isMobile ? 6 : 8) + (isMobile ? 4 : 6),
                    repeat: Infinity,
                    ease: "easeInOut",
                    delay: Math.random() * 5,
                  }}
                />
              ))}
            </div>
          )}
          
          <div className="mx-auto max-w-2xl">
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
              viewport={{ once: true }}
            >
              <h2 className="text-3xl font-bold tracking-tight text-primary-300 sm:text-4xl font-display">
                Prêt à trouver votre résidence idéale ?
              </h2>
              <p className="mt-6 text-lg leading-8 text-primary-100">
                Rejoignez ChapeChape Residence aujourd'hui et découvrez comment nous pouvons vous aider à trouver la résidence parfaite ou à gérer efficacement vos propriétés.
              </p>
              <div className="mt-10 flex items-center justify-center gap-x-6">
                <Link
                  to="/apps"
                  className="rounded-md bg-primary-300 px-3.5 py-2.5 text-sm font-semibold text-secondary-900 shadow-gold hover:bg-primary-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-300 relative overflow-hidden group"
                >
                  <span className="relative z-10">Télécharger l'application</span>
                  <motion.span 
                    className="absolute inset-0 bg-primary-400 z-0"
                    initial={{ x: '-100%' }}
                    whileHover={{ x: 0 }}
                    transition={{ duration: 0.3, ease: "easeInOut" }}
                  />
                </Link>
                <Link to="/about" className="text-sm font-semibold leading-6 text-primary-300 group relative">
                  En savoir plus 
                  <motion.span 
                    className="inline-block ml-1"
                    initial={{ x: 0 }}
                    whileHover={{ x: 5 }}
                    transition={{ duration: 0.2 }}
                  >
                    →
                  </motion.span>
                </Link>
              </div>
            </motion.div>
          </div>
        </motion.div>
      </div>
    </div>
  )
}