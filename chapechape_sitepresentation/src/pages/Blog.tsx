import { motion, AnimatePresence } from 'framer-motion'
import { useState } from 'react'
import { apiService, validateNewsletterForm, type NewsletterData } from '../services/api.service'
import { trackContactForm } from '../components/analytics/GoogleAnalytics'
import { useToast } from '../components/ui/ToastProvider'
import SEOHead from '../components/seo/SEOHead'

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com'

// Données des articles de blog
const blogPosts = [
  {
    id: 1,
    title: "L'évolution du marché immobilier en Côte d'Ivoire en 2024",
    excerpt: "Analyse des tendances actuelles du marché immobilier ivoirien et perspectives pour les investisseurs.",
    content: "Lorem ipsum dolor sit amet...",
    category: "marché",
    author: "Adams Diaby",
    authorRole: "CEO & Co-fondateur",
    authorImage: "/assets/team/adams-diaby.jpg",
    date: "15 avril 2024",
    readTime: "8 min",
    image: "https://images.unsplash.com/photo-1560518883-ce09059eeffa?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",
    tags: ["Marché immobilier", "Investissement", "Côte d'Ivoire"]
  },
  {
    id: 2,
    title: "5 conseils pour aménager un petit espace avec style",
    excerpt: "Découvrez comment maximiser l'espace et le confort dans un studio ou un petit appartement.",
    content: "Lorem ipsum dolor sit amet...",
    category: "décoration",
    author: "Marie Koné",
    authorRole: "Décoratrice d'intérieur",
    authorImage: "/assets/blog/author-marie.svg",
    date: "28 mars 2024",
    readTime: "5 min",
    image: "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",
    tags: ["Décoration", "Studio", "Petit espace"]
  },
  {
    id: 3,
    title: "Guide complet de la location en Afrique de l'Ouest : droits et obligations",
    excerpt: "Tout ce que vous devez savoir sur les aspects juridiques de la location dans différents pays d'Afrique de l'Ouest.",
    content: "Lorem ipsum dolor sit amet...",
    category: "juridique",
    author: "Me Pascal Amoikon",
    authorRole: "Consultant juridique",
    authorImage: "/assets/blog/author-pascal.svg",
    date: "12 mars 2024",
    readTime: "12 min",
    image: "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",
    tags: ["Juridique", "Location", "Droits"]
  },
  {
    id: 4,
    title: "Les quartiers émergents d'Abidjan pour investir en 2024",
    excerpt: "Focus sur les zones en développement qui offrent les meilleures opportunités pour les investisseurs immobiliers.",
    content: "Lorem ipsum dolor sit amet...",
    category: "investissement",
    author: "Sidney Jordan",
    authorRole: "CTO & Co-fondateur",
    authorImage: "/assets/team/sidney-jordan.jpg",
    date: "5 mars 2024",
    readTime: "10 min",
    image: "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",
    tags: ["Investissement", "Abidjan", "Quartiers"]
  },
  {
    id: 5,
    title: "Comment préparer efficacement son dossier de location",
    excerpt: "Conseils pratiques pour constituer un dossier de location solide et augmenter vos chances d'obtenir le logement de vos rêves.",
    content: "Lorem ipsum dolor sit amet...",
    category: "conseil",
    author: "Aminata Touré",
    authorRole: "Responsable Relations Clients",
    authorImage: "/assets/blog/author-aminata.svg",
    date: "20 février 2024",
    readTime: "7 min",
    image: "https://images.unsplash.com/photo-1554224155-6726b3ff858f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",
    tags: ["Conseils", "Location", "Dossier"]
  },
  {
    id: 6,
    title: "Les avantages de la gestion locative professionnelle pour les propriétaires",
    excerpt: "Pourquoi confier la gestion de votre bien immobilier à des professionnels peut être un choix judicieux.",
    content: "Lorem ipsum dolor sit amet...",
    category: "gestion",
    author: "Adams Diaby",
    authorRole: "CEO & Co-fondateur",
    authorImage: "/assets/team/adams-diaby.jpg",
    date: "12 février 2024",
    readTime: "6 min",
    image: "https://images.unsplash.com/photo-1560518883-ce09059eeffa?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",
    tags: ["Gestion locative", "Propriétaires", "Services"]
  }
]

