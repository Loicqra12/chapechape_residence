import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import Contact from '../components/home/Contact'
import SEOHead from '../components/seo/SEOHead'

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com'

// Tous les logos pour la section dispersée
const allLogos = [
  { id: 1, name: 'Partenaire 1', logo: '/assets/partners/partner1_logo.png', pos: { left: '30%', top: '4%'  } },
  { id: 2, name: 'BNI',          logo: '/assets/partners/partner2_logo.png', pos: { left: '62%', top: '8%'  } },
  { id: 3, name: 'Partenaire 3', logo: '/assets/partners/partner3_logo.png', pos: { left: '78%', top: '40%' } },
  { id: 4, name: 'Partenaire 4', logo: '/assets/partners/partner4_logo.png', pos: { left: '45%', top: '48%' } },
  { id: 5, name: 'Onloutou',     logo: '/assets/partners/partner5_logo.png', pos: { left: '22%', top: '55%' } },
  { id: 6, name: 'Partenaire 6', logo: '/assets/partners/partner6_logo.png', pos: { left: '65%', top: '68%' } },
  { id: 7, name: 'Wave',         logo: '/assets/partners/partner7_logo.png', pos: { left: '38%', top: '75%' } },
]

// 3 cards seulement
const partners = [
  {
    id: 7,
    name: 'Wave',
    category: 'Services de paiement',
    description: "Leader des services financiers mobiles en Afrique de l'Ouest, Wave offre à nos clients une solution de paiement simple, rapide et sécurisée.",
    logo: '/assets/partners/partner7_logo.png',
    website: 'https://www.wave.com',
  },
  {
    id: 2,
    name: 'BNI',
    category: 'Banque',
    description: "La Banque Nationale d'Investissement, partenaire bancaire de référence en Côte d'Ivoire, accompagne notre développement et sécurise les transactions de nos propriétaires.",
    logo: '/assets/partners/partner2_logo.png',
    website: 'https://www.bni.ci',
  },
  {
    id: 5,
    name: 'Onloutou',
    category: 'Partenaire technologique',
    description: "Plateforme ivoirienne de location d'équipements fondée par Adams Diaby. Onloutou partage notre vision d'un écosystème numérique accessible et innovant en Afrique de l'Ouest.",
    logo: '/assets/partners/partner5_logo.png',
    website: 'https://www.onloutou.com',
  },
]

const floatVariants = [
  { y: [-5, 5, -5], duration: 4 },
  { y: [5, -5, 5], duration: 5 },
  { y: [-4, 6, -4], duration: 6 },
  { y: [6, -4, 6], duration: 4.5 },
  { y: [-6, 4, -6], duration: 5.5 },
  { y: [4, -6, 4], duration: 3.5 },
  { y: [-3, 7, -3], duration: 4.2 },
]

