import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'

const posts = [
  {
    title: "Comment trouver le logement parfait à Cotonou ?",
    excerpt: "Découvrez nos conseils d'experts pour dénicher le logement idéal qui correspond à vos besoins et à votre budget à Cotonou.",
    imageUrl: "/assets/blog/placeholder.jpg",
    date: "10 Mai 2025",
    author: "Marie Konaté",
    category: "Conseils"
  },
  {
    title: "Les tendances immobilières en Afrique de l'Ouest pour 2025",
    excerpt: "Analyse des évolutions du marché immobilier en Afrique de l'Ouest et perspectives pour les investisseurs et locataires.",
    imageUrl: "/assets/blog/placeholder.jpg",
    date: "2 Mai 2025",
    author: "Jean-Pierre Kouassi",
    category: "Marché immobilier"
  },
  {
    title: "5 avantages de la gestion immobilière digitale",
    excerpt: "Pourquoi la digitalisation de la gestion immobilière représente une révolution pour les propriétaires et les gestionnaires de biens.",
    imageUrl: "/assets/blog/placeholder.jpg",
    date: "25 Avril 2025",
    author: "Sophie Mensah",
    category: "Technologie"
  }
]

const Blog = () => {
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
          <h2 className="text-3xl font-bold text-secondary-900 dark:text-white mb-4">Actualités & Conseils</h2>
          <p className="text-secondary-600 dark:text-secondary-300 max-w-2xl mx-auto">
            Restez informé des dernières tendances du marché immobilier et découvrez nos conseils d'experts.
          </p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {posts.map((post, index) => (
            <motion.article
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className="bg-white dark:bg-secondary-700 rounded-xl overflow-hidden shadow-md hover:shadow-xl transition-all duration-200"
            >
              <div className="aspect-w-16 aspect-h-9 bg-secondary-200 dark:bg-secondary-600">
                <div className="w-full h-48 bg-primary-300/30 flex items-center justify-center text-secondary-900">
                  <svg className="h-16 w-16 text-primary-300/60" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>
              </div>
              <div className="p-6">
                <div className="flex items-center text-xs text-primary-500 font-medium mb-2 space-x-2">
                  <span>{post.category}</span>
                  <span>•</span>
                  <time dateTime="2023-05-01">{post.date}</time>
                </div>
                <h3 className="text-xl font-bold text-secondary-900 dark:text-white mb-2">
                  {post.title}
                </h3>
                <p className="text-secondary-600 dark:text-secondary-300 mb-4 line-clamp-3">
                  {post.excerpt}
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-secondary-500 dark:text-secondary-400">
                    Par {post.author}
                  </span>
                  <Link to="/blog" className="text-sm font-medium text-primary-500 hover:text-primary-600 transition-colors duration-200">
                    Lire plus →
                  </Link>
                </div>
              </div>
            </motion.article>
          ))}
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