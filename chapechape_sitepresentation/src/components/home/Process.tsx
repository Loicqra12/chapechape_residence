import { useRef } from 'react'
import { motion, useScroll, useTransform } from 'framer-motion'

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
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"]
  })
  
  // Effet de parallaxe pour l'arrière-plan
  const y = useTransform(scrollYProgress, [0, 1], [50, -50])
  
  // Animation pour la ligne de connexion
  const pathLength = useTransform(scrollYProgress, [0.1, 0.5], [0.1, 1])
  const pathOpacity = useTransform(scrollYProgress, [0.1, 0.15], [0, 1])
  
  // Variants pour les animations des étapes
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.2,
        delayChildren: 0.3
      }
    }
  }
  
  const itemVariants = {
    hidden: { opacity: 0, y: 50 },
    visible: (index: number) => ({
      opacity: 1,
      y: 0,
      transition: {
        type: "spring",
        stiffness: 80,
        damping: 15,
        delay: index * 0.1
      }
    })
  }
  
  // Animation pour les icônes
  const iconVariants = {
    hidden: { scale: 0.5, opacity: 0 },
    visible: { 
      scale: 1, 
      opacity: 1,
      transition: {
        type: "spring",
        stiffness: 200,
        damping: 20
      }
    },
    hover: { 
      scale: 1.1, 
      rotate: [0, 10, -10, 0],
      transition: { 
        duration: 0.7 
      }
    }
  }
  
  return (
    <section 
      ref={containerRef}
      className="relative py-24 overflow-hidden"
    >
      {/* Arrière-plan avec dégradé */}
      <motion.div 
        className="absolute inset-0 bg-gradient-to-r from-secondary-800 to-secondary-900 -z-10"
        style={{ y }}
      />
      
      {/* Motif en filigrane */}
      <div className="absolute inset-0 bg-[url('/assets/pattern-dot.svg')] bg-repeat opacity-5 -z-5"></div>
      
      {/* Rayons dorés */}
      <motion.div 
        className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,#D4AF37,transparent_80%)] opacity-10 -z-5"
        animate={{
          opacity: [0.05, 0.1, 0.05],
          scale: [1, 1.05, 1],
        }}
        transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
      />
      
      <div className="container-custom relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-20"
        >
          <h2 className="text-3xl font-bold text-primary-300 mb-4 font-display">Comment ça fonctionne</h2>
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-primary-100 max-w-2xl mx-auto"
          >
            Un processus simple et efficace pour trouver la résidence de vos rêves en quelques étapes.
          </motion.p>
          
          {/* Ligne décorative dorée */}
          <motion.div 
            initial={{ width: 0 }}
            whileInView={{ width: "80px" }}
            viewport={{ once: true }}
            transition={{ duration: 0.8, delay: 0.4 }}
            className="h-1 bg-primary-300 mx-auto mt-6"
          />
        </motion.div>

        {/* Ligne de connexion animée pour desktop */}
        <div className="hidden lg:block absolute left-1/2 top-[12rem] bottom-20 w-0.5 -translate-x-1/2 z-0">
          <motion.svg 
            className="absolute h-full w-12 left-1/2 -translate-x-1/2" 
            viewBox="0 0 10 100" 
            preserveAspectRatio="none"
          >
            <motion.path
              d="M5,0 L5,100"
              stroke="#D4AF37"
              strokeWidth="2"
              strokeDasharray="1"
              style={{ pathLength, opacity: pathOpacity }}
              fill="none"
            />
          </motion.svg>
        </div>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-100px" }}
          className="grid gap-8 lg:gap-12"
        >
          {steps.map((step, index) => (
            <motion.div
              key={step.id}
              custom={index}
              variants={itemVariants}
              whileHover={{ scale: 1.02, transition: { duration: 0.2 } }}
              className="group"
            >
              <div className={`relative flex flex-col lg:flex-row items-center ${
                index % 2 === 0 ? 'lg:text-left' : 'lg:flex-row-reverse lg:text-right'
              } bg-secondary-800/50 backdrop-blur-sm rounded-xl p-6 shadow-lg border border-primary-300/10 hover:border-primary-300/30 transition-all duration-300`}>
                
                {/* Effet de halo doré subtil */}
                <motion.div 
                  className="absolute -inset-1 bg-primary-300/5 rounded-xl blur-md -z-10 opacity-0 group-hover:opacity-100 transition-opacity duration-500"
                />
                
                {/* Numéro et icône */}
                <motion.div
                  className="relative h-20 w-20 flex-shrink-0 rounded-full bg-gradient-to-r from-primary-400/20 to-primary-300/20 flex items-center justify-center mb-6 lg:mb-0 group-hover:bg-gradient-to-r group-hover:from-primary-400/30 group-hover:to-primary-300/30 transition-all duration-300"
                  whileHover="hover"
                >
                  {/* Effet brillant */}
                  <motion.div 
                    className="absolute inset-0 rounded-full"
                    animate={{
                      background: [
                        "radial-gradient(circle at 50% 50%, rgba(212, 175, 55, 0.1) 0%, rgba(212, 175, 55, 0) 50%)",
                        "radial-gradient(circle at 50% 50%, rgba(212, 175, 55, 0.2) 0%, rgba(212, 175, 55, 0) 50%)",
                        "radial-gradient(circle at 50% 50%, rgba(212, 175, 55, 0.1) 0%, rgba(212, 175, 55, 0) 50%)"
                      ]
                    }}
                    transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
                  />
                  
                  {/* Numéro */}
                  <div className="absolute inset-0 flex items-center justify-center opacity-30 text-primary-300 text-2xl font-bold">
                    {step.id}
                  </div>
                  
                  {/* Icône */}
                  <motion.div 
                    variants={iconVariants}
                    className="relative text-primary-300 z-10"
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
                
                {/* Espacement pour l'alignement */}
                <div className={`lg:w-8 ${index % 2 === 0 ? 'lg:ml-8' : 'lg:mr-8'}`}></div>
                
                {/* Contenu */}
                <div className="flex-1">
                  <motion.h3 
                    className="text-xl font-bold text-primary-300 mb-2"
                    initial={{ opacity: 0 }}
                    whileInView={{ opacity: 1 }}
                    transition={{ duration: 0.5, delay: 0.2 }}
                    viewport={{ once: true }}
                  >
                    {step.title}
                  </motion.h3>
                  <motion.p 
                    className="text-primary-100/80"
                    initial={{ opacity: 0 }}
                    whileInView={{ opacity: 1 }}
                    transition={{ duration: 0.5, delay: 0.3 }}
                    viewport={{ once: true }}
                  >
                    {step.description}
                  </motion.p>
                </div>
                
                {/* Indicateur visuel pour mobile */}
                {index < steps.length - 1 && (
                  <div className="absolute -bottom-6 left-1/2 transform -translate-x-1/2 w-0.5 h-12 bg-gradient-to-b from-primary-300 to-transparent lg:hidden z-0"></div>
                )}
              </div>
            </motion.div>
          ))}
        </motion.div>
        
        {/* Appel à l'action */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.8 }}
          className="flex justify-center mt-16"
        >
          <a 
            href="/apps" 
            className="group flex items-center gap-2 px-8 py-4 bg-primary-300 text-secondary-900 rounded-full hover:bg-primary-400 transition-all duration-300 shadow-gold"
          >
            <span>Commencer maintenant</span>
            <motion.span 
              className="bg-secondary-900/20 w-6 h-6 rounded-full flex items-center justify-center"
              whileHover={{ x: 5 }}
              transition={{ duration: 0.2 }}
            >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-3 h-3">
                <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
              </svg>
            </motion.span>
          </a>
        </motion.div>
      </div>
    </section>
  )
}

export default Process 