export default function PartnersPage() {
  return (
    <div className="bg-white">
      <SEOHead
        title="Partenaires"
        description="Partenaires ChapeChape Residence : Wave, Orange Money, MTN, banques. Paiements et services en Côte d'Ivoire."
        url={`${siteUrl}/partners`}
      />

      {/* ── HERO ─────────────────────────────────── */}
      <section className="relative py-32 bg-secondary-900 overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-b from-secondary-900/60 via-secondary-900/85 to-white" />
        <div className="absolute inset-0 bg-[radial-gradient(circle,#D4AF37_1px,transparent_1px)] [background-size:32px_32px] opacity-[0.04]" />

        <motion.div
          className="absolute right-0 top-0 w-[500px] h-[500px] rounded-full bg-primary-500/10 blur-[120px] pointer-events-none"
          animate={{ scale: [1, 1.2, 1], opacity: [0.3, 0.6, 0.3] }}
          transition={{ duration: 8, repeat: Infinity, ease: 'easeInOut' }}
        />

        <div className="relative z-10 max-w-6xl mx-auto px-6 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <span className="inline-block py-1.5 px-4 rounded-full bg-white/10 backdrop-blur-md border border-white/15 text-primary-300 text-xs font-bold tracking-widest uppercase mb-6 font-body">
              Confiance & Collaboration
            </span>
            <h1 className="text-3xl sm:text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              Nos{' '}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">
                Partenaires
              </span>
            </h1>
            <p className="text-lg text-white/60 max-w-2xl mx-auto font-body leading-relaxed">
              Découvrez les acteurs qui nous accompagnent dans notre mission d'excellence et d'innovation au service du marché ivoirien.
            </p>
          </motion.div>
        </div>
      </section>

      {/* ── LOGOS DISPERSÉS style Veone ──────────── */}
      <section className="max-w-7xl mx-auto px-6 lg:px-12 py-24">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">

          {/* Gauche — texte */}
          <motion.div
            initial={{ opacity: 0, x: -30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.7 }}
          >
            <p className="text-xs font-bold tracking-widest uppercase text-primary-600 font-body mb-3">
              Notre écosystème
            </p>
            <h2 className="text-3xl md:text-4xl font-bold text-secondary-900 font-display leading-tight mb-5">
              Nos partenaires<br className="hidden sm:block" /> de référence
            </h2>
            <p className="text-secondary-500 font-body text-[15px] leading-relaxed max-w-sm">
              Nous sommes fiers de collaborer avec des leaders du secteur —
              paiement mobile, banque, technologie — qui partagent notre engagement
              envers l'excellence et l'innovation pour le marché ivoirien.
            </p>

            <div className="mt-8">
              <Link
                to="/contact"
                className="inline-flex items-center gap-2 text-sm font-bold text-primary-600 hover:text-primary-700 font-body group"
              >
                Devenir partenaire
                <svg className="w-4 h-4 group-hover:translate-x-1 transition-transform duration-200" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M17 8l4 4m0 0l-4 4m4-4H3" />
                </svg>
              </Link>
            </div>
          </motion.div>

          {/* Droite — tous les logos dispersés */}
          <div className="relative h-80 md:h-96">
            {allLogos.map((p, i) => {
              const fv = floatVariants[i]
              return (
                <motion.div
                  key={p.id}
                  className="absolute group"
                  style={{ left: p.pos.left, top: p.pos.top }}
                  initial={{ opacity: 0, y: 16 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.6, delay: i * 0.1 }}
                  animate={{ y: fv.y }}
                  // @ts-ignore
                  whileHover={{ scale: 1.15 }}
                >
                  <div className="flex items-center justify-center opacity-75 hover:opacity-100 transition-opacity duration-300">
                    <img
                      src={p.logo}
                      alt={p.name}
                      className="h-10 w-auto object-contain max-w-[120px]"
                    />
                  </div>
                </motion.div>
              )
            })}
          </div>

        </div>
      </section>

      {/* ── CARDS détail ─────────────────────────── */}
      <section className="bg-secondary-50 py-20">
        <div className="max-w-7xl mx-auto px-6 lg:px-12">

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="mb-12"
          >
            <h2 className="text-2xl md:text-3xl font-bold text-secondary-900 font-display">
              Un écosystème de confiance
            </h2>
            <div className="mt-4 h-px bg-gradient-to-r from-primary-500 to-transparent max-w-xs" />
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {partners.map((p, i) => (
              <motion.div
                key={p.id}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: i * 0.07 }}
                className="group bg-white rounded-2xl border border-secondary-100 hover:border-primary-200 hover:shadow-lg transition-all duration-300 overflow-hidden"
              >
                {/* Logo zone */}
                <div className="h-40 bg-secondary-50 flex items-center justify-center p-8 border-b border-secondary-100 group-hover:bg-white transition-colors duration-300">
                  <img
                    src={p.logo}
                    alt={p.name}
                    className="max-h-16 max-w-[70%] object-contain transition-transform duration-300 group-hover:scale-105"
                  />
                </div>

                {/* Texte */}
                <div className="p-6">
                  <div className="flex items-start justify-between mb-3">
                    <h3 className="font-bold text-secondary-900 font-display text-base leading-tight">{p.name}</h3>
                    <span className="text-[10px] font-bold uppercase tracking-wider text-primary-600 bg-primary-50 border border-primary-100 px-2 py-0.5 rounded-full whitespace-nowrap ml-2 shrink-0">
                      {p.category}
                    </span>
                  </div>
                  <p className="text-sm text-secondary-500 font-body leading-relaxed mb-4">{p.description}</p>
                  <a
                    href={p.website}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1.5 text-sm font-bold text-primary-600 hover:text-primary-700 font-body group/link"
                  >
                    Visiter le site
                    <svg className="w-3.5 h-3.5 group-hover/link:translate-x-1 transition-transform duration-200" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M17 8l4 4m0 0l-4 4m4-4H3" />
                    </svg>
                  </a>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ── CTA DEVENIR PARTENAIRE ────────────────── */}
      <section className="max-w-7xl mx-auto px-6 lg:px-12 py-20">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="relative bg-secondary-900 rounded-3xl p-10 sm:p-16 overflow-hidden"
        >
          <div className="absolute inset-0 bg-[radial-gradient(circle,#D4AF37_1px,transparent_1px)] [background-size:32px_32px] opacity-[0.03]" />
          <motion.div
            className="absolute top-0 right-0 w-80 h-80 rounded-full bg-primary-500/10 blur-3xl"
            animate={{ scale: [1, 1.2, 1], opacity: [0.3, 0.5, 0.3] }}
            transition={{ duration: 7, repeat: Infinity, ease: 'easeInOut' }}
          />
          <div className="relative z-10 flex flex-col md:flex-row items-center justify-between gap-10">
            <div className="md:w-2/3">
              <h2 className="text-3xl font-bold text-white mb-4 font-display">
                Devenez notre partenaire
              </h2>
              <p className="text-white/60 font-body leading-relaxed text-[15px]">
                Vous souhaitez rejoindre notre écosystème ? Nous recherchons des entreprises innovantes
                qui partagent notre vision et nos valeurs pour transformer l'immobilier en Afrique de l'Ouest.
              </p>
            </div>
            <div className="md:w-1/3 flex justify-center md:justify-end">
              <Link
                to="/contact"
                className="inline-flex items-center gap-3 px-8 py-4 rounded-full bg-primary-500 text-secondary-900 font-bold font-body text-sm hover:bg-primary-400 transition-colors duration-200 whitespace-nowrap"
              >
                Nous contacter
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M17 8l4 4m0 0l-4 4m4-4H3" />
                </svg>
              </Link>
            </div>
          </div>
        </motion.div>
      </section>

      <Contact />
    </div>
  )
}
