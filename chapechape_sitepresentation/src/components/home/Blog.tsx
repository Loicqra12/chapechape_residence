import { motion, useScroll, useTransform } from 'framer-motion'
import { Link } from 'react-router-dom'
import { useState, useRef } from 'react'

const posts = [
  {
    title: "Comment trouver le logement parfait à Cotonou ?",
    excerpt: "Découvrez nos conseils d'experts pour dénicher le logement idéal qui correspond à vos besoins et à votre budget à Cotonou.",
    imageUrl: "https://images.unsplash.com/photo-1560518883-ce09059eeffa?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=250&q=80",
    date: "10 Mai 2025",
    author: "Marie Konaté",
    category: "Conseils"
  },
  {
    title: "Les tendances immobilières en Afrique de l'Ouest pour 2025",
    excerpt: "Analyse des évolutions du marché immobilier en Afrique de l'Ouest et perspectives pour les investisseurs et locataires.",
    imageUrl: "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=250&q=80",
    date: "2 Mai 2025",
    author: "Jean-Pierre Kouassi",
    category: "Marché immobilier"
  },
  {
    title: "5 avantages de la gestion immobilière digitale",
    excerpt: "Pourquoi la digitalisation de la gestion immobilière représente une révolution pour les propriétaires et les gestionnaires de biens.",
    imageUrl: "https://images.unsplash.com/photo-1551434678-e076c223a692?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=250&q=80",
    date: "25 Avril 2025",
    author: "Sophie Mensah",
    category: "Technologie"
  }
]

