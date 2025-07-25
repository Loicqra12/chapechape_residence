import { useRef, useState } from 'react'
import { motion, useScroll, useTransform, useInView } from 'framer-motion'

const steps = [
  {
    id: 1,
    title: "Téléchargez l'application",
    description: "Installez notre application client depuis l'App Store ou Google Play et créez votre compte en quelques minutes.",
    icon: "download"
  },
  {
    id: 2,
    title: "Recherchez votre résidence idéale",
    description: "Utilisez nos filtres avancés pour trouver la résidence qui correspond parfaitement à vos besoins et à votre budget.",
    icon: "search"
  },
  {
    id: 3,
    title: "Réservez et payez en toute sécurité",
    description: "Effectuez votre réservation et payez via notre plateforme sécurisée qui propose plusieurs méthodes de paiement adaptées au marché africain.",
    icon: "secure"
  },
  {
    id: 4,
    title: "Emménagez dans votre nouvelle résidence",
    description: "Recevez les instructions d'accès et profitez de votre nouvelle résidence en toute quiétude avec notre support disponible 24/7.",
    icon: "home"
  }
]

const Process = () => {
  const containerRef = useRef(null)
  const [hoveredStep, setHoveredStep] = useState<number | null>(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"]
  })
  
  // Effet de parallaxe pour l'arrière-plan
  const y = useTransform(scrollYProgress, [0, 1], [50, -50])
  
  // Animation pour la ligne de timeline dorée progressive
  const timelineProgress = useTransform(scrollYProgress, [0.2, 0.8], [0, 1])
  const timelineOpacity = useTransform(scrollYProgress, [0.1, 0.2], [0, 1])
  
  // Variants pour les animations premium - Style Stripe
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.2,
        delayChildren: 0.1
      }
    }
  }
  
  // Variants pour les cartes glassmorphism
  const cardVariants = {
    hidden: { 
      opacity: 0,
      y: 60,
      scale: 0.9,
      rotateX: 15
    },
    visible: (index: number) => ({
      opacity: 1,
      y: 0,
      scale: 1,
      rotateX: 0,
      transition: {
        type: "spring",
        stiffness: 100,
        damping: 15,
        delay: index * 0.15
      }
    }),
    hover: {
      y: -12,
      scale: 1.02,
      rotateX: -3,
      transition: {
        duration: 0.3,
        ease: "easeOut"
      }
    }
  }
  
  // Variants pour les icônes animées
  const iconVariants = {
    hidden: { 
      scale: 0,
      rotate: -180,
      opacity: 0
    },
    visible: {
      scale: 1,
      rotate: 0,
      opacity: 1,
      transition: {
        type: "spring",
        stiffness: 200,
        damping: 15,
        delay: 0.2
      }
    },
    hover: {
      scale: 1.3,
      rotate: 360,
      transition: {
        duration: 0.8,
        ease: "easeInOut"
      }
    },
    pulse: {
      scale: [1, 1.1, 1],
      boxShadow: [
        "0 0 0 0 rgba(212, 175, 55, 0.4)",
        "0 0 0 10px rgba(212, 175, 55, 0)",
        "0 0 0 0 rgba(212, 175, 55, 0)"
      ],
      transition: {
        duration: 2,
        repeat: Infinity,
        ease: "easeInOut"
      }
    }
  }
  
  // Variants pour les textes avec stagger
  const textVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: 0.6,
        ease: "easeOut"
      }
    }
  }
  
  return (
    <section 
      ref={containerRef}
      className="relative py-32 overflow-hidden bg-gradient-to-br from-secondary-900 via-secondary-800 to-secondary-900 dark:from-secondary-950 dark:via-secondary-900 dark:to-secondary-950"
    >
      {/* Background géométrique animé */}
      <motion.div 
        className="absolute inset-0 opacity-5"
        style={{ y }}
      >
        <div className="absolute inset-0 bg-[url('data:image/svg+xml,%3Csvg%20width%3D%2260%22%20height%3D%2260%22%20viewBox%3D%220%200%2060%2060%22%20xmlns%3D%22http%3A//www.w3.org/2000/svg%22%3E%3Cg%20fill%3D%22none%22%20fill-rule%3D%22evenodd%22%3E%3Cg%20fill%3D%22%23D4AF37%22%20fill-opacity%3D%220.1%22%3E%3Cpath%20d%3D%22M36%2034v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6%2034v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6%204V0H4v4H0v2h4v4h2V6h4V4H6z%22/%3E%3C/g%3E%3C/g%3E%3C/svg%3E')] bg-repeat"></div>
      </motion.div>
      
      {/* Particules flottantes dorées */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        {[...Array(8)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-1 h-1 bg-primary-400 rounded-full"
            style={{
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 100}%`,
            }}
            animate={{
              y: [-20, -100],
              opacity: [0, 1, 0],
              scale: [0, 1, 0],
            }}
            transition={{
              duration: Math.random() * 3 + 2,
              repeat: Infinity,
              delay: Math.random() * 2,
              ease: "easeInOut"
            }}
          />
        ))}
      </div>
      
      <div className="container-custom relative z-10">
        {/* Header Section Premium */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8 }}
          className="text-center mb-20"
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.1 }}
            className="inline-flex items-center px-4 py-2 bg-primary-400/10 border border-primary-400/20 rounded-full mb-6"
          >
            <span className="text-primary-400 text-sm font-medium tracking-wide uppercase">Processus Simple</span>
          </motion.div>
          
          <motion.h2 
            className="text-5xl md:text-6xl font-bold bg-gradient-to-r from-white via-primary-200 to-primary-400 bg-clip-text text-transparent mb-6"
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8, delay: 0.2 }}
          >
            Comment ça marche ?
          </motion.h2>
          
          <motion.p 
            className="text-xl text-white/70 max-w-3xl mx-auto leading-relaxed"
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.4 }}
          >
            Découvrez notre processus simple et sécurisé pour trouver et réserver votre résidence idéale en Afrique de l'Ouest.
          </motion.p>
        </motion.div>

        {/* Timeline verticale dorée animée - Desktop */}
        <div className="hidden lg:block absolute left-1/2 top-[16rem] bottom-32 w-1 -translate-x-1/2 z-0">
          <div className="absolute inset-0 bg-gradient-to-b from-primary-400/20 via-primary-400/40 to-primary-400/20 rounded-full"></div>
          <motion.div 
            className="absolute top-0 left-0 w-full bg-gradient-to-b from-primary-400 to-primary-300 rounded-full origin-top"
            style={{ scaleY: timelineProgress, opacity: timelineOpacity }}
          />
          
          {/* Particules dorées le long de la timeline */}
          {[...Array(6)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute w-2 h-2 bg-primary-400 rounded-full -left-0.5"
              style={{ top: `${(i + 1) * 16}%` }}
              animate={{
                scale: [1, 1.5, 1],
                opacity: [0.5, 1, 0.5],
                boxShadow: [
                  "0 0 0 0 rgba(212, 175, 55, 0.4)",
                  "0 0 10px 2px rgba(212, 175, 55, 0.2)",
                  "0 0 0 0 rgba(212, 175, 55, 0.4)"
                ]
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
                delay: i * 0.3,
                ease: "easeInOut"
              }}
            />
          ))}
        </div>

        {/* Timeline horizontale mobile - Carousel */}
        <div className="lg:hidden mb-12">
          <div className="relative">
            {/* Progress bar horizontale */}
            <div className="absolute top-1/2 left-0 right-0 h-1 bg-primary-400/20 rounded-full -translate-y-1/2 z-0">
              <motion.div 
                className="absolute top-0 left-0 h-full bg-gradient-to-r from-primary-400 to-primary-300 rounded-full origin-left"
                style={{ scaleX: timelineProgress, opacity: timelineOpacity }}
              />
            </div>
            
            {/* Dots indicateurs */}
            <div className="flex justify-between items-center relative z-10">
              {steps.map((_, index) => (
                <motion.div
                  key={index}
                  className="w-4 h-4 rounded-full bg-primary-400 border-2 border-secondary-900 shadow-lg"
                  animate={{
                    scale: [1, 1.2, 1],
                    boxShadow: [
                      "0 0 0 0 rgba(212, 175, 55, 0.4)",
                      "0 0 8px 2px rgba(212, 175, 55, 0.3)",
                      "0 0 0 0 rgba(212, 175, 55, 0.4)"
                    ]
                  }}
                  transition={{
                    duration: 1.5,
                    repeat: Infinity,
                    delay: index * 0.3,
                    ease: "easeInOut"
                  }}
                />
              ))}
            </div>
          </div>
        </div>

        {/* Cartes glassmorphism premium - Desktop layout */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
          className="hidden lg:block relative max-w-4xl mx-auto space-y-16"
        >
          {steps.map((step, index) => (
            <motion.div
              key={step.id}
              custom={index}
              variants={cardVariants}
              onHoverStart={() => setHoveredStep(step.id)}
              onHoverEnd={() => setHoveredStep(null)}
              className="group relative"
            >
              {/* Carte glassmorphism premium */}
              <motion.div 
                className={`relative flex flex-col lg:flex-row items-center gap-8 p-8 rounded-2xl ${
                  index % 2 === 0 ? 'lg:text-left' : 'lg:flex-row-reverse lg:text-right'
                } bg-white/5 backdrop-blur-xl border border-white/10 shadow-2xl hover:shadow-primary-400/20 transition-all duration-500 cursor-pointer overflow-hidden`}
                whileHover="hover"
              >
                {/* Glow effect premium */}
                <motion.div 
                  className="absolute -inset-4 bg-gradient-to-r from-primary-400/10 via-primary-300/20 to-primary-400/10 rounded-3xl blur-xl opacity-0 group-hover:opacity-100 transition-opacity duration-700"
                />
                
                {/* Background pattern animé */}
                <motion.div 
                  className="absolute top-0 right-0 w-32 h-32 opacity-5"
                  animate={{
                    rotate: [0, 360],
                    scale: [1, 1.1, 1]
                  }}
                  transition={{
                    duration: 20,
                    repeat: Infinity,
                    ease: "linear"
                  }}
                >
                  <div className="w-full h-full bg-gradient-to-br from-primary-400 to-transparent rounded-full"></div>
                </motion.div>
                
                {/* Icône premium animée */}
                <motion.div
                  className="relative w-24 h-24 flex-shrink-0 rounded-2xl bg-gradient-to-br from-primary-400/20 via-primary-300/30 to-primary-400/20 backdrop-blur-sm border border-primary-400/30 flex items-center justify-center shadow-2xl"
                  variants={iconVariants}
                  animate={hoveredStep === step.id ? "pulse" : "visible"}
                  whileHover="hover"
                >
                  {/* Effet de brillance */}
                  <motion.div 
                    className="absolute inset-0 rounded-2xl bg-gradient-to-br from-white/20 via-transparent to-transparent"
                    animate={{
                      opacity: [0.3, 0.6, 0.3],
                      scale: [1, 1.05, 1]
                    }}
                    transition={{
                      duration: 3,
                      repeat: Infinity,
                      ease: "easeInOut"
                    }}
                  />
                  
                  {/* Numéro d'étape */}
                  <motion.div 
                    className="absolute -top-2 -right-2 w-8 h-8 bg-primary-400 rounded-full flex items-center justify-center text-secondary-900 text-sm font-bold shadow-lg"
                    animate={{
                      scale: [1, 1.1, 1],
                      boxShadow: [
                        "0 0 0 0 rgba(212, 175, 55, 0.4)",
                        "0 0 0 8px rgba(212, 175, 55, 0)",
                        "0 0 0 0 rgba(212, 175, 55, 0.4)"
                      ]
                    }}
                    transition={{
                      duration: 2,
                      repeat: Infinity,
                      ease: "easeInOut"
                    }}
                  >
                    {step.id}
                  </motion.div>
                  
                  {/* Icône SVG */}
                  <motion.div 
                    className="relative text-primary-300 z-10"
                    variants={iconVariants}
                  >
                    {step.icon === "download" && (
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-8 h-8">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
                      </svg>
                    )}
                    {step.icon === "search" && (
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-8 h-8">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
                      </svg>
                    )}
                    {step.icon === "secure" && (
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-8 h-8">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12c0 1.268-.63 2.39-1.593 3.068a3.745 3.745 0 01-1.043 3.296 3.745 3.745 0 01-3.296 1.043A3.745 3.745 0 0112 21c-1.268 0-2.39-.63-3.068-1.593a3.746 3.746 0 01-3.296-1.043 3.745 3.745 0 01-1.043-3.296A3.745 3.745 0 013 12c0-1.268.63-2.39 1.593-3.068a3.745 3.745 0 011.043-3.296 3.746 3.746 0 013.296-1.043A3.746 3.746 0 0112 3c1.268 0 2.39.63 3.068 1.593a3.746 3.746 0 013.296 1.043 3.746 3.746 0 011.043 3.296A3.745 3.745 0 0121 12z" />
                      </svg>
                    )}
                    {step.icon === "home" && (
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-8 h-8">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 21v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21m0 0h4.5V3.545M12.75 21h7.5V10.75M2.25 21h1.5m18 0h-18M2.25 9l4.5-1.636M18.75 3l-1.5.545m0 6.205l3 1m1.5.5l-1.5-.5M6.75 7.364V3h-3v18m3-13.636l10.5-3.819" />
                      </svg>
                    )}
                  </motion.div>
                </motion.div>
                
                {/* Contenu textuel avec micro-animations */}
                <div className="flex-1 space-y-4">
                  <motion.h3 
                    className="text-2xl font-bold bg-gradient-to-r from-white to-primary-200 bg-clip-text text-transparent"
                    variants={textVariants}
                    initial="hidden"
                    whileInView="visible"
                    viewport={{ once: true }}
                    transition={{ delay: 0.2 }}
                  >
                    {step.title}
                  </motion.h3>
                  
                  <motion.p 
                    className="text-white/70 leading-relaxed text-lg"
                    variants={textVariants}
                    initial="hidden"
                    whileInView="visible"
                    viewport={{ once: true }}
                    transition={{ delay: 0.3 }}
                  >
                    {step.description}
                  </motion.p>
                  
                  {/* Progress indicator pour mobile */}
                  <motion.div 
                    className="lg:hidden w-full h-1 bg-white/10 rounded-full overflow-hidden mt-6"
                    initial={{ opacity: 0 }}
                    whileInView={{ opacity: 1 }}
                    viewport={{ once: true }}
                    transition={{ delay: 0.4 }}
                  >
                    <motion.div 
                      className="h-full bg-gradient-to-r from-primary-400 to-primary-300 rounded-full"
                      initial={{ width: 0 }}
                      whileInView={{ width: `${((index + 1) / steps.length) * 100}%` }}
                      viewport={{ once: true }}
                      transition={{ duration: 1, delay: 0.5, ease: "easeOut" }}
                    />
                  </motion.div>
                </div>
                
                {/* Connecteur pour mobile */}
                {index < steps.length - 1 && (
                  <motion.div 
                    className="lg:hidden absolute -bottom-8 left-1/2 transform -translate-x-1/2 w-1 h-16 bg-gradient-to-b from-primary-400 via-primary-300 to-transparent rounded-full"
                    initial={{ scaleY: 0 }}
                    whileInView={{ scaleY: 1 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.8, delay: 0.6 }}
                  />
                )}
              </motion.div>
            </motion.div>
          ))}
        </motion.div>
        
        {/* Version mobile - Carousel cards */}
        <div className="lg:hidden">
          <motion.div
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-50px" }}
            className="space-y-8"
          >
            {steps.map((step, index) => (
              <motion.div
                key={`mobile-${step.id}`}
                custom={index}
                variants={cardVariants}
                className="group relative"
              >
                {/* Carte mobile simplifiée */}
                <motion.div 
                  className="relative flex flex-col items-center text-center gap-6 p-6 rounded-2xl bg-white/5 backdrop-blur-xl border border-white/10 shadow-xl transition-all duration-500 overflow-hidden"
                  whileHover={{ scale: 1.02, y: -5 }}
                >
                  {/* Glow effect mobile */}
                  <motion.div 
                    className="absolute -inset-2 bg-gradient-to-r from-primary-400/10 via-primary-300/20 to-primary-400/10 rounded-3xl blur-xl opacity-0 group-hover:opacity-100 transition-opacity duration-700"
                  />
                  
                  {/* Icône mobile */}
                  <motion.div
                    className="relative w-16 h-16 flex-shrink-0 rounded-xl bg-gradient-to-br from-primary-400/20 via-primary-300/30 to-primary-400/20 backdrop-blur-sm border border-primary-400/30 flex items-center justify-center shadow-xl"
                    variants={iconVariants}
                    animate="visible"
                    whileHover="hover"
                  >
                    {/* Numéro d'étape mobile */}
                    <motion.span 
                      className="text-2xl font-bold bg-gradient-to-r from-primary-300 to-primary-400 bg-clip-text text-transparent"
                      animate={{
                        scale: [1, 1.1, 1],
                        textShadow: [
                          "0 0 0 rgba(212, 175, 55, 0.5)",
                          "0 0 20px rgba(212, 175, 55, 0.8)",
                          "0 0 0 rgba(212, 175, 55, 0.5)"
                        ]
                      }}
                      transition={{
                        duration: 2,
                        repeat: Infinity,
                        ease: "easeInOut"
                      }}
                    >
                      {step.id}
                    </motion.span>
                  </motion.div>
                  
                  {/* Contenu mobile */}
                  <div className="space-y-3">
                    <motion.h3 
                      className="text-xl font-bold bg-gradient-to-r from-white to-primary-200 bg-clip-text text-transparent"
                      variants={textVariants}
                      initial="hidden"
                      whileInView="visible"
                      viewport={{ once: true }}
                    >
                      {step.title}
                    </motion.h3>
                    
                    <motion.p 
                      className="text-white/70 leading-relaxed text-sm"
                      variants={textVariants}
                      initial="hidden"
                      whileInView="visible"
                      viewport={{ once: true }}
                      transition={{ delay: 0.1 }}
                    >
                      {step.description}
                    </motion.p>
                  </div>
                  
                  {/* Progress indicator mobile */}
                  <motion.div 
                    className="w-full h-1 bg-white/10 rounded-full overflow-hidden"
                    initial={{ opacity: 0 }}
                    whileInView={{ opacity: 1 }}
                    viewport={{ once: true }}
                    transition={{ delay: 0.2 }}
                  >
                    <motion.div 
                      className="h-full bg-gradient-to-r from-primary-400 to-primary-300 rounded-full"
                      initial={{ width: 0 }}
                      whileInView={{ width: `${((index + 1) / steps.length) * 100}%` }}
                      viewport={{ once: true }}
                      transition={{ duration: 1, delay: 0.3, ease: "easeOut" }}
                    />
                  </motion.div>
                </motion.div>
                
                {/* Connecteur mobile */}
                {index < steps.length - 1 && (
                  <motion.div 
                    className="flex justify-center py-4"
                    initial={{ opacity: 0 }}
                    whileInView={{ opacity: 1 }}
                    viewport={{ once: true }}
                    transition={{ delay: 0.4 }}
                  >
                    <motion.div 
                      className="w-1 h-8 bg-gradient-to-b from-primary-400 to-primary-300 rounded-full"
                      initial={{ scaleY: 0 }}
                      whileInView={{ scaleY: 1 }}
                      viewport={{ once: true }}
                      transition={{ duration: 0.6, delay: 0.5 }}
                    />
                  </motion.div>
                )}
              </motion.div>
            ))}
          </motion.div>
        </div>
        
        {/* CTA Premium avec effet ripple */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8, delay: 0.6 }}
          className="flex justify-center mt-20"
        >
          <motion.a 
            href="/apps" 
            className="group relative inline-flex items-center gap-3 px-10 py-5 bg-gradient-to-r from-primary-400 via-primary-300 to-primary-400 text-secondary-900 rounded-2xl font-bold text-lg shadow-2xl overflow-hidden transition-all duration-500"
            whileHover={{ 
              scale: 1.05,
              boxShadow: "0 25px 50px rgba(212, 175, 55, 0.4)",
              background: "linear-gradient(135deg, #F4D03F, #D4AF37, #F4D03F)"
            }}
            whileTap={{ scale: 0.95 }}
            animate={{
              boxShadow: [
                "0 15px 30px rgba(212, 175, 55, 0.2)",
                "0 20px 40px rgba(212, 175, 55, 0.3)",
                "0 15px 30px rgba(212, 175, 55, 0.2)"
              ]
            }}
            transition={{
              boxShadow: { duration: 3, repeat: Infinity, ease: "easeInOut" }
            }}
          >
            {/* Background gradient animé */}
            <motion.div 
              className="absolute inset-0 bg-gradient-to-r from-primary-300 via-primary-400 to-primary-300 opacity-0 group-hover:opacity-100 transition-opacity duration-500"
            />
            
            {/* Texte principal */}
            <motion.span 
              className="relative z-10 font-bold"
              animate={{
                textShadow: [
                  "0 0 0 rgba(0,0,0,0.3)",
                  "0 2px 4px rgba(0,0,0,0.5)",
                  "0 0 0 rgba(0,0,0,0.3)"
                ]
              }}
              transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
            >
              Commencer maintenant
            </motion.span>
            
            {/* Icône flèche animée */}
            <motion.div 
              className="relative z-10 w-8 h-8 bg-secondary-900/20 rounded-full flex items-center justify-center backdrop-blur-sm"
              whileHover={{ 
                x: 8,
                rotate: 360,
                scale: 1.1
              }}
              transition={{ duration: 0.4, ease: "easeOut" }}
            >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2.5} stroke="currentColor" className="w-4 h-4">
                <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
              </svg>
            </motion.div>
            
            {/* Effet ripple multiple */}
            <motion.div 
              className="absolute inset-0 rounded-2xl bg-white/20"
              animate={{
                scale: [1, 1.1, 1],
                opacity: [0.5, 0.8, 0.5]
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
                ease: "easeInOut"
              }}
            />
          </motion.a>
        </motion.div>
      </div>
    </section>
  )
}

export default Process 