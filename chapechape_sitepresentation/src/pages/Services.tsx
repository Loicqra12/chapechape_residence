import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import SEOHead from '../components/seo/SEOHead';

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com';

const services = [
  {
    id: 'owners',
    tag: 'Pour les Propriétaires',
    title: 'Maximisez votre patrimoine immobilier',
    description: 'Confiez-nous la gestion de votre bien et profitez de revenus optimisés, sans les contraintes du quotidien. Notre plateforme met en relation propriétaires et locataires vérifiés en toute transparence.',
    image: '/assets/images/femmepartner.png', // Remplacer par /assets/services/owners.jpg
    features: [
      { num: '01', title: 'Mise en ligne en 48h', desc: 'Votre résidence est publiée et visible par des milliers de locataires potentiels sous 2 jours ouvrés.' },
      { num: '02', title: 'Locataires vérifiés', desc: 'Chaque profil locataire est contrôlé par nos équipes avant toute réservation. Sécurité garantie.' },
      { num: '03', title: 'Paiements garantis', desc: 'Versements sécurisés à date fixe via Orange Money, Wave, MTN ou virement bancaire.' },
      { num: '04', title: 'Dashboard temps réel', desc: 'Suivez vos revenus, réservations et avis directement depuis l\'application mobile ChapeChape Partner.' },
    ],
    cta: { label: 'Devenir propriétaire partenaire', href: '/partenaires' },
    align: 'left', // image à gauche, texte à droite
  },
  {
    id: 'tenants',
    tag: 'Pour les Locataires',
    title: 'Trouvez votre résidence idéale à Abidjan',
    description: 'Accédez à des centaines de résidences meublées, vérifiées et disponibles dans toutes les communes d\'Abidjan. Réservez en quelques clics, payez avec votre mobile money, emménagez sereinement.',
    image: '/assets/images/hero-luxury.png', // Remplacer par /assets/services/tenants.jpg
    features: [
      { num: '01', title: 'Recherche intelligente', desc: 'Filtres avancés par commune, budget, type de résidence, équipements et durée de séjour.' },
      { num: '02', title: 'Réservation instantanée', desc: 'Confirmez votre séjour en quelques minutes, sans paperasse ni intermédiaire inutile.' },
      { num: '03', title: 'Paiement mobile money', desc: 'Orange Money, Wave, MTN MoMo — payez avec la solution qui vous convient, en toute sécurité.' },
      { num: '04', title: 'Support 24h/24', desc: 'Notre équipe est disponible à toute heure pour répondre à vos questions et urgences.' },
    ],
    cta: { label: 'Télécharger l\'application', href: '/apps' },
    align: 'right', // image à droite, texte à gauche
  },
];

const fadeUp = (delay = 0) => ({
  initial: { opacity: 0, y: 24 },
  whileInView: { opacity: 1, y: 0 },
  viewport: { once: true },
  transition: { duration: 0.6, delay, ease: 'easeOut' as const },
});

