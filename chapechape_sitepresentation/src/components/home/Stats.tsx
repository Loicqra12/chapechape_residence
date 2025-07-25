import { motion, useScroll, useTransform } from 'framer-motion'
import { useInView } from 'react-intersection-observer'
import { useEffect, useState, useRef } from 'react'

// Composant pour l'animation de comptage avec effets améliorés
const CountUp = ({ end, duration = 2000, suffix = '' }: { end: number, duration?: number, suffix?: string }) => {
  const [count, setCount] = useState(0)
  const { ref, inView } = useInView({
    triggerOnce: true,
    threshold: 0.1,
  })

  useEffect(() => {
    let startTimestamp: number | null = null
    let animationFrameId: number | null = null
    
    const step = (timestamp: number) => {
      if (!startTimestamp) startTimestamp = timestamp
      const progress = Math.min((timestamp - startTimestamp) / duration, 1)
      
      setCount(Math.floor(progress * end))
      
      if (progress < 1) {
        animationFrameId = requestAnimationFrame(step)
      }
    }
    
    if (inView) {
      animationFrameId = requestAnimationFrame(step)
    }
    
    return () => {
      if (animationFrameId) {
        cancelAnimationFrame(animationFrameId)
      }
    }
  }, [end, duration, inView])

  return (
    <motion.span 
      ref={ref}
      initial={{ scale: 0.8 }}
      animate={inView ? { scale: [0.8, 1.2, 1] } : {}}
      transition={{ duration: 0.5, ease: "easeOut" }}
    >
      {count}{suffix}
    </motion.span>
  )
}

const stats = [
  { value: 10000, label: "Utilisateurs", icon: "users", suffix: "+" },
  { value: 1500, label: "Propriétés", icon: "home", suffix: "" },
  { value: 8000, label: "Transactions", icon: "chart-bar", suffix: "" },
  { value: 12, label: "Villes", icon: "map", suffix: "" }
]

