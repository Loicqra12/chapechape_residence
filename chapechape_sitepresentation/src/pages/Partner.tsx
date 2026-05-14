import { useState, useRef, useEffect, useCallback } from 'react'
import { motion, useScroll, useTransform, AnimatePresence } from 'framer-motion'
import { Link } from 'react-router-dom'
import SEOHead from '../components/seo/SEOHead'
import Contact from '../components/home/Contact'

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com'
const partnerAndroid = (import.meta as any).env?.VITE_PARTNER_ANDROID_URL || '#'
const partnerIos = (import.meta as any).env?.VITE_PARTNER_IOS_URL || '#'

// ─── Icônes SVG propriétés ───────────────────────────────────────────────────
const IconStudio = () => (
  <svg className="w-8 h-8" viewBox="0 0 40 40" fill="none" stroke="currentColor" strokeWidth={1.6} strokeLinecap="round" strokeLinejoin="round">
    <path d="M7 18.5L20 8l13 10.5V34H7V18.5z" />
    <rect x="15" y="26" width="10" height="8" />
    <path d="M15 26v8" />
  </svg>
)
const IconAppart = () => (
  <svg className="w-8 h-8" viewBox="0 0 40 40" fill="none" stroke="currentColor" strokeWidth={1.6} strokeLinecap="round" strokeLinejoin="round">
    <rect x="6" y="6" width="28" height="28" />
    <path d="M6 14h28M6 22h28M20 6v28" />
    <rect x="10" y="26" width="4" height="8" />
    <rect x="26" y="26" width="4" height="8" />
  </svg>
)
const IconVilla = () => (
  <svg className="w-8 h-8" viewBox="0 0 40 40" fill="none" stroke="currentColor" strokeWidth={1.6} strokeLinecap="round" strokeLinejoin="round">
    <path d="M4 20L20 6l16 14" />
    <path d="M8 20v14h24V20" />
    <rect x="16" y="27" width="8" height="7" />
    <rect x="10" y="22" width="6" height="5" />
    <rect x="24" y="22" width="6" height="5" />
    <path d="M4 20h4M32 20h4" />
  </svg>
)
const IconDuplex = () => (
  <svg className="w-8 h-8" viewBox="0 0 40 40" fill="none" stroke="currentColor" strokeWidth={1.6} strokeLinecap="round" strokeLinejoin="round">
    <rect x="6" y="18" width="28" height="16" />
    <path d="M6 18l14-12 14 12" />
    <path d="M6 26h28" />
    <rect x="14" y="28" width="12" height="6" />
    <rect x="11" y="20" width="6" height="5" />
    <rect x="23" y="20" width="6" height="5" />
  </svg>
)

// ─── Données calculateur ────────────────────────────────────────────────────
const propertyTypes = [
  { id: 'studio',  label: 'Studio',        base: 120000, Icon: IconStudio },
  { id: 'appart',  label: 'Appartement',   base: 220000, Icon: IconAppart },
  { id: 'villa',   label: 'Villa',         base: 450000, Icon: IconVilla  },
  { id: 'duplex',  label: 'Duplex / Loft', base: 320000, Icon: IconDuplex },
]
const districts = [
  { id: 'cocody',   label: 'Cocody',       mult: 1.35 },
  { id: 'plateau',  label: 'Plateau',      mult: 1.45 },
  { id: 'marcory',  label: 'Marcory',      mult: 1.10 },
  { id: 'yopougon', label: 'Yopougon',     mult: 0.90 },
  { id: 'riviera',  label: 'Riviera',      mult: 1.30 },
  { id: 'treichville',label:'Treichville', mult: 1.00 },
]
const durations = [
  { id: 'short', label: 'Courte durée (nuit / jour)', mult: 1.6 },
  { id: 'long',  label: 'Longue durée (mensuel)',     mult: 1.0 },
]

// ─── Avantages ───────────────────────────────────────────────────────────────
const benefits = [
  {
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
      </svg>
    ),
    title: 'Gère tes logements en toute simplicité',
    desc: 'Publie ton bien en quelques clics. Ajoute des photos, fixe tes disponibilités et commence à recevoir des réservations dès le lendemain.',
    tag: 'Mise en ligne rapide',
  },
  {
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
    title: 'Fais travailler tes logements pour toi',
    desc: 'Génère des revenus passifs stables. Les locataires proches trouvent ton logement grâce à la géolocalisation. Paiements sécurisés et garantis.',
    tag: 'Revenus garantis',
  },
  {
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
      </svg>
    ),
    title: 'Choisis la durée qui t\'arrange',
    desc: 'Location à l\'heure, à la journée ou au mois — tu decides. Adapte ton offre selon tes besoins sans aucune contrainte contractuelle longue durée.',
    tag: 'Flexibilité totale',
  },
  {
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
      </svg>
    ),
    title: 'Locataires vérifiés, zéro mauvaise surprise',
    desc: 'Chaque locataire passe par notre processus de vérification. Tu approuves chaque réservation avant confirmation. Tu gardes le contrôle.',
    tag: 'Sélection rigoureuse',
  },
  {
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
      </svg>
    ),
    title: 'Dashboard complet en temps réel',
    desc: 'Revenus, taux d\'occupation, tendances, stats par ville — tout sur un écran. Prends les meilleures décisions pour maximiser tes gains.',
    tag: 'Analytics avancées',
  },
]

// ─── Icônes SVG app features ─────────────────────────────────────────────────
const IconDashboard = () => (
  <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round">
    <rect x="2" y="13" width="5" height="8" /><rect x="9" y="9" width="5" height="12" /><rect x="16" y="4" width="5" height="17" />
  </svg>
)
const IconResidence = () => (
  <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round">
    <path d="M3 10.5L12 3l9 7.5V21H3V10.5z" /><rect x="9" y="15" width="6" height="6" />
  </svg>
)
const IconCalendar = () => (
  <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round">
    <rect x="3" y="4" width="18" height="18" rx="2" /><path d="M16 2v4M8 2v4M3 10h18" /><circle cx="9" cy="15" r="1" fill="currentColor" /><circle cx="15" cy="15" r="1" fill="currentColor" />
  </svg>
)
const IconChat = () => (
  <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round">
    <path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2v10z" />
  </svg>
)
const IconWallet = () => (
  <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round">
    <path d="M21 7H3a1 1 0 00-1 1v12a1 1 0 001 1h18a1 1 0 001-1V8a1 1 0 00-1-1z" /><path d="M16 3l-4 4-4-4" /><circle cx="17" cy="14" r="1.5" fill="currentColor" />
  </svg>
)

