import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import { MapPinIcon, ClockIcon, HomeModernIcon, ChatBubbleLeftRightIcon, UserGroupIcon } from '@heroicons/react/24/outline'
import ContactComponent from '../components/home/Contact'
import SEOHead from '../components/seo/SEOHead'

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com'

const faqs = [
  {
    icon: <ClockIcon className="w-6 h-6" />,
    question: "Quels sont vos horaires d'ouverture ?",
    answer: "Nos bureaux sont ouverts du lundi au vendredi de 8h à 18h et le samedi de 9h à 13h. Notre service client en ligne est disponible 24h/24, 7j/7.",
  },
  {
    icon: <HomeModernIcon className="w-6 h-6" />,
    question: "Comment visiter un logement ?",
    answer: "Réservez une visite directement via notre application mobile ou en nous contactant par téléphone. Nous organiserons un rendez-vous à votre convenance.",
  },
  {
    icon: <ChatBubbleLeftRightIcon className="w-6 h-6" />,
    question: "Quel est le délai de réponse ?",
    answer: "Nous nous engageons à répondre à toutes les demandes dans un délai de 24h ouvrées. Pour les questions urgentes, contactez-nous par téléphone.",
  },
  {
    icon: <UserGroupIcon className="w-6 h-6" />,
    question: "Comment devenir partenaire ?",
    answer: "Contactez-nous à partners@chapechaperesidence.com ou via notre formulaire de contact. Notre équipe partenariats vous répondra sous 48h.",
  },
]

const engagements = [
  { label: "Réponse garantie", value: "< 24h" },
  { label: "Disponibilité", value: "7j/7" },
  { label: "Satisfaction client", value: "98%" },
]