// Catégories d'articles
const categories = [
  { id: "tous", name: "Tous les articles" },
  { id: "marché", name: "Marché immobilier" },
  { id: "investissement", name: "Investissement" },
  { id: "décoration", name: "Décoration & Design" },
  { id: "conseil", name: "Conseils pratiques" },
  { id: "juridique", name: "Informations juridiques" },
  { id: "gestion", name: "Gestion locative" }
]

const Blog = () => {
  const [activeCategory, setActiveCategory] = useState("tous")

  // État pour le formulaire newsletter
  const [newsletterData, setNewsletterData] = useState<NewsletterData>({
    email: '',
    firstName: '',
    lastName: ''
  })
  const [isSubmittingNewsletter, setIsSubmittingNewsletter] = useState(false)
  const [newsletterErrors, setNewsletterErrors] = useState<string[]>([])
  const [newsletterSuccess, setNewsletterSuccess] = useState(false)

  const { showToast } = useToast()

  // Gestion de la soumission newsletter
  const handleNewsletterSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setNewsletterErrors([])
    setNewsletterSuccess(false)

    // Validation côté client
    const errors = validateNewsletterForm(newsletterData)
    if (errors.length > 0) {
      setNewsletterErrors(errors)
      showToast('Veuillez corriger les erreurs dans le formulaire', 'error')
      return
    }

    setIsSubmittingNewsletter(true)

    try {
      const response = await apiService.subscribeNewsletter(newsletterData)

      if (response.success) {
        setNewsletterSuccess(true)
        showToast('Inscription à la newsletter réussie !', 'success')
        // Tracker l'événement Google Analytics
        trackContactForm('newsletter')
        setNewsletterData({ email: '', firstName: '', lastName: '' })
      } else {
        const errorMsg = response.message || 'Une erreur est survenue lors de l\'inscription.'
        setNewsletterErrors([errorMsg])
        showToast(errorMsg, 'error')
      }
    } catch (error) {
      console.error('Erreur lors de l\'inscription à la newsletter:', error)
      const errorMsg = 'Une erreur est survenue. Veuillez réessayer plus tard.'
      setNewsletterErrors([errorMsg])
      showToast(errorMsg, 'error')
    } finally {
      setIsSubmittingNewsletter(false)
    }
  }

  // Filtrer les articles par catégorie
  const filteredPosts = activeCategory === "tous"
    ? blogPosts
    : blogPosts.filter(post => post.category === activeCategory)

  return (
    <div className="bg-white">
      <SEOHead
        title="Blog"
        description="Actualités et conseils immobilier en Côte d'Ivoire : marché, décoration, investissement. ChapeChape Residence."
        url={`${siteUrl}/blog`}
      />
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
              Actualités & Conseils
            </span>
            <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              Le Blog <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">ChapeChape</span>
            </h1>
            <p className="text-xl text-gray-300 mb-10 max-w-2xl mx-auto font-light leading-relaxed">
              Restez informé des dernières tendances du marché immobilier, découvrez nos conseils d'experts et suivez l'actualité de ChapeChape Residence.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Main content */}
      <div className="container mx-auto px-4 max-w-7xl py-16 sm:py-24">
        {/* Filtres */}
        <div className="mb-16">
          <h2 className="text-xl font-semibold text-secondary-900 mb-6 text-center font-display">
            Explorer par catégorie
          </h2>
          <div className="flex flex-wrap justify-center gap-3">
            {categories.map(category => (
              <button
                key={category.id}
                className={`px-4 py-2 rounded-full text-sm font-medium transition-all duration-300 ${activeCategory === category.id
                  ? 'bg-primary-500 text-white shadow-lg shadow-primary-500/30'
                  : 'bg-gray-100 text-secondary-600 hover:bg-gray-200'
                  }`}
                onClick={() => setActiveCategory(category.id)}
              >
                {category.name}
              </button>
            ))}
          </div>
        </div>

        {/* Articles */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {filteredPosts.map((post, index) => (
            <motion.div
              key={post.id}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className="bg-white rounded-2xl shadow-lg overflow-hidden hover:shadow-2xl transition-all duration-300 flex flex-col h-full border border-gray-100 group"
            >
              <div className="overflow-hidden h-56 relative">
                <div className="absolute inset-0 bg-secondary-900/10 group-hover:bg-secondary-900/0 transition-colors z-10" />
                <img
                  src={post.image}
                  alt={post.title}
                  className="w-full h-full object-cover transform group-hover:scale-110 transition-transform duration-700"
                />
                <div className="absolute top-4 left-4 z-20">
                  <span className="inline-block px-3 py-1 text-xs font-bold uppercase tracking-wider bg-white/90 backdrop-blur-sm text-primary-600 rounded-full shadow-sm">
                    {categories.find(cat => cat.id === post.category)?.name || post.category}
                  </span>
                </div>
              </div>
              <div className="p-8 flex-grow flex flex-col">
                <h3 className="text-xl font-bold text-secondary-900 mb-3 font-display group-hover:text-primary-600 transition-colors">{post.title}</h3>
                <p className="text-secondary-600 mb-6 flex-grow leading-relaxed">{post.excerpt}</p>

                <div className="flex items-center justify-between mt-auto pt-6 border-t border-gray-100">
                  <div className="flex items-center">
                    <div className="h-10 w-10 rounded-full overflow-hidden bg-primary-100 mr-3 ring-2 ring-white shadow-sm">
                      {post.authorImage ? (
                        <img
                          src={post.authorImage}
                          alt={post.author}
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <span className="flex items-center justify-center h-full w-full text-primary-500 font-bold">
                          {post.author.charAt(0)}
                        </span>
                      )}
                    </div>
                    <div className="text-sm">
                      <span className="font-bold text-secondary-900 block">{post.author}</span>
                      <span className="text-xs text-gray-500">{post.date}</span>
                    </div>
                  </div>
                  <div className="text-xs font-medium text-primary-500 bg-primary-50 px-2 py-1 rounded-md">
                    {post.readTime}
                  </div>
                </div>
              </div>
              <div className="px-8 py-4 bg-gray-50 border-t border-gray-100 flex justify-between items-center group-hover:bg-primary-50/30 transition-colors">
                <span className="text-sm font-medium text-gray-500">Lire la suite</span>
                <svg className="w-5 h-5 text-primary-500 transform group-hover:translate-x-1 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                </svg>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Newsletter */}
        <div className="mt-24 bg-secondary-900 rounded-3xl p-8 sm:p-16 relative overflow-hidden shadow-2xl">
          {/* Background pattern */}
          <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-5 mix-blend-overlay" />
          <div className="absolute top-0 right-0 w-64 h-64 bg-primary-500/20 rounded-full blur-3xl transform translate-x-1/2 -translate-y-1/2" />
          <div className="absolute bottom-0 left-0 w-64 h-64 bg-primary-500/10 rounded-full blur-3xl transform -translate-x-1/2 translate-y-1/2" />

          <div className="max-w-3xl mx-auto relative z-10">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="text-center"
            >
              <h2 className="text-3xl font-bold text-white mb-6 font-display">
                Restez connecté à l'immobilier
              </h2>
              <p className="text-primary-100 mb-10 text-lg">
                Inscrivez-vous à notre newsletter pour recevoir nos derniers articles, conseils exclusifs et
                opportunités d'investissement en avant-première.
              </p>

              <form onSubmit={handleNewsletterSubmit} className="space-y-4 max-w-lg mx-auto">
                {/* Champs prénom et nom (optionnels) */}
                <div className="flex flex-col sm:flex-row gap-4">
                  <input
                    type="text"
                    placeholder="Prénom (optionnel)"
                    value={newsletterData.firstName}
                    onChange={(e) => setNewsletterData(prev => ({ ...prev, firstName: e.target.value }))}
                    className="px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-400 focus:bg-white/20 transition-all duration-200 w-full"
                  />
                  <input
                    type="text"
                    placeholder="Nom (optionnel)"
                    value={newsletterData.lastName}
                    onChange={(e) => setNewsletterData(prev => ({ ...prev, lastName: e.target.value }))}
                    className="px-4 py-3 rounded-xl bg-white/10 border border-white/20 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-400 focus:bg-white/20 transition-all duration-200 w-full"
                  />
                </div>

                {/* Email (obligatoire) et bouton */}
                <div className="flex flex-col sm:flex-row gap-4">
                  <input
                    type="email"
                    placeholder="Votre adresse email *"
                    value={newsletterData.email}
                    onChange={(e) => setNewsletterData(prev => ({ ...prev, email: e.target.value }))}
                    required
                    className="px-4 py-3 rounded-xl flex-grow bg-white/10 border border-white/20 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-400 focus:bg-white/20 transition-all duration-200"
                  />
                  <motion.button
                    type="submit"
                    disabled={isSubmittingNewsletter}
                    whileHover={{ scale: isSubmittingNewsletter ? 1 : 1.05 }}
                    whileTap={{ scale: isSubmittingNewsletter ? 1 : 0.95 }}
                    className="btn-primary whitespace-nowrap relative overflow-hidden disabled:opacity-70 disabled:cursor-not-allowed shadow-lg shadow-primary-500/30"
                  >
                    {isSubmittingNewsletter ? (
                      <span className="flex items-center">
                        <motion.svg
                          className="animate-spin -ml-1 mr-3 h-4 w-4"
                          xmlns="http://www.w3.org/2000/svg"
                          fill="none"
                          viewBox="0 0 24 24"
                          animate={{ rotate: 360 }}
                          transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                        >
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </motion.svg>
                        Inscription...
                      </span>
                    ) : (
                      'S\'inscrire'
                    )}
                  </motion.button>
                </div>

                {/* Affichage des erreurs */}
                <AnimatePresence>
                  {newsletterErrors.length > 0 && (
                    <motion.div
                      initial={{ opacity: 0, y: -10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -10 }}
                      className="bg-red-500/20 border border-red-500/50 text-red-200 px-4 py-3 rounded-xl backdrop-blur-sm"
                    >
                      <ul className="list-disc list-inside space-y-1">
                        {newsletterErrors.map((error, index) => (
                          <li key={index} className="text-sm">{error}</li>
                        ))}
                      </ul>
                    </motion.div>
                  )}
                </AnimatePresence>

                {/* Message de succès */}
                <AnimatePresence>
                  {newsletterSuccess && (
                    <motion.div
                      initial={{ opacity: 0, y: -10, scale: 0.9 }}
                      animate={{ opacity: 1, y: 0, scale: 1 }}
                      exit={{ opacity: 0, y: -10, scale: 0.9 }}
                      className="bg-green-500/20 border border-green-500/50 text-green-200 px-4 py-3 rounded-xl flex items-center backdrop-blur-sm"
                    >
                      <motion.svg
                        className="w-5 h-5 mr-2"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                        initial={{ scale: 0 }}
                        animate={{ scale: 1 }}
                        transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
                      >
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                      </motion.svg>
                      <span className="text-sm font-medium">Inscription réussie ! Vous recevrez bientôt nos actualités.</span>
                    </motion.div>
                  )}
                </AnimatePresence>
              </form>
              <p className="text-gray-400 text-xs mt-6">
                Vous pouvez vous désinscrire à tout moment. En vous inscrivant, vous acceptez notre politique de confidentialité.
              </p>
            </motion.div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Blog