// ─── Fonctionnalités app ─────────────────────────────────────────────────────
const appFeatures = [
  {
    tab: 'Dashboard',
    Icon: IconDashboard,
    title: 'Pilotez vos revenus en temps réel',
    desc: 'Un tableau de bord intelligent qui centralise toutes vos données financières. Visualisez vos performances, anticipez les tendances et prenez les meilleures décisions pour maximiser vos gains.',
    vision: 'Avoir une vision claire et instantanée de la santé financière de votre patrimoine',
    priority: 'Maximiser le taux d\'occupation et les revenus nets',
    tags: ['Revenus', 'Analytiques', 'Temps réel'],
    delivers: [
      'Revenus du mois, de la semaine et du jour en un coup d\'œil',
      'Graphiques de tendances sur 6 et 12 mois',
      'Taux d\'occupation par résidence et par ville',
      'Comparaisons de périodes et objectifs de revenus',
    ],
    impact: [
      'Identification rapide des périodes creuses pour ajuster les tarifs',
      'Réduction des vacances locatives grâce aux alertes proactives',
      'Augmentation moyenne de 18% des revenus après 3 mois d\'utilisation',
    ],
  },
  {
    tab: 'Résidences',
    Icon: IconResidence,
    title: 'Publiez et gérez vos biens facilement',
    desc: 'Ajoutez vos logements en quelques minutes avec notre assistant de création guidé. Gérez les photos, les équipements, les tarifs et les disponibilités depuis un seul endroit.',
    vision: 'Rendre la gestion de votre portefeuille immobilier aussi simple qu\'une application bancaire',
    priority: 'Mise en ligne rapide et optimisation automatique des annonces',
    tags: ['Annonces', 'Photos', 'Disponibilités'],
    delivers: [
      'Création d\'annonce en moins de 10 minutes avec assistant guidé',
      'Galerie photos haute résolution avec recadrage automatique',
      'Calendrier de disponibilités synchronisé en temps réel',
      'Gestion des promotions, tarifs saisonniers et réductions',
    ],
    impact: [
      'Annonces complètes reçoivent 3x plus de réservations',
      'Mise en ligne en 48h chrono, validation équipe incluse',
      'Géolocalisation automatique pour attirer les locataires proches',
    ],
  },
  {
    tab: 'Réservations',
    Icon: IconCalendar,
    title: 'Gardez le contrôle sur chaque séjour',
    desc: 'Approuvez ou refusez chaque demande selon vos critères. Suivez le parcours complet de chaque réservation, du check-in au check-out, avec notre système de QR code intégré.',
    vision: 'Zéro surprise, zéro mauvaise expérience — chaque séjour parfaitement orchestré',
    priority: 'Fluidifier les entrées/sorties et réduire les litiges locatifs',
    tags: ['Check-in QR', 'Approbation', 'Suivi'],
    delivers: [
      'Approbation ou rejet en un clic avec message automatique au locataire',
      'Check-in et Check-out via QR code sécurisé sur votre téléphone',
      'Suivi des statuts en temps réel : confirmé, en cours, terminé',
      'Historique complet de toutes vos réservations téléchargeable',
    ],
    impact: [
      'Réduction de 70% des échanges inutiles grâce aux confirmations automatiques',
      'Check-in sans contact : pratique, moderne et sécurisé',
      'Traçabilité complète en cas de litige avec le locataire',
    ],
  },
  {
    tab: 'Messages',
    Icon: IconChat,
    title: 'Communiquez sans effort avec vos locataires',
    desc: 'Une messagerie temps réel intégrée directement dans l\'app. Échangez avec vos locataires, partagez des documents, et accédez au support ChapeChape — tout au même endroit.',
    vision: 'Une communication fluide et professionnelle qui renforce la confiance locataire',
    priority: 'Répondre vite, fidéliser les bons locataires et éviter les malentendus',
    tags: ['Temps réel', 'Documents', 'Support'],
    delivers: [
      'Chat instantané avec notifications push sur votre mobile',
      'Envoi de pièces jointes : contrats, photos d\'état des lieux',
      'Accès direct au support ChapeChape depuis la messagerie',
      'Historique complet de toutes vos conversations',
    ],
    impact: [
      'Les propriétaires réactifs reçoivent 40% d\'avis positifs de plus',
      'Résolution des problèmes en moins de 2h en moyenne',
      'Réduction significative des conflits grâce à la traçabilité écrite',
    ],
  },
  {
    tab: 'Paiements',
    Icon: IconWallet,
    title: 'Encaissez vos revenus en toute sécurité',
    desc: 'Tous vos paiements centralisés et sécurisés. Consultez vos transactions, demandez vos versements et téléchargez vos factures — Wave, CinetPay et plus encore.',
    vision: 'Des revenus prévisibles et garantis, sans aucune gestion bancaire complexe',
    priority: 'Automatiser les versements et offrir une transparence financière totale',
    tags: ['Wave', 'CinetPay', 'Payouts auto'],
    delivers: [
      'Historique détaillé de toutes vos transactions par résidence',
      'Paiements acceptés via Wave, CinetPay, Mobile Money',
      'Payouts automatiques selon votre calendrier choisi',
      'Factures et reçus téléchargeables pour votre comptabilité',
    ],
    impact: [
      'Zéro impayé : ChapeChape garantit le paiement avant check-in',
      'Versements sous 48h après chaque séjour confirmé',
      'Tableau de bord fiscal complet pour la déclaration de revenus',
    ],
  },
]

// ─── Étapes d'inscription ─────────────────────────────────────────────────────
const steps = [
  {
    n: '01',
    title: 'Téléchargez ChapeChape Partner',
    desc: 'Disponible sur Google Play et App Store. Créez votre compte en quelques minutes.',
  },
  {
    n: '02',
    title: 'Ajoutez votre bien',
    desc: 'Remplissez les informations, ajoutez vos photos et définissez vos disponibilités.',
  },
  {
    n: '03',
    title: 'Recevez des réservations',
    desc: 'Approuvez ou refusez chaque demande. Vous gardez le contrôle total à chaque étape.',
  },
  {
    n: '04',
    title: 'Encaissez vos revenus',
    desc: 'Paiements sécurisés directement sur votre compte. Suivez tout depuis le dashboard.',
  },
]

