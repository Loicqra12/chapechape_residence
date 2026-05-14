import { useEffect } from 'react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import SEOHead from '../components/seo/SEOHead';

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com';

const coreTeam = [
  {
    name: 'Adams Diaby',
    role: 'CEO & Co-fondateur',
    description: 'Fondateur de Onloutou, une plateforme de location d\'équipements, Adams est un visionnaire du numérique en Afrique de l\'Ouest. Il apporte son expertise en gestion de projets technologiques et sa connaissance approfondie du marché ivoirien.',
    image: '/assets/team/adams_diaby.jpg',
    linkedin: 'https://ci.linkedin.com/in/ousmane-adams-diaby-6b8a72156',
  },
  {
    name: 'Sidney Jordan',
    role: 'CTO & Co-fondateur',
    description: 'Fondateur de Soutrali Deals, une plateforme numérique ivoirienne qui valorise les produits, services et talents issus de l\'économie informelle et artisanale. Sidney est responsable de la stratégie technologique et du développement de la plateforme.',
    image: '/assets/team/sidney-jordan.jpg',
    linkedin: 'https://ci.linkedin.com/in/sidney-jordan-39587a283',
    github: 'loicqra12',
  },
];

const fadeUp = (delay = 0) => ({
  initial: { opacity: 0, y: 24 },
  whileInView: { opacity: 1, y: 0 },
  viewport: { once: true },
  transition: { duration: 0.6, delay, ease: 'easeOut' },
});

