import { motion, AnimatePresence } from 'framer-motion'
import { useState } from 'react'

// Données des questions fréquemment posées
const faqItems = [
  {
    id: 1,
    category: "général",
    question: "Qu'est-ce que ChapeChape Residence?",
    answer: "ChapeChape Residence est une plateforme immobilière innovante spécialisée dans la réservation, la gestion et la valorisation de résidences meublées et de logements temporaires en Afrique de l'Ouest. Nous connectons propriétaires et locataires grâce à une plateforme numérique intuitive et sécurisée."
  },
  {
    id: 2,
    category: "général",
    question: "Dans quelles villes êtes-vous présents?",
    answer: "Actuellement, ChapeChape Residence est présent à Abidjan en Côte d'Ivoire, avec des plans d'expansion dans d'autres grandes villes d'Afrique de l'Ouest comme Dakar, Accra, et Lagos dans un futur proche."
  },
  {
    id: 3,
    category: "locataire",
    question: "Comment puis-je réserver un logement?",
    answer: "La réservation d'un logement sur ChapeChape Residence est simple. Vous pouvez parcourir les options disponibles sur notre application mobile ou notre site web, filtrer selon vos critères, visualiser les biens, puis effectuer votre réservation en ligne en suivant les étapes indiquées. Un conseiller vous contactera pour finaliser votre dossier."
  },
  {
    id: 4,
    category: "locataire",
    question: "Quels documents sont nécessaires pour louer?",
    answer: "Pour louer un logement, vous aurez généralement besoin d'une pièce d'identité valide, d'un justificatif de revenus récent, et parfois d'une garantie financière selon le type de bien. Tous les détails spécifiques vous seront communiqués lors du processus de réservation."
  },
  {
    id: 5,
    category: "locataire",
    question: "Les charges sont-elles incluses dans le loyer?",
    answer: "Cela dépend du bien immobilier. Certaines offres incluent toutes les charges (eau, électricité, internet), tandis que d'autres les facturent séparément. Cette information est clairement indiquée dans la description de chaque bien sur notre plateforme."
  },
  {
    id: 6,
    category: "propriétaire",
    question: "Comment mettre mon bien en location sur ChapeChape Residence?",
    answer: "Pour mettre votre bien en location, vous pouvez vous inscrire sur notre plateforme partenaire, remplir un formulaire détaillé sur votre propriété, et un de nos conseillers vous contactera pour organiser une visite et finaliser le processus. Nous nous occupons ensuite de la mise en valeur et de la gestion de votre bien."
  },
  {
    id: 7,
    category: "propriétaire",
    question: "Quels sont vos frais de gestion?",
    answer: "Nos frais de gestion sont compétitifs et varient entre 8% et 15% du loyer mensuel selon le niveau de service choisi. Nous offrons différentes formules adaptées aux besoins de chaque propriétaire, de la simple mise en relation à la gestion complète du bien."
  },
  {
    id: 8,
    category: "propriétaire",
    question: "Comment sélectionnez-vous les locataires?",
    answer: "Nous avons un processus rigoureux de sélection des locataires qui comprend une vérification des antécédents financiers, des références professionnelles, et parfois un entretien personnel. Notre objectif est de garantir des locataires fiables et respectueux de votre bien."
  },
  {
    id: 9,
    category: "paiement",
    question: "Quels modes de paiement acceptez-vous?",
    answer: "Nous acceptons plusieurs modes de paiement, incluant les cartes bancaires, les virements bancaires, et les paiements mobiles populaires en Afrique de l'Ouest comme Orange Money, MTN Mobile Money et Wave."
  },
  {
    id: 10,
    category: "paiement",
    question: "Comment fonctionne le dépôt de garantie?",
    answer: "Le dépôt de garantie équivaut généralement à un mois de loyer. Il est conservé en sécurité pendant la durée de la location et restitué à la fin du bail, déduction faite d'éventuels dommages constatés lors de l'état des lieux de sortie."
  },
  {
    id: 11,
    category: "appli",
    question: "Comment télécharger l'application ChapeChape Residence?",
    answer: "Nos applications pour locataires et propriétaires sont disponibles sur l'App Store (iOS) et Google Play Store (Android). Vous pouvez les trouver en recherchant 'ChapeChape Residence' ou via les liens sur notre site web."
  },
  {
    id: 12,
    category: "appli",
    question: "L'application est-elle gratuite?",
    answer: "Oui, nos applications sont totalement gratuites à télécharger et à utiliser. Les propriétaires ne paient des frais que lorsqu'un locataire est trouvé, et les locataires paient uniquement leur loyer et les frais associés directement liés à leur location."
  }
]

