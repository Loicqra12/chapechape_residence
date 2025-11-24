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
import Features from '../components/home/Features'
import SEOHead from '../components/seo/SEOHead'
import ParallaxSection from '../components/ui/ParallaxSection'
import { useRef } from 'react'
import { useReducedMotion, createOptimizedVariants, optimizeTransition } from '../hooks/useReducedMotion'



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
      <SEOHead
        title="Accueil"
        description="ChapeChape Residence révolutionne l'expérience de location avec une plateforme intelligente qui connecte propriétaires et locataires en toute simplicité."
        url="https://presentation.chapechaperesidence.com/"
      />
      {/* Hero section avec effets parallaxe et animations avancées - Style Stripe */}
      <div
        ref={heroRef}
        className="relative isolate overflow-hidden min-h-screen flex items-center"
      >
        {/* Cinematic Background Image with Ken Burns Effect */}
        <div className="absolute inset-0 -z-20 overflow-hidden">
          <motion.div
            initial={{ scale: 1 }}
            animate={{ scale: 1.1 }}
            transition={{
              duration: 20,
              repeat: Infinity,
              repeatType: "reverse",
              ease: "linear"
            }}
            className="absolute inset-0 bg-cover bg-center"
            style={{
              backgroundImage: "url('/assets/images/hero-luxury.png')",
            }}
          />
          {/* Cinematic Overlay */}
          <div className="absolute inset-0 bg-gradient-to-r from-secondary-900/90 via-secondary-900/70 to-secondary-900/30" />
          <div className="absolute inset-0 bg-gradient-to-t from-secondary-900 via-transparent to-secondary-900/50" />
        </div>



        {/* Particules dorées flottantes - Optimisées pour mobile */}
        {!shouldReduceMotion && (
          <div className="absolute inset-0 opacity-30 z-0 overflow-hidden pointer-events-none">
            {[...Array(isMobile ? 5 : 15)].map((_, i) => (
              <motion.div
                key={i}
                className="absolute rounded-full bg-primary-300 blur-[1px]"
                style={{
                  width: Math.random() * 6 + 2 + 'px',
                  height: Math.random() * 6 + 2 + 'px',
                  left: Math.random() * 100 + '%',
                  top: Math.random() * 100 + '%',
                }}
                animate={{
                  y: [0, isMobile ? -50 : -100, 0],
                  x: [0, Math.random() * (isMobile ? 25 : 50) - (isMobile ? 12.5 : 25), 0],
                  opacity: [0, 0.5, 0],
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
                  {/* Badge Premium - Style Luxe & Minimaliste */}
                  <motion.div variants={itemVariants}>
                    <div className="inline-flex items-center gap-3 px-5 py-2.5 rounded-full bg-white/10 backdrop-blur-md border border-white/20 shadow-2xl mb-10 group hover:bg-white/15 transition-all duration-300 cursor-default">
                      <div className="relative flex h-2.5 w-2.5">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-accent-green opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-accent-green"></span>
                      </div>
                      <span className="text-sm font-medium text-white/90 tracking-wide uppercase text-[11px]">
                        Plateforme N°1 en Afrique de l'Ouest
                      </span>
                    </div>
                  </motion.div>

                  <motion.div variants={itemVariants} className="relative z-10">
                    <h1 className="text-5xl sm:text-6xl lg:text-7xl font-display font-bold text-white leading-[1.1] tracking-tight drop-shadow-2xl">
                      L'avenir de la
                      <br />
                      <span className="relative inline-block">
                        <span className="absolute -inset-1 bg-gradient-to-r from-primary-400/20 to-transparent blur-lg"></span>
                        <span className="relative bg-gradient-to-r from-primary-200 via-primary-100 to-white bg-clip-text text-transparent">
                          location immobilière
                        </span>
                      </span>
                      <br />
                      <span className="text-white/90 font-light italic">en Afrique</span>
                    </h1>
                  </motion.div>

                  <motion.div variants={itemVariants}>
                    <p className="mt-8 text-lg lg:text-xl leading-relaxed text-gray-200/90 max-w-lg font-light tracking-wide border-l-2 border-primary-400/30 pl-6">
                      ChapeChape Residence révolutionne l'expérience de location avec une plateforme intelligente qui connecte propriétaires et locataires en toute simplicité.
                    </p>
                  </motion.div>

                  <motion.div
                    variants={itemVariants}
                    className="mt-12 flex flex-col sm:flex-row gap-5 items-start"
                  >
                    {/* Bouton Principal - Or Premium */}
                    <motion.div
                      whileHover={{ scale: 1.02, translateY: -2 }}
                      whileTap={{ scale: 0.98 }}
                    >
                      <Link
                        to="/residences"
                        className="group relative inline-flex items-center gap-3 px-8 py-4 bg-gradient-to-r from-primary-400 to-primary-600 text-secondary-900 rounded-full font-bold text-base shadow-[0_0_20px_rgba(212,175,55,0.3)] hover:shadow-[0_0_30px_rgba(212,175,55,0.5)] transition-all duration-300 overflow-hidden"
                      >
                        <span className="absolute inset-0 bg-white/20 translate-y-full group-hover:translate-y-0 transition-transform duration-300 ease-out"></span>
                        <span className="relative z-10 uppercase tracking-wider text-sm">Explorer la collection</span>
                        <motion.svg
                          className="w-4 h-4 relative z-10"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                          animate={{ x: [0, 4, 0] }}
                          transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
                        >
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                        </motion.svg>
                      </Link>
                    </motion.div>

                    {/* Bouton Secondaire - Glassmorphism */}
                    <motion.div
                      whileHover={{ scale: 1.02, translateY: -2 }}
                      whileTap={{ scale: 0.98 }}
                    >
                      <Link
                        to="/about"
                        className="group inline-flex items-center gap-3 px-8 py-4 bg-white/5 backdrop-blur-sm text-white rounded-full font-medium text-base border border-white/20 hover:bg-white/10 hover:border-white/40 transition-all duration-300"
                      >
                        <span className="uppercase tracking-wider text-sm">Notre Vision</span>
                        <div className="w-8 h-[1px] bg-white/50 group-hover:w-12 transition-all duration-300"></div>
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
                              className={`text-xs px-1.5 py-0.5 lg:px-2 lg:py-1 rounded-full font-medium ${stat.positive
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
      <Features />

      {/* Parallax Section - Interior */}
      <ParallaxSection image="/assets/images/parallax-interior.png" height="60vh">
        <div className="text-center text-white px-4">
          <motion.h3
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            className="text-4xl md:text-6xl font-display font-bold mb-4 text-shadow-lg"
          >
            L'Élégance au Quotidien
          </motion.h3>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="text-xl md:text-2xl font-light text-primary-100"
          >
            Des espaces conçus pour votre confort absolu
          </motion.p>
        </div>
      </ParallaxSection>

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

      {/* Parallax Section - Pool */}
      <ParallaxSection image="/assets/images/parallax-pool.png" height="60vh">
        <div className="text-center text-white px-4">
          <motion.h3
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            className="text-4xl md:text-6xl font-display font-bold mb-4 text-shadow-lg"
          >
            Vivez l'Exceptionnel
          </motion.h3>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="text-xl md:text-2xl font-light text-primary-100"
          >
            Des vues imprenables sur Abidjan
          </motion.p>
        </div>
      </ParallaxSection>

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
      <div className="relative isolate mt-32 px-6 py-32 sm:mt-56 sm:px-8 lg:px-8">
        <div className="absolute inset-0 -z-10 overflow-hidden">
          <div className="absolute inset-0 bg-secondary-900" />
          <div className="absolute inset-0 bg-gradient-to-br from-primary-900/20 via-secondary-900 to-secondary-900" />
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 0.3 }}
            transition={{ duration: 1.5 }}
            className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-10 mix-blend-overlay"
          />
        </div>

        <div className="mx-auto max-w-2xl text-center relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            viewport={{ once: true }}
          >
            <h2 className="text-4xl font-bold tracking-tight text-white sm:text-5xl font-display mb-6">
              Prêt à vivre l'expérience <span className="text-primary-400">ChapeChape</span> ?
            </h2>
            <p className="mx-auto mt-6 max-w-xl text-lg leading-8 text-gray-300">
              Rejoignez des milliers d'utilisateurs satisfaits et découvrez une nouvelle façon de vivre l'immobilier en Afrique.
            </p>
            <div className="mt-10 flex items-center justify-center gap-x-6">
              <Link
                to="/apps"
                className="btn-primary"
              >
                Télécharger l'application
              </Link>
              <Link to="/contact" className="text-sm font-semibold leading-6 text-white hover:text-primary-300 transition-colors duration-300 flex items-center gap-2 group">
                Nous contacter
                <span aria-hidden="true" className="group-hover:translate-x-1 transition-transform">→</span>
              </Link>
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  )
}