const Contact = () => {
  return (
    <div className="bg-white">
      <SEOHead
        title="Contact"
        description="Contactez ChapeChape Residence : support, questions, réservations. Abidjan, Côte d'Ivoire."
        url={`${siteUrl}/contact`}
      />

      {/* ── Hero ── */}
      <section className="relative py-32 bg-secondary-900 overflow-hidden">
        <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-10 mix-blend-overlay" />
        <div className="absolute inset-0 bg-gradient-to-b from-secondary-900/50 via-secondary-900/80 to-white" />
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          {[...Array(6)].map((_, i) => (
            <motion.div key={i} className="absolute rounded-full bg-primary-400/20 blur-xl"
              style={{ width: 80 + i * 20 + 'px', height: 80 + i * 20 + 'px', left: (i * 17) % 100 + '%', top: (i * 13) % 100 + '%' }}
              animate={{ y: [0, -80, 0], opacity: [0, 0.4, 0] }}
              transition={{ duration: 12 + i * 2, repeat: Infinity, ease: "easeInOut", delay: i * 1.5 }}
            />
          ))}
        </div>
        <div className="container mx-auto px-4 max-w-6xl relative z-10 text-center">
          <motion.div initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.8 }}>
            <span className="inline-block py-1 px-3 rounded-full bg-white/10 backdrop-blur-md border border-white/20 text-primary-300 text-xs font-bold tracking-widest uppercase mb-6">
              Assistance & Support
            </span>
            <h1 className="text-3xl sm:text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              Contactez <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">Nous</span>
            </h1>
            <p className="text-xl text-secondary-200 mb-10 max-w-2xl mx-auto font-light leading-relaxed">
              Notre équipe est à votre disposition pour répondre à toutes vos questions et vous accompagner dans vos projets.
            </p>
          </motion.div>
        </div>
      </section>

      {/* ── Formulaire (overlap) ── */}
      <div className="-mt-20 relative z-20 container mx-auto px-4 max-w-7xl">
        <div className="bg-white rounded-3xl shadow-2xl overflow-hidden border border-secondary-100">
          <ContactComponent />
        </div>
      </div>

      {/* ── Section engagement — image + texte (style Webattou) ── */}
      <section className="mt-24 mb-0 overflow-hidden">
        <div className="grid grid-cols-1 lg:grid-cols-2 min-h-[520px]">

          {/* Panneau image sombre avec overlay + stats */}
          <motion.div
            initial={{ opacity: 0, x: -40 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
            className="relative overflow-hidden min-h-[400px] lg:min-h-[520px]"
          >
            <img
              src="/assets/images/contact.jpg"
              alt="Équipe ChapeChape"
              className="absolute inset-0 w-full h-full object-cover object-center"
            />
            {/* Overlay sombre dégradé */}
            <div className="absolute inset-0 bg-gradient-to-r from-secondary-900/90 via-secondary-900/70 to-secondary-900/40" />
            <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/60 to-transparent" />

            {/* Contenu sur l'image */}
            <div className="relative z-10 h-full flex flex-col justify-end p-10 lg:p-14">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.7, delay: 0.3 }}
              >
                <span className="inline-block px-3 py-1 rounded-full bg-primary-500/20 border border-primary-400/40 text-primary-300 text-xs font-bold tracking-widest uppercase mb-4">
                  Notre promesse
                </span>
                <h2 className="text-3xl md:text-4xl font-bold text-white font-display leading-tight mb-6">
                  Une équipe <br />
                  <span className="text-primary-400">passionnée</span> pour vous
                </h2>

                {/* Stats animées en bas de l'image */}
                <div className="flex flex-wrap gap-x-8 gap-y-3">
                  {engagements.map((e, i) => (
                    <motion.div
                      key={i}
                      initial={{ opacity: 0, y: 15 }}
                      whileInView={{ opacity: 1, y: 0 }}
                      viewport={{ once: true }}
                      transition={{ duration: 0.5, delay: 0.4 + i * 0.15 }}
                    >
                      <p className="text-2xl font-bold text-primary-400 font-display">{e.value}</p>
                      <p className="text-white/60 text-xs font-body tracking-wide">{e.label}</p>
                    </motion.div>
                  ))}
                </div>
              </motion.div>
            </div>

            {/* Bordure dorée droite */}
            <div className="absolute top-8 bottom-8 right-0 w-px bg-gradient-to-b from-transparent via-primary-500/50 to-transparent hidden lg:block" />
          </motion.div>

          {/* Panneau texte — approche orientée résultats */}
          <motion.div
            initial={{ opacity: 0, x: 40 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8, delay: 0.15 }}
            className="bg-secondary-50 flex flex-col justify-center px-10 lg:px-16 py-14"
          >
            <span className="inline-block px-3 py-1 rounded-full bg-primary-100 border border-primary-200 text-primary-700 text-xs font-bold tracking-widest uppercase mb-6 w-fit">
              Notre approche
            </span>
            <h2 className="text-3xl md:text-4xl font-bold text-secondary-900 font-display leading-tight mb-6">
              Une expérience orientée <span className="text-primary-600">résultats</span>
            </h2>
            <p className="text-secondary-600 font-body leading-relaxed mb-8">
              ChapeChape Residence combine expertise immobilière et technologie pour vous offrir
              un service rapide, transparent et personnalisé. Chaque demande est traitée avec soin
              par une équipe dédiée, avec des délais clairs et un suivi concret.
            </p>

            {/* Points clés */}
            <ul className="space-y-4">
              {[
                "Réponse personnalisée dans les 24h ouvrées",
                "Suivi de votre demande en temps réel",
                "Équipe bilingue français / anglais disponible",
                "Accompagnement de A à Z dans vos projets",
              ].map((point, i) => (
                <motion.li
                  key={i}
                  initial={{ opacity: 0, x: 15 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.4, delay: 0.2 + i * 0.1 }}
                  className="flex items-start gap-3"
                >
                  <span className="mt-0.5 shrink-0 w-5 h-5 rounded-full bg-primary-500 flex items-center justify-center">
                    <svg className="w-3 h-3 text-secondary-900" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                  </span>
                  <span className="text-secondary-700 font-body text-sm leading-relaxed">{point}</span>
                </motion.li>
              ))}
            </ul>
          </motion.div>
        </div>
      </section>

      {/* ── FAQ premium ── */}
      <section className="py-24 bg-white">
        <div className="container mx-auto px-4 max-w-5xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-14"
          >
            <span className="inline-block px-3 py-1 rounded-full bg-primary-50 border border-primary-200 text-primary-700 text-xs font-bold tracking-widest uppercase mb-4">
              FAQ
            </span>
            <h2 className="text-3xl md:text-4xl font-bold text-secondary-900 mb-4 font-display">Questions fréquentes</h2>
            <p className="text-secondary-500 text-base max-w-xl mx-auto font-body">
              Tout ce qu'il faut savoir avant de nous contacter.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            {faqs.map((faq, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: i * 0.1 }}
                whileHover={{ y: -3 }}
                className="group relative bg-white rounded-2xl p-7 border border-secondary-100 shadow-sm hover:shadow-lg hover:border-primary-200 transition-all duration-300 overflow-hidden"
              >
                {/* Glow hover */}
                <div className="absolute inset-0 bg-gradient-to-br from-primary-50/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none" />
                {/* Ligne top dorée au hover */}
                <div className="absolute top-0 left-6 right-6 h-px bg-gradient-to-r from-transparent via-primary-400 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />

                <div className="relative z-10 flex items-start gap-4">
                  <div className="shrink-0 w-11 h-11 rounded-xl bg-secondary-900 text-primary-400 flex items-center justify-center group-hover:bg-primary-500 group-hover:text-secondary-900 transition-all duration-300">
                    {faq.icon}
                  </div>
                  <div>
                    <h3 className="text-base font-bold text-secondary-900 mb-2 font-display group-hover:text-primary-700 transition-colors duration-300">{faq.question}</h3>
                    <p className="text-secondary-500 text-sm leading-relaxed font-body">{faq.answer}</p>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.4 }}
            className="text-center mt-10"
          >
            <Link to="/faq" className="inline-flex items-center gap-2 text-primary-600 hover:text-primary-700 font-bold transition-colors group font-body">
              Voir toutes les questions fréquentes
              <svg className="h-4 w-4 transform group-hover:translate-x-1 transition-transform" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M10.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L12.586 11H5a1 1 0 110-2h7.586l-2.293-2.293a1 1 0 010-1.414z" clipRule="evenodd" />
              </svg>
            </Link>
          </motion.div>
        </div>
      </section>

      {/* ── Carte Google Maps ── */}
      <section className="py-24 bg-secondary-50">
        <div className="container mx-auto px-4 max-w-6xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-14"
          >
            <span className="inline-block px-3 py-1 rounded-full bg-primary-50 border border-primary-200 text-primary-700 text-xs font-bold tracking-widest uppercase mb-4">
              Localisation
            </span>
            <h2 className="text-3xl md:text-4xl font-bold text-secondary-900 mb-4 font-display">Nous trouver</h2>
            <p className="text-secondary-500 max-w-xl mx-auto font-body">
              Nos bureaux sont situés à Abidjan dans un quartier facilement accessible.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="lg:col-span-2 rounded-2xl overflow-hidden shadow-xl h-[460px] border border-secondary-200"
            >
              <iframe
                src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3972.4736881794175!2d-3.9761723852929284!3d5.3481699371855435!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zNcKwMjAnNTMuNCJOIDPCsDU4JzMzLjEiVw!5e0!3m2!1sfr!2sci!4v1663342965642!5m2!1sfr!2sci"
                width="100%" height="100%"
                style={{ border: 0 }} allowFullScreen loading="lazy"
                referrerPolicy="no-referrer-when-downgrade"
                title="Bureaux ChapeChape Residence"
                className="grayscale hover:grayscale-0 transition-all duration-700"
              />
            </motion.div>

            <motion.div
              initial={{ opacity: 0, x: 20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.15 }}
              className="bg-secondary-900 rounded-2xl p-8 shadow-xl flex flex-col justify-between text-white relative overflow-hidden"
            >
              {/* Glow doré */}
              <motion.div
                className="absolute bottom-0 right-0 w-40 h-40 rounded-full bg-primary-500/10 blur-3xl pointer-events-none"
                animate={{ scale: [1, 1.2, 1], opacity: [0.4, 0.7, 0.4] }}
                transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
              />
              <MapPinIcon className="absolute top-6 right-6 w-16 h-16 opacity-5" />

              <div className="relative z-10">
                <div className="w-12 h-12 rounded-xl bg-primary-500/20 border border-primary-500/30 flex items-center justify-center text-primary-400 mb-6">
                  <MapPinIcon className="h-6 w-6" />
                </div>
                <h3 className="text-xl font-bold mb-4 font-display">Notre adresse</h3>
                <p className="text-secondary-300 leading-relaxed text-sm mb-6">
                  Angré, Rond-point CNPS<br />
                  En face du restaurant La Shish<br />
                  92HH+CVM Riviera, Abidjan<br />
                  Côte d'Ivoire
                </p>
              </div>

              <div className="relative z-10 flex flex-col gap-3">
                {[
                  { label: "Ouvrir Google Maps", href: "https://maps.app.goo.gl/1iBVEeDp6Q58RSB69" },
                  { label: "Ouvrir Waze", href: "https://waze.com/ul?ll=5.348169,3.976172&navigate=yes" },
                ].map((btn, i) => (
                  <a key={i} href={btn.href} target="_blank" rel="noopener noreferrer"
                    className="inline-flex items-center justify-between px-5 py-3 rounded-xl bg-white/8 hover:bg-white/15 border border-white/10 transition-all duration-200 group text-sm font-semibold font-body"
                  >
                    {btn.label}
                    <svg className="h-4 w-4 transform group-hover:translate-x-1 transition-transform" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                      <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z" />
                      <path d="M5 5a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2v-3a1 1 0 10-2 0v3H5V7h3a1 1 0 000-2H5z" />
                    </svg>
                  </a>
                ))}
              </div>
            </motion.div>
          </div>
        </div>
      </section>
    </div>
  )
}

export default Contact