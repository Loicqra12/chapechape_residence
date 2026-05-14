import { Link } from 'react-router-dom'
import SEOHead from '../components/seo/SEOHead'

export default function NotFound() {
  return (
    <section className="min-h-[60vh] flex items-center justify-center bg-white px-6">
      <SEOHead
        title="Page introuvable"
        description="La page demandee est introuvable. Retournez a l'accueil de ChapeChape Residence."
        url="https://presentation.chapechaperesidence.com/404"
      />
      <div className="text-center max-w-xl">
        <p className="text-sm uppercase tracking-widest text-primary-600 font-semibold">Erreur 404</p>
        <h1 className="mt-4 text-4xl font-bold text-secondary-900">Page introuvable</h1>
        <p className="mt-4 text-secondary-600">
          Le lien que vous avez suivi n'existe plus ou a ete deplace.
        </p>
        <Link
          to="/"
          className="inline-block mt-8 rounded-xl bg-primary-500 px-6 py-3 text-white font-semibold hover:bg-primary-600 transition-colors"
        >
          Retour a l'accueil
        </Link>
      </div>
    </section>
  )
}
