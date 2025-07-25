import { motion, useInView, useMotionValue, useTransform, animate } from 'framer-motion'
import { useState, useEffect, useRef } from 'react'

const plans = [
  {
    name: "Basique",
    price: {
      monthly: 0,
      yearly: 0
    },
    description: "Parfait pour les particuliers à la recherche d'un logement",
    features: [
      "Recherche illimitée de propriétés",
      "Filtres de recherche avancés",
      "Sauvegarde de 5 favoris",
      "Assistance par email",
      "Notifications de nouveaux logements"
    ],
    cta: "Commencer gratuitement",
    mostPopular: false
  },
  {
    name: "Standard",
    price: {
      monthly: 5000,
      yearly: 50000
    },
    description: "Idéal pour les locataires réguliers et les petits propriétaires",
    features: [
      "Tout ce qui est inclus dans Basique",
      "Visites virtuelles illimitées",
      "Communication directe avec les propriétaires",
      "Sauvegarde de 20 favoris",
      "Assistance prioritaire",
      "Vérification de profil avancée"
    ],
    cta: "Essai gratuit de 14 jours",
    mostPopular: true
  },
  {
    name: "Premium",
    price: {
      monthly: 15000,
      yearly: 150000
    },
    description: "Pour les propriétaires et gestionnaires professionnels",
    features: [
      "Tout ce qui est inclus dans Standard",
      "Gestion de portefeuille immobilier",
      "Publicité en tête des résultats",
      "Rapports analytiques détaillés",
      "API pour intégrations tierces",
      "Gestionnaire de compte dédié",
      "Formation personnalisée"
    ],
    cta: "Contactez-nous",
    mostPopular: false
  }
]

// Hook pour l'animation de comptage des prix
const useCountAnimation = (target: number, isInView: boolean) => {
  const count = useMotionValue(0)
  const rounded = useTransform(count, (latest) => Math.round(latest))
  
  useEffect(() => {
    if (isInView && target > 0) {
      const controls = animate(count, target, {
        duration: 1.5,
        ease: "easeOut"
      })
      return controls.stop
    }
  }, [count, target, isInView])
  
  return rounded
}

