import { motion } from 'framer-motion'
import VisionSection from '../components/about/VisionSection'
import Coverage from '../components/home/Coverage'
import Stats from '../components/home/Stats'
import Contact from '../components/home/Contact'
import Partners from '../components/home/Partners'
import SEOHead from '../components/seo/SEOHead'

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com'

export default function About() {
  // Variantes d'animation pour les titres et textes
  const textVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.6 }
    }
  }

  return (
    <div className="bg-secondary-50 dark:bg-secondary-900">
      <SEOHead
        title="À propos"
        description="ChapeChape Residence : location de résidences de standing en Côte d'Ivoire. Découvrez notre histoire, nos valeurs et notre engagement pour votre confort."
        url={`${siteUrl}/about`}
      />
      {/* Hero Section Harmonisé */}
      <section className="relative py-32 bg-secondary-900 overflow-hidden">
        <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-10 mix-blend-overlay" />
        <div className="absolute inset-0 bg-gradient-to-b from-secondary-900/50 via-secondary-900/80 to-white" />

        {/* Golden particles */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
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
                ease: "easeInOut",
              }}
            />
          ))}
        </div>

        <div className="container mx-auto px-4 max-w-6xl relative z-10 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <span className="inline-block py-1 px-3 rounded-full bg-white/10 backdrop-blur-md border border-white/20 text-primary-300 text-xs font-bold tracking-widest uppercase mb-6">
              Notre Histoire
            </span>
            <h1 className="text-3xl sm:text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              À Propos de <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">ChapeChape</span>
            </h1>
            <p className="text-xl text-secondary-200 mb-10 max-w-2xl mx-auto font-light leading-relaxed">
              Découvrez notre histoire, notre mission et ce qui fait de ChapeChape Residence le partenaire idéal pour votre expérience résidentielle en Afrique de l'Ouest.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Section Vision, Ce que nous faisons & Catégories */}
      <VisionSection />

      {/* Qui sommes-nous ? - Section Premium */}
      <div className="relative py-24 sm:py-32 bg-white dark:bg-secondary-900 overflow-hidden">
        {/* Background Elements */}
        <div className="absolute inset-0">
          <motion.div
            className="absolute top-32 right-20 w-64 h-64 bg-gradient-to-br from-primary-200/15 to-primary-300/15 rounded-full blur-2xl"
            animate={{
              scale: [1, 1.3, 1],
              x: [0, 30, 0],
              opacity: [0.3, 0.6, 0.3]
            }}
            transition={{ duration: 15, repeat: Infinity, ease: "easeInOut" }}
          />
          <motion.div
            className="absolute bottom-32 left-20 w-80 h-80 bg-gradient-to-br from-secondary-200/10 to-secondary-300/10 rounded-full blur-3xl"
            animate={{
              scale: [1.2, 1, 1.2],
              x: [0, -20, 0],
              opacity: [0.2, 0.5, 0.2]
            }}
            transition={{ duration: 18, repeat: Infinity, ease: "easeInOut" }}
          />
        </div>

        <div className="relative mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-3xl text-center mb-20">
            {/* Badge Premium */}
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, type: "spring", stiffness: 100 }}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-gradient-to-r from-secondary-100 to-secondary-200 dark:from-secondary-800/50 dark:to-secondary-700/50 border border-secondary-200 dark:border-secondary-600 mb-8"
            >
              <motion.div
                className="w-2 h-2 bg-secondary-500 rounded-full"
                animate={{ scale: [1, 1.2, 1] }}
                transition={{ duration: 2, repeat: Infinity }}
              />
              <span className="text-sm font-semibold text-secondary-600 dark:text-secondary-300">Qui sommes-nous ?</span>
            </motion.div>

            <motion.h2
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8, type: "spring", stiffness: 100 }}
              className="text-4xl font-bold tracking-tight text-secondary-900 dark:text-white sm:text-5xl lg:text-6xl font-display"
            >
              Les visionnaires derrière ChapeChape
            </motion.h2>
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.3 }}
              className="mt-6 text-xl leading-8 text-secondary-600 dark:text-secondary-300 max-w-2xl mx-auto"
            >
              ChapeChape Residence est le fruit de la collaboration entre deux entrepreneurs passionnés par la transformation digitale du secteur immobilier en Afrique.
            </motion.p>
          </div>

          {/* Profils des fondateurs */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 max-w-6xl mx-auto">
            {[
              {
                name: 'Adams Diaby',
                role: 'CEO & Co-fondateur',
                photo: '/assets/team/adams_diaby.jpg',
                description: 'Fondateur de Onloutou, une plateforme de location d\'équipements. Adams est un visionnaire du numérique en Afrique de l\'Ouest. Il apporte son expertise en gestion de projets technologiques et sa connaissance approfondie du marché ivoirien.',
              },
              {
                name: 'Sidney Jordan',
                role: 'CTO & Co-fondateur',
                photo: '/assets/team/sidney-jordan.jpg',
                description: 'Fondateur de Soutrali Deals, une plateforme numérique ivoirienne qui valorise les produits, services et talents issus de l\'économie informelle et artisanale. Sidney est responsable de la stratégie technologique et du développement de la plateforme.',
              },
            ].map((founder, index) => (
              <motion.div
                key={founder.name}
                initial={{ opacity: 0, y: 40 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.7, delay: index * 0.15 }}
                className="group relative bg-white dark:bg-secondary-800 p-10 rounded-3xl shadow-xl hover:shadow-2xl transition-all duration-500 border border-secondary-100 dark:border-secondary-700 overflow-hidden"
              >
                <div className="relative">
                  {/* Photo */}
                  <div className="flex items-center justify-center mb-8">
                    <div className="relative w-28 h-28 rounded-full overflow-hidden ring-4 ring-primary-100 shadow-xl group-hover:ring-primary-300 transition-all duration-300">
                      <img
                        src={founder.photo}
                        alt={founder.name}
                        className="w-full h-full object-cover object-top group-hover:scale-105 transition-transform duration-500"
                      />
                    </div>
                  </div>

                  {/* Nom et rôle */}
                  <div className="text-center mb-6">
                    <h3 className="text-2xl font-bold text-secondary-900 dark:text-white mb-2 font-display">
                      {founder.name}
                    </h3>
                    <p className="text-base font-semibold text-primary-600 font-body">
                      {founder.role}
                    </p>
                  </div>

                  {/* Description */}
                  <p className="text-secondary-600 dark:text-secondary-300 leading-relaxed text-center font-body text-sm">
                    {founder.description}
                  </p>

                  {/* Accent doré */}
                  <motion.div
                    className="mt-8 h-0.5 bg-gradient-to-r from-primary-400 to-primary-600 rounded-full mx-auto"
                    initial={{ width: 0 }}
                    whileInView={{ width: '80%' }}
                    viewport={{ once: true }}
                    transition={{ duration: 1, delay: index * 0.2 + 0.6 }}
                  />
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>

      {/* Coverage Section */}
      <Coverage />

      {/* Stats Section */}
      <Stats />

      {/* Partners Section */}
      <Partners />

      {/* Contact Section */}
      <Contact />
    </div>
  )
}