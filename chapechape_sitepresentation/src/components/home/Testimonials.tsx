import { useState, useRef, useEffect } from 'react'
import { motion, useScroll, useTransform, AnimatePresence } from 'framer-motion'

type Testimonial = {
  id: number
  name: string
  role: string
  avatar: string
  content: string
  rating: number
  location: string
}

const testimonials: Testimonial[] = [
  {
    id: 1,
    name: "Amara Koné",
    role: "Locataire",
    avatar: "/assets/testimonials/avatar1.jpg",
    content: "Grâce à ChapeChape Residence, j'ai trouvé rapidement un appartement meublé qui correspondait parfaitement à mes attentes. Le processus était simple et la qualité du service irréprochable. Je recommande vivement cette plateforme à tous ceux qui cherchent un logement de qualité en Côte d'Ivoire!",
    rating: 5,
    location: "Abidjan, Côte d'Ivoire"
  },
  {
    id: 2,
    name: "Mohamed Diallo",
    role: "Propriétaire",
    avatar: "/assets/testimonials/avatar2.jpg",
    content: "En tant que propriétaire, j'apprécie la simplicité avec laquelle je peux gérer mes résidences sur ChapeChape. Les réservations affluent et le système de paiement est sécurisé. C'est exactement ce dont j'avais besoin pour optimiser la gestion de mes biens immobiliers.",
    rating: 5,
    location: "Dakar, Sénégal"
  },
  {
    id: 3,
    name: "Fatou Sow",
    role: "Entreprise",
    avatar: "/assets/testimonials/avatar3.jpg",
    content: "Notre entreprise utilise ChapeChape Residence pour loger nos collaborateurs internationaux lors de leurs missions. La variété des résidences disponibles et la fiabilité du service nous ont permis de simplifier considérablement notre gestion des déplacements professionnels.",
    rating: 4,
    location: "Abidjan, Côte d'Ivoire"
  }
]