// ─── Composant principal ─────────────────────────────────────────────────────
export default function Partner() {
  // Calculateur
  const [propType, setPropType]   = useState(propertyTypes[0].id)
  const [district, setDistrict]   = useState(districts[0].id)
  const [duration, setDuration]   = useState(durations[0].id)
  const [activeFeature, setActiveFeature] = useState(0)
  const [progress, setProgress]           = useState(0)
  const progressRef  = useRef<ReturnType<typeof setInterval> | null>(null)
  const DURATION_MS  = 6000
  const TICK_MS      = 30

  const startProgress = useCallback((idx: number) => {
    if (progressRef.current) clearInterval(progressRef.current)
    setProgress(0)
    setActiveFeature(idx)
    let elapsed = 0
    progressRef.current = setInterval(() => {
      elapsed += TICK_MS
      const pct = Math.min((elapsed / DURATION_MS) * 100, 100)
      setProgress(pct)
      if (elapsed >= DURATION_MS) {
        clearInterval(progressRef.current!)
        const next = (idx + 1) % appFeatures.length
        startProgress(next)
      }
    }, TICK_MS)
  }, [])

  useEffect(() => {
    startProgress(0)
    return () => { if (progressRef.current) clearInterval(progressRef.current) }
  }, [startProgress])

  const pt = propertyTypes.find(p => p.id === propType)!
  const di = districts.find(d => d.id === district)!
  const du = durations.find(d => d.id === duration)!
  const revenue     = Math.round(pt.base * di.mult * du.mult / 1000) * 1000
  const occupancy   = duration === 'short' ? 82 : 91
  const weekly      = Math.round(revenue / 4)

  // Parallaxe hero
  const heroRef = useRef<HTMLElement>(null)
  const { scrollYProgress } = useScroll({ target: heroRef, offset: ['start start', 'end start'] })
  const heroY       = useTransform(scrollYProgress, [0, 1], [0, 160])
  const heroOpacity = useTransform(scrollYProgress, [0, 0.6], [1, 0])

  return (
    <div className="bg-white">
      <SEOHead
        title="Devenez Partenaire"
        description="Rentabilisez votre bien immobilier avec ChapeChape Residence. Rejoignez notre réseau de partenaires propriétaires à Abidjan et en Côte d'Ivoire."
        url={`${siteUrl}/partenaires`}
      />

      {/* ══ 1. HERO ══════════════════════════════════════════════════════════ */}
      <section ref={heroRef} className="relative min-h-screen flex items-center overflow-hidden bg-secondary-900">

        {/* Fond décoratif */}
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,_rgba(212,175,55,0.15),_transparent_55%)]" />
        <div className="absolute inset-0 opacity-[0.04] bg-[radial-gradient(#D4AF37_1px,transparent_1px)] [background-size:24px_24px]" />

        {/* Image droite */}
        <motion.div style={{ y: heroY }} className="absolute inset-y-0 right-0 w-1/2 hidden lg:block">
          <img
            src="/assets/images/femmepartner.png"
            alt="Partenaire ChapeChape"
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-r from-secondary-900 via-secondary-900/60 to-transparent" />
        </motion.div>

        {/* Glow doré */}
        <motion.div
          animate={{ opacity: [0.4, 0.7, 0.4], scale: [1, 1.05, 1] }}
          transition={{ duration: 6, repeat: Infinity, ease: 'easeInOut' }}
          className="absolute left-1/4 top-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-primary-500/10 rounded-full blur-[120px] pointer-events-none"
        />

        <motion.div
          style={{ opacity: heroOpacity }}
          className="relative z-10 mx-auto max-w-7xl px-6 lg:px-8 py-32 w-full"
        >
          <div className="max-w-2xl">
            {/* Badge */}
            <motion.div
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6 }}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary-500/10 border border-primary-500/30 mb-8"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-primary-400 animate-pulse" />
              <span className="text-xs font-bold tracking-widest uppercase text-primary-400">ChapeChape Partner</span>
            </motion.div>

            {/* Titre */}
            <motion.h1
              initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, delay: 0.1 }}
              className="text-3xl sm:text-5xl md:text-6xl lg:text-7xl font-bold text-white leading-tight font-display mb-6"
            >
              Fais travailler<br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-300 via-primary-400 to-primary-200">
                tes logements
              </span><br />
              pour toi
            </motion.h1>

            <motion.p
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, delay: 0.2 }}
              className="text-xl text-white/60 leading-relaxed mb-10 border-l-2 border-primary-500/40 pl-5 max-w-lg"
            >
              Rejoins le réseau de partenaires ChapeChape et génère des revenus locatifs stables sans aucune contrainte de gestion.
            </motion.p>

            {/* CTAs */}
            <motion.div
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, delay: 0.3 }}
              className="flex flex-wrap gap-4 mb-16"
            >
              <a
                href={partnerAndroid}
                target={partnerAndroid !== '#' ? '_blank' : undefined}
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2.5 px-8 py-4 rounded-xl bg-primary-400 text-secondary-900 font-bold text-sm hover:bg-primary-300 transition-colors shadow-lg shadow-primary-500/20"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                Télécharger l'app
              </a>
              <a
                href="#calculateur"
                className="inline-flex items-center gap-2 px-8 py-4 rounded-xl border border-white/20 text-white font-semibold text-sm hover:bg-white/5 transition-all"
              >
                Calculer mes revenus →
              </a>
            </motion.div>

            {/* Stats hero */}
            <motion.div
              initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7, delay: 0.4 }}
              className="flex flex-wrap gap-6"
            >
              {[
                { v: '48h', l: 'Délai de mise en ligne' },
                { v: '91%', l: 'Taux d\'occupation moyen' },
                { v: '100%', l: 'Paiements sécurisés' },
                { v: '24/7', l: 'Support dédié' },
              ].map(s => (
                <div key={s.l} className="text-center">
                  <p className="text-2xl font-bold text-primary-400 font-display">{s.v}</p>
                  <p className="text-xs text-white/40 mt-0.5">{s.l}</p>
                </div>
              ))}
            </motion.div>
          </div>
        </motion.div>
      </section>

      {/* ══ 2. CALCULATEUR ═══════════════════════════════════════════════════ */}
      <section id="calculateur" className="py-24 bg-secondary-50">
        <div className="mx-auto max-w-6xl px-6 lg:px-8">

          <motion.div
            initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ duration: 0.7 }}
            className="text-center mb-14"
          >
            <span className="inline-block px-3 py-1 rounded-full bg-primary-50 border border-primary-200 text-primary-700 text-xs font-bold tracking-widest uppercase mb-4">
              Simulateur de revenus
            </span>
            <h2 className="text-4xl md:text-5xl font-bold text-secondary-900 font-display mb-4">
              Calculez le montant<br className="hidden md:block" /> que vous pouvez gagner
            </h2>
            <p className="text-secondary-500 text-lg max-w-xl mx-auto">
              Estimez vos revenus potentiels en fonction de votre bien et de votre quartier à Abidjan.
            </p>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 32 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ duration: 0.8, delay: 0.1 }}
            className="grid grid-cols-1 lg:grid-cols-5 gap-6"
          >
            {/* Formulaire */}
            <div className="lg:col-span-3 bg-white rounded-3xl border border-secondary-100 shadow-sm p-8 space-y-8">

              {/* Type de bien */}
              <div>
                <label className="block text-sm font-bold text-secondary-700 mb-3 uppercase tracking-wider">Type de bien</label>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                  {propertyTypes.map(p => (
                    <button
                      key={p.id}
                      type="button"
                      onClick={() => setPropType(p.id)}
                      className={`flex flex-col items-center gap-2 p-4 rounded-2xl border-2 text-sm font-semibold transition-all duration-200 ${
                        propType === p.id
                          ? 'border-primary-500 bg-primary-50 text-primary-700 shadow-sm'
                          : 'border-secondary-100 text-secondary-500 hover:border-secondary-200'
                      }`}
                    >
                      <p.Icon />
                      {p.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Quartier */}
              <div>
                <label className="block text-sm font-bold text-secondary-700 mb-3 uppercase tracking-wider">Sélectionnez votre quartier</label>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                  {districts.map(d => (
                    <button
                      key={d.id}
                      type="button"
                      onClick={() => setDistrict(d.id)}
                      className={`py-3 px-4 rounded-xl border-2 text-sm font-semibold transition-all duration-200 ${
                        district === d.id
                          ? 'border-primary-500 bg-primary-50 text-primary-700 shadow-sm'
                          : 'border-secondary-100 text-secondary-500 hover:border-secondary-200'
                      }`}
                    >
                      {d.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Durée */}
              <div>
                <label className="block text-sm font-bold text-secondary-700 mb-3 uppercase tracking-wider">Mode de location</label>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {durations.map(d => (
                    <button
                      key={d.id}
                      type="button"
                      onClick={() => setDuration(d.id)}
                      className={`py-4 px-5 rounded-xl border-2 text-sm font-semibold text-left transition-all duration-200 ${
                        duration === d.id
                          ? 'border-primary-500 bg-primary-50 text-primary-700 shadow-sm'
                          : 'border-secondary-100 text-secondary-500 hover:border-secondary-200'
                      }`}
                    >
                      {d.label}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Résultat */}
            <div className="lg:col-span-2 flex flex-col gap-4">
              {/* Carte résultat principal */}
              <motion.div
                key={revenue}
                initial={{ scale: 0.97, opacity: 0.6 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ duration: 0.35 }}
                className="bg-secondary-900 rounded-3xl p-8 flex-1 flex flex-col justify-between relative overflow-hidden"
              >
                <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,_rgba(212,175,55,0.15),_transparent_60%)]" />
                <div className="relative z-10">
                  <p className="text-white/50 text-sm font-semibold uppercase tracking-widest mb-2">Revenus estimés / mois</p>
                  <p className="text-5xl font-bold text-primary-400 font-display leading-none mb-1">
                    {revenue.toLocaleString('fr-FR')}
                  </p>
                  <p className="text-white/50 text-sm">FCFA</p>

                  <div className="mt-8 space-y-4">
                    <div className="flex justify-between items-center border-t border-white/10 pt-4">
                      <span className="text-white/50 text-sm">Par semaine</span>
                      <span className="text-white font-bold">{weekly.toLocaleString('fr-FR')} FCFA</span>
                    </div>
                    <div className="flex justify-between items-center border-t border-white/10 pt-4">
                      <span className="text-white/50 text-sm">Taux d'occupation estimé</span>
                      <span className="text-primary-400 font-bold">{occupancy}%</span>
                    </div>
                    <div className="flex justify-between items-center border-t border-white/10 pt-4">
                      <span className="text-white/50 text-sm">Quartier</span>
                      <span className="text-white font-bold">{di.label}</span>
                    </div>
                  </div>
                </div>

                <p className="relative z-10 text-white/25 text-xs mt-6">
                  * Estimation basée sur les données du marché immobilier à Abidjan. Résultats réels peuvent varier.
                </p>
              </motion.div>

              {/* CTA sous le résultat */}
              <a
                href={partnerAndroid}
                target={partnerAndroid !== '#' ? '_blank' : undefined}
                rel="noopener noreferrer"
                className="flex items-center justify-center gap-2.5 py-4 rounded-2xl bg-primary-400 text-secondary-900 font-bold text-sm hover:bg-primary-300 transition-colors shadow-lg shadow-primary-500/20"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                </svg>
                Soumettre mon bien maintenant
              </a>
            </div>
          </motion.div>
        </div>
      </section>

      {/* ══ 3. FONCTIONNALITÉS APP ═══════════════════════════════════════════ */}
      <section className="py-24 bg-white overflow-hidden">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">

          <motion.div
            initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ duration: 0.7 }}
            className="text-center mb-14"
          >
            <span className="inline-block px-3 py-1 rounded-full bg-secondary-100 text-secondary-600 text-xs font-bold tracking-widest uppercase mb-4">
              L'application partenaire
            </span>
            <h2 className="text-4xl md:text-5xl font-bold text-secondary-900 font-display mb-4">
              Tout ce dont tu as besoin,<br className="hidden md:block" /> dans une seule app
            </h2>
          </motion.div>

          <div className="grid grid-cols-1 lg:grid-cols-[1fr_1.5fr] gap-8 lg:gap-16 items-start">

            {/* ── Liste avec barre de progression ── */}
            <div className="lg:sticky lg:top-24 space-y-2">
              {appFeatures.map((f, i) => (
                <motion.div
                  key={f.tab}
                  initial={{ opacity: 0, x: -20 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: i * 0.08 }}
                >
                  <button
                    type="button"
                    onClick={() => startProgress(i)}
                    className={`w-full text-left px-6 py-5 rounded-2xl transition-all duration-300 group ${
                      activeFeature === i
                        ? 'bg-white shadow-lg border border-secondary-100'
                        : 'hover:bg-white/70 border border-transparent hover:shadow-sm'
                    }`}
                  >
                    <div className="flex items-center gap-5">
                      {/* Icône */}
                      <div className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 transition-all duration-300 ${
                        activeFeature === i
                          ? 'bg-primary-50 border border-primary-200 text-primary-600 scale-110'
                          : 'bg-secondary-100 text-secondary-400 group-hover:bg-secondary-200'
                      }`}>
                        <f.Icon />
                      </div>

                      {/* Texte */}
                      <div className="flex-1 min-w-0">
                        <span className={`text-[11px] font-bold uppercase tracking-widest block mb-0.5 ${
                          activeFeature === i ? 'text-primary-600' : 'text-secondary-400'
                        }`}>{f.tab}</span>
                        <p className={`font-bold leading-snug transition-colors duration-200 ${
                          activeFeature === i ? 'text-secondary-900 text-base' : 'text-secondary-600 text-sm'
                        }`}>{f.title}</p>
                      </div>

                      {/* Flèche active */}
                      <div className={`shrink-0 transition-all duration-300 ${activeFeature === i ? 'opacity-100 text-primary-500' : 'opacity-0'}`}>
                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                        </svg>
                      </div>
                    </div>

                    {/* Barre de progression — visible seulement sur l'item actif */}
                    {activeFeature === i && (
                      <div className="mt-3 h-0.5 w-full bg-secondary-100 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-primary-400 rounded-full transition-none"
                          style={{ width: `${progress}%` }}
                        />
                      </div>
                    )}
                  </button>
                </motion.div>
              ))}
            </div>

            {/* ── Panneau détail animé ── */}
            <motion.div
              initial={{ opacity: 0, x: 40 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8 }}
            >
              <AnimatePresence mode="wait">
                {(() => {
                  const f = appFeatures[activeFeature]
                  return (
                    <motion.div
                      key={activeFeature}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -20 }}
                      transition={{ duration: 0.38, ease: 'easeOut' }}
                      className="bg-white rounded-3xl border border-secondary-100 shadow-xl overflow-hidden"
                    >
                      {/* ── Header ── */}
                      <div className="bg-secondary-900 px-8 pt-8 pb-6 relative overflow-hidden">
                        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,_rgba(212,175,55,0.14),_transparent_55%)]" />
                        <div className="relative z-10">
                          <div className="flex items-center gap-3 mb-4">
                            <div className="w-10 h-10 rounded-xl bg-primary-400/10 border border-primary-400/20 flex items-center justify-center text-primary-400 shrink-0">
                              <f.Icon />
                            </div>
                            <span className="text-primary-400 text-xs font-bold uppercase tracking-widest">{f.tab}</span>
                          </div>
                          <h3 className="text-white font-bold text-2xl font-display leading-snug mb-3">{f.title}</h3>
                          <p className="text-white/55 text-sm leading-relaxed">{f.desc}</p>
                        </div>
                      </div>

                      <div className="p-8 space-y-6">

                        {/* ── Vision / Priorité ── */}
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                          <motion.div
                            initial={{ opacity: 0, scale: 0.96 }} animate={{ opacity: 1, scale: 1 }}
                            transition={{ delay: 0.05 }}
                            className="bg-primary-50 border border-primary-100 rounded-2xl p-4"
                          >
                            <p className="text-[10px] font-bold uppercase tracking-widest text-primary-600 mb-1.5">Vision</p>
                            <p className="text-secondary-800 text-sm font-semibold leading-snug">{f.vision}</p>
                          </motion.div>
                          <motion.div
                            initial={{ opacity: 0, scale: 0.96 }} animate={{ opacity: 1, scale: 1 }}
                            transition={{ delay: 0.1 }}
                            className="bg-secondary-900 rounded-2xl p-4"
                          >
                            <p className="text-[10px] font-bold uppercase tracking-widest text-primary-400 mb-1.5">Priorité</p>
                            <p className="text-white text-sm font-semibold leading-snug">{f.priority}</p>
                          </motion.div>
                        </div>

                        {/* ── Tags ── */}
                        <div className="flex flex-wrap gap-2">
                          {f.tags.map(tag => (
                            <span key={tag} className="px-3 py-1 rounded-full bg-secondary-100 text-secondary-600 text-xs font-bold border border-secondary-200">
                              {tag}
                            </span>
                          ))}
                        </div>

                        {/* ── Ce que nous livrons ── */}
                        <div>
                          <p className="text-[10px] font-bold uppercase tracking-widest text-secondary-400 mb-3">Ce que tu obtiens</p>
                          <div className="space-y-2">
                            {f.delivers.map((it, idx) => (
                              <motion.div
                                key={it}
                                initial={{ opacity: 0, x: -10 }}
                                animate={{ opacity: 1, x: 0 }}
                                transition={{ delay: 0.15 + idx * 0.07 }}
                                className="flex items-start gap-3"
                              >
                                <div className="w-5 h-5 rounded-md bg-primary-50 border border-primary-100 flex items-center justify-center shrink-0 mt-0.5">
                                  <svg className="w-2.5 h-2.5 text-primary-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                                    <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                                  </svg>
                                </div>
                                <span className="text-secondary-600 text-sm leading-relaxed">{it}</span>
                              </motion.div>
                            ))}
                          </div>
                        </div>

                        {/* ── Impact ── */}
                        <motion.div
                          initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }}
                          transition={{ delay: 0.4 }}
                          className="bg-secondary-50 border border-secondary-100 rounded-2xl p-5"
                        >
                          <p className="text-[10px] font-bold uppercase tracking-widest text-secondary-400 mb-3">Impact concret</p>
                          <div className="space-y-2">
                            {f.impact.map(it => (
                              <p key={it} className="text-secondary-600 text-sm leading-relaxed flex gap-2">
                                <span className="text-primary-500 font-bold shrink-0">—</span>
                                {it}
                              </p>
                            ))}
                          </div>
                        </motion.div>

                        {/* ── CTA ── */}
                        <a
                          href={partnerAndroid}
                          target={partnerAndroid !== '#' ? '_blank' : undefined}
                          rel="noopener noreferrer"
                          className="flex items-center justify-center gap-2 w-full py-3.5 rounded-xl bg-secondary-900 text-white font-bold text-sm hover:bg-secondary-800 transition-colors"
                        >
                          Télécharger ChapeChape Partner
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                          </svg>
                        </a>
                      </div>
                    </motion.div>
                  )
                })()}
              </AnimatePresence>
            </motion.div>

          </div>
        </div>
      </section>

      {/* ══ 4. AVANTAGES ═════════════════════════════════════════════════════ */}
      <section className="py-24 bg-secondary-50 relative overflow-hidden">

        {/* ── Décor fond : hexagones + arbre ── */}
        <div className="absolute inset-0 pointer-events-none overflow-hidden select-none">

          {/* Hexagones dorés — droite */}
          <svg className="absolute -right-8 -top-8 w-[560px] h-[560px] opacity-20" viewBox="0 0 560 560" fill="none">
            {[...Array(7)].map((_, row) =>
              [...Array(7)].map((_, col) => {
                const size = 38
                const w = size * Math.sqrt(3)
                const h = size * 2
                const x = col * w + (row % 2 === 0 ? 0 : w / 2) + 30
                const y = row * h * 0.75 + 30
                const pts = [...Array(6)].map((_, k) => {
                  const angle = (Math.PI / 180) * (60 * k - 30)
                  return `${x + size * Math.cos(angle)},${y + size * Math.sin(angle)}`
                }).join(' ')
                return (
                  <polygon
                    key={`r${row}-c${col}`}
                    points={pts}
                    stroke="#D4AF37"
                    strokeWidth="2"
                    fill="#D4AF37"
                    fillOpacity={(row + col) % 3 === 0 ? '0.08' : '0.03'}
                  />
                )
              })
            )}
          </svg>

          {/* Hexagones navy — gauche bas */}
          <svg className="absolute -left-8 -bottom-8 w-[440px] h-[440px] opacity-15" viewBox="0 0 440 440" fill="none">
            {[...Array(6)].map((_, row) =>
              [...Array(6)].map((_, col) => {
                const size = 34
                const w = size * Math.sqrt(3)
                const h = size * 2
                const x = col * w + (row % 2 === 0 ? 0 : w / 2) + 20
                const y = row * h * 0.75 + 20
                const pts = [...Array(6)].map((_, k) => {
                  const angle = (Math.PI / 180) * (60 * k - 30)
                  return `${x + size * Math.cos(angle)},${y + size * Math.sin(angle)}`
                }).join(' ')
                return (
                  <polygon
                    key={`r${row}-c${col}`}
                    points={pts}
                    stroke="#1A3A5C"
                    strokeWidth="2"
                    fill="#1A3A5C"
                    fillOpacity={(row + col) % 2 === 0 ? '0.12' : '0.04'}
                  />
                )
              })
            )}
          </svg>

          {/* Arbre fractal — centre */}
          <svg
            className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[700px] opacity-[0.10]"
            viewBox="0 0 240 240" fill="none" stroke="#D4AF37" strokeLinecap="round"
          >
            <line x1="120" y1="240" x2="120" y2="158" strokeWidth="4"/>
            <line x1="120" y1="158" x2="82"  y2="108" strokeWidth="3"/><line x1="120" y1="158" x2="158" y2="108" strokeWidth="3"/>
            <line x1="82"  y1="108" x2="56"  y2="72"  strokeWidth="2.5"/><line x1="82"  y1="108" x2="100" y2="72"  strokeWidth="2.5"/>
            <line x1="158" y1="108" x2="140" y2="72"  strokeWidth="2.5"/><line x1="158" y1="108" x2="184" y2="72"  strokeWidth="2.5"/>
            <line x1="56"  y1="72"  x2="42"  y2="46"  strokeWidth="1.8"/><line x1="56"  y1="72"  x2="64"  y2="46"  strokeWidth="1.8"/>
            <line x1="100" y1="72"  x2="90"  y2="46"  strokeWidth="1.8"/><line x1="100" y1="72"  x2="108" y2="46"  strokeWidth="1.8"/>
            <line x1="140" y1="72"  x2="132" y2="46"  strokeWidth="1.8"/><line x1="140" y1="72"  x2="148" y2="46"  strokeWidth="1.8"/>
            <line x1="184" y1="72"  x2="176" y2="46"  strokeWidth="1.8"/><line x1="184" y1="72"  x2="196" y2="46"  strokeWidth="1.8"/>
            <line x1="42"  y1="46"  x2="36"  y2="28"  strokeWidth="1.2"/><line x1="42"  y1="46"  x2="46"  y2="28"  strokeWidth="1.2"/>
            <line x1="64"  y1="46"  x2="60"  y2="28"  strokeWidth="1.2"/><line x1="64"  y1="46"  x2="68"  y2="28"  strokeWidth="1.2"/>
            <line x1="90"  y1="46"  x2="86"  y2="28"  strokeWidth="1.2"/><line x1="90"  y1="46"  x2="93"  y2="28"  strokeWidth="1.2"/>
            <line x1="108" y1="46"  x2="105" y2="28"  strokeWidth="1.2"/><line x1="108" y1="46"  x2="112" y2="28"  strokeWidth="1.2"/>
            <line x1="132" y1="46"  x2="128" y2="28"  strokeWidth="1.2"/><line x1="132" y1="46"  x2="135" y2="28"  strokeWidth="1.2"/>
            <line x1="148" y1="46"  x2="145" y2="28"  strokeWidth="1.2"/><line x1="148" y1="46"  x2="152" y2="28"  strokeWidth="1.2"/>
            <line x1="176" y1="46"  x2="172" y2="28"  strokeWidth="1.2"/><line x1="176" y1="46"  x2="179" y2="28"  strokeWidth="1.2"/>
            <line x1="196" y1="46"  x2="193" y2="28"  strokeWidth="1.2"/><line x1="196" y1="46"  x2="200" y2="28"  strokeWidth="1.2"/>
          </svg>
        </div>

        <div className="mx-auto max-w-7xl px-6 lg:px-8 relative z-10">

          <motion.div
            initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ duration: 0.7 }}
            className="text-center mb-14"
          >
            <span className="inline-block px-3 py-1 rounded-full bg-primary-50 border border-primary-200 text-primary-700 text-xs font-bold tracking-widest uppercase mb-4">
              Pourquoi nous rejoindre
            </span>
            <h2 className="text-4xl md:text-5xl font-bold text-secondary-900 font-display">
              Profitez au maximum<br className="hidden md:block" /> de tous les avantages
            </h2>
          </motion.div>

          {/* Grille : 3 cards en haut (col-span-2/6) + 2 cards en bas (col-span-3/6) */}
          <div className="grid grid-cols-1 md:grid-cols-6 gap-6">
            {benefits.map((b, i) => (
              <motion.div
                key={b.title}
                initial={{ opacity: 0, y: 24 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: i * 0.1 }}
                className={`bg-white rounded-3xl p-8 border border-secondary-100 shadow-sm hover:shadow-lg hover:-translate-y-1 transition-all duration-300 group
                  ${i < 3 ? 'md:col-span-2' : 'md:col-span-3'}`}
              >
                <div className="w-12 h-12 rounded-2xl bg-primary-50 border border-primary-100 flex items-center justify-center text-primary-600 mb-5 group-hover:bg-primary-100 transition-colors">
                  {b.icon}
                </div>
                <span className="inline-block px-2 py-0.5 rounded-md bg-secondary-100 text-secondary-500 text-[10px] font-bold uppercase tracking-wider mb-3">
                  {b.tag}
                </span>
                <h3 className="font-bold text-secondary-900 text-lg mb-2 leading-snug">{b.title}</h3>
                <p className="text-secondary-500 text-sm leading-relaxed">{b.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ══ 5. PROCESS ═══════════════════════════════════════════════════════ */}
      <section className="py-28 bg-secondary-900 relative overflow-hidden">

        {/* Fond : gradient + points */}
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_left,_rgba(212,175,55,0.12),_transparent_55%)]" />
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,_rgba(212,175,55,0.07),_transparent_55%)]" />
        <div className="absolute inset-0 opacity-[0.05] bg-[radial-gradient(#D4AF37_1px,transparent_1px)] [background-size:28px_28px]" />

        {/* Particules flottantes dorées */}
        {[...Array(10)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute rounded-full bg-primary-400"
            style={{
              width:  `${3 + (i % 4)}px`,
              height: `${3 + (i % 4)}px`,
              left:   `${8 + i * 9}%`,
              top:    `${15 + ((i * 37) % 70)}%`,
            }}
            animate={{
              y:       [0, -(20 + (i % 3) * 15), 0],
              opacity: [0, 0.5 + (i % 3) * 0.2, 0],
            }}
            transition={{
              duration: 3 + (i % 4),
              repeat:   Infinity,
              delay:    i * 0.4,
              ease:     'easeInOut',
            }}
          />
        ))}

        <div className="mx-auto max-w-7xl px-6 lg:px-8 relative z-10">

          {/* Titre */}
          <motion.div
            initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }} transition={{ duration: 0.7 }}
            className="text-center mb-20"
          >
            <span className="inline-block px-3 py-1 rounded-full bg-primary-500/10 border border-primary-500/30 text-primary-400 text-xs font-bold tracking-widest uppercase mb-4">
              Simple et rapide
            </span>
            <h2 className="text-4xl md:text-5xl font-bold text-white font-display">
              Comment s'enregistrer
            </h2>
          </motion.div>

          {/* Ligne SVG animée qui relie les étapes */}
          <div className="hidden lg:block relative mb-4 px-[10%]">
            <svg viewBox="0 0 900 4" className="w-full" preserveAspectRatio="none">
              <motion.line
                x1="0" y1="2" x2="900" y2="2"
                stroke="#D4AF37" strokeWidth="1.5" strokeDasharray="6 4"
                initial={{ pathLength: 0, opacity: 0 }}
                whileInView={{ pathLength: 1, opacity: 0.35 }}
                viewport={{ once: true }}
                transition={{ duration: 1.6, ease: 'easeInOut', delay: 0.4 }}
              />
            </svg>
            {/* Points sur la ligne */}
            {[0, 33.3, 66.6, 100].map((pct, i) => (
              <motion.div
                key={i}
                initial={{ scale: 0, opacity: 0 }}
                whileInView={{ scale: 1, opacity: 1 }}
                viewport={{ once: true }}
                transition={{ delay: 0.3 + i * 0.3, duration: 0.4, type: 'spring' }}
                className="absolute top-1/2 -translate-y-1/2 w-3 h-3 rounded-full bg-primary-400 border-2 border-secondary-900 shadow-[0_0_8px_rgba(212,175,55,0.8)]"
                style={{ left: `calc(${pct}% + ${i === 0 ? 0 : i === 3 ? -12 : -6}px)` }}
              />
            ))}
          </div>

          {/* Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
            {steps.map((s, i) => (
              <motion.div
                key={s.n}
                initial={{ opacity: 0, y: 40 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.65, delay: i * 0.15, ease: 'easeOut' }}
                whileHover={{ y: -6, transition: { duration: 0.25 } }}
                className="group relative bg-white/5 border border-white/10 rounded-3xl p-8 h-full cursor-default
                  hover:bg-white/10 hover:border-primary-400/40
                  hover:shadow-[0_0_30px_rgba(212,175,55,0.12)]
                  transition-all duration-300"
              >
                {/* Badge numéro avec glow au hover */}
                <div className="relative w-16 h-16 rounded-2xl bg-primary-400/10 border border-primary-400/20 flex items-center justify-center mb-6
                  group-hover:bg-primary-400/20 group-hover:border-primary-400/50
                  group-hover:shadow-[0_0_20px_rgba(212,175,55,0.3)]
                  transition-all duration-300"
                >
                  {/* Pulse ring */}
                  <motion.div
                    className="absolute inset-0 rounded-2xl border border-primary-400/30"
                    animate={{ scale: [1, 1.18, 1], opacity: [0.4, 0, 0.4] }}
                    transition={{ duration: 2.5, repeat: Infinity, delay: i * 0.5 }}
                  />
                  <motion.span
                    initial={{ opacity: 0, scale: 0.5 }}
                    whileInView={{ opacity: 1, scale: 1 }}
                    viewport={{ once: true }}
                    transition={{ delay: 0.4 + i * 0.15, type: 'spring', stiffness: 200 }}
                    className="text-2xl font-bold text-primary-400 font-display relative z-10"
                  >
                    {s.n}
                  </motion.span>
                </div>

                {/* Contenu */}
                <motion.h3
                  initial={{ opacity: 0 }}
                  whileInView={{ opacity: 1 }}
                  viewport={{ once: true }}
                  transition={{ delay: 0.5 + i * 0.15 }}
                  className="font-bold text-white text-lg mb-3 leading-snug group-hover:text-primary-100 transition-colors duration-300"
                >
                  {s.title}
                </motion.h3>
                <motion.p
                  initial={{ opacity: 0 }}
                  whileInView={{ opacity: 1 }}
                  viewport={{ once: true }}
                  transition={{ delay: 0.6 + i * 0.15 }}
                  className="text-white/50 text-sm leading-relaxed group-hover:text-white/65 transition-colors duration-300"
                >
                  {s.desc}
                </motion.p>

                {/* Coin décoratif doré */}
                <div className="absolute top-4 right-4 w-6 h-6 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                  <svg viewBox="0 0 24 24" fill="none">
                    <path d="M4 4h8M4 4v8" stroke="#D4AF37" strokeWidth="2" strokeLinecap="round"/>
                  </svg>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ══ 6. DOWNLOAD CTA ══════════════════════════════════════════════════ */}
      <section className="py-20 bg-secondary-50">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: 32 }} whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }} transition={{ duration: 0.8 }}
            className="relative bg-white rounded-3xl border border-secondary-100 shadow-xl overflow-hidden"
          >
            <div className="grid grid-cols-1 lg:grid-cols-[1fr_420px] min-h-[380px]">

              {/* ── Gauche : texte + badges + checklist ── */}
              <div className="p-10 lg:p-16 flex flex-col justify-center">
                <p className="text-primary-600 text-xs font-bold uppercase tracking-widest mb-4">Téléchargez maintenant</p>
                <h3 className="text-4xl lg:text-5xl font-bold text-secondary-900 font-display mb-4 leading-tight">
                  Commencez à gagner<br />dès aujourd'hui
                </h3>
                <p className="text-secondary-500 text-base leading-relaxed mb-8 max-w-lg">
                  Rejoignez des centaines de propriétaires qui font confiance à ChapeChape pour rentabiliser leur patrimoine immobilier à Abidjan.
                </p>

                {/* Badges officiels */}
                <div className="flex flex-wrap gap-3 mb-10">
                  <motion.a
                    whileHover={{ scale: 1.04, y: -2 }} whileTap={{ scale: 0.97 }}
                    href={partnerIos}
                    target={partnerIos !== '#' ? '_blank' : undefined}
                    rel="noopener noreferrer"
                    className="inline-block rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-shadow"
                  >
                    <img src="/assets/appstore.png" alt="Télécharger sur l'App Store" className="h-10 w-auto" />
                  </motion.a>
                  <motion.a
                    whileHover={{ scale: 1.04, y: -2 }} whileTap={{ scale: 0.97 }}
                    href={partnerAndroid}
                    target={partnerAndroid !== '#' ? '_blank' : undefined}
                    rel="noopener noreferrer"
                    className="inline-block rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-shadow"
                  >
                    <img src="/assets/googleplay.png" alt="Disponible sur Google Play" className="h-10 w-auto" />
                  </motion.a>
                </div>

                {/* Checklist 2 colonnes */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-10 gap-y-3 mb-8">
                  {[
                    { t: 'Mise en ligne en 48h',    s: 'Validation sous 2 jours ouvrés' },
                    { t: 'Locataires vérifiés',      s: 'Sélection rigoureuse par nos équipes' },
                    { t: 'Paiements garantis',       s: 'Versements sécurisés à date fixe' },
                    { t: 'Dashboard temps réel',     s: 'Revenus et stats sur mobile' },
                    { t: 'Support dédié 24h/24',     s: 'Une équipe toujours disponible' },
                    { t: 'Courte & longue durée',    s: 'Adaptez selon vos préférences' },
                  ].map((item, i) => (
                    <motion.div
                      key={item.t}
                      initial={{ opacity: 0, x: -10 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      viewport={{ once: true }}
                      transition={{ delay: i * 0.07, duration: 0.4 }}
                      className="flex items-start gap-2.5"
                    >
                      <div className="w-5 h-5 rounded-full bg-primary-50 border border-primary-200 flex items-center justify-center shrink-0 mt-0.5">
                        <svg className="w-2.5 h-2.5 text-primary-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                        </svg>
                      </div>
                      <div>
                        <p className="text-secondary-800 text-sm font-semibold leading-tight">{item.t}</p>
                        <p className="text-secondary-400 text-xs">{item.s}</p>
                      </div>
                    </motion.div>
                  ))}
                </div>

                {/* Contact */}
                <div className="border-t border-secondary-100 pt-6 flex flex-wrap gap-6 items-center">
                  <div>
                    <p className="text-secondary-400 text-xs mb-1">Support</p>
                    <a href="mailto:support@chapechaperesidence.com" className="text-primary-600 text-sm font-semibold hover:text-primary-500 transition-colors">
                      support@chapechaperesidence.com
                    </a>
                  </div>
                  <div>
                    <p className="text-secondary-400 text-xs mb-1">Téléphone</p>
                    <a href="tel:+2250748001042" className="text-secondary-600 text-sm font-medium hover:text-secondary-800 transition-colors">
                      +225 07 48 00 10 42
                    </a>
                  </div>
                  <Link
                    to="/contact"
                    className="ml-auto inline-flex items-center gap-2 text-primary-600 text-sm font-bold hover:text-primary-500 transition-colors"
                  >
                    Nous contacter
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                    </svg>
                  </Link>
                </div>
              </div>

              {/* ── Droite : grand logo sur fond sombre ── */}
              <div className="relative bg-secondary-900 flex flex-col items-center justify-center p-12 overflow-hidden">
                {/* Fond décoratif */}
                <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_rgba(212,175,55,0.18),_transparent_65%)]" />
                <div className="absolute inset-0 opacity-[0.05] bg-[radial-gradient(#D4AF37_1px,transparent_1px)] [background-size:20px_20px]" />

                {/* Glow animé */}
                <motion.div
                  animate={{ scale: [1, 1.15, 1], opacity: [0.3, 0.55, 0.3] }}
                  transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
                  className="absolute w-64 h-64 rounded-full bg-primary-400/20 blur-3xl"
                />

                {/* Logo */}
                <motion.div
                  initial={{ opacity: 0, scale: 0.8 }}
                  whileInView={{ opacity: 1, scale: 1 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.7, type: 'spring', stiffness: 140 }}
                  className="relative z-10"
                >
                  <img
                    src="/assets/logochape_partner.png"
                    alt="ChapeChape Partner"
                    className="w-52 h-52 rounded-[2.5rem] shadow-2xl border-4 border-white/10 object-contain bg-white p-4"
                  />
                </motion.div>

                <motion.div
                  initial={{ opacity: 0, y: 12 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: 0.3 }}
                  className="relative z-10 text-center mt-6"
                >
                  <p className="text-white font-bold text-xl font-display">ChapeChape Partner</p>
                  <p className="text-white/40 text-sm mt-1">Application Partenaire</p>
                </motion.div>
              </div>

            </div>
          </motion.div>
        </div>
      </section>

      {/* Contact */}
      <Contact />
    </div>
  )
}