// Catégories de FAQ avec icônes
const categories = [
  {
    id: "général",
    name: "Questions générales",
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    )
  },
  {
    id: "locataire",
    name: "Pour les locataires",
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
      </svg>
    )
  },
  {
    id: "propriétaire",
    name: "Pour les propriétaires",
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
      </svg>
    )
  },
  {
    id: "paiement",
    name: "Paiement",
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
      </svg>
    )
  },
  {
    id: "appli",
    name: "Application mobile",
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
      </svg>
    )
  }
]

const FAQ = () => {
  const [activeCategory, setActiveCategory] = useState<string>("général")
  const [openItems, setOpenItems] = useState<number[]>([])

  const toggleItem = (id: number) => {
    setOpenItems(prev =>
      prev.includes(id)
        ? prev.filter(item => item !== id)
        : [...prev, id]
    )
  }

  // Filtrer les questions par catégorie
  const filteredFAQs = activeCategory === "tous"
    ? faqItems
    : faqItems.filter(item => item.category === activeCategory)

  return (
    <div className="bg-white">
      {/* Hero Section Harmonisé */}
      <section className="relative py-32 bg-secondary-900 overflow-hidden">
        <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-10 mix-blend-overlay" />
        <div className="absolute inset-0 bg-gradient-to-b from-secondary-900/50 via-secondary-900/80 to-white" />

        {/* Golden particles */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          {[...Array(6)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute rounded-full bg-primary-400/20 blur-xl"
              style={{
                width: Math.random() * 150 + 50 + 'px',
                height: Math.random() * 150 + 50 + 'px',
                left: Math.random() * 100 + '%',
                top: Math.random() * 100 + '%',
              }}
              animate={{
                y: [0, -100, 0],
                x: [0, Math.random() * 50 - 25, 0],
                opacity: [0, 0.4, 0],
              }}
              transition={{
                duration: Math.random() * 10 + 10,
                repeat: Infinity,
                ease: "easeInOut",
              }}
            />
          ))}
        </div>

        <div className="container mx-auto px-4 max-w-6xl relative z-10 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <span className="inline-block py-1 px-3 rounded-full bg-white/10 backdrop-blur-md border border-white/20 text-primary-300 text-xs font-bold tracking-widest uppercase mb-6">
              Support & Aide
            </span>
            <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              Foire Aux <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">Questions</span>
            </h1>
            <p className="text-xl text-gray-300 mb-10 max-w-2xl mx-auto font-light leading-relaxed">
              Trouvez rapidement des réponses à vos questions les plus fréquentes. Notre base de connaissances est là pour vous aider.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Main content */}
      <div className="container mx-auto px-4 max-w-6xl py-16 sm:py-24">
        {/* Introduction */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-3xl font-bold text-secondary-900 mb-6 font-display">
            Comment pouvons-nous vous aider ?
          </h2>
          <p className="text-lg text-secondary-600">
            Consultez nos réponses aux questions fréquemment posées. Si vous ne trouvez pas
            l'information que vous recherchez, n'hésitez pas à nous contacter directement.
          </p>
        </div>

        {/* Catégories */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-12">
          <button
            className={`flex flex-col items-center justify-center p-6 rounded-2xl border transition-all duration-300 ${activeCategory === "tous"
                ? "border-primary-500 bg-primary-50 text-primary-600 shadow-lg shadow-primary-500/10 scale-105"
                : "border-gray-100 bg-white text-secondary-500 hover:border-primary-200 hover:bg-gray-50 hover:shadow-md"
              }`}
            onClick={() => setActiveCategory("tous")}
          >
            <svg xmlns="http://www.w3.org/2000/svg" className="h-8 w-8 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 6h16M4 10h16M4 14h16M4 18h16" />
            </svg>
            <span className="text-sm font-bold">Toutes</span>
          </button>

          {categories.map(category => (
            <button
              key={category.id}
              className={`flex flex-col items-center justify-center p-6 rounded-2xl border transition-all duration-300 ${activeCategory === category.id
                  ? "border-primary-500 bg-primary-50 text-primary-600 shadow-lg shadow-primary-500/10 scale-105"
                  : "border-gray-100 bg-white text-secondary-500 hover:border-primary-200 hover:bg-gray-50 hover:shadow-md"
                }`}
              onClick={() => setActiveCategory(category.id)}
            >
              <div className="mb-3 text-current">{category.icon}</div>
              <span className="text-sm font-bold text-center">{category.name}</span>
            </button>
          ))}
        </div>

        {/* Questions et réponses */}
        <div className="max-w-4xl mx-auto space-y-4">
          {filteredFAQs.length > 0 ? (
            filteredFAQs.map((item, index) => (
              <motion.div
                key={item.id}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.4, delay: index * 0.05 }}
                className={`border rounded-2xl overflow-hidden transition-all duration-300 ${openItems.includes(item.id)
                    ? 'bg-white border-primary-200 shadow-lg'
                    : 'bg-white border-gray-100 hover:border-primary-100'
                  }`}
              >
                <button
                  className="flex w-full justify-between items-center text-left p-6 focus:outline-none"
                  onClick={() => toggleItem(item.id)}
                >
                  <span className={`text-lg font-bold transition-colors ${openItems.includes(item.id) ? 'text-primary-600' : 'text-secondary-900'
                    }`}>
                    {item.question}
                  </span>
                  <span className={`ml-6 flex-shrink-0 h-8 w-8 rounded-full flex items-center justify-center transition-all duration-300 ${openItems.includes(item.id) ? 'bg-primary-100 text-primary-600 rotate-180' : 'bg-gray-100 text-gray-500'
                    }`}>
                    <svg
                      className="h-5 w-5"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                    </svg>
                  </span>
                </button>
                <AnimatePresence>
                  {openItems.includes(item.id) && (
                    <motion.div
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: "auto" }}
                      exit={{ opacity: 0, height: 0 }}
                      transition={{ duration: 0.3 }}
                    >
                      <div className="px-6 pb-6 text-secondary-600 leading-relaxed border-t border-gray-50 pt-4">
                        {item.answer}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            ))
          ) : (
            <div className="py-12 text-center bg-gray-50 rounded-2xl border border-dashed border-gray-200">
              <p className="text-secondary-500 font-medium">Aucune question ne correspond à cette catégorie.</p>
            </div>
          )}
        </div>

        {/* Appel à l'action */}
        <div className="mt-20 p-10 bg-secondary-900 rounded-3xl text-center relative overflow-hidden shadow-2xl">
          <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-5 mix-blend-overlay" />
          <div className="relative z-10">
            <h3 className="text-2xl font-bold text-white mb-4 font-display">Vous ne trouvez pas la réponse à votre question ?</h3>
            <p className="text-primary-100 mb-8 max-w-2xl mx-auto text-lg">
              Notre équipe de support client est là pour vous aider et répondre à toutes vos questions.
            </p>
            <a
              href="/contact"
              className="btn-primary inline-flex items-center"
            >
              Contactez-nous
              <svg className="ml-2 h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14 5l7 7m0 0l-7 7m7-7H3" />
              </svg>
            </a>
          </div>
        </div>
      </div>
    </div>
  )
}

export default FAQ