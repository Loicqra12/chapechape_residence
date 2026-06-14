import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import AppProductSection from '../components/apps/AppProductSection'
import Contact from '../components/home/Contact'
import SEOHead from '../components/seo/SEOHead'
import {
  clientFeatures,
  clientScreenshots,
  partnerFeatures,
  partnerScreenshots,
} from '../data/appsPageContent'

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com'
const clientAndroid = (import.meta as any).env?.VITE_CLIENT_ANDROID_URL || '#'
const clientIos = (import.meta as any).env?.VITE_CLIENT_IOS_URL || '#'
const partnerAndroid = (import.meta as any).env?.VITE_PARTNER_ANDROID_URL || '#'
const partnerIos = (import.meta as any).env?.VITE_PARTNER_IOS_URL || '#'

export default function Apps() {
  return (
    <div className="bg-secondary-50">
      <SEOHead
        title="Applications"
        description="Téléchargez ChapeChape Client et ChapeChape Partner : recherche, réservation et gestion de résidences en Côte d'Ivoire."
        url={`${siteUrl}/apps`}
      />

      <section className="relative overflow-hidden bg-secondary-900 py-32">
        <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-10 mix-blend-overlay" />
        <div className="absolute inset-0 bg-gradient-to-b from-secondary-900/50 via-secondary-900/80 to-white" />
        <div className="pointer-events-none absolute inset-0 overflow-hidden">
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
                ease: 'easeInOut',
              }}
            />
          ))}
        </div>
        <div className="container relative z-10 mx-auto max-w-6xl px-4 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <span className="mb-6 inline-block rounded-full border border-white/20 bg-white/10 px-3 py-1 text-xs font-bold uppercase tracking-widest text-primary-300 backdrop-blur-md">
              Innovation & Mobilité
            </span>
            <h1 className="mb-6 font-display text-3xl font-bold tracking-tight text-white sm:text-5xl md:text-6xl lg:text-7xl">
              Nos{' '}
              <span className="bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200 bg-clip-text text-transparent">
                Applications
              </span>
            </h1>
            <p className="mx-auto mb-10 max-w-2xl text-xl font-light leading-relaxed text-secondary-200">
              Découvrez comment nos applications mobiles facilitent la gestion et la location de résidences en
              Afrique de l&apos;Ouest, où que vous soyez.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Section 1 — Application Client + captures */}
      <AppProductSection
        variant="client"
        eyebrow="Pour les Locataires"
        title="Application Client"
        description="Trouvez et réservez facilement la résidence idéale pour votre séjour, que ce soit pour quelques jours ou plusieurs mois."
        features={clientFeatures}
        screenshots={clientScreenshots}
        androidUrl={clientAndroid}
        iosUrl={clientIos}
      />

      {/* Section 2 — Application Partenaire + captures */}
      <AppProductSection
        variant="partner"
        eyebrow="Pour les Propriétaires"
        title="Application Partenaire"
        description="Gérez efficacement vos propriétés et maximisez vos revenus grâce à notre solution complète pour les propriétaires."
        features={partnerFeatures}
        screenshots={partnerScreenshots}
        androidUrl={partnerAndroid}
        iosUrl={partnerIos}
      />

      <section className="bg-white py-24 sm:py-32">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: 50 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7 }}
            viewport={{ once: true }}
            className="relative isolate overflow-hidden rounded-3xl border border-primary-100 bg-gradient-to-br from-primary-50 to-white px-6 py-24 text-center shadow-2xl sm:px-16"
          >
            <h2 className="font-display text-3xl font-bold tracking-tight text-secondary-900 sm:text-4xl">
              Commencez l&apos;expérience dès aujourd&apos;hui
            </h2>
            <p className="mx-auto mt-6 max-w-2xl text-lg leading-8 text-secondary-600">
              Rejoignez les milliers d&apos;utilisateurs qui simplifient déjà leur expérience de logement avec
              ChapeChape Residence.
            </p>
            <div className="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
              <Link
                to="/"
                className="w-full transform rounded-full bg-primary-500 px-8 py-4 text-center text-sm font-bold text-white shadow-lg transition-all duration-300 hover:-translate-y-1 hover:bg-primary-600 hover:shadow-primary-500/30 sm:w-auto"
              >
                Découvrir nos résidences
              </Link>
              <Link
                to="/contact"
                className="text-sm font-bold leading-6 text-secondary-900 transition-colors hover:text-primary-600"
              >
                Nous contacter <span aria-hidden="true">→</span>
              </Link>
            </div>
          </motion.div>
        </div>
      </section>

      <Contact />
    </div>
  )
}
