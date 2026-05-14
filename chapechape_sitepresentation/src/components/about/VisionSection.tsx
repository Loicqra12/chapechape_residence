import { motion, useScroll, useTransform } from 'framer-motion';
import { useRef } from 'react';

// ─── Données valeurs ─────────────────────────────────────────────────────────
const values = [
  {
    title: 'Accessibilité',
    desc: 'Nous rendons la location de résidences meublées simple, rapide et accessible à tous — qu\'on soit locataire, expatrié ou professionnel en déplacement à Abidjan.',
  },
  {
    title: 'Confiance',
    desc: 'Chaque transaction est sécurisée, chaque bien est vérifié. Nous garantissons des hébergements conformes aux attentes, avec des processus transparents à chaque étape.',
  },
  {
    title: 'Innovation',
    desc: 'Nous intégrons les technologies adaptées au marché ivoirien — paiements mobile money, plateforme intuitive, réservation instantanée ou sur approbation.',
  },
  {
    title: 'Responsabilité',
    desc: 'Nous agissons de manière éthique envers nos clients, nos partenaires et la communauté. Chaque décision est guidée par l\'intégrité et le respect de nos engagements.',
  },
  {
    title: 'Excellence',
    desc: 'Offrir un service de qualité supérieure à chaque étape du processus. Du premier contact à la fin du séjour, nous visons à dépasser les attentes.',
  },
  {
    title: 'Proximité',
    desc: 'Une équipe locale basée à Abidjan, qui connaît les quartiers, les réalités du marché et les besoins spécifiques des Ivoiriens et des visiteurs.',
  },
];

// ─── Données catégories ───────────────────────────────────────────────────────
const categories = [
  {
    id: 'meuble',
    label: 'Studio Meublé',
    tag: 'Court séjour',
    slug: 'chapechaperesidence.com/studio',
    description: 'Studios et appartements entièrement équipés — linge, cuisine, WiFi. Parfait pour un passage à Abidjan, tout est prêt à votre arrivée.',
    image: '/assets/residences/meuble.png',
    rates: [
      { label: '1 heure', price: 'dès 5 000 FCFA' },
      { label: 'Demi-journée', price: 'dès 15 000 FCFA' },
      { label: 'Journée', price: 'dès 25 000 FCFA' },
      { label: 'Nuitée', price: 'dès 30 000 FCFA' },
    ],
  },
  {
    id: 'economique',
    label: 'Résidence Économique',
    tag: 'Abordable',
    slug: 'chapechaperesidence.com/economique',
    description: 'Des logements propres et bien situés à prix accessible. Parfaits pour les étudiants, petits budgets et séjours de courte durée.',
    image: '/assets/residences/economique.png',
    rates: [
      { label: 'Demi-journée', price: 'dès 8 000 FCFA' },
      { label: 'Journée', price: 'dès 15 000 FCFA' },
      { label: 'Nuitée', price: 'dès 18 000 FCFA' },
      { label: 'Mensuel', price: 'dès 90 000 FCFA' },
    ],
  },
  {
    id: 'villa',
    label: 'Villa & Prestige',
    tag: 'Prestige',
    slug: 'chapechaperesidence.com/villa',
    description: 'Villas haut de gamme avec piscine, sécurité 24h/24, terrasse et personnel dédié. L\'excellence de l\'hospitalité ivoirienne.',
    image: '/assets/residences/insolite.png',
    rates: [
      { label: 'Demi-journée', price: 'dès 75 000 FCFA' },
      { label: 'Journée', price: 'dès 120 000 FCFA' },
      { label: 'Nuitée', price: 'dès 150 000 FCFA' },
      { label: 'Weekend', price: 'dès 250 000 FCFA' },
    ],
  },
  {
    id: 'hotel',
    label: 'Style Hôtel',
    tag: 'Tout inclus',
    slug: 'chapechaperesidence.com/hotel',
    description: 'Résidences avec services hôteliers : ménage quotidien, room service, conciergerie. Le meilleur des deux mondes.',
    image: '/assets/residences/hotel.png',
    rates: [
      { label: '1 heure', price: 'dès 10 000 FCFA' },
      { label: 'Demi-journée', price: 'dès 25 000 FCFA' },
      { label: 'Journée', price: 'dès 40 000 FCFA' },
      { label: 'Nuitée', price: 'dès 50 000 FCFA' },
    ],
  },
  {
    id: 'longue_duree',
    label: 'Longue Durée',
    tag: 'Mensuel',
    slug: 'chapechaperesidence.com/longue-duree',
    description: 'Résidences meublées pour expatriés, familles et professionnels en mission longue. Contrats flexibles à la semaine ou au mois.',
    image: '/assets/residences/longue_duree.png',
    rates: [
      { label: 'Semaine', price: 'dès 80 000 FCFA' },
      { label: 'Mensuel', price: 'dès 150 000 FCFA' },
      { label: '3 mois', price: 'dès 400 000 FCFA' },
      { label: 'Annuel', price: 'dès 1 200 000 FCFA' },
    ],
  },
  {
    id: 'colocation',
    label: 'Colocation',
    tag: 'Communauté',
    slug: 'chapechaperesidence.com/colocation',
    description: 'Espaces partagés modernes pour jeunes actifs et étudiants. Charges incluses, ambiance conviviale, au cœur d\'Abidjan.',
    image: '/assets/residences/colocation.png',
    rates: [
      { label: 'Mensuel', price: 'dès 60 000 FCFA' },
      { label: '3 mois', price: 'dès 160 000 FCFA' },
      { label: '6 mois', price: 'dès 300 000 FCFA' },
      { label: 'Annuel', price: 'dès 550 000 FCFA' },
    ],
  },
];