const Blog = () => {
  const [hoveredPost, setHoveredPost] = useState<number | null>(null)
  const sectionRef = useRef(null)
  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start end", "end start"]
  })

  // Parallax effect pour le background
  const y = useTransform(scrollYProgress, [0, 1], ["0%", "50%"])
  const opacity = useTransform(scrollYProgress, [0, 0.2, 0.8, 1], [0.3, 1, 1, 0.3])



  return (
    <section className="py-32 bg-secondary-50 dark:bg-secondary-800 relative overflow-hidden" ref={sectionRef}>
      {/* Background parallax animé */}
      <motion.div 
        className="absolute inset-0 opacity-30 dark:opacity-20"
        style={{ y, opacity }}
      >
        <div 
          className="w-full h-full"
          style={{
            backgroundImage: `
              radial-gradient(circle at 20% 20%, rgba(212, 175, 55, 0.1) 0%, transparent 50%),
              radial-gradient(circle at 80% 80%, rgba(212, 175, 55, 0.08) 0%, transparent 50%),
              linear-gradient(45deg, transparent 40%, rgba(212, 175, 55, 0.03) 50%, transparent 60%)
            `
          }}
        />
      </motion.div>

      <div className="container-custom relative z-10">
        {/* Header avec animations premium */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8, ease: "easeOut" }}
          className="text-center mb-20"
        >
          {/* Badge premium animé */}
          <motion.div
            initial={{ scale: 0, rotate: -10 }}
            whileInView={{ scale: 1, rotate: 0 }}
            transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
            className="inline-flex items-center px-4 py-2 rounded-full bg-gradient-to-r from-primary-300/20 via-primary-400/20 to-primary-300/20 border border-primary-300/30 mb-6"
          >
            <motion.span 
              className="text-sm font-medium text-primary-700 dark:text-primary-300"
              animate={{ 
                backgroundPosition: ['0% 50%', '100% 50%', '0% 50%']
              }}
              transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
              style={{
                background: 'linear-gradient(90deg, currentColor 0%, rgba(212, 175, 55, 0.8) 50%, currentColor 100%)',
                backgroundSize: '200% 100%',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent'
              }}
            >
              📚 Blog & Actualités
            </motion.span>
          </motion.div>

          <motion.h2 
            className="text-6xl font-bold mb-6"
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3, duration: 0.6 }}
          >
            <span className="bg-gradient-to-r from-secondary-900 via-primary-600 to-secondary-900 bg-clip-text text-transparent dark:from-white dark:via-primary-300 dark:to-white">
              Actualités & Conseils
            </span>
          </motion.h2>

          <motion.p 
            className="text-xl text-secondary-600 dark:text-secondary-300 max-w-3xl mx-auto leading-relaxed"
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            transition={{ delay: 0.4, duration: 0.6 }}
          >
            Restez informé des dernières tendances du marché immobilier et découvrez nos conseils d'experts pour réussir vos projets.
          </motion.p>
        </motion.div>

        {/* Grid layout avec lazy loading - Style Stripe Premium */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {posts.map((post, index) => {
            const isHovered = hoveredPost === index
            
            return (
              <motion.article
                key={index}
                initial={{ opacity: 0, y: 60, scale: 0.9 }}
                whileInView={{ opacity: 1, y: 0, scale: 1 }}
                viewport={{ once: true, margin: "-50px" }}
                transition={{ 
                  duration: 0.7, 
                  delay: index * 0.2,
                  type: "spring",
                  stiffness: 100,
                  damping: 15
                }}
                whileHover={{
                  y: -15,
                  scale: 1.02,
                  transition: { duration: 0.3, ease: "easeOut" }
                }}
                onHoverStart={() => setHoveredPost(index)}
                onHoverEnd={() => setHoveredPost(null)}
                className="group relative bg-white/80 dark:bg-secondary-900/80 backdrop-blur-sm rounded-2xl overflow-hidden shadow-lg hover:shadow-2xl transition-all duration-500 cursor-pointer border border-secondary-100 dark:border-secondary-700"
                style={{
                  filter: hoveredPost !== null && hoveredPost !== index ? 'brightness(0.8) blur(2px)' : 'brightness(1) blur(0px)',
                  transition: 'filter 0.4s ease'
                }}
              >
                {/* Image avec hover zoom et parallax */}
                <div className="relative h-56 bg-gradient-to-br from-primary-300/20 via-primary-400/10 to-secondary-200/20 overflow-hidden">
                  {/* Image réelle */}
                  <motion.img
                    src={post.imageUrl}
                    alt={post.title}
                    className="absolute inset-0 w-full h-full object-cover"
                    initial={{ scale: 1.1, opacity: 0 }}
                    whileInView={{ scale: 1, opacity: 1 }}
                    transition={{ duration: 0.6, ease: "easeOut" }}
                    animate={{
                      scale: isHovered ? 1.05 : 1
                    }}
                  />
                  
                  {/* Overlay gradient avec hover effect */}
                  <motion.div 
                    className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent"
                    animate={{ opacity: isHovered ? 0.8 : 0.3 }}
                    transition={{ duration: 0.3 }}
                  />
                  
                  {/* Effet parallax sur l'image (simulé) */}
                  <motion.div
                    className="absolute inset-0 bg-gradient-to-br from-primary-300/30 via-primary-400/20 to-secondary-200/30"
                    animate={{
                      scale: isHovered ? 1.1 : 1,
                      rotate: isHovered ? 1 : 0
                    }}
                    transition={{ duration: 0.6, ease: "easeOut" }}
                  />
                  
                  {/* Badge catégorie animé */}
                  <motion.div
                    className="absolute top-4 left-4 z-10"
                    initial={{ scale: 0, rotate: -10 }}
                    whileInView={{ scale: 1, rotate: 0 }}
                    transition={{ delay: index * 0.2 + 0.5, type: "spring" }}
                  >
                    <motion.span 
                      className="inline-block px-3 py-1 rounded-full text-xs font-semibold bg-gradient-to-r from-primary-400 via-primary-300 to-primary-400 text-secondary-900 shadow-lg"
                      whileHover={{ scale: 1.1, rotate: 5 }}
                      animate={{
                        boxShadow: [
                          "0 4px 15px rgba(212, 175, 55, 0.3)",
                          "0 4px 25px rgba(212, 175, 55, 0.5)",
                          "0 4px 15px rgba(212, 175, 55, 0.3)"
                        ]
                      }}
                      transition={{
                        boxShadow: { duration: 2, repeat: Infinity, ease: "easeInOut" }
                      }}
                    >
                      {post.category}
                    </motion.span>
                  </motion.div>
                  
                  {/* Date badge */}
                  <motion.div
                    className="absolute top-4 right-4 z-10"
                    initial={{ opacity: 0, x: 20 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.2 + 0.7 }}
                  >
                    <span className="inline-block px-2 py-1 rounded-lg text-xs font-medium bg-white/90 dark:bg-secondary-800/90 text-secondary-700 dark:text-secondary-300 backdrop-blur-sm">
                      {post.date}
                    </span>
                  </motion.div>
                </div>
                
                {/* Content avec animations */}
                <div className="p-6 relative">
                  {/* Background pattern subtil */}
                  <div className="absolute inset-0 opacity-5 dark:opacity-10">
                    <div className="w-full h-full bg-gradient-to-br from-primary-300/10 to-transparent" />
                  </div>
                  
                  <motion.h3 
                    className="text-xl font-bold text-secondary-900 dark:text-white mb-3 line-clamp-2 relative z-10"
                    initial={{ opacity: 0, y: 10 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.2 + 0.8 }}
                  >
                    {post.title}
                  </motion.h3>
                  
                  <motion.p 
                    className="text-secondary-600 dark:text-secondary-300 mb-6 line-clamp-3 leading-relaxed relative z-10"
                    initial={{ opacity: 0 }}
                    whileInView={{ opacity: 1 }}
                    transition={{ delay: index * 0.2 + 0.9 }}
                  >
                    {post.excerpt}
                  </motion.p>
                  
                  {/* Footer avec avatar bounce et lien animé */}
                  <motion.div 
                    className="flex items-center justify-between relative z-10"
                    initial={{ opacity: 0, y: 10 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.2 + 1 }}
                  >
                    {/* Avatar avec bounce effect */}
                    <div className="flex items-center space-x-3">
                      <motion.div
                        className="w-8 h-8 rounded-full bg-gradient-to-r from-primary-400 to-primary-300 flex items-center justify-center text-secondary-900 font-bold text-sm shadow-md"
                        whileHover={{ 
                          scale: 1.2,
                          rotate: 10,
                          y: -2
                        }}
                        animate={{
                          y: isHovered ? [-2, 2, -2] : 0
                        }}
                        transition={{
                          y: isHovered ? { duration: 0.6, repeat: Infinity, ease: "easeInOut" } : { duration: 0.3 }
                        }}
                      >
                        {post.author.split(' ').map(n => n[0]).join('')}
                      </motion.div>
                      <span className="text-sm text-secondary-500 dark:text-secondary-400 font-medium">
                        {post.author}
                      </span>
                    </div>
                    
                    {/* Lien "Lire plus" avec animation */}
                    <motion.div
                      whileHover={{ x: 5 }}
                      className="group/link"
                    >
                      <Link 
                        to="/blog" 
                        className="inline-flex items-center text-sm font-semibold text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300 transition-colors duration-200"
                      >
                        Lire plus
                        <motion.svg 
                          className="ml-1 h-4 w-4" 
                          xmlns="http://www.w3.org/2000/svg" 
                          fill="none" 
                          viewBox="0 0 24 24" 
                          stroke="currentColor"
                          animate={{
                            x: isHovered ? [0, 3, 0] : 0
                          }}
                          transition={{
                            duration: 0.6,
                            repeat: isHovered ? Infinity : 0,
                            ease: "easeInOut"
                          }}
                        >
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                        </motion.svg>
                      </Link>
                    </motion.div>
                  </motion.div>
                </div>
                
                {/* Glow effect au hover */}
                <motion.div
                  className="absolute -inset-1 rounded-2xl bg-gradient-to-r from-primary-400/20 via-primary-300/20 to-primary-400/20 blur-xl opacity-0 group-hover:opacity-100 -z-10"
                  transition={{ duration: 0.4 }}
                />
              </motion.article>
            )
          })}
        </div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.4 }}
          className="text-center mt-12"
        >
          <Link to="/blog" className="btn-secondary">
            Voir tous les articles
          </Link>
        </motion.div>
      </div>
    </section>
  )
}

export default Blog 