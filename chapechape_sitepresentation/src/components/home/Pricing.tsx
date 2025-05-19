import { motion } from 'framer-motion'
import { useState } from 'react'

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

const Pricing = () => {
  const [billingPeriod, setBillingPeriod] = useState<'monthly' | 'yearly'>('monthly')

  const formatPrice = (price: number) => {
    if (price === 0) return "Gratuit"
    return `${price.toLocaleString()} FCFA${billingPeriod === 'monthly' ? '/mois' : '/an'}`
  }

  return (
    <section className="py-24 bg-secondary-50 dark:bg-secondary-800">
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

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {plans.map((plan, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className={`relative rounded-xl overflow-hidden border ${
                plan.mostPopular
                  ? 'border-primary-300 shadow-xl shadow-primary-300/10'
                  : 'border-secondary-200 dark:border-secondary-700 shadow-md'
              }`}
            >
              {plan.mostPopular && (
                <div className="absolute top-0 right-0 -mt-1 -mr-1">
                  <div className="text-xs font-semibold text-secondary-900 bg-primary-300 py-1 px-3 rounded-bl-lg shadow-md">
                    Le plus populaire
                  </div>
                </div>
              )}
              <div className="p-8 bg-white dark:bg-secondary-900 h-full flex flex-col">
                <h3 className="text-xl font-bold text-secondary-900 dark:text-white mb-2">{plan.name}</h3>
                <p className="text-secondary-600 dark:text-secondary-300 mb-6 flex-grow">
                  {plan.description}
                </p>
                <div className="mb-6">
                  <span className="text-4xl font-bold text-secondary-900 dark:text-white">
                    {formatPrice(plan.price[billingPeriod])}
                  </span>
                </div>
                <ul className="space-y-3 mb-8">
                  {plan.features.map((feature, featureIndex) => (
                    <li key={featureIndex} className="flex items-start">
                      <svg className="h-5 w-5 text-primary-300 mt-0.5 flex-shrink-0" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                      <span className="ml-3 text-secondary-600 dark:text-secondary-300">{feature}</span>
                    </li>
                  ))}
                </ul>
                <button
                  className={`w-full py-3 px-6 rounded-md text-center font-medium ${
                    plan.mostPopular
                      ? 'bg-primary-300 text-secondary-900 hover:bg-primary-400'
                      : 'bg-secondary-100 dark:bg-secondary-800 text-secondary-900 dark:text-white hover:bg-secondary-200 dark:hover:bg-secondary-700'
                  } transition-colors duration-200`}
                >
                  {plan.cta}
                </button>
              </div>
            </motion.div>
          ))}
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