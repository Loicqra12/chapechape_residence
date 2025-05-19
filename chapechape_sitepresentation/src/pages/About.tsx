import { motion } from 'framer-motion'
import AboutSection from '../components/home/AboutSection'
import Coverage from '../components/home/Coverage'
import Stats from '../components/home/Stats'
import Contact from '../components/home/Contact'
import Partners from '../components/home/Partners'

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
    <div className="bg-secondary-50">
      {/* Hero section */}
      <div className="relative isolate overflow-hidden bg-gradient-to-br from-secondary-900 via-secondary-800 to-secondary-900 py-24 sm:py-32">
        {/* Grille d'arrière-plan animée */}
        <motion.div 
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.3 }}
          transition={{ duration: 1.5 }}
          className="absolute inset-0 bg-grid-white/5 bg-[linear-gradient(to_right,#161616_1px,transparent_1px),linear-gradient(to_bottom,#161616_1px,transparent_1px)] bg-[size:4rem_4rem] z-0"
        />
        
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl lg:mx-0">
            <motion.h1 
              variants={textVariants}
              initial="hidden"
              animate="visible"
              className="text-4xl font-bold tracking-tight text-primary-300 sm:text-6xl font-display"
            >
              À Propos de ChapeChape Residence
            </motion.h1>
            <motion.p 
              variants={textVariants}
              initial="hidden"
              animate="visible"
              transition={{ delay: 0.2 }}
              className="mt-6 text-lg leading-8 text-primary-100"
            >
              Découvrez notre histoire, notre mission et ce qui fait de ChapeChape Residence le partenaire idéal pour votre expérience résidentielle en Afrique de l'Ouest.
            </motion.p>
          </div>
        </div>
      </div>

      {/* Section principale About */}
      <AboutSection />

      {/* Notre Vision */}
      <div className="py-24 sm:py-32 bg-white">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl lg:text-center">
            <motion.h2 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="text-base font-semibold leading-7 text-primary-500"
            >
              Notre Vision
            </motion.h2>
            <motion.p 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.1 }}
              className="mt-2 text-3xl font-bold tracking-tight text-secondary-900 sm:text-4xl font-display"
            >
              Transformer l'expérience résidentielle en Afrique de l'Ouest
            </motion.p>
            <motion.p 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="mt-6 text-lg leading-8 text-secondary-600"
            >
              Chez ChapeChape Residence, nous aspirons à créer un écosystème où la recherche et la gestion de résidences sont transparentes, efficaces et agréables pour tous les acteurs impliqués.
            </motion.p>
          </div>

          <div className="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-4xl">
            <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-10 lg:max-w-none lg:grid-cols-2 lg:gap-y-16">
              {[
                {
                  name: 'Accessibilité',
                  description: 'Rendre les logements de qualité accessibles à tous les budgets et dans toutes les régions.',
                  icon: (
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 5.25a3 3 0 013 3m3 0a6 6 0 01-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1 .43-1.563A6 6 0 1121.75 8.25z" />
                    </svg>
                  ),
                },
                {
                  name: 'Innovation',
                  description: 'Utiliser la technologie pour simplifier et améliorer chaque aspect de l\'expérience résidentielle.',
                  icon: (
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
                    </svg>
                  ),
                },
                {
                  name: 'Communauté',
                  description: 'Favoriser des communautés résidentielles dynamiques et solidaires où les habitants peuvent s\'épanouir.',
                  icon: (
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M18 18.72a9.094 9.094 0 003.741-.479 3 3 0 00-4.682-2.72m.94 3.198l.001.031c0 .225-.012.447-.037.666A11.944 11.944 0 0112 21c-2.17 0-4.207-.576-5.963-1.584A6.062 6.062 0 016 18.719m12 0a5.971 5.971 0 00-.941-3.197m0 0A5.995 5.995 0 0012 12.75a5.995 5.995 0 00-5.058 2.772m0 0a3 3 0 00-4.681 2.72 8.986 8.986 0 003.74.477m.94-3.197a5.971 5.971 0 00-.94 3.197M15 6.75a3 3 0 11-6 0 3 3 0 016 0zm6 3a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0zm-13.5 0a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z" />
                    </svg>
                  ),
                },
                {
                  name: 'Durabilité',
                  description: 'Promouvoir des pratiques résidentielles écologiques et durables pour un avenir meilleur.',
                  icon: (
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M12.75 3.03v.568c0 .334.148.65.405.864l1.068.89c.442.369.535 1.01.216 1.49l-.51.766a2.25 2.25 0 01-1.161.886l-.143.048a1.107 1.107 0 00-.57 1.664c.369.555.169 1.307-.427 1.605L9 13.125l.423 1.059a.956.956 0 01-1.652.928l-.679-.906a1.125 1.125 0 00-1.906.172L4.5 15.75l-.612.153M12.75 3.031a9 9 0 00-8.862 12.872M12.75 3.031a9 9 0 016.69 14.036m0 0l-.177-.529A2.25 2.25 0 0017.128 15H16.5l-.324-.324a1.453 1.453 0 00-2.328.377l-.036.073a1.586 1.586 0 01-.982.816l-.99.282c-.55.157-.894.702-.8 1.267l.073.438c.08.474.49.821.97.821.846 0 1.598.542 1.865 1.345l.215.643m5.276-3.67a9.012 9.012 0 01-5.276 3.67m0 0a9 9 0 01-10.275-4.835M15.75 9c0 .896-.393 1.7-1.016 2.25" />
                    </svg>
                  ),
                },
              ].map((item) => (
                <motion.div 
                  key={item.name}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5 }}
                  className="bg-white p-6 rounded-xl shadow-sm border border-secondary-100"
                >
                  <dt className="flex items-center gap-x-3 text-lg font-semibold leading-7 text-secondary-900">
                    <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary-300">
                      {item.icon}
                    </div>
                    {item.name}
                  </dt>
                  <dd className="mt-4 text-base leading-7 text-secondary-600">{item.description}</dd>
                </motion.div>
              ))}
            </dl>
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