const Testimonials = () => {
  const [currentIndex, setCurrentIndex] = useState(0)
  const [direction, setDirection] = useState(0)
  const intervalRef = useRef<number | null>(null)
  const containerRef = useRef(null)

  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"]
  })

  // Effets de parallaxe
  const y = useTransform(scrollYProgress, [0, 1], [50, -50])
  const opacity = useTransform(scrollYProgress, [0, 0.2, 0.8, 1], [0.3, 1, 1, 0.3])

  // Défilement automatique des témoignages
  useEffect(() => {
    const startAutoSlide = () => {
      intervalRef.current = window.setInterval(() => {
        setDirection(1)
        setCurrentIndex((prevIndex) => (prevIndex + 1) % testimonials.length)
      }, 8000)
    }

    startAutoSlide()

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current)
      }
    }
  }, [])

  // Réinitialiser le timer lors du changement manuel
  const handleSlideChange = (index: number) => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current)
    }

    setDirection(index > currentIndex ? 1 : -1)
    setCurrentIndex(index)

    intervalRef.current = window.setInterval(() => {
      setDirection(1)
      setCurrentIndex((prevIndex) => (prevIndex + 1) % testimonials.length)
    }, 8000)
  }

  // Fonction pour naviguer au témoignage suivant
  const goToNext = () => {
    setDirection(1)
    setCurrentIndex((prevIndex) => (prevIndex + 1) % testimonials.length)

    if (intervalRef.current) {
      clearInterval(intervalRef.current)
      intervalRef.current = window.setInterval(() => {
        setDirection(1)
        setCurrentIndex((prevIndex) => (prevIndex + 1) % testimonials.length)
      }, 8000)
    }
  }

  // Fonction pour naviguer au témoignage précédent
  const goToPrevious = () => {
    setDirection(-1)
    setCurrentIndex((prevIndex) => (prevIndex - 1 + testimonials.length) % testimonials.length)

    if (intervalRef.current) {
      clearInterval(intervalRef.current)
      intervalRef.current = window.setInterval(() => {
        setDirection(1)
        setCurrentIndex((prevIndex) => (prevIndex + 1) % testimonials.length)
      }, 8000)
    }
  }

  // Variants d'animation pour le conteneur
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
        delayChildren: 0.3
      }
    }
  }

  // Variants d'animation pour le témoignage
  const cardVariants = {
    enter: (direction: number) => ({
      x: direction > 0 ? 100 : -100,
      opacity: 0,
      scale: 0.9,
    }),
    center: {
      x: 0,
      opacity: 1,
      scale: 1,
      transition: {
        type: "spring",
        stiffness: 100,
        damping: 15,
      }
    },
    exit: (direction: number) => ({
      x: direction > 0 ? -100 : 100,
      opacity: 0,
      scale: 0.9,
      transition: {
        duration: 0.3,
      }
    })
  }

  // Variants pour l'effet de scintillement de l'étoile
  const starGlowVariants = {
    initial: { opacity: 0.3, scale: 1 },
    animate: {
      opacity: [0.3, 1, 0.3],
      scale: [1, 1.1, 1],
      transition: {
        duration: 2,
        repeat: Infinity,
        ease: "easeInOut",
      }
    }
  }

  // Variantes pour les quotes
  const quoteVariants = {
    hidden: { opacity: 0, scale: 0 },
    visible: {
      opacity: 1,
      scale: 1,
      transition: {
        type: "spring",
        stiffness: 300,
        damping: 15,
        delay: 0.5
      }
    }
  }

  // Effet de particules dorées
  const glitterVariants = {
    animate: (i: number) => ({
      opacity: [0, 0.7, 0],
      scale: [0.4, 1, 0.4],
      x: [0, Math.random() * 100 - 50, 0],
      y: [0, Math.random() * 100 - 50, 0],
      transition: {
        duration: Math.random() * 3 + 5,
        repeat: Infinity,
        delay: i * 0.3,
      }
    })
  }

  return (
    <section
      ref={containerRef}
      className="relative py-24 overflow-hidden"
    >
      {/* Arrière-plan avec dégradé */}
      <motion.div
        className="absolute inset-0 bg-white -z-10"
        style={{ y, opacity }}
      />

      {/* Motif élégant en arrière-plan */}
      <motion.div
        className="absolute inset-0 bg-[linear-gradient(135deg,rgba(212,175,55,0.03)_1px,transparent_1px),linear-gradient(45deg,rgba(212,175,55,0.03)_1px,transparent_1px)] bg-[size:30px_30px] -z-10"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 1.5 }}
      />

      {/* Symboles de guillemets géants en arrière-plan */}
      <div className="absolute top-20 left-10 opacity-5 text-primary-300 text-[200px] font-serif">
        <motion.div
          variants={quoteVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
        >
          "
        </motion.div>
      </div>
      <div className="absolute bottom-20 right-10 opacity-5 text-primary-300 text-[200px] font-serif">
        <motion.div
          variants={quoteVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
        >
          "
        </motion.div>
      </div>

      {/* Particules dorées subtiles */}
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

      <div className="container-custom">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl font-bold text-secondary-900 mb-4 font-display">Ce que disent nos utilisateurs</h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-secondary-600 max-w-2xl mx-auto"
          >
            Découvrez les témoignages de nos clients satisfaits qui ont trouvé la résidence de leurs rêves grâce à ChapeChape Residence.
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

        <div className="relative max-w-4xl mx-auto px-4">
          {/* Contrôles de navigation */}
          <div className="absolute left-0 right-0 top-1/2 -translate-y-1/2 flex justify-between z-10 pointer-events-none">
            <motion.button
              className="w-12 h-12 rounded-full bg-white shadow-md text-primary-500 flex items-center justify-center pointer-events-auto transform -translate-x-1/2 hover:bg-primary-50 transition-all duration-300"
              onClick={goToPrevious}
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.95 }}
            >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-5 h-5">
                <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
              </svg>
            </motion.button>
            <motion.button
              className="w-12 h-12 rounded-full bg-white shadow-md text-primary-500 flex items-center justify-center pointer-events-auto transform translate-x-1/2 hover:bg-primary-50 transition-all duration-300"
              onClick={goToNext}
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.95 }}
            >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor" className="w-5 h-5">
                <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
              </svg>
            </motion.button>
          </div>

          {/* Témoignages */}
          <motion.div
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            className="relative overflow-hidden min-h-[400px] flex items-center justify-center"
          >
            <AnimatePresence custom={direction} mode="wait">
              <motion.div
                key={testimonials[currentIndex].id}
                custom={direction}
                variants={cardVariants}
                initial="enter"
                animate="center"
                exit="exit"
                className="absolute w-full"
              >
                <div className="bg-white rounded-2xl shadow-xl overflow-hidden border border-primary-100">
                  <div className="p-8 flex flex-col md:flex-row gap-8">
                    {/* Avatar et informations */}
                    <div className="flex flex-col items-center md:items-start space-y-4 md:w-1/3">
                      <div className="w-20 h-20 rounded-full overflow-hidden border-2 border-primary-300 shadow-lg">
                        {/* Image de substitution si l'avatar n'est pas disponible */}
                        <div className="w-full h-full bg-gradient-to-br from-primary-200 to-primary-300 flex items-center justify-center text-secondary-800 text-xl font-semibold">
                          {testimonials[currentIndex].name.charAt(0)}
                        </div>
                      </div>

                      <div className="text-center md:text-left">
                        <h3 className="text-lg font-semibold text-secondary-900">{testimonials[currentIndex].name}</h3>
                        <p className="text-sm text-secondary-500">{testimonials[currentIndex].role}</p>
                        <p className="text-xs text-secondary-400 mt-1">{testimonials[currentIndex].location}</p>
                      </div>

                      {/* Étoiles de notation */}
                      <div className="flex space-x-1">
                        {[...Array(5)].map((_, i) => (
                          <motion.span
                            key={i}
                            variants={i < testimonials[currentIndex].rating ? starGlowVariants : {}}
                            initial="initial"
                            animate="animate"
                            className={i < testimonials[currentIndex].rating ? "text-primary-400" : "text-secondary-300"}
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
                              <path fillRule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.007 5.404.433c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.433 2.082-5.006z" clipRule="evenodd" />
                            </svg>
                          </motion.span>
                        ))}
                      </div>
                    </div>

                    {/* Contenu du témoignage */}
                    <div className="md:w-2/3 relative">
                      {/* Guillemets */}
                      <svg className="absolute -top-2 -left-2 h-8 w-8 text-primary-200 opacity-50" fill="currentColor" viewBox="0 0 32 32">
                        <path d="M9.352 4C4.456 7.456 1 13.12 1 19.36c0 5.088 3.072 8.064 6.624 8.064 3.36 0 5.856-2.688 5.856-5.856 0-3.168-2.208-5.472-5.088-5.472-.576 0-1.344.096-1.536.192.48-3.264 3.552-7.104 6.624-9.024L9.352 4zm16.512 0c-4.8 3.456-8.256 9.12-8.256 15.36 0 5.088 3.072 8.064 6.624 8.064 3.264 0 5.856-2.688 5.856-5.856 0-3.168-2.304-5.472-5.184-5.472-.576 0-1.248.096-1.44.192.48-3.264 3.456-7.104 6.528-9.024L25.864 4z" />
                      </svg>

                      <motion.p
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.5, delay: 0.3 }}
                        className="relative z-10 text-secondary-700 italic text-lg leading-relaxed"
                      >
                        {testimonials[currentIndex].content}
                      </motion.p>
                    </div>
                  </div>
                </div>
              </motion.div>
            </AnimatePresence>
          </motion.div>

          {/* Indicateurs */}
          <div className="flex justify-center space-x-2 mt-8">
            {testimonials.map((_, index) => (
              <motion.button
                key={index}
                onClick={() => handleSlideChange(index)}
                className={`w-3 h-3 rounded-full transition-all duration-300 ${index === currentIndex ? 'bg-primary-400 w-8' : 'bg-primary-200'}`}
                whileHover={{ scale: 1.2 }}
                whileTap={{ scale: 0.9 }}
              />
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}

export default Testimonials