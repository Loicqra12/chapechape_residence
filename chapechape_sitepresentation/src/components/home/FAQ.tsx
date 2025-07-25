import { useState, useRef, useMemo } from 'react'
import { motion, AnimatePresence, useScroll, useTransform } from 'framer-motion'

type FAQItem = {
  question: string
  answer: string
}

const faqs: FAQItem[] = [
  {
    question: "Comment fonctionne ChapeChape Residence ?",
    answer: "ChapeChape Residence met en relation les propriétaires et les locataires. Les propriétaires peuvent lister leurs résidences, tandis que les locataires peuvent rechercher et réserver des propriétés. Notre plateforme gère les paiements, les réservations et les communications, garantissant une expérience fluide pour tous les utilisateurs."
  },
  {
    question: "Quels types de résidences peut-on trouver sur ChapeChape Residence ?",
    answer: "Notre plateforme propose une large gamme de propriétés : appartements, villas, résidences meublées, maisons d'hôtes, studios économiques et bien plus encore. Que vous cherchiez une location de vacances ou une résidence à long terme, ChapeChape Residence offre des options pour tous les besoins et budgets."
  },
  {
    question: "Comment devenir partenaire sur ChapeChape Residence ?",
    answer: "Pour devenir partenaire, téléchargez l'application Partenaire ChapeChape Residence, créez un compte, complétez votre profil, et ajoutez vos propriétés. Notre équipe validera vos informations et votre propriété apparaîtra sur la plateforme. Des frais de service peuvent s'appliquer sur les réservations réussies."
  },
  {
    question: "Les paiements sont-ils sécurisés sur la plateforme ?",
    answer: "Oui, tous les paiements sur ChapeChape Residence sont entièrement sécurisés. Nous utilisons des technologies de cryptage avancées et travaillons avec des partenaires de paiement fiables. Nous proposons plusieurs méthodes de paiement, notamment les cartes bancaires, les virements, et les services de paiement mobile populaires en Afrique."
  },
  {
    question: "Comment contacter le service client ?",
    answer: "Vous pouvez contacter notre service client via l'application (bouton Aide et support), par email à support@chapechaperesidence.com, ou par téléphone au +225 0700000000. Notre équipe est disponible 7j/7 pour répondre à vos questions et résoudre les problèmes."
  },
  {
    question: "Est-ce que ChapeChape Residence est disponible dans toute l'Afrique ?",
    answer: "Actuellement, ChapeChape Residence est disponible en Côte d'Ivoire, au Sénégal, et dans certaines zones d'Afrique de l'Ouest. Nous prévoyons d'étendre nos services à d'autres pays africains dans un futur proche. Consultez notre section Couverture géographique pour plus de détails."
  }
]