export default function Services() {
  return (
    <div className="bg-white min-h-screen">
      <SEOHead
        title="Nos services"
        description="Services propriétaires et locataires : gestion locative, réservation, paiement mobile. ChapeChape Residence, Côte d'Ivoire."
        url={`${siteUrl}/services`}
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
              Expertise & Excellence
            </span>
            <h1 className="text-3xl sm:text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              Nos{' '}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">
                Services
              </span>
            </h1>
            <p className="text-lg text-white/60 max-w-2xl mx-auto font-body leading-relaxed">
              Une gamme complète de services sur-mesure pour propriétaires et locataires,
              conçus pour le marché immobilier ivoirien.
            </p>
          </motion.div>
        </div>
      </section>

      {/* ── SERVICES — layout alterné ─────────────── */}
      {services.map((service, i) => {
        const isLeft = service.align === 'left';
        return (
          <section key={service.id} className={i % 2 === 0 ? 'bg-white' : 'bg-secondary-50'}>
            <div className="max-w-7xl mx-auto px-6 lg:px-12 py-24">
              <div className={`grid grid-cols-1 lg:grid-cols-2 gap-16 items-center ${isLeft ? '' : 'lg:grid-flow-dense'}`}>

                {/* Image */}
                <motion.div
                  initial={{ opacity: 0, x: isLeft ? -30 : 30 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.8 }}
                  className={isLeft ? '' : 'lg:col-start-2'}
                >
                  <div className="relative rounded-2xl overflow-hidden aspect-[4/3] bg-secondary-100 group">
                    <img
                      src={service.image}
                      alt={service.title}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/40 via-transparent to-transparent" />
                    {/* Badge tag sur l'image */}
                    <div className="absolute top-4 left-4 px-3 py-1.5 rounded-full bg-secondary-900/70 backdrop-blur-sm border border-white/10 text-white text-xs font-bold font-body tracking-widest uppercase">
                      {service.tag}
                    </div>
                  </div>
                </motion.div>

                {/* Texte */}
                <motion.div
                  initial={{ opacity: 0, x: isLeft ? 30 : -30 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.8, delay: 0.15 }}
                  className={isLeft ? '' : 'lg:col-start-1 lg:row-start-1'}
                >
                  <p className="text-xs font-bold tracking-widest uppercase text-primary-600 font-body mb-3">
                    {service.tag}
                  </p>
                  <h2 className="text-3xl md:text-4xl font-bold text-secondary-900 font-display leading-tight mb-6">
                    {service.title}
                  </h2>
                  <div className="h-px bg-gradient-to-r from-primary-500 to-transparent max-w-[80px] mb-6" />
                  <p className="text-secondary-600 font-body text-[15px] leading-relaxed mb-10">
                    {service.description}
                  </p>

                  {/* Features numérotées */}
                  <div className="space-y-0 divide-y divide-secondary-100 mb-10">
                    {service.features.map((f) => (
                      <div key={f.num} className="group flex items-start gap-5 py-4">
                        <span className="shrink-0 text-xs font-bold text-primary-500 font-body mt-0.5">{f.num}</span>
                        <div>
                          <h4 className="font-bold text-secondary-900 font-display text-sm mb-0.5 group-hover:text-primary-600 transition-colors duration-200">
                            {f.title}
                          </h4>
                          <p className="text-xs text-secondary-500 font-body leading-relaxed">{f.desc}</p>
                        </div>
                      </div>
                    ))}
                  </div>

                  <Link
                    to={service.cta.href}
                    className="inline-flex items-center gap-3 px-7 py-3.5 rounded-full bg-secondary-900 text-white font-bold font-body text-sm hover:bg-secondary-800 transition-colors duration-200"
                  >
                    {service.cta.label}
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M17 8l4 4m0 0l-4 4m4-4H3" />
                    </svg>
                  </Link>
                </motion.div>

              </div>
            </div>

            {/* Séparateur discret entre sections */}
            {i < services.length - 1 && (
              <div className="max-w-7xl mx-auto px-6 lg:px-12">
                <div className="h-px bg-gradient-to-r from-transparent via-secondary-200 to-transparent" />
              </div>
            )}
          </section>
        );
      })}

      {/* ── CTA FINAL ────────────────────────────── */}
      <section className="bg-white">
        <div className="max-w-7xl mx-auto px-6 lg:px-12 py-20">
          <motion.div
            {...fadeUp()}
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
                <h2 className="text-3xl font-bold text-white font-display mb-4">
                  Prêt à vivre l'expérience ChapeChape ?
                </h2>
                <p className="text-white/60 font-body text-[15px] leading-relaxed">
                  Que vous soyez propriétaire ou locataire, nous avons la solution adaptée à vos besoins
                  sur le marché immobilier ivoirien.
                </p>
              </div>
              <div className="md:w-1/3 flex flex-col sm:flex-row md:flex-col lg:flex-row gap-3 justify-center md:justify-end">
                <Link
                  to="/contact"
                  className="inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-full bg-primary-500 text-secondary-900 font-bold font-body text-sm hover:bg-primary-400 transition-colors duration-200 whitespace-nowrap"
                >
                  Nous contacter
                </Link>
                <Link
                  to="/residences"
                  className="inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-full border border-white/20 text-white font-bold font-body text-sm hover:bg-white/10 transition-colors duration-200 whitespace-nowrap"
                >
                  Voir les résidences
                </Link>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

    </div>
  );
}
