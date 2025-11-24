import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import AppScreenshots from '../components/home/AppScreenshots'
import Contact from '../components/home/Contact'

export default function Apps() {
  // Variantes d'animation pour les titres et textes
  const textVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.6 }
    }
  }

  // Données des applications
  const appFeatures = {
    client: [
      {
        title: "Recherche avancée",
        description: "Filtrez les résidences selon vos critères spécifiques: localisation, prix, commodités, etc.",
        icon: (
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
            <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
        )
      },
      {
        title: "Réservation instantanée",
        description: "Réservez votre résidence en quelques clics et recevez une confirmation immédiate.",
        icon: (
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
            <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5m-9-6h.008v.008H12v-.008zM12 15h.008v.008H12V15zm0 2.25h.008v.008H12v-.008zM9.75 15h.008v.008H9.75V15zm0 2.25h.008v.008H9.75v-.008zM7.5 15h.008v.008H7.5V15zm0 2.25h.008v.008H7.5v-.008zm6.75-4.5h.008v.008h-.008v-.008zm0 2.25h.008v.008h-.008V15zm0 2.25h.008v.008h-.008v-.008zm2.25-4.5h.008v.008H16.5v-.008zm0 2.25h.008v.008H16.5V15z" />
          </svg>
        )
      },
      {
        title: "Paiement sécurisé",
        description: "Utilisez plusieurs méthodes de paiement sécurisées, incluant mobile money et cartes bancaires.",
        icon: (
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
            <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5z" />
          </svg>
        )
      },
      {
        title: "Communication directe",
        description: "Discutez avec les propriétaires via notre messagerie intégrée pour toute question ou demande.",
        icon: (
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
            <path strokeLinecap="round" strokeLinejoin="round" d="M8.625 12a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H8.25m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H12m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0h-.375M21 12c0 4.556-4.03 8.25-9 8.25a9.764 9.764 0 01-2.555-.337A5.972 5.972 0 015.41 20.97a5.969 5.969 0 01-.474-.065 4.48 4.48 0 00.978-2.025c.09-.457-.133-.901-.467-1.226C3.93 16.178 3 14.189 3 12c0-4.556 4.03-8.25 9-8.25s9 3.694 9 8.25z" />
          </svg>
        )
      }
    ],
    partner: [
      {
        title: "Gestion des propriétés",
        description: "Gérez facilement toutes vos résidences, leurs disponibilités et leurs tarifs depuis une seule interface.",
        icon: (
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
            <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008zm0 3h.008v.008h-.008v-.008z" />
          </svg>
        )
      },
      {
        title: "Suivi des réservations",
        description: "Visualisez et gérez toutes vos réservations en temps réel avec notifications instantanées.",
        icon: (
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z" />
          </svg>
        )
      },
      {
        title: "Analyse de performance",
        description: "Accédez à des statistiques détaillées sur vos propriétés: taux d'occupation, revenus, avis clients, etc.",
        icon: (
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
            <path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z" />
          </svg>
        )
      },
      {
        title: "Support prioritaire",
        description: "Bénéficiez d'un support dédié pour vous accompagner dans la gestion de vos résidences.",
        icon: (
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-6 h-6">
            <path strokeLinecap="round" strokeLinejoin="round" d="M9.879 7.519c1.171-1.025 3.071-1.025 4.242 0 1.172 1.025 1.172 2.687 0 3.712-.203.179-.43.326-.67.442-.745.361-1.45.999-1.45 1.827v.75M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9 5.25h.008v.008H12v-.008z" />
          </svg>
        )
      }
    ]
  };

  return (
    <div className="bg-secondary-50">
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
              Innovation & Mobilité
            </span>
            <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              Nos <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">Applications</span>
            </h1>
            <p className="text-xl text-gray-300 mb-10 max-w-2xl mx-auto font-light leading-relaxed">
              Découvrez comment nos applications mobiles facilitent la gestion et la location de résidences en Afrique de l'Ouest, où que vous soyez.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Applications Screenshots */}
      <AppScreenshots />

      {/* Application Client */}
      <div className="py-24 sm:py-32 bg-white">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl lg:text-center">
            <motion.h2
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="text-base font-semibold leading-7 text-primary-500 uppercase tracking-widest"
            >
              Pour les Locataires
            </motion.h2>
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.1 }}
              className="mt-2 text-3xl font-bold tracking-tight text-secondary-900 sm:text-4xl font-display"
            >
              Application Client
            </motion.p>
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="mt-6 text-lg leading-8 text-secondary-600"
            >
              Trouvez et réservez facilement la résidence idéale pour votre séjour, que ce soit pour quelques jours ou plusieurs mois.
            </motion.p>
          </div>

          <div className="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none">
            <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-10 lg:max-w-none lg:grid-cols-2 lg:gap-y-16">
              {appFeatures.client.map((feature, index) => (
                <motion.div
                  key={feature.title}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: index * 0.1 }}
                  className="bg-white p-8 rounded-2xl shadow-lg border border-gray-100 hover:border-primary-200 hover:shadow-xl transition-all duration-300 group"
                >
                  <dt className="flex items-center gap-x-4 text-lg font-bold leading-7 text-secondary-900">
                    <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary-100 text-primary-600 group-hover:bg-primary-500 group-hover:text-white transition-colors duration-300">
                      {feature.icon}
                    </div>
                    {feature.title}
                  </dt>
                  <dd className="mt-4 text-base leading-7 text-secondary-600 pl-16">{feature.description}</dd>
                </motion.div>
              ))}
            </dl>
          </div>

          <div className="mt-16 flex justify-center">
            <div className="flex flex-wrap gap-4 justify-center">
              <a
                href="#"
                className="inline-flex items-center px-6 py-3 rounded-xl text-sm font-bold shadow-lg bg-secondary-900 text-white hover:bg-secondary-800 transition-all transform hover:-translate-y-1"
              >
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 mr-3" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M17.5,1.5A1.5,1.5,0,0,0,16,0H8A1.5,1.5,0,0,0,6.5,1.5v21A1.5,1.5,0,0,0,8,24h8a1.5,1.5,0,0,0,1.5-1.5ZM12,23a1.5,1.5,0,1,1,1.5-1.5A1.5,1.5,0,0,1,12,23Zm4.5-4H7.5V5h9Z" />
                </svg>
                <div className="flex flex-col items-start">
                  <span className="text-[10px] uppercase font-normal opacity-80">Disponible sur</span>
                  <span className="text-base">Google Play</span>
                </div>
              </a>
              <a
                href="#"
                className="inline-flex items-center px-6 py-3 rounded-xl text-sm font-bold shadow-lg bg-secondary-900 text-white hover:bg-secondary-800 transition-all transform hover:-translate-y-1"
              >
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 mr-3" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M22,17.28a4.19,4.19,0,0,1-2-3.51A4.06,4.06,0,0,1,22,10.24v-.8a4.15,4.15,0,0,0-2,.35A4.53,4.53,0,0,0,17.5,6,4.39,4.39,0,0,0,14,7.47a7.34,7.34,0,0,0-2,.28,7.26,7.26,0,0,0-2-.28A4.38,4.38,0,0,0,6.5,6,4.51,4.51,0,0,0,4,9.78a4.31,4.31,0,0,0-2-.34v.8a4,4,0,0,1,2,3.53,4.13,4.13,0,0,1-2,3.51v.8a4.29,4.29,0,0,0,2-.34,4.52,4.52,0,0,0,2.5,3.77A4.38,4.38,0,0,0,10,18.53a7.14,7.14,0,0,0,2-.28,7.15,7.15,0,0,0,2,.28,4.39,4.39,0,0,0,3.5-1.47,4.53,4.53,0,0,0,2.5-3.77,4.22,4.22,0,0,0,2,.34Z" />
                </svg>
                <div className="flex flex-col items-start">
                  <span className="text-[10px] uppercase font-normal opacity-80">Télécharger sur</span>
                  <span className="text-base">App Store</span>
                </div>
              </a>
            </div>
          </div>
        </div>
      </div>

      {/* Application Partenaire */}
      <div className="py-24 sm:py-32 bg-secondary-50">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl lg:text-center">
            <motion.h2
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="text-base font-semibold leading-7 text-secondary-600 uppercase tracking-widest"
            >
              Pour les Propriétaires
            </motion.h2>
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.1 }}
              className="mt-2 text-3xl font-bold tracking-tight text-secondary-900 sm:text-4xl font-display"
            >
              Application Partenaire
            </motion.p>
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="mt-6 text-lg leading-8 text-secondary-600"
            >
              Gérez efficacement vos propriétés et maximisez vos revenus grâce à notre solution complète pour les propriétaires.
            </motion.p>
          </div>

          <div className="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none">
            <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-10 lg:max-w-none lg:grid-cols-2 lg:gap-y-16">
              {appFeatures.partner.map((feature, index) => (
                <motion.div
                  key={feature.title}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: index * 0.1 }}
                  className="bg-white p-8 rounded-2xl shadow-lg border border-secondary-100 hover:border-secondary-300 hover:shadow-xl transition-all duration-300 group"
                >
                  <dt className="flex items-center gap-x-4 text-lg font-bold leading-7 text-secondary-900">
                    <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-secondary-800 text-white group-hover:bg-secondary-900 transition-colors duration-300">
                      {feature.icon}
                    </div>
                    {feature.title}
                  </dt>
                  <dd className="mt-4 text-base leading-7 text-secondary-600 pl-16">{feature.description}</dd>
                </motion.div>
              ))}
            </dl>
          </div>

          <div className="mt-16 flex justify-center">
            <div className="flex flex-wrap gap-4 justify-center">
              <a
                href="#"
                className="inline-flex items-center px-6 py-3 rounded-xl text-sm font-bold shadow-lg bg-secondary-800 text-white hover:bg-secondary-900 transition-all transform hover:-translate-y-1"
              >
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 mr-3" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M17.5,1.5A1.5,1.5,0,0,0,16,0H8A1.5,1.5,0,0,0,6.5,1.5v21A1.5,1.5,0,0,0,8,24h8a1.5,1.5,0,0,0,1.5-1.5ZM12,23a1.5,1.5,0,1,1,1.5-1.5A1.5,1.5,0,0,1,12,23Zm4.5-4H7.5V5h9Z" />
                </svg>
                <div className="flex flex-col items-start">
                  <span className="text-[10px] uppercase font-normal opacity-80">Disponible sur</span>
                  <span className="text-base">Google Play</span>
                </div>
              </a>
              <a
                href="#"
                className="inline-flex items-center px-6 py-3 rounded-xl text-sm font-bold shadow-lg bg-secondary-800 text-white hover:bg-secondary-900 transition-all transform hover:-translate-y-1"
              >
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 mr-3" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M22,17.28a4.19,4.19,0,0,1-2-3.51A4.06,4.06,0,0,1,22,10.24v-.8a4.15,4.15,0,0,0-2,.35A4.53,4.53,0,0,0,17.5,6,4.39,4.39,0,0,0,14,7.47a7.34,7.34,0,0,0-2,.28,7.26,7.26,0,0,0-2-.28A4.38,4.38,0,0,0,6.5,6,4.51,4.51,0,0,0,4,9.78a4.31,4.31,0,0,0-2-.34v.8a4,4,0,0,1,2,3.53,4.13,4.13,0,0,1-2,3.51v.8a4.29,4.29,0,0,0,2-.34,4.52,4.52,0,0,0,2.5,3.77A4.38,4.38,0,0,0,10,18.53a7.14,7.14,0,0,0,2-.28,7.15,7.15,0,0,0,2,.28,4.39,4.39,0,0,0,3.5-1.47,4.53,4.53,0,0,0,2.5-3.77,4.22,4.22,0,0,0,2,.34Z" />
                </svg>
                <div className="flex flex-col items-start">
                  <span className="text-[10px] uppercase font-normal opacity-80">Télécharger sur</span>
                  <span className="text-base">App Store</span>
                </div>
              </a>
            </div>
          </div>
        </div>
      </div>

      {/* CTA Section */}
      <div className="py-24 sm:py-32 bg-white">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: 50 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7 }}
            viewport={{ once: true }}
            className="relative isolate overflow-hidden bg-gradient-to-br from-primary-50 to-white px-6 py-24 text-center shadow-2xl rounded-3xl border border-primary-100 sm:px-16"
          >
            <h2 className="text-3xl font-bold tracking-tight text-secondary-900 sm:text-4xl font-display">
              Commencez l'expérience dès aujourd'hui
            </h2>
            <p className="mt-6 text-lg leading-8 text-secondary-600 max-w-2xl mx-auto">
              Rejoignez les milliers d'utilisateurs qui simplifient déjà leur expérience de logement avec ChapeChape Residence.
            </p>
            <div className="mt-10 flex items-center justify-center gap-x-6">
              <Link
                to="/"
                className="rounded-full bg-primary-500 px-8 py-4 text-sm font-bold text-white shadow-lg hover:bg-primary-600 hover:shadow-primary-500/30 transition-all duration-300 transform hover:-translate-y-1"
              >
                Découvrir nos résidences
              </Link>
              <Link
                to="/contact"
                className="text-sm font-bold leading-6 text-secondary-900 hover:text-primary-600 transition-colors"
              >
                Nous contacter <span aria-hidden="true">→</span>
              </Link>
            </div>
          </motion.div>
        </div>
      </div>

      {/* Contact Section */}
      <Contact />
    </div>
  )
}