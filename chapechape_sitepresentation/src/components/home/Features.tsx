import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'

const features = [
  {
    name: 'Application Mobile',
    description: 'Gérez vos locations, réservations et paiements depuis votre smartphone avec notre application intuitive.',
    icon: 'mobile',
    href: '/apps'
  },
  {
    name: 'Gestion Immobilière',
    description: 'Une suite complète d\'outils pour les propriétaires : suivi des revenus, taux d\'occupation et maintenance.',
    icon: 'building',
    href: '/residences'
  },
  {
    name: 'Support Premium',
    description: 'Une équipe dédiée disponible 7j/7 pour accompagner propriétaires et locataires dans leurs démarches.',
    icon: 'users',
    href: '/contact'
  },
]

const Features = () => {
  return (
    <section className="relative py-24 overflow-hidden bg-secondary-50/50">
      {/* Background Elements */}
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(212,175,55,0.05),transparent_40%)]" />
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_bottom_left,rgba(212,175,55,0.05),transparent_40%)]" />

      <div className="mx-auto max-w-6xl px-6 lg:px-8 relative z-10">
        <div className="mx-auto max-w-2xl lg:text-center mb-16">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            viewport={{ once: true }}
            className="text-base font-semibold leading-7 text-primary-600 uppercase tracking-wider"
          >
            Tout ce dont vous avez besoin
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.1 }}
            viewport={{ once: true }}
            className="mt-2 text-3xl font-bold tracking-tight text-secondary-900 sm:text-4xl font-display"
          >
            Une expérience <span className="text-primary-600">Premium</span> complète
          </motion.p>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            viewport={{ once: true }}
            className="mt-6 text-lg leading-relaxed text-secondary-600"
          >
            Découvrez nos solutions innovantes conçues pour simplifier et sublimer la gestion de vos résidences.
          </motion.p>
        </div>

        <div className="mx-auto max-w-2xl lg:max-w-none">
          <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-16 lg:max-w-none lg:grid-cols-3">
            {features.map((feature, index) => (
              <motion.div
                key={feature.name}
                initial={{ opacity: 0, y: 50 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                viewport={{ once: true }}
                whileHover={{ y: -10 }}
                className="group relative flex flex-col p-8 bg-white rounded-2xl shadow-soft-xl hover:shadow-gold transition-all duration-300 border border-secondary-100 hover:border-primary-200 overflow-hidden"
              >
                {/* Hover Gradient Background */}
                <div className="absolute inset-0 bg-gradient-to-br from-primary-50/0 to-primary-50/0 group-hover:from-primary-50/30 group-hover:to-transparent transition-all duration-500" />

                <dt className="flex items-center gap-x-4 text-xl font-bold leading-7 text-secondary-900 z-10">
                  <div className="flex h-14 w-14 items-center justify-center rounded-xl bg-primary-50 text-primary-600 group-hover:bg-primary-600 group-hover:text-white transition-colors duration-300 shadow-sm group-hover:shadow-md">
                    {feature.icon === 'mobile' && (
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-7 h-7">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 1.5H8.25A2.25 2.25 0 006 3.75v16.5a2.25 2.25 0 002.25 2.25h7.5A2.25 2.25 0 0018 20.25V3.75a2.25 2.25 0 00-2.25-2.25H13.5m-3 0V3h3V1.5m-3 0h3m-3 18.75h3" />
                      </svg>
                    )}
                    {feature.icon === 'building' && (
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-7 h-7">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008z" />
                      </svg>
                    )}
                    {feature.icon === 'users' && (
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-7 h-7">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
                      </svg>
                    )}
                  </div>
                  {feature.name}
                </dt>
                <dd className="mt-6 flex flex-auto flex-col text-base leading-7 text-secondary-600 z-10">
                  <p className="flex-auto">{feature.description}</p>
                  <p className="mt-8">
                    <Link to={feature.href} className="text-sm font-semibold leading-6 text-primary-600 hover:text-primary-700 group-hover:translate-x-2 transition-transform duration-300 inline-flex items-center">
                      En savoir plus
                      <svg className="w-4 h-4 ml-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                      </svg>
                    </Link>
                  </p>
                </dd>
              </motion.div>
            ))}
          </dl>
        </div>
      </div>
    </section>
  )
}

export default Features
