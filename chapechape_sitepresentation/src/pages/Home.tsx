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
  
  const floatingHouseVariants = {
    initial: {
      y: 0,
      rotate: 0,
    },
    animate: {
      y: [0, -15, 0],
      rotate: [0, 1, 0],
      transition: {
        duration: 6,
        repeat: Infinity,
        repeatType: "reverse" as const,
        ease: "easeInOut"
      }
    }
  }

  return (
    <div className="bg-secondary-50">
      {/* Hero section avec effets parallaxe et animations avancées */}
      <div 
        ref={heroRef}
        className="relative isolate overflow-hidden bg-gradient-to-br from-secondary-900 via-secondary-800 to-secondary-900"
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

        {/* Particules dorées flottantes */}
        <div className="absolute inset-0 opacity-30 z-0 overflow-hidden">
          {[...Array(15)].map((_, i) => (
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
                y: [0, -100, 0],
                x: [0, Math.random() * 50 - 25, 0],
                opacity: [0, 0.7, 0],
              }}
              transition={{
                duration: Math.random() * 10 + 10,
                repeat: Infinity,
                ease: "easeInOut",
                delay: Math.random() * 5,
              }}
            />
          ))}
        </div>
        
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
                  <motion.div variants={itemVariants}>
                    <h1 className="mt-10 text-4xl font-bold tracking-tight text-primary-300 sm:text-6xl font-display">
                      ChapeChape Residence
                    </h1>
                  </motion.div>
                  <motion.div variants={itemVariants}>
                    <p className="mt-6 text-lg leading-8 text-primary-100">
                      Votre partenaire de confiance pour trouver la résidence parfaite. Nous connectons les propriétaires et les locataires pour créer des expériences de vie exceptionnelles.
                    </p>
                  </motion.div>
                  <motion.div
                    variants={itemVariants}
                    className="mt-10 flex items-center gap-x-6"
                  >
                    <Link
                      to="/apps"
                      className="rounded-md bg-primary-300 px-3.5 py-2.5 text-sm font-semibold text-secondary-900 shadow-gold hover:bg-primary-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-300 relative overflow-hidden group"
                    >
                      <span className="relative z-10">Découvrir nos applications</span>
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
                  </motion.div>
                </motion.div>
              </div>
            </div>
          </motion.div>
          <motion.div 
            style={{ scale }}
            className="mt-20 sm:mt-24 md:mx-auto md:max-w-2xl lg:mx-0 lg:mt-0 lg:w-screen z-10"
          >
            <motion.div
              variants={floatingHouseVariants}
              initial="initial"
              animate="animate"
              className="relative h-[20rem] sm:h-[24rem] lg:h-[32rem] w-full rounded-2xl bg-secondary-900 shadow-xl shadow-primary-300/10 ring-1 ring-primary-300/10 overflow-hidden"
            >
              <div className="absolute inset-0 flex items-center justify-center">
                <motion.img 
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 0.8, scale: 1.5 }}
                  transition={{ duration: 1, delay: 0.5 }}
                  src="/assets/logo.png"
                  alt="ChapeChape Residence"
                  className="h-24 w-auto object-contain"
                />
              </div>
              <motion.div 
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ duration: 2 }}
                className="absolute inset-0 bg-gradient-to-br from-primary-300/10 via-transparent to-primary-300/5"
              />
            </motion.div>
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
          
          {/* Particules dorées en arrière-plan */}
          <div className="absolute inset-0 opacity-20 z-0 overflow-hidden">
            {[...Array(10)].map((_, i) => (
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
                  y: [0, -70, 0],
                  x: [0, Math.random() * 40 - 20, 0],
                  opacity: [0, 0.8, 0],
                }}
                transition={{
                  duration: Math.random() * 8 + 6,
                  repeat: Infinity,
                  ease: "easeInOut",
                  delay: Math.random() * 5,
                }}
              />
            ))}
          </div>
          
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