const pillars = [
  {
    title: 'Innovation Africaine',
    desc: 'Paiements Orange Money, Wave, MTN — une plateforme pensée pour les réalités du marché ivoirien.',
  },
  {
    title: 'Excellence Opérationnelle',
    desc: 'Validation des biens sous 48h, locataires vérifiés, paiements sécurisés, support 24h/24 en français.',
  },
  {
    title: 'Proximité & Confiance',
    desc: 'Équipe locale basée à Abidjan, présente de Cocody à Port-Bouët, engagée envers la communauté.',
  },
];

// ─── Composant principal ──────────────────────────────────────────────────────
const VisionSection = () => {
  const logoRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: logoRef, offset: ['start end', 'end start'] });
  const logoY = useTransform(scrollYProgress, [0, 1], [-30, 30]);

  return (
    <section className="relative overflow-hidden">

      {/* ══════════════════════════════════════════
          BLOC 1 — NOTRE VISION  (dark, Veone)
      ══════════════════════════════════════════ */}
      <div className="relative bg-secondary-900 overflow-hidden min-h-[520px] flex items-center">

        {/* Grille de points très subtile */}
        <div className="absolute inset-0 pointer-events-none opacity-[0.04] bg-[radial-gradient(circle,#D4AF37_1px,transparent_1px)] [background-size:32px_32px]" />

        {/* Halo doré derrière le logo */}
        <motion.div
          className="absolute right-0 top-1/2 -translate-y-1/2 w-[500px] h-[500px] rounded-full bg-primary-500/10 blur-[120px] pointer-events-none"
          animate={{ scale: [1, 1.12, 1], opacity: [0.3, 0.55, 0.3] }}
          transition={{ duration: 9, repeat: Infinity, ease: 'easeInOut' }}
        />

        <div className="relative z-10 w-full max-w-7xl mx-auto px-6 lg:px-12 py-24">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">

            {/* Gauche — texte */}
            <motion.div
              initial={{ opacity: 0, y: 40 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8 }}
            >
              {/* Badge */}
              <motion.div
                initial={{ opacity: 0, x: -20 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5 }}
                className="inline-flex items-center gap-2 px-3 py-1.5 mb-8 rounded-full border border-white/10 bg-white/5 text-white/60 text-xs font-bold tracking-widest uppercase font-body"
              >
                <motion.span
                  className="w-1.5 h-1.5 rounded-full bg-primary-400"
                  animate={{ opacity: [1, 0.3, 1] }}
                  transition={{ duration: 2, repeat: Infinity }}
                />
                Notre Vision
              </motion.div>

              {/* Titre */}
              <h2 className="text-4xl md:text-5xl lg:text-[3.5rem] font-bold text-white font-display leading-[1.08] mb-8 tracking-tight">
                L'immobilier ivoirien,{' '}
                <br className="hidden sm:block" />
                <span className="text-primary-400">réinventé pour vous</span>
              </h2>

              {/* Texte */}
              <p className="text-white/60 text-base md:text-lg leading-relaxed font-body mb-4 max-w-lg">
                En Côte d'Ivoire, trouver une résidence de qualité relève souvent du parcours du combattant.
                <span className="text-white/90"> ChapeChape Residence </span>
                est né de cette réalité : simplifier l'accès à des logements meublés, sécurisés et accessibles,
                pour chaque Abidjanais, chaque visiteur, chaque professionnel en mission.
              </p>
              <p className="text-white/40 text-sm leading-relaxed font-body mb-10 max-w-lg">
                Notre ambition : devenir la <span className="text-white/70">référence de l'hébergement temporaire en Afrique de l'Ouest</span>,
                en connectant propriétaires et locataires sur une plateforme pensée pour le marché local.
              </p>

              {/* CTA */}
              <motion.a
                href="/contact"
                whileHover={{ scale: 1.03 }}
                whileTap={{ scale: 0.97 }}
                className="inline-flex items-center gap-3 px-7 py-3.5 rounded-full bg-primary-500 text-secondary-900 font-bold text-sm font-body hover:bg-primary-400 transition-colors duration-200"
              >
                Nous écrire
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M17 8l4 4m0 0l-4 4m4-4H3" />
                </svg>
              </motion.a>
            </motion.div>

            {/* Droite — logo flottant */}
            <div ref={logoRef} className="hidden lg:flex justify-center items-center">
              <motion.div
                style={{ y: logoY }}
                className="relative"
              >
                {/* Halo derrière le logo */}
                <motion.div
                  className="absolute inset-[-40px] rounded-full bg-primary-500/8 blur-3xl"
                  animate={{ scale: [1, 1.15, 1] }}
                  transition={{ duration: 6, repeat: Infinity, ease: 'easeInOut' }}
                />
                {/* Logo */}
                <motion.img
                  src="/assets/logo.png"
                  alt="ChapeChape Residence"
                  className="relative w-64 md:w-80 object-contain drop-shadow-2xl"
                  initial={{ opacity: 0, scale: 0.9 }}
                  whileInView={{ opacity: 1, scale: 1 }}
                  viewport={{ once: true }}
                  transition={{ duration: 1, ease: 'easeOut' }}
                  animate={{ y: [0, -10, 0] }}
                  style={{ animationDuration: '6s', animationIterationCount: 'infinite', animationTimingFunction: 'ease-in-out' }}
                />
              </motion.div>
            </div>

          </div>
        </div>
      </div>

      {/* ══════════════════════════════════════════
          BLOC 2 — CE QUE NOUS FAISONS
      ══════════════════════════════════════════ */}
      <div className="bg-white">

        {/* Liseré or/navy */}
        <div className="h-1 w-full bg-gradient-to-r from-secondary-900 via-primary-500 to-secondary-900" />

        <div className="max-w-7xl mx-auto px-6 lg:px-12 py-20">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-start">

            {/* Gauche — narrative */}
            <motion.div
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.7 }}
            >
              <h3 className="text-3xl md:text-4xl font-bold text-secondary-900 font-display mb-8 leading-tight">
                Ce que nous faisons
              </h3>
              <div className="space-y-5 text-secondary-600 font-body leading-relaxed text-[15px]">
                <p>
                  Nous nous engageons à fournir une plateforme de location de résidences meublées innovante et de haute qualité,
                  adaptée aux réalités du marché ivoirien. En nous appuyant sur les paiements locaux
                  (Orange Money, Wave, MTN), nous rendons chaque transaction fluide et sécurisée.
                </p>
                <p>
                  Notre objectif est de devenir le partenaire de confiance des propriétaires et des locataires en Côte d'Ivoire,
                  en optimisant les revenus locatifs et l'expérience résidentielle pour tous.
                </p>
                <p>
                  Nous croyons en l'innovation, la proximité et la satisfaction client. Chaque résidence est une occasion
                  de dépasser les attentes, de créer de la valeur et de renforcer l'excellence de l'hospitalité africaine.
                  Ensemble, construisons l'Abidjan de demain.
                </p>
              </div>
            </motion.div>

            {/* Droite — 3 piliers épurés */}
            <div className="space-y-0 divide-y divide-secondary-100">
              {pillars.map((p, i) => (
                <motion.div
                  key={p.title}
                  initial={{ opacity: 0, x: 20 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.6, delay: i * 0.1 }}
                  className="py-6 group"
                >
                  <div className="flex items-start gap-4">
                    {/* Numéro */}
                    <span className="shrink-0 text-xs font-bold text-primary-500 font-body mt-1">
                      0{i + 1}
                    </span>
                    <div>
                      <h4 className="font-bold text-secondary-900 font-display mb-1 group-hover:text-primary-600 transition-colors duration-200">
                        {p.title}
                      </h4>
                      <p className="text-sm text-secondary-500 font-body leading-relaxed">{p.desc}</p>
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>

          </div>
        </div>
      </div>

      {/* ══════════════════════════════════════════
          BLOC 3 — NOS VALEURS
      ══════════════════════════════════════════ */}
      <div className="bg-white">
        <div className="max-w-7xl mx-auto px-6 lg:px-12 py-20">

          {/* En-tête */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="mb-12"
          >
            <p className="text-xs font-bold tracking-widest uppercase text-primary-600 font-body mb-3">
              Nos Valeurs
            </p>
            <h3 className="text-3xl md:text-4xl font-bold text-secondary-900 font-display leading-tight max-w-xl">
              Ce qui nous guide chaque jour
            </h3>
          </motion.div>

          {/* Grille 3 × 2 — cartes épurées sans icône */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-0 border border-secondary-200 rounded-xl overflow-hidden">
            {values.map((v, i) => (
              <motion.div
                key={v.title}
                initial={{ opacity: 0, y: 16 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: i * 0.07 }}
                className="group p-8 border-b border-r border-secondary-200 last:border-r-0 hover:bg-secondary-50 transition-colors duration-200 cursor-default [&:nth-child(3n)]:border-r-0 [&:nth-last-child(-n+3)]:border-b-0"
              >
                {/* Ligne dorée animée en haut au hover */}
                <div className="w-8 h-0.5 bg-primary-500 mb-5 group-hover:w-14 transition-all duration-300" />
                <h4 className="font-bold text-secondary-900 font-display text-lg mb-3 leading-tight">
                  {v.title}
                </h4>
                <p className="text-sm text-secondary-500 font-body leading-relaxed">
                  {v.desc}
                </p>
              </motion.div>
            ))}
          </div>

        </div>
      </div>

      {/* ══════════════════════════════════════════
          BLOC 4 — NOS 6 TYPES DE RÉSIDENCES
      ══════════════════════════════════════════ */}
      <div className="bg-secondary-50">

        <div className="max-w-7xl mx-auto px-6 lg:px-12 py-20">

          {/* En-tête */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="mb-16"
          >
            <p className="text-xs font-bold tracking-widest uppercase text-primary-600 font-body mb-3">
              Nos résidences
            </p>
            <div className="flex flex-col md:flex-row md:items-end md:justify-between gap-4">
              <h3 className="text-3xl md:text-4xl font-bold text-secondary-900 font-display leading-tight max-w-xl">
                6 types de logements pour chaque besoin, chaque budget
              </h3>
              <p className="text-secondary-500 font-body text-sm max-w-xs leading-relaxed">
                Du studio au passage à la villa prestige — tout Abidjan à portée de main.
              </p>
            </div>
            {/* Ligne décorative */}
            <motion.div
              className="mt-6 h-px bg-gradient-to-r from-primary-500 to-transparent"
              initial={{ width: 0 }}
              whileInView={{ width: '100%' }}
              viewport={{ once: true }}
              transition={{ duration: 1, ease: 'easeOut' }}
            />
          </motion.div>

          {/* Grille — style Blok/Danaya */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-x-10 gap-y-12">
            {categories.map((cat, i) => (
              <motion.div
                key={cat.id}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: i * 0.07 }}
                className="group flex flex-col gap-4"
              >
                {/* Image carrée style icône app */}
                <div className="w-[72px] h-[72px] rounded-2xl overflow-hidden shadow-sm border border-secondary-100 shrink-0 group-hover:shadow-md transition-shadow duration-300">
                  <motion.img
                    src={cat.image}
                    alt={cat.label}
                    className="w-full h-full object-cover"
                    whileHover={{ scale: 1.06 }}
                    transition={{ duration: 0.4 }}
                  />
                </div>

                {/* Texte */}
                <div>
                  {/* Nom + séparateur */}
                  <h4 className="font-bold text-primary-600 font-display text-lg leading-tight mb-1">
                    {cat.label}
                  </h4>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-xs text-secondary-400 font-body">{cat.tag}</span>
                    <span className="flex-1 h-px bg-secondary-200 max-w-[40px]" />
                  </div>
                  <p className="text-xs text-secondary-400 font-body mb-3">{cat.slug}</p>

                  {/* Description */}
                  <p className="text-sm text-secondary-600 font-body leading-relaxed mb-4">
                    {cat.description}
                  </p>

                  {/* Séparateur */}
                  <div className="w-full h-px bg-secondary-100 mb-3" />

                  {/* Tarifs */}
                  <div className="space-y-1.5">
                    {cat.rates.map((rate) => (
                      <div key={rate.label} className="flex items-center justify-between">
                        <span className="text-xs text-secondary-400 font-body">{rate.label}</span>
                        <span className="text-xs font-semibold text-secondary-700 font-body">{rate.price}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          {/* CTA */}
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.5 }}
            className="flex justify-center mt-16"
          >
            <a
              href="/residences"
              className="inline-flex items-center gap-3 px-8 py-4 rounded-full bg-secondary-900 text-white font-bold font-body text-sm hover:bg-secondary-800 transition-colors duration-200"
            >
              Explorer toutes nos résidences
              <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M17 8l4 4m0 0l-4 4m4-4H3" />
              </svg>
            </a>
          </motion.div>

        </div>
      </div>

    </section>
  );
};

export default VisionSection;
