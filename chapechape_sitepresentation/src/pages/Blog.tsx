import { motion } from 'framer-motion'
import { useState } from 'react'

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
    image: "/assets/blog/market-trends.jpg",
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
    authorImage: "/assets/blog/author-marie.jpg",
    date: "28 mars 2024",
    readTime: "5 min",
    image: "/assets/blog/small-space.jpg",
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
    authorImage: "/assets/blog/author-pascal.jpg",
    date: "12 mars 2024",
    readTime: "12 min",
    image: "/assets/blog/legal-guide.jpg",
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
    image: "/assets/blog/emerging-areas.jpg",
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
    authorImage: "/assets/blog/author-aminata.jpg",
    date: "20 février 2024",
    readTime: "7 min",
    image: "/assets/blog/rental-application.jpg",
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
    image: "/assets/blog/property-management.jpg",
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
              <form className="flex flex-col sm:flex-row gap-4 max-w-lg mx-auto">
                <input
                  type="email"
                  placeholder="Votre adresse email"
                  className="px-4 py-3 rounded-lg flex-grow focus:outline-none focus:ring-2 focus:ring-primary-300"
                />
                <button
                  type="submit"
                  className="btn-primary whitespace-nowrap"
                >
                  S'inscrire
                </button>
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