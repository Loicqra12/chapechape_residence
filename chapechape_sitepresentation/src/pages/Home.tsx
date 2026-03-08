import { Link } from 'react-router-dom'
import { motion, useScroll, useTransform } from 'framer-motion'
import { ArrowRightIcon } from '@heroicons/react/24/outline'
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
                  {/* Badge — typo site : font-body, uppercase, primary */}
                  <motion.div variants={itemVariants}>
                    <div className="inline-flex items-center gap-2.5 px-4 py-2 rounded-full bg-white/10 backdrop-blur-md border border-primary-400/30 mb-8 cursor-default">
                      <span className="relative flex h-2 w-2">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary-400 opacity-75" />
                        <span className="relative inline-flex rounded-full h-2 w-2 bg-primary-400" />
                      </span>
                      <span className="font-body text-xs font-semibold uppercase tracking-widest text-primary-200">
                        Plateforme N°1 en Afrique de l'Ouest
                      </span>
                    </div>
                  </motion.div>

                  {/* Titre — font-display, hiérarchie claire */}
                  <motion.div variants={itemVariants} className="relative z-10">
                    <h1 className="text-4xl sm:text-5xl lg:text-6xl xl:text-7xl font-display font-bold text-white leading-[1.1] tracking-tight">
                      L'avenir de la
                      <br />
                      <span className="bg-gradient-to-r from-primary-200 via-primary-100 to-white bg-clip-text text-transparent">
                        location immobilière
                      </span>
                      <br />
                      <span className="text-white/90 font-light italic">en Afrique</span>
                    </h1>
                  </motion.div>

                  {/* Une seule phrase + un seul CTA */}
                  <motion.div variants={itemVariants}>
                    <p className="mt-6 text-lg text-white/80 max-w-md font-body font-normal leading-relaxed border-l-2 border-primary-500/50 pl-5">
                      Trouvez et réservez votre résidence idéale en toute simplicité.
                    </p>
                  </motion.div>

                  <motion.div variants={itemVariants} className="mt-10">
                    <Link
                      to="/residences"
                      className="btn-primary group inline-flex items-center gap-2.5 px-8 py-4 text-secondary-900"
                    >
                      <span className="font-body font-bold uppercase tracking-wider text-sm">Trouver un hébergement</span>
                      <ArrowRightIcon className="w-5 h-5 shrink-0 transition-transform group-hover:translate-x-1" strokeWidth={2.5} />
                    </Link>
                  </motion.div>
                </motion.div>
              </div>
            </div>
          </motion.div>
          <motion.div
            style={{ scale }}
            className="relative mt-12 sm:mt-16 lg:mt-0 lg:flex lg:items-center lg:justify-center lg:pl-8 z-10 w-full"
          >
            {/* Un seul mockup : App Client — typo et couleurs site */}
            <div className="relative w-full max-w-sm mx-auto lg:max-w-none flex flex-col items-center min-h-[320px] sm:min-h-[400px] lg:min-h-[480px]">
              <motion.span
                initial={{ opacity: 0, y: -8 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, delay: 0.25 }}
                className="font-body text-xs font-semibold uppercase tracking-widest text-primary-400 mb-3"
              >
                Application Client
              </motion.span>
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, ease: "easeOut", delay: 0.3 }}
                className="relative w-[200px] h-[400px] sm:w-[240px] sm:h-[480px] lg:w-[280px] lg:h-[560px] rounded-[2.5rem] bg-secondary-800 p-2.5 border border-white/10 overflow-hidden shadow-2xl"
                style={{ boxShadow: '0 24px 48px -12px rgba(0,0,0,0.4), 0 0 0 1px rgba(255,255,255,0.05)' }}
              >
                <div className="absolute top-4 left-1/2 -translate-x-1/2 w-20 h-6 bg-secondary-900 rounded-full z-10" aria-hidden />
                <img
                  src="/assets/apps/hero/client-hero.png"
                  alt="Application ChapeChape Residence — trouvez votre résidence"
                  className="w-full h-full object-cover object-top rounded-[1.75rem]"
                />
              </motion.div>
            </div>
          </motion.div>
        </div>
      </div>

      {/* Feature section : inclut "Ils nous font confiance" + villes (un seul bloc) */}
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
            Tous les espaces, tous les budgets
          </motion.h3>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="text-xl md:text-2xl font-light text-primary-100"
          >
            Court ou longue durée, classique ou insolite
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
            Réservez en toute simplicité
          </motion.h3>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="text-xl md:text-2xl font-light text-primary-100"
          >
            Partout en Afrique de l'Ouest
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