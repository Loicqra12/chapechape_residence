import { motion, AnimatePresence } from 'framer-motion'
import { useState } from 'react'
import { apiService, validateNewsletterForm, type NewsletterData } from '../services/api.service'
import { trackContactForm } from '../components/analytics/GoogleAnalytics'

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

  // Gestion de la soumission newsletter
  const handleNewsletterSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setNewsletterErrors([])
    setNewsletterSuccess(false)

    // Validation côté client
    const errors = validateNewsletterForm(newsletterData)
    if (errors.length > 0) {
      setNewsletterErrors(errors)
      return
    }

    setIsSubmittingNewsletter(true)

    try {
      const response = await apiService.subscribeNewsletter(newsletterData)
      
      if (response.success) {
        setNewsletterSuccess(true)
        // Tracker l'événement Google Analytics
        trackContactForm('newsletter')
        setNewsletterData({ email: '', firstName: '', lastName: '' })
      } else {
        setNewsletterErrors([response.message || 'Une erreur est survenue lors de l\'inscription.'])
      }
    } catch (error) {
      console.error('Erreur lors de l\'inscription à la newsletter:', error)
      setNewsletterErrors(['Une erreur est survenue. Veuillez réessayer plus tard.'])
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
      {/* Hero section */}
      <div className="relative bg-secondary-900 py-24 px-6 sm:py-32 sm:px-12">
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-secondary-900 to-secondary-800 opacity-90" />
          <div 
            className="absolute inset-0 bg-cover bg-center opacity-20" 
            style={{ backgroundImage: 'url(/assets/blog/hero-bg.jpg)' }}
          />
        </div>
        <div className="relative mx-auto max-w-7xl">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            <h1 className="text-4xl font-bold tracking-tight text-white sm:text-5xl lg:text-6xl">
              Blog ChapeChape
            </h1>
            <p className="mt-6 max-w-lg mx-auto text-xl text-primary-200">
              Actualités, conseils et tendances sur l'immobilier en Afrique de l'Ouest.
            </p>
          </motion.div>
        </div>
      </div>

      {/* Main content */}
      <div className="container-custom py-16 sm:py-24">
        {/* Filtres */}
        <div className="mb-16">
          <h2 className="text-xl font-semibold text-secondary-900 mb-6 text-center">
            Explorer par catégorie
          </h2>
          <div className="flex flex-wrap justify-center gap-3">
            {categories.map(category => (
              <button
                key={category.id}
                className={`px-4 py-2 rounded-full text-sm font-medium transition-all duration-300 ${
                  activeCategory === category.id 
                    ? 'bg-primary-300 text-secondary-900 shadow-md' 
                    : 'bg-secondary-100 text-secondary-700 hover:bg-secondary-200'
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
              className="bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-all duration-300 flex flex-col h-full"
            >
              <div className="overflow-hidden h-48">
                <img 
                  src={post.image} 
                  alt={post.title}
                  className="w-full h-full object-cover transform hover:scale-105 transition-transform duration-500"
                />
              </div>
              <div className="p-6 flex-grow flex flex-col">
                <div className="mb-4">
                  <span className="inline-block px-3 py-1 text-xs font-semibold bg-primary-100 text-primary-600 rounded-full">
                    {categories.find(cat => cat.id === post.category)?.name || post.category}
                  </span>
                </div>
                <h3 className="text-xl font-bold text-secondary-900 mb-3">{post.title}</h3>
                <p className="text-secondary-600 mb-4 flex-grow">{post.excerpt}</p>
                <div className="flex items-center justify-between mt-4 pt-4 border-t border-secondary-100">
                  <div className="flex items-center">
                    <div className="h-8 w-8 rounded-full overflow-hidden bg-primary-100 mr-3">
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
                      <span className="font-medium text-secondary-900">{post.author}</span>
                    </div>
                  </div>
                  <div className="text-xs text-secondary-500">
                    {post.date} · {post.readTime} de lecture
                  </div>
                </div>
              </div>
              <div className="px-6 py-4 bg-secondary-50">
                <a
                  href={`/blog/${post.id}`}
                  className="inline-flex items-center text-primary-500 hover:text-primary-600 font-medium"
                >
                  Lire l'article
                  <svg className="ml-2 h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M10.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L12.586 11H5a1 1 0 110-2h7.586l-2.293-2.293a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                </a>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Newsletter */}
        <div className="mt-24 bg-secondary-900 rounded-2xl p-8 sm:p-12">
          <div className="max-w-3xl mx-auto">
            <motion.div 
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="text-center"
            >
              <h2 className="text-2xl font-bold text-white mb-4">
                Recevez nos actualités immobilières
              </h2>
              <p className="text-primary-200 mb-8">
                Inscrivez-vous à notre newsletter pour recevoir nos derniers articles, conseils et 
                nouvelles du marché immobilier en Afrique de l'Ouest.
              </p>
              <form onSubmit={handleNewsletterSubmit} className="space-y-4 max-w-lg mx-auto">
                {/* Champs prénom et nom (optionnels) */}
                <div className="flex flex-col sm:flex-row gap-4">
                  <input
                    type="text"
                    placeholder="Prénom (optionnel)"
                    value={newsletterData.firstName}
                    onChange={(e) => setNewsletterData(prev => ({ ...prev, firstName: e.target.value }))}
                    className="px-4 py-3 rounded-lg bg-white text-secondary-900 placeholder-secondary-500 focus:outline-none focus:ring-2 focus:ring-primary-300 transition-all duration-200"
                  />
                  <input
                    type="text"
                    placeholder="Nom (optionnel)"
                    value={newsletterData.lastName}
                    onChange={(e) => setNewsletterData(prev => ({ ...prev, lastName: e.target.value }))}
                    className="px-4 py-3 rounded-lg bg-white text-secondary-900 placeholder-secondary-500 focus:outline-none focus:ring-2 focus:ring-primary-300 transition-all duration-200"
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
                    className="px-4 py-3 rounded-lg flex-grow bg-white text-secondary-900 placeholder-secondary-500 focus:outline-none focus:ring-2 focus:ring-primary-300 transition-all duration-200"
                  />
                  <motion.button
                    type="submit"
                    disabled={isSubmittingNewsletter}
                    whileHover={{ scale: isSubmittingNewsletter ? 1 : 1.02 }}
                    whileTap={{ scale: isSubmittingNewsletter ? 1 : 0.98 }}
                    className="btn-primary whitespace-nowrap relative overflow-hidden disabled:opacity-70 disabled:cursor-not-allowed"
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
                      className="bg-red-100 border border-red-300 text-red-700 px-4 py-3 rounded-lg"
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
                      className="bg-green-100 border border-green-300 text-green-700 px-4 py-3 rounded-lg flex items-center"
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
              <p className="text-primary-200/80 text-xs mt-4">
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