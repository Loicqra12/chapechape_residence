import { useState, useRef } from 'react'
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
  const containerRef = useRef(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"]
  })
  
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
              className="h-1 bg-primary-300 mx-auto mt-6"
            />
          </motion.div>

          <motion.div
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-50px" }}
            className="grid gap-5"
          >
            {faqs.map((faq, index) => (
              <motion.div
                key={index}
                variants={itemVariants}
                className="overflow-hidden"
              >
                <motion.div
                  className={`rounded-xl p-5 shadow-sm border border-primary-200/20 transition-all duration-300 ${activeIndex === index ? 'bg-gradient-to-r from-primary-50 to-white shadow-md border-primary-200/50' : 'bg-white hover:bg-primary-50/30'}`}
                  whileHover={{ scale: activeIndex === index ? 1 : 1.01, transition: { duration: 0.2 } }}
                >
                  <button
                    className="flex justify-between items-center w-full text-left focus:outline-none"
                    onClick={() => setActiveIndex(activeIndex === index ? null : index)}
                  >
                    <h3 className="text-lg font-semibold text-secondary-800 pr-6">{faq.question}</h3>
                    <motion.div
                      variants={iconVariants}
                      animate={activeIndex === index ? 'open' : 'closed'}
                      transition={{ duration: 0.3 }}
                      className="flex-shrink-0 w-6 h-6 flex items-center justify-center rounded-full bg-primary-100 text-primary-600"
                    >
                      <svg className="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                      </svg>
                    </motion.div>
                  </button>
                  
                  <AnimatePresence initial={false}>
                    {activeIndex === index && (
                      <motion.div
                        key={`content-${index}`}
                        variants={contentVariants}
                        initial="hidden"
                        animate="visible"
                        exit="hidden"
                      >
                        <div className="mt-4">
                          <motion.p 
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.3, delay: 0.1 }}
                            className="text-secondary-600"
                          >
                            {faq.answer}
                          </motion.p>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </motion.div>
              </motion.div>
            ))}
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