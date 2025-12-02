import { motion, useInView, useMotionValue, useTransform, animate } from 'framer-motion'
import { useState, useEffect, useRef } from 'react'

const plans = [
  {
    name: "Basique",
    price: {
      monthly: 0,
      yearly: 0
    },
    description: "Pour découvrir la plateforme",
    features: [
      "Recherche illimitée",
      "5 favoris sauvegardés",
      "Support standard",
      "Accès aux offres publiques"
    ],
    cta: "Commencer gratuitement",
    mostPopular: false,
    color: "bg-secondary-100"
  },
  {
    name: "Premium",
    price: {
      monthly: 5000,
      yearly: 50000
    },
    description: "Pour les locataires actifs",
    features: [
      "Tout du plan Basique",
      "Visites virtuelles illimitées",
      "Contact direct propriétaires",
      "Alertes en temps réel",
      "Support prioritaire 7j/7"
    ],
    cta: "Essai gratuit 14 jours",
    mostPopular: true,
    color: "bg-primary-500"
  },
  {
    name: "Business",
    price: {
      monthly: 15000,
      yearly: 150000
    },
    description: "Pour les professionnels",
    features: [
      "Tout du plan Premium",
      "Dashboard analytique",
      "Gestion multi-biens",
      "API dédiée",
      "Account Manager dédié"
    ],
    cta: "Contacter les ventes",
    mostPopular: false,
    color: "bg-secondary-900"
  }
]

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
    } else if (target === 0) {
      count.set(0)
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
    <section className="py-24 bg-white relative overflow-hidden" ref={sectionRef}>
      {/* Background decoration */}
      <div className="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none">
        <div className="absolute top-[-10%] right-[-5%] w-[500px] h-[500px] bg-primary-50/50 rounded-full blur-3xl" />
        <div className="absolute bottom-[-10%] left-[-5%] w-[500px] h-[500px] bg-secondary-50/50 rounded-full blur-3xl" />
      </div>

      <div className="container-custom relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <span className="text-primary-600 font-bold tracking-widest uppercase text-xs mb-2 block">Tarification</span>
          <h2 className="text-3xl md:text-4xl font-bold text-secondary-900 mb-6 font-display">
            Des offres adaptées à vos besoins
          </h2>
          <p className="text-secondary-600 max-w-2xl mx-auto mb-8">
            Que vous soyez un particulier ou un professionnel, nous avons le plan qu'il vous faut.
          </p>

          {/* Toggle Switch */}
          <div className="flex justify-center items-center gap-4">
            <span className={`text-sm font-medium transition-colors ${billingPeriod === 'monthly' ? 'text-secondary-900' : 'text-secondary-500'}`}>Mensuel</span>
            <button
              onClick={() => setBillingPeriod(prev => prev === 'monthly' ? 'yearly' : 'monthly')}
              className="relative w-16 h-8 bg-secondary-200 rounded-full p-1 transition-colors duration-300 focus:outline-none focus:ring-2 focus:ring-primary-400"
            >
              <motion.div
                className="w-6 h-6 bg-white rounded-full shadow-md"
                animate={{ x: billingPeriod === 'monthly' ? 0 : 32 }}
                transition={{ type: "spring", stiffness: 500, damping: 30 }}
              />
            </button>
            <span className={`text-sm font-medium transition-colors ${billingPeriod === 'yearly' ? 'text-secondary-900' : 'text-secondary-500'}`}>
              Annuel <span className="text-primary-600 text-xs font-bold ml-1">-17%</span>
            </span>
          </div>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {plans.map((plan, index) => {
            const animatedPrice = useCountAnimation(plan.price[billingPeriod], isInView)
            const isPopular = plan.mostPopular

            return (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 40 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.1, duration: 0.5 }}
                onHoverStart={() => setHoveredCard(index)}
                onHoverEnd={() => setHoveredCard(null)}
                className={`relative rounded-3xl p-8 transition-all duration-300 border ${isPopular
                    ? 'bg-secondary-900 text-white border-secondary-800 shadow-2xl scale-105 z-10'
                    : 'bg-white text-secondary-900 border-secondary-100 hover:border-secondary-300 hover:shadow-xl'
                  }`}
              >
                {isPopular && (
                  <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-gradient-to-r from-primary-400 to-primary-600 text-white text-xs font-bold px-4 py-1 rounded-full shadow-lg uppercase tracking-wider">
                    Recommandé
                  </div>
                )}

                <div className="mb-8">
                  <h3 className={`text-xl font-bold mb-2 ${isPopular ? 'text-white' : 'text-secondary-900'}`}>
                    {plan.name}
                  </h3>
                  <p className={`text-sm ${isPopular ? 'text-secondary-300' : 'text-secondary-500'}`}>
                    {plan.description}
                  </p>
                </div>

                <div className="mb-8 flex items-baseline gap-1">
                  <span className={`text-4xl font-bold ${isPopular ? 'text-white' : 'text-secondary-900'}`}>
                    {plan.price[billingPeriod] === 0 ? "Gratuit" : (
                      <motion.span>{animatedPrice}</motion.span>
                    )}
                  </span>
                  {plan.price[billingPeriod] > 0 && (
                    <span className={`text-sm ${isPopular ? 'text-secondary-400' : 'text-secondary-500'}`}>
                      FCFA/{billingPeriod === 'monthly' ? 'mois' : 'an'}
                    </span>
                  )}
                </div>

                <ul className="space-y-4 mb-8">
                  {plan.features.map((feature, idx) => (
                    <li key={idx} className="flex items-start gap-3">
                      <svg
                        className={`w-5 h-5 flex-shrink-0 ${isPopular ? 'text-primary-400' : 'text-primary-600'}`}
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                      <span className={`text-sm ${isPopular ? 'text-secondary-300' : 'text-secondary-600'}`}>
                        {feature}
                      </span>
                    </li>
                  ))}
                </ul>

                <button
                  className={`w-full py-3 px-6 rounded-xl font-semibold transition-all duration-300 ${isPopular
                      ? 'bg-primary-500 text-white hover:bg-primary-600 shadow-lg hover:shadow-primary-500/30'
                      : 'bg-secondary-100 text-secondary-900 hover:bg-secondary-200'
                    }`}
                >
                  {plan.cta}
                </button>
              </motion.div>
            )
          })}
        </div>
      </div>
    </section>
  )
}

export default Pricing 