const Stats = () => {
  const containerRef = useRef(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"]
  })
  
  // Animation de parallaxe lors du défilement
  const y = useTransform(scrollYProgress, [0, 1], [50, -50])
  const opacity = useTransform(scrollYProgress, [0, 0.3, 0.8, 1], [0.3, 1, 1, 0.3])
  
  // Variantes d'animation pour les cartes de statistiques
  const cardVariants = {
    hidden: { opacity: 0, y: 50, scale: 0.8 },
    visible: (i: number) => ({
      opacity: 1,
      y: 0,
      scale: 1,
      transition: {
        type: "spring",
        stiffness: 100,
        damping: 15,
        delay: 0.1 * i,
      }
    })
  }
  
  // Variantes pour les animations des icônes - Style Stripe
  const iconVariants = {
    hidden: { scale: 0.5, opacity: 0 },
    visible: { 
      scale: 1, 
      opacity: 1,
      transition: {
        type: "spring",
        stiffness: 200,
        damping: 10,
      }
    },
    hover: { 
      scale: 1.3, 
      rotate: 360, // Rotation complète 360°
      transition: { 
        duration: 0.6,
        ease: "easeInOut"
      }
    }
  }
  
  // Effet de scintillement pour les particules d'or
  const glitterVariants = {
    animate: (i: number) => ({
      opacity: [0, 0.8, 0],
      scale: [0.4, 1, 0.4],
      transition: {
        duration: Math.random() * 2 + 3,
        repeat: Infinity,
        delay: i * 0.2,
      }
    })
  }
  
  return (
    <section 
      ref={containerRef}
      className="relative py-24 overflow-hidden"
    >
      {/* Arrière-plan avec dégradé et effet de profondeur */}
      <motion.div 
        className="absolute inset-0 bg-gradient-to-r from-secondary-900 via-secondary-800 to-secondary-900 -z-10"
        style={{ y }}
      />
      
      {/* Background pattern géométrique animé - Style Stripe */}
      <motion.div 
        className="absolute inset-0 bg-[linear-gradient(to_right,rgba(212,175,55,0.08)_1px,transparent_1px),linear-gradient(to_bottom,rgba(212,175,55,0.08)_1px,transparent_1px)] bg-[size:4rem_4rem] -z-10"
        style={{ opacity }}
        animate={{
          backgroundPosition: ['0px 0px', '64px 64px'],
        }}
        transition={{
          duration: 20,
          repeat: Infinity,
          ease: "linear"
        }}
      />
      
      {/* Pattern géométrique secondaire */}
      <motion.div 
        className="absolute inset-0 bg-[radial-gradient(circle_at_25%_25%,rgba(212,175,55,0.03)_2px,transparent_2px),radial-gradient(circle_at_75%_75%,rgba(168,85,247,0.02)_2px,transparent_2px)] bg-[size:8rem_8rem] -z-10"
        animate={{
          backgroundPosition: ['0px 0px', '-128px -128px'],
        }}
        transition={{
          duration: 30,
          repeat: Infinity,
          ease: "linear"
        }}
      />
      
      {/* Particules dorées flottantes */}
      <div className="absolute inset-0 overflow-hidden -z-5">
        {[...Array(20)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute rounded-full bg-primary-300"
            style={{
              width: Math.random() * 6 + 2 + 'px',
              height: Math.random() * 6 + 2 + 'px',
              left: Math.random() * 100 + '%',
              top: Math.random() * 100 + '%',
            }}
            variants={glitterVariants}
            custom={i}
            animate="animate"
          />
        ))}
      </div>
      
      <div className="container-custom relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl font-bold text-primary-300 mb-4">ChapeChape Residence en chiffres</h2>
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-primary-100 max-w-2xl mx-auto"
          >
            Découvrez l'impact de notre plateforme sur le marché immobilier en Afrique.
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

        <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
          {stats.map((stat, index) => (
            <motion.div
              key={index}
              custom={index}
              variants={cardVariants}
              initial="hidden"
              whileInView="visible"
              whileHover={{ 
                y: -15, 
                scale: 1.05,
                boxShadow: "0 25px 50px rgba(212, 175, 55, 0.25), 0 0 0 1px rgba(212, 175, 55, 0.1)",
                transition: { duration: 0.3, ease: "easeOut" }
              }}
              viewport={{ once: true, margin: "-50px" }}
              className="relative bg-secondary-800/50 backdrop-blur-sm p-6 rounded-xl text-center transform transition-all duration-300 border border-primary-300/10 hover:border-primary-300/50 cursor-pointer group"
            >
              {/* Halo doré subtil avec glow au hover */}
              <motion.div 
                className="absolute -inset-1 bg-primary-300/5 rounded-xl blur-md -z-10 group-hover:bg-primary-300/15"
                animate={{
                  opacity: [0.3, 0.5, 0.3],
                  scale: [1, 1.05, 1],
                }}
                transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
              />
              
              {/* Glow effect premium au hover */}
              <motion.div 
                className="absolute -inset-2 bg-gradient-to-r from-primary-300/0 via-primary-300/20 to-primary-300/0 rounded-xl blur-xl -z-20 opacity-0 group-hover:opacity-100"
                transition={{ duration: 0.3 }}
              />
              
              <motion.div 
                className="inline-flex items-center justify-center h-16 w-16 rounded-full bg-primary-300/10 mb-4 relative overflow-hidden group"
                whileHover="hover"
              >
                <motion.div 
                  className="absolute inset-0 bg-primary-300/5"
                  animate={{
                    opacity: [0.5, 0.8, 0.5],
                    scale: [1, 1.1, 1],
                  }}
                  transition={{ duration: 3, repeat: Infinity }}
                />
                
                {stat.icon === "users" && (
                  <motion.svg 
                    variants={iconVariants} 
                    initial="hidden" 
                    whileInView="visible"
                    className="h-8 w-8 text-primary-300" 
                    xmlns="http://www.w3.org/2000/svg" 
                    fill="none" 
                    viewBox="0 0 24 24" 
                    stroke="currentColor"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                  </motion.svg>
                )}
                {stat.icon === "home" && (
                  <motion.svg 
                    variants={iconVariants} 
                    initial="hidden" 
                    whileInView="visible"
                    className="h-8 w-8 text-primary-300" 
                    xmlns="http://www.w3.org/2000/svg" 
                    fill="none" 
                    viewBox="0 0 24 24" 
                    stroke="currentColor"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                  </motion.svg>
                )}
                {stat.icon === "chart-bar" && (
                  <motion.svg 
                    variants={iconVariants} 
                    initial="hidden" 
                    whileInView="visible"
                    className="h-8 w-8 text-primary-300" 
                    xmlns="http://www.w3.org/2000/svg" 
                    fill="none" 
                    viewBox="0 0 24 24" 
                    stroke="currentColor"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                  </motion.svg>
                )}
                {stat.icon === "map" && (
                  <motion.svg 
                    variants={iconVariants} 
                    initial="hidden" 
                    whileInView="visible"
                    className="h-8 w-8 text-primary-300" 
                    xmlns="http://www.w3.org/2000/svg" 
                    fill="none" 
                    viewBox="0 0 24 24" 
                    stroke="currentColor"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
                  </motion.svg>
                )}
              </motion.div>
              
              <div className="text-4xl font-bold text-primary-300 mb-2 relative">
                <CountUp end={stat.value} suffix={stat.suffix} />
              </div>
              
              <motion.p 
                initial={{ opacity: 0 }}
                whileInView={{ opacity: 1 }}
                transition={{ duration: 0.5, delay: 0.3 + index * 0.1 }}
                viewport={{ once: true }}
                className="text-primary-100"
              >
                {stat.label}
              </motion.p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}

export default Stats 