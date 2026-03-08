import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import SEOHead from '../components/seo/SEOHead'

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com'

const resources = [
  { name: 'Blog', href: '/blog', description: 'Actualités et conseils immobilier.' },
  { name: 'Témoignages', href: '/testimonials', description: 'Avis clients et propriétaires.' },
  { name: 'FAQ', href: '/faq', description: 'Questions fréquentes.' },
  { name: 'Applications', href: '/apps', description: 'Télécharger nos applications.' },
]

export default function Resources() {
  return (
    <div className="bg-white min-h-screen">
      <SEOHead
        title="Ressources"
        description="Ressources ChapeChape Residence : blog, FAQ, témoignages et applications. Côte d'Ivoire."
        url={`${siteUrl}/resources`}
      />
      <section className="relative py-32 bg-secondary-900 overflow-hidden">
        <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-10 mix-blend-overlay" />
        <div className="container mx-auto px-4 max-w-6xl relative z-10 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <h1 className="text-5xl md:text-6xl font-bold text-white mb-6 font-display">
              Ressources
            </h1>
            <p className="text-xl text-secondary-200 max-w-2xl mx-auto">
              Guides, actualités et outils pour votre expérience ChapeChape Residence.
            </p>
          </motion.div>
        </div>
      </section>
      <section className="py-16 px-4" aria-labelledby="resources-list-heading">
        <h2 id="resources-list-heading" className="sr-only">Ressources disponibles</h2>
        <div className="max-w-4xl mx-auto grid gap-6 sm:grid-cols-2">
          {resources.map((item, i) => (
            <motion.div
              key={item.href}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: i * 0.1 }}
            >
              <Link
                to={item.href}
                className="block p-6 rounded-xl border border-secondary-200 bg-secondary-50 hover:bg-secondary-100 hover:border-primary-300 transition-colors"
              >
                <h3 className="text-xl font-semibold text-secondary-900 mb-2">{item.name}</h3>
                <p className="text-secondary-600">{item.description}</p>
              </Link>
            </motion.div>
          ))}
        </div>
      </section>
    </div>
  )
}