const Team = () => {
  useEffect(() => { window.scrollTo(0, 0); }, []);

  return (
    <div className="bg-white min-h-screen">
      <SEOHead
        title="Notre équipe"
        description="Découvrez l'équipe ChapeChape Residence : Adams Diaby et Sidney Jordan, fondateurs passionnés par la transformation digitale de l'immobilier en Côte d'Ivoire."
        url={`${siteUrl}/team`}
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
              Excellence & Expertise
            </span>
            <h1 className="text-3xl sm:text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              Les visages de{' '}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">
                l'innovation
              </span>
            </h1>
            <p className="text-lg text-white/60 max-w-2xl mx-auto font-body leading-relaxed">
              Découvrez les visionnaires qui font de ChapeChape Residence une référence dans la location de résidences meublées en Afrique de l'Ouest.
            </p>
          </motion.div>
        </div>
      </section>

      {/* ── SECTION 1 — CORE TEAM (style MStudio) ── */}
      <section className="max-w-7xl mx-auto px-6 lg:px-12 py-24">

        <motion.div {...fadeUp()} className="mb-16">
          <h2 className="text-3xl md:text-4xl font-bold text-secondary-900 font-display">
            Notre core team
          </h2>
          <div className="mt-4 h-px bg-gradient-to-r from-primary-500 to-transparent max-w-xs" />
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-10 lg:gap-16">
          {coreTeam.map((member, i) => (
            <motion.div key={member.name} {...fadeUp(i * 0.15)} className="group">

              {/* Photo */}
              <div className="relative overflow-hidden rounded-2xl aspect-[3/4] mb-6 bg-secondary-100">
                <img
                  src={member.image}
                  alt={member.name}
                  className="w-full h-full object-cover object-top group-hover:scale-105 transition-transform duration-500"
                />
                {/* Overlay liens sociaux au hover */}
                <div className="absolute bottom-0 left-0 right-0 p-5 translate-y-full group-hover:translate-y-0 transition-transform duration-300 flex gap-4 bg-secondary-900/70 backdrop-blur-sm">
                  {member.linkedin && (
                    <a
                      href={member.linkedin}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-white hover:text-primary-400 transition-colors"
                      aria-label="LinkedIn"
                    >
                      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" />
                      </svg>
                    </a>
                  )}
                  {member.github && (
                    <a
                      href={`https://github.com/${member.github}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-white hover:text-primary-400 transition-colors"
                      aria-label="GitHub"
                    >
                      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
                      </svg>
                    </a>
                  )}
                </div>
              </div>

              {/* Texte — ligne + nom + rôle + description */}
              <div className="w-8 h-0.5 bg-secondary-800 mb-4" />
              <h3 className="text-2xl font-bold text-secondary-900 font-display mb-1">
                {member.name}
              </h3>
              <p className="text-primary-600 font-semibold text-sm font-body mb-4">
                {member.role}
              </p>
              <p className="text-secondary-600 font-body text-sm leading-relaxed">
                {member.description}
              </p>
            </motion.div>
          ))}
        </div>
      </section>

      {/* ── SECTION 2 — NOTRE ÉQUIPE (style Veone) ── */}
      <section className="bg-secondary-50">
        <div className="max-w-7xl mx-auto px-6 lg:px-12 py-24">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">

            {/* Gauche — texte */}
            <motion.div {...fadeUp(0.1)}>
              <h2 className="text-3xl md:text-4xl font-bold text-secondary-900 font-display leading-tight mb-8">
                Notre équipe est là<br className="hidden sm:block" /> pour soutenir votre projet
              </h2>
              <div className="space-y-5 text-secondary-600 font-body text-[15px] leading-relaxed">
                <p>
                  ChapeChape Residence, c'est une startup ivoirienne fondée par deux entrepreneurs passionnés
                  par la transformation digitale du secteur immobilier en Afrique de l'Ouest.
                  Nous combinons expertise technologique et connaissance approfondie du marché local.
                </p>
                <p>
                  Avec une maîtrise des réalités du terrain — des quartiers de Cocody au Plateau,
                  de Marcory à Yopougon — nos équipes mettent tout en œuvre pour comprendre et répondre
                  aux besoins spécifiques de chaque propriétaire et de chaque locataire.
                </p>
                <p>
                  Nous nous concentrons sur les défis uniques du marché ivoirien et fournissons
                  des solutions adaptées — paiements mobile money, validation rapide, support 24h/24 —
                  pour vous aider à prospérer dans un environnement en constante évolution.
                </p>
                <p>
                  Chez ChapeChape, nous nous engageons à offrir non seulement notre expertise digitale,
                  mais aussi une touche humaine qui fait toute la différence.
                  Faites-nous confiance pour transformer vos défis immobiliers en opportunités.
                </p>
              </div>

              <div className="mt-10">
                <Link
                  to="/contact"
                  className="inline-flex items-center gap-3 px-7 py-3.5 rounded-full bg-secondary-900 text-white font-bold font-body text-sm hover:bg-secondary-800 transition-colors duration-200"
                >
                  Nous contacter
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M17 8l4 4m0 0l-4 4m4-4H3" />
                  </svg>
                </Link>
              </div>
            </motion.div>

            {/* Droite — image équipe */}
            <motion.div
              initial={{ opacity: 0, x: 30 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8, delay: 0.2 }}
              className="relative"
            >
              <div className="relative rounded-2xl overflow-hidden aspect-[4/3] bg-secondary-100">
                <img
                  src="/assets/team/teamchapechape.png"
                  alt="L'équipe ChapeChape"
                  className="w-full h-full object-cover object-center"
                />
                {/* Masque le panneau en haut : dégradé opaque → transparent */}
                <div className="absolute inset-x-0 top-0 h-[42%] bg-gradient-to-b from-secondary-900 via-secondary-900/80 to-transparent pointer-events-none z-10" />
                {/* Légère vignette sur les côtés */}
                <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/30 via-transparent to-transparent pointer-events-none z-10" />
              </div>
              {/* Badge décoratif */}
              <motion.div
                className="absolute -bottom-5 -left-5 bg-white rounded-2xl shadow-xl p-4 border border-secondary-100"
                initial={{ opacity: 0, scale: 0.8 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.5 }}
              >
                <p className="text-xs font-bold text-secondary-500 font-body uppercase tracking-widest mb-1">Fondée en</p>
                <p className="text-2xl font-bold text-secondary-900 font-display">2024</p>
                <p className="text-xs text-primary-600 font-semibold font-body">Abidjan, Côte d'Ivoire</p>
              </motion.div>
            </motion.div>

          </div>
        </div>
      </section>

      {/* ── CTA RECRUTEMENT ───────────────────────── */}
      <section className="max-w-7xl mx-auto px-6 lg:px-12 py-20">
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
                Rejoignez notre équipe
              </h2>
              <p className="text-white/60 font-body text-[15px] leading-relaxed">
                Vous êtes passionné par l'innovation et le secteur immobilier en Afrique ?
                Nous sommes toujours à la recherche de talents pour transformer l'expérience de location en Afrique de l'Ouest.
              </p>
            </div>
            <div className="md:w-1/3 flex justify-center md:justify-end">
              <Link
                to="/contact"
                className="inline-flex items-center gap-3 px-8 py-4 rounded-full bg-primary-500 text-secondary-900 font-bold font-body text-sm hover:bg-primary-400 transition-colors duration-200 whitespace-nowrap"
              >
                Postuler maintenant
                <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M17 8l4 4m0 0l-4 4m4-4H3" />
                </svg>
              </Link>
            </div>
          </div>
        </motion.div>
      </section>

    </div>
  );
};

export default Team;