const Pricing = () => {
  const [billingPeriod, setBillingPeriod] = useState<'monthly' | 'yearly'>('monthly')
  const [hoveredCard, setHoveredCard] = useState<number | null>(null)
  const sectionRef = useRef(null)
  const isInView = useInView(sectionRef, { once: true, margin: "-100px" })



  return (
    <section className="py-24 bg-secondary-50 dark:bg-secondary-800" ref={sectionRef}>
      <div className="container-custom">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl font-bold text-secondary-900 dark:text-white mb-4">Tarifs simples et transparents</h2>
          <p className="text-secondary-600 dark:text-secondary-300 max-w-2xl mx-auto">
            Choisissez le plan qui correspond à vos besoins. Tous nos plans incluent un accès complet à la plateforme.
          </p>

          <div className="mt-8 flex justify-center">
            <div className="relative flex p-1 rounded-full bg-white dark:bg-secondary-700 shadow-sm">
              <button
                onClick={() => setBillingPeriod('monthly')}
                className={`relative py-2 px-6 text-sm font-medium rounded-full whitespace-nowrap ${
                  billingPeriod === 'monthly'
                    ? 'text-secondary-900 bg-primary-300'
                    : 'text-secondary-600 dark:text-secondary-300 hover:text-secondary-900 dark:hover:text-white'
                }`}
              >
                Mensuel
              </button>
              <button
                onClick={() => setBillingPeriod('yearly')}
                className={`relative py-2 px-6 text-sm font-medium rounded-full whitespace-nowrap ${
                  billingPeriod === 'yearly'
                    ? 'text-secondary-900 bg-primary-300'
                    : 'text-secondary-600 dark:text-secondary-300 hover:text-secondary-900 dark:hover:text-white'
                }`}
              >
                Annuel <span className="ml-1 text-xs text-primary-400">-17%</span>
              </button>
            </div>
          </div>
        </motion.div>

        {/* Cards comparison animées - Style Stripe Premium */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {plans.map((plan, index) => {
            const animatedPrice = useCountAnimation(plan.price[billingPeriod], isInView)
            
            return (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 40, scale: 0.9 }}
                whileInView={{ opacity: 1, y: 0, scale: 1 }}
                viewport={{ once: true }}
                transition={{ 
                  duration: 0.6, 
                  delay: index * 0.15,
                  type: "spring",
                  stiffness: 100,
                  damping: 15
                }}
                whileHover={{ 
                  scale: hoveredCard === index ? 1.05 : (hoveredCard !== null ? 0.98 : 1),
                  y: hoveredCard === index ? -10 : 0,
                  transition: { duration: 0.3, ease: "easeOut" }
                }}
                onHoverStart={() => setHoveredCard(index)}
                onHoverEnd={() => setHoveredCard(null)}
                className={`relative rounded-2xl overflow-hidden border-2 cursor-pointer group ${
                  plan.mostPopular
                    ? 'border-primary-300 shadow-2xl shadow-primary-300/20'
                    : 'border-secondary-200 dark:border-secondary-700 shadow-lg hover:shadow-2xl'
                } transition-all duration-300`}
                style={{
                  filter: hoveredCard !== null && hoveredCard !== index ? 'brightness(0.7) blur(1px)' : 'brightness(1) blur(0px)',
                  transition: 'filter 0.3s ease'
                }}
              >
                {/* Badge "Le plus populaire" avec glow pulsant */}
                {plan.mostPopular && (
                  <motion.div 
                    className="absolute top-0 right-0 -mt-1 -mr-1 z-10"
                    initial={{ scale: 0, rotate: -10 }}
                    animate={{ scale: 1, rotate: 0 }}
                    transition={{ delay: index * 0.15 + 0.5, type: "spring" }}
                  >
                    <motion.div 
                      className="text-xs font-semibold text-secondary-900 bg-gradient-to-r from-primary-300 via-primary-400 to-primary-300 py-2 px-4 rounded-bl-2xl shadow-lg relative overflow-hidden"
                      animate={{
                        boxShadow: [
                          "0 4px 20px rgba(212, 175, 55, 0.3)",
                          "0 4px 30px rgba(212, 175, 55, 0.6)",
                          "0 4px 20px rgba(212, 175, 55, 0.3)"
                        ],
                        backgroundPosition: ['0% 50%', '100% 50%', '0% 50%']
                      }}
                      transition={{
                        duration: 2,
                        repeat: Infinity,
                        ease: "easeInOut"
                      }}
                      style={{ backgroundSize: '200% 100%' }}
                    >
                      ⭐ Le plus populaire
                      {/* Glow effect */}
                      <motion.div
                        className="absolute inset-0 bg-gradient-to-r from-primary-300/50 via-primary-400/50 to-primary-300/50 rounded-bl-2xl"
                        animate={{ opacity: [0.5, 1, 0.5] }}
                        transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
                      />
                    </motion.div>
                  </motion.div>
                )}
                
                {/* Card content avec glassmorphism */}
                <div className="p-8 bg-white/90 dark:bg-secondary-900/90 backdrop-blur-sm h-full flex flex-col relative overflow-hidden">
                  {/* Background pattern animé */}
                  <div className="absolute inset-0 opacity-5 dark:opacity-10">
                    <div 
                      className="w-full h-full"
                      style={{
                        backgroundImage: `radial-gradient(circle at 20% 80%, rgba(212, 175, 55, 0.3) 0%, transparent 50%),
                                         radial-gradient(circle at 80% 20%, rgba(212, 175, 55, 0.2) 0%, transparent 50%)`
                      }}
                    />
                  </div>
                  
                  <motion.h3 
                    className="text-2xl font-bold text-secondary-900 dark:text-white mb-3 relative z-10"
                    initial={{ opacity: 0, x: -20 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.15 + 0.2 }}
                  >
                    {plan.name}
                  </motion.h3>
                  
                  <motion.p 
                    className="text-secondary-600 dark:text-secondary-300 mb-8 flex-grow relative z-10"
                    initial={{ opacity: 0 }}
                    whileInView={{ opacity: 1 }}
                    transition={{ delay: index * 0.15 + 0.3 }}
                  >
                    {plan.description}
                  </motion.p>
                  
                  {/* Prix avec effet counting */}
                  <motion.div 
                    className="mb-8 relative z-10"
                    initial={{ scale: 0.8, opacity: 0 }}
                    whileInView={{ scale: 1, opacity: 1 }}
                    transition={{ delay: index * 0.15 + 0.4, type: "spring" }}
                  >
                    <motion.span 
                      className="text-5xl font-bold bg-gradient-to-r from-secondary-900 via-primary-600 to-secondary-900 bg-clip-text text-transparent dark:from-white dark:via-primary-300 dark:to-white"
                      whileHover={{ scale: 1.05 }}
                    >
                      {plan.price[billingPeriod] === 0 ? "Gratuit" : (
                        <motion.span>
                          {animatedPrice.get().toLocaleString()} FCFA
                          <span className="text-lg font-medium text-secondary-600 dark:text-secondary-400">
                            {billingPeriod === 'monthly' ? '/mois' : '/an'}
                          </span>
                        </motion.span>
                      )}
                    </motion.span>
                  </motion.div>
                  
                  {/* Features list avec progressive reveal */}
                  <div className="space-y-4 mb-8 relative z-10">
                    {plan.features.map((feature, featureIndex) => (
                      <motion.div
                        key={featureIndex}
                        initial={{ opacity: 0, x: -20, scale: 0.8 }}
                        whileInView={{ opacity: 1, x: 0, scale: 1 }}
                        transition={{ 
                          delay: index * 0.15 + 0.5 + featureIndex * 0.1,
                          type: "spring",
                          stiffness: 200
                        }}
                        className="flex items-start group/feature"
                      >
                        <motion.div
                          className="h-6 w-6 rounded-full bg-gradient-to-r from-primary-300 to-primary-400 flex items-center justify-center mt-0.5 flex-shrink-0 mr-3"
                          whileHover={{ scale: 1.2, rotate: 360 }}
                          transition={{ duration: 0.3 }}
                        >
                          <motion.svg 
                            className="h-4 w-4 text-secondary-900" 
                            xmlns="http://www.w3.org/2000/svg" 
                            fill="none" 
                            viewBox="0 0 24 24" 
                            stroke="currentColor"
                            initial={{ pathLength: 0 }}
                            whileInView={{ pathLength: 1 }}
                            transition={{ delay: index * 0.15 + 0.6 + featureIndex * 0.1, duration: 0.3 }}
                          >
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                          </motion.svg>
                        </motion.div>
                        <span className="text-secondary-700 dark:text-secondary-300 group-hover/feature:text-secondary-900 dark:group-hover/feature:text-white transition-colors">
                          {feature}
                        </span>
                      </motion.div>
                    ))}
                  </div>
                  
                  {/* CTA Button avec ripple effect */}
                  <motion.button
                    className={`relative w-full py-4 px-6 rounded-xl text-center font-semibold text-lg overflow-hidden group/cta ${
                      plan.mostPopular
                        ? 'bg-gradient-to-r from-primary-400 via-primary-300 to-primary-400 text-secondary-900 shadow-lg'
                        : 'bg-gradient-to-r from-secondary-100 via-secondary-50 to-secondary-100 dark:from-secondary-800 dark:via-secondary-700 dark:to-secondary-800 text-secondary-900 dark:text-white shadow-md'
                    } transition-all duration-300 relative z-10`}
                    whileHover={{ 
                      scale: 1.02,
                      boxShadow: plan.mostPopular 
                        ? "0 20px 40px rgba(212, 175, 55, 0.4)" 
                        : "0 10px 30px rgba(0, 0, 0, 0.2)"
                    }}
                    whileTap={{ scale: 0.98 }}
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.15 + 0.8 }}
                    style={{ backgroundSize: '200% 100%' }}
                    animate={{
                      backgroundPosition: ['0% 50%', '100% 50%', '0% 50%']
                    }}
                  >
                    {/* Ripple effect */}
                    <motion.div
                      className="absolute inset-0 bg-white/20 rounded-xl"
                      initial={{ scale: 0, opacity: 1 }}
                      whileTap={{ scale: 2, opacity: 0 }}
                      transition={{ duration: 0.4 }}
                    />
                    
                    {/* Glow effect */}
                    <motion.div
                      className={`absolute -inset-1 rounded-xl blur-md opacity-0 group-hover/cta:opacity-100 ${
                        plan.mostPopular
                          ? 'bg-gradient-to-r from-primary-400/50 via-primary-300/50 to-primary-400/50'
                          : 'bg-gradient-to-r from-secondary-400/30 via-secondary-300/30 to-secondary-400/30'
                      }`}
                      transition={{ duration: 0.3 }}
                    />
                    
                    <span className="relative z-10">{plan.cta}</span>
                  </motion.button>
                </div>
              </motion.div>
            )
          })}
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.4 }}
          className="mt-16 bg-white dark:bg-secondary-900 rounded-xl p-8 shadow-md border border-secondary-200 dark:border-secondary-700"
        >
          <div className="flex flex-col md:flex-row items-center md:justify-between">
            <div>
              <h3 className="text-xl font-bold text-secondary-900 dark:text-white">Vous avez besoin d'une solution sur mesure ?</h3>
              <p className="mt-2 text-secondary-600 dark:text-secondary-300">
                Contactez notre équipe commerciale pour discuter de vos besoins spécifiques.
              </p>
            </div>
            <a
              href="#contact"
              className="mt-6 md:mt-0 btn-secondary whitespace-nowrap"
            >
              Demander un devis
            </a>
          </div>
        </motion.div>
      </div>
    </section>
  )
}

export default Pricing 