const FAQ = () => {
  const [activeIndex, setActiveIndex] = useState<number | null>(null)
  const [searchQuery, setSearchQuery] = useState('')
  const [isSearchFocused, setIsSearchFocused] = useState(false)
  const containerRef = useRef(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"]
  })
  
  // Filtered FAQs based on search query
  const filteredFaqs = useMemo(() => {
    if (!searchQuery.trim()) return faqs
    return faqs.filter(faq => 
      faq.question.toLowerCase().includes(searchQuery.toLowerCase()) ||
      faq.answer.toLowerCase().includes(searchQuery.toLowerCase())
    )
  }, [searchQuery])
  
  const y = useTransform(scrollYProgress, [0, 1], [100, -100])
  const opacity = useTransform(scrollYProgress, [0, 0.3, 0.7, 1], [0.3, 1, 1, 0.3])
  
  // Animation variants pour les éléments de FAQ
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
        delayChildren: 0.2
      }
    }
  }
  
  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { 
      opacity: 1, 
      y: 0,
      transition: {
        type: "spring",
        stiffness: 100,
        damping: 15
      }
    }
  }
  
  const contentVariants = {
    hidden: { 
      height: 0,
      opacity: 0,
      transition: { 
        duration: 0.2,
        ease: "easeInOut"
      }
    },
    visible: { 
      height: "auto",
      opacity: 1,
      transition: { 
        duration: 0.3,
        ease: "easeInOut"
      }
    }
  }
  
  const iconVariants = {
    closed: { rotate: 0 },
    open: { rotate: 45 }
  }
  
  // Effet de particules dorées
  const glitterVariants = {
    animate: (i: number) => ({
      opacity: [0, 0.7, 0],
      scale: [0.5, 1, 0.5],
      x: [0, Math.random() * 50 - 25, 0],
      transition: {
        duration: Math.random() * 3 + 5,
        repeat: Infinity,
        delay: i * 0.3,
      }
    })
  }

  return (
    <motion.section 
      ref={containerRef}
      className="relative py-24 overflow-hidden"
    >
      {/* Fond avec subtil dégradé doré */}
      <motion.div 
        className="absolute inset-0 bg-gradient-to-b from-secondary-50 via-secondary-50 to-white -z-10"
        style={{ y, opacity }}
      />
      
      {/* Motif élégant en arrière-plan */}
      <motion.div 
        className="absolute inset-0 bg-[linear-gradient(135deg,rgba(212,175,55,0.03)_1px,transparent_1px),linear-gradient(45deg,rgba(212,175,55,0.03)_1px,transparent_1px)] bg-[size:40px_40px] -z-10"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 1.5 }}
      />
      
      {/* Particules dorées subtiles */}
      <div className="absolute inset-0 overflow-hidden -z-5">
        {[...Array(15)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute rounded-full bg-primary-300"
            style={{
              width: Math.random() * 4 + 2 + 'px',
              height: Math.random() * 4 + 2 + 'px',
              left: Math.random() * 100 + '%',
              top: Math.random() * 100 + '%',
            }}
            variants={glitterVariants}
            custom={i}
            animate="animate"
          />
        ))}
      </div>
      
      <div className="container-custom">
        <div className="max-w-4xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="text-3xl font-bold text-secondary-900 mb-4 font-display">Questions fréquemment posées</h2>
            <motion.p 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-100px" }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="text-secondary-600 max-w-2xl mx-auto"
            >
              Vous avez des questions ? Nous avons les réponses. Si vous ne trouvez pas l'information que vous cherchez, n'hésitez pas à nous contacter.
            </motion.p>
            
            {/* Ligne décorative dorée */}
            <motion.div 
              initial={{ width: 0 }}
              whileInView={{ width: "60px" }}
              viewport={{ once: true }}
              transition={{ duration: 0.8, delay: 0.4 }}
              className="h-1 bg-gradient-to-r from-primary-400 to-secondary-400 mx-auto mt-6 rounded-full"
            />
          </motion.div>

          {/* Premium Search Bar */}
          <motion.div
            initial={{ opacity: 0, y: 30, scale: 0.95 }}
            whileInView={{ opacity: 1, y: 0, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="mb-12 max-w-2xl mx-auto"
          >
            <div className="relative group">
              {/* Glow effect background */}
              <div className={`absolute -inset-1 bg-gradient-to-r from-primary-400 to-secondary-400 rounded-2xl blur-lg opacity-0 group-hover:opacity-20 transition-all duration-500 ${isSearchFocused ? 'opacity-30' : ''}`} />
              
              <div className={`relative flex items-center bg-white dark:bg-gray-800 rounded-2xl border-2 transition-all duration-300 shadow-lg hover:shadow-xl ${isSearchFocused ? 'border-primary-400 shadow-primary-100 dark:shadow-primary-900/20' : 'border-gray-200 dark:border-gray-600'}`}>
                {/* Search Icon */}
                <motion.div 
                  className="pl-6 pr-3"
                  animate={{
                    scale: isSearchFocused ? 1.1 : 1,
                    rotate: searchQuery ? 360 : 0
                  }}
                  transition={{ type: "spring", stiffness: 300, damping: 20 }}
                >
                  <svg 
                    className={`w-6 h-6 transition-colors duration-300 ${isSearchFocused || searchQuery ? 'text-primary-500' : 'text-gray-400 dark:text-gray-500'}`} 
                    fill="none" 
                    stroke="currentColor" 
                    viewBox="0 0 24 24"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                </motion.div>
                
                {/* Input Field */}
                <input
                  type="text"
                  placeholder="Rechercher dans les questions fréquentes..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onFocus={() => setIsSearchFocused(true)}
                  onBlur={() => setIsSearchFocused(false)}
                  className="flex-1 py-4 pr-6 bg-transparent text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none text-lg"
                />
                
                {/* Clear button */}
                <AnimatePresence>
                  {searchQuery && (
                    <motion.button
                      initial={{ opacity: 0, scale: 0.8 }}
                      animate={{ opacity: 1, scale: 1 }}
                      exit={{ opacity: 0, scale: 0.8 }}
                      whileHover={{ scale: 1.1 }}
                      whileTap={{ scale: 0.9 }}
                      onClick={() => setSearchQuery('')}
                      className="mr-4 p-2 rounded-full bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors duration-200"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </motion.button>
                  )}
                </AnimatePresence>
              </div>
              
              {/* Search results count */}
              <AnimatePresence>
                {searchQuery && (
                  <motion.div
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    className="absolute top-full left-0 right-0 mt-2 text-center"
                  >
                    <span className="inline-block px-4 py-2 bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300 rounded-full text-sm font-medium">
                      {filteredFaqs.length} résultat{filteredFaqs.length !== 1 ? 's' : ''} trouvé{filteredFaqs.length !== 1 ? 's' : ''}
                    </span>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </motion.div>

          {/* No results message */}
          <AnimatePresence>
            {searchQuery && filteredFaqs.length === 0 && (
              <motion.div
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9 }}
                className="text-center py-12"
              >
                <motion.div
                  animate={{ rotate: [0, 10, -10, 0] }}
                  transition={{ duration: 0.5, repeat: Infinity, repeatDelay: 3 }}
                  className="w-16 h-16 mx-auto mb-4 bg-gradient-to-br from-gray-200 to-gray-300 dark:from-gray-700 dark:to-gray-600 rounded-full flex items-center justify-center"
                >
                  <svg className="w-8 h-8 text-gray-500 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.172 16.172a4 4 0 015.656 0M9 12h6m-6-4h6m2 5.291A7.962 7.962 0 0112 15c-2.34 0-4.291-1.007-5.691-2.709M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                  </svg>
                </motion.div>
                <h3 className="text-xl font-semibold text-gray-700 dark:text-gray-300 mb-2">Aucun résultat trouvé</h3>
                <p className="text-gray-500 dark:text-gray-400 max-w-md mx-auto">
                  Nous n'avons pas trouvé de questions correspondant à "<span className="font-medium text-primary-600 dark:text-primary-400">{searchQuery}</span>". 
                  Essayez avec d'autres mots-clés ou contactez notre support.
                </p>
              </motion.div>
            )}
          </AnimatePresence>

          <motion.div
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-50px" }}
            className="grid gap-6"
          >
            <AnimatePresence mode="popLayout">
              {filteredFaqs.map((faq, index) => {
                const originalIndex = faqs.findIndex(f => f.question === faq.question)
                return (
                  <motion.div
                    key={faq.question}
                    layout
                    variants={itemVariants}
                    className="overflow-hidden"
                  >
                    <motion.div
                      className={`rounded-xl p-6 shadow-lg border border-primary-200/30 transition-all duration-500 hover:shadow-xl ${activeIndex === index ? 'bg-gradient-to-r from-primary-50 via-white to-secondary-50 shadow-xl border-primary-300/50 scale-[1.02]' : 'bg-white dark:bg-gray-800 hover:bg-gradient-to-r hover:from-primary-50/50 hover:to-white dark:hover:from-gray-700 dark:hover:to-gray-800'}`}
                      whileHover={{ 
                        scale: activeIndex === index ? 1.02 : 1.01, 
                        transition: { duration: 0.3, type: "spring", stiffness: 300 } 
                      }}
                >
                      <button
                        className="flex justify-between items-center w-full text-left focus:outline-none group"
                        onClick={() => setActiveIndex(activeIndex === index ? null : index)}
                      >
                        <h3 className="text-lg font-bold text-secondary-800 dark:text-white pr-6 group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors duration-300">
                          {faq.question}
                        </h3>
                        <motion.div
                          variants={{
                            closed: { rotate: 0, scale: 1, backgroundColor: "rgba(212, 175, 55, 0.1)" },
                            open: { rotate: 45, scale: 1.1, backgroundColor: "rgba(212, 175, 55, 0.2)" }
                          }}
                          animate={activeIndex === index ? 'open' : 'closed'}
                          transition={{ duration: 0.4, type: "spring", stiffness: 200 }}
                          whileHover={{ scale: 1.2, rotate: activeIndex === index ? 45 : 15 }}
                          className="flex-shrink-0 w-10 h-10 flex items-center justify-center rounded-full bg-gradient-to-br from-primary-100 to-primary-200 dark:from-primary-800 dark:to-primary-700 text-primary-600 dark:text-primary-300 shadow-md"
                        >
                          <motion.svg 
                            className="w-5 h-5" 
                            xmlns="http://www.w3.org/2000/svg" 
                            fill="none" 
                            viewBox="0 0 24 24" 
                            stroke="currentColor"
                            strokeWidth={2.5}
                          >
                            <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                          </motion.svg>
                        </motion.div>
                      </button>
                  
                      <AnimatePresence initial={false}>
                        {activeIndex === index && (
                          <motion.div
                            key={`content-${index}`}
                            variants={{
                              hidden: { 
                                height: 0,
                                opacity: 0,
                                marginTop: 0,
                                transition: { 
                                  duration: 0.3,
                                  ease: "easeInOut"
                                }
                              },
                              visible: { 
                                height: "auto",
                                opacity: 1,
                                marginTop: 20,
                                transition: { 
                                  duration: 0.4,
                                  ease: "easeOut"
                                }
                              }
                            }}
                            initial="hidden"
                            animate="visible"
                            exit="hidden"
                            className="overflow-hidden"
                          >
                            <motion.div 
                              initial={{ opacity: 0, y: 15 }}
                              animate={{ opacity: 1, y: 0 }}
                              transition={{ duration: 0.4, delay: 0.1 }}
                              className="pb-2"
                            >
                              <div className="w-full h-px bg-gradient-to-r from-transparent via-primary-200 to-transparent mb-4" />
                              <motion.p 
                                initial={{ opacity: 0, y: 10 }}
                                animate={{ opacity: 1, y: 0 }}
                                transition={{ duration: 0.4, delay: 0.2 }}
                                className="text-secondary-600 dark:text-gray-300 leading-relaxed text-base"
                              >
                                {faq.answer}
                              </motion.p>
                            </motion.div>
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </motion.div>
                  </motion.div>
                )
              })}
            </AnimatePresence>
          </motion.div>
          
          {/* Bouton de support supplémentaire */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.8 }}
            className="flex justify-center mt-12"
          >
            <a 
              href="/contact" 
              className="group inline-flex items-center justify-center px-6 py-3 rounded-lg bg-primary-50 text-primary-600 hover:bg-primary-100 transition-all duration-300 border border-primary-200 shadow-sm"
            >
              <span className="mr-2">Vous avez d'autres questions?</span>
              <motion.span 
                initial={{ x: 0 }}
                whileHover={{ x: 5 }}
                transition={{ duration: 0.2 }}
                className="inline-flex"
              >
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-5 h-5">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M8.625 12a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H8.25m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H12m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0h-.375M21 12c0 4.556-4.03 8.25-9 8.25a9.764 9.764 0 01-2.555-.337A5.972 5.972 0 015.41 20.97a5.969 5.969 0 01-.474-.065 4.48 4.48 0 00.978-2.025c.09-.457-.133-.901-.467-1.226C3.93 16.178 3 14.189 3 12c0-4.556 4.03-8.25 9-8.25s9 3.694 9 8.25z" />
                </svg>
              </motion.span>
            </a>
          </motion.div>
        </div>
      </div>
    </motion.section>
  )
}

export default FAQ 