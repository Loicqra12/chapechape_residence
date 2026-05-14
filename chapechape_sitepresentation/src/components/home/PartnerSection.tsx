import { useRef } from 'react'
import { motion, useScroll, useTransform } from 'framer-motion'
import { Link } from 'react-router-dom'

const partnerAndroid = (import.meta as any).env?.VITE_PARTNER_ANDROID_URL || '#'
const partnerIos = (import.meta as any).env?.VITE_PARTNER_IOS_URL || '#'

const benefits = [
  {
    icon: (
      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
    title: 'Revenus garantis',
    desc: 'Percevez vos loyers à date fixe, même en cas de vacance locative.',
  },
  {
    icon: (
      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
      </svg>
    ),
    title: 'Locataires vérifiés',
    desc: 'Chaque locataire est soigneusement sélectionné par nos équipes.',
  },
  {
    icon: (
      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
      </svg>
    ),
    title: 'Tableau de bord complet',
    desc: 'Suivez vos performances, taux d\'occupation et revenus en temps réel.',
  },
  {
    icon: (
      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
      </svg>
    ),
    title: 'Support 24/7',
    desc: 'Notre équipe dédiée gère tout à votre place, de la maintenance aux urgences.',
  },
]

const stats = [
  { value: '0%', label: 'Vacance locative moyenne' },
  { value: '48h', label: 'Délai de mise en ligne' },
  { value: '100%', label: 'Paiements sécurisés' },
]

export default function PartnerSection() {
  const ref = useRef<HTMLElement>(null)
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start end', 'end start'] })
  const imgY = useTransform(scrollYProgress, [0, 1], [40, -40])
  const glowOpacity = useTransform(scrollYProgress, [0, 0.5, 1], [0.3, 0.7, 0.3])

  return (
    <section ref={ref} className="relative overflow-hidden bg-secondary-900 py-28 lg:py-36">

      {/* Fond décoratif */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,_rgba(212,175,55,0.12),_transparent_60%)]" />
      <div className="absolute inset-0 opacity-[0.04] bg-[radial-gradient(#D4AF37_1px,transparent_1px)] [background-size:24px_24px]" />

      {/* Glow doré gauche */}
      <motion.div
        style={{ opacity: glowOpacity }}
        className="absolute -left-40 top-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-primary-500/20 rounded-full blur-[100px] pointer-events-none"
      />

      <div className="mx-auto max-w-7xl px-6 lg:px-8 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 lg:gap-24 items-center">

          {/* ── Colonne image ── */}
          <motion.div
            initial={{ opacity: 0, x: -60 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.9, ease: 'easeOut' }}
            className="relative order-2 lg:order-1"
          >
            {/* Cadre décoratif */}
            <div className="absolute -inset-4 rounded-3xl bg-gradient-to-br from-primary-500/20 to-transparent border border-primary-500/10" />

            {/* Image principale */}
            <motion.div style={{ y: imgY }} className="relative rounded-2xl overflow-hidden shadow-2xl shadow-black/50">
              <img
                src="/assets/images/imagepartner.png"
                alt="Application ChapeChape Partner pour propriétaires"
                className="w-full h-[480px] lg:h-[560px] object-cover"
              />
              {/* Overlay gradient bas */}
              <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/80 via-transparent to-transparent" />
            </motion.div>

            {/* Stats flottants */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.5 }}
              className="absolute -bottom-6 left-4 right-4 flex flex-wrap gap-3"
            >
              {stats.map((s) => (
                <div key={s.label} className="flex-1 bg-white/10 backdrop-blur-md border border-white/10 rounded-2xl p-4 text-center">
                  <p className="text-xl font-bold text-primary-400 font-display">{s.value}</p>
                  <p className="text-[10px] text-white/60 mt-0.5 leading-tight">{s.label}</p>
                </div>
              ))}
            </motion.div>
          </motion.div>

          {/* ── Colonne texte ── */}
          <motion.div
            initial={{ opacity: 0, x: 60 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.9, ease: 'easeOut' }}
            className="order-1 lg:order-2 pt-0 lg:pt-0"
          >
            {/* Badge */}
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary-500/10 border border-primary-500/30 mb-8">
              <span className="w-1.5 h-1.5 rounded-full bg-primary-400 animate-pulse" />
              <span className="text-xs font-bold tracking-widest uppercase text-primary-400">
                ChapeChape Partner
              </span>
            </div>

            <h2 className="text-4xl md:text-5xl lg:text-[3.25rem] font-bold text-white leading-tight font-display mb-6">
              Rentabilisez votre{' '}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-300 via-primary-400 to-primary-200">
                bien immobilier
              </span>
            </h2>

            <p className="text-lg text-white/60 leading-relaxed mb-10 max-w-lg border-l-2 border-primary-500/40 pl-5">
              Confiez-nous votre bien et percevez des revenus locatifs stables sans aucun souci de gestion. 
              Notre équipe s'occupe de tout.
            </p>

            {/* Bénéfices */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-12">
              {benefits.map((b, i) => (
                <motion.div
                  key={b.title}
                  initial={{ opacity: 0, y: 16 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: 0.2 + i * 0.1 }}
                  className="flex items-start gap-3 group"
                >
                  <div className="shrink-0 w-9 h-9 rounded-xl bg-primary-500/10 border border-primary-500/20 flex items-center justify-center text-primary-400 group-hover:bg-primary-500/20 group-hover:border-primary-400/40 transition-all duration-300">
                    {b.icon}
                  </div>
                  <div>
                    <p className="font-semibold text-white text-sm">{b.title}</p>
                    <p className="text-white/50 text-xs mt-0.5 leading-relaxed">{b.desc}</p>
                  </div>
                </motion.div>
              ))}
            </div>

            {/* CTAs */}
            <div className="flex flex-col sm:flex-row gap-4 mb-8">
              <Link
                to="/partenaires"
                className="inline-flex items-center justify-center gap-2.5 px-8 py-4 rounded-xl bg-primary-400 text-secondary-900 font-bold text-sm hover:bg-primary-300 transition-colors duration-200 shadow-lg shadow-primary-500/20"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                </svg>
                Devenir partenaire
              </Link>
              <Link
                to="/about"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-xl border border-white/20 text-white font-semibold text-sm hover:bg-white/5 hover:border-white/30 transition-all duration-200"
              >
                En savoir plus
              </Link>
            </div>

            {/* Téléchargement app Partner */}
            <div className="border-t border-white/10 pt-8">
              <p className="text-xs font-semibold uppercase tracking-widest text-white/40 mb-4">
                Téléchargez l'application partenaire
              </p>
              <div className="flex flex-wrap gap-3">
                <motion.a
                  whileHover={{ scale: 1.04, y: -2 }} whileTap={{ scale: 0.97 }}
                  href={partnerAndroid}
                  target={partnerAndroid !== '#' ? '_blank' : undefined}
                  rel={partnerAndroid !== '#' ? 'noopener noreferrer' : undefined}
                  className="inline-block rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-shadow"
                >
                  <img src="/assets/googleplay.png" alt="Disponible sur Google Play" className="h-10 w-auto" />
                </motion.a>
                <motion.a
                  whileHover={{ scale: 1.04, y: -2 }} whileTap={{ scale: 0.97 }}
                  href={partnerIos}
                  target={partnerIos !== '#' ? '_blank' : undefined}
                  rel={partnerIos !== '#' ? 'noopener noreferrer' : undefined}
                  className="inline-block rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-shadow"
                >
                  <img src="/assets/appstore.png" alt="Télécharger sur l'App Store" className="h-10 w-auto" />
                </motion.a>
              </div>
            </div>
          </motion.div>

        </div>
      </div>
    </section>
  )
}
