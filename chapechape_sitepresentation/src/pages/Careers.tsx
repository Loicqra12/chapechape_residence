import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import SEOHead from '../components/seo/SEOHead'

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com'

export default function Careers() {
  return (
    <div className="bg-white min-h-screen">
      <SEOHead
        title="Carrières"
        description="Rejoignez l'équipe ChapeChape Residence. Opportunités à Abidjan, Côte d'Ivoire."
        url={`${siteUrl}/careers`}
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
              Carrières
            </h1>
            <p className="text-xl text-secondary-200 max-w-2xl mx-auto">
              Rejoignez notre équipe et participez à la transformation de la location résidentielle en Côte d'Ivoire.
            </p>
          </motion.div>
        </div>
      </section>
      <section className="py-16 px-4">
        <div className="max-w-2xl mx-auto text-center">
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.3 }}
            className="text-secondary-600 mb-8"
          >
            Nous recrutons des profils passionnés pour renforcer notre équipe à Abidjan.
            Envoyez-nous votre CV et lettre de motivation pour être recontacté.
            Consultez cette page régulièrement ou écrivez-nous pour être informé des postes ouverts.
          </motion.p>
          <Link
            to="/contact"
            className="inline-flex items-center justify-center rounded-lg bg-primary-500 px-6 py-3 text-base font-semibold text-white shadow-sm hover:bg-primary-600 transition-colors"
          >
            Nous contacter
          </Link>
        </div>
      </section>
    </div>
  )
}
