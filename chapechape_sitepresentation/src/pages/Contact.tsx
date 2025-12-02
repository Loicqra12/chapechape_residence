import { motion } from 'framer-motion'
import { MapPinIcon } from '@heroicons/react/24/outline'
import ContactComponent from '../components/home/Contact'

const Contact = () => {
  return (
    <div className="bg-white">
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
              Assistance & Support
            </span>
            <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              Contactez <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">Nous</span>
            </h1>
            <p className="text-xl text-gray-300 mb-10 max-w-2xl mx-auto font-light leading-relaxed">
              Notre équipe est à votre disposition pour répondre à toutes vos questions et vous accompagner dans vos projets.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Composant de contact existant - Ajustement marge négative pour chevauchement élégant */}
      <div className="-mt-20 relative z-20 container mx-auto px-4 max-w-7xl">
        <div className="bg-white rounded-3xl shadow-2xl overflow-hidden border border-gray-100">
          <ContactComponent />
        </div>
      </div>

      {/* Section FAQ rapide */}
      <section className="bg-secondary-50 py-24 mt-12">
        <div className="container mx-auto px-4 max-w-6xl">
          <div className="max-w-3xl mx-auto">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="text-center mb-16"
            >
              <h2 className="text-3xl font-bold text-secondary-900 mb-4 font-display">Questions fréquentes</h2>
              <p className="text-secondary-600 text-lg">
                Voici quelques réponses aux questions les plus courantes. Si vous ne trouvez pas l'information que vous cherchez, n'hésitez pas à nous contacter directement.
              </p>
            </motion.div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.1 }}
                className="bg-white p-8 rounded-2xl shadow-lg border border-gray-100 hover:shadow-xl transition-shadow"
              >
                <h3 className="text-lg font-bold text-secondary-900 mb-3">Quels sont vos horaires d'ouverture ?</h3>
                <p className="text-secondary-600 leading-relaxed">
                  Nos bureaux sont ouverts du lundi au vendredi de 8h à 18h et le samedi de
                  9h à 13h. Notre service client en ligne est disponible 24h/24, 7j/7.
                </p>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.2 }}
                className="bg-white p-8 rounded-2xl shadow-lg border border-gray-100 hover:shadow-xl transition-shadow"
              >
                <h3 className="text-lg font-bold text-secondary-900 mb-3">Comment visiter un logement ?</h3>
                <p className="text-secondary-600 leading-relaxed">
                  Vous pouvez réserver une visite directement via notre application mobile ou
                  en nous contactant par téléphone. Nous organiserons un rendez-vous à votre convenance.
                </p>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.3 }}
                className="bg-white p-8 rounded-2xl shadow-lg border border-gray-100 hover:shadow-xl transition-shadow"
              >
                <h3 className="text-lg font-bold text-secondary-900 mb-3">Quel est le délai de réponse ?</h3>
                <p className="text-secondary-600 leading-relaxed">
                  Nous nous engageons à répondre à toutes les demandes dans un délai de 24h
                  ouvrées. Pour les questions urgentes, nous vous recommandons de nous contacter par téléphone.
                </p>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.4 }}
                className="bg-white p-8 rounded-2xl shadow-lg border border-gray-100 hover:shadow-xl transition-shadow"
              >
                <h3 className="text-lg font-bold text-secondary-900 mb-3">Comment devenir partenaire ?</h3>
                <p className="text-secondary-600 leading-relaxed">
                  Pour devenir partenaire, veuillez nous contacter directement par email à
                  partners@chapechaperesidence.com ou utiliser notre formulaire de contact.
                </p>
              </motion.div>
            </div>

            <div className="text-center mt-12">
              <a href="/faq" className="inline-flex items-center text-primary-600 hover:text-primary-700 font-bold transition-colors group">
                Voir toutes les questions fréquentes
                <svg className="ml-2 h-5 w-5 transform group-hover:translate-x-1 transition-transform" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L12.586 11H5a1 1 0 110-2h7.586l-2.293-2.293a1 1 0 010-1.414z" clipRule="evenodd" />
                </svg>
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* Carte Google Maps */}
      <section className="py-24 bg-white">
        <div className="container mx-auto px-4 max-w-6xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="text-3xl font-bold text-secondary-900 mb-4 font-display">Nous trouver</h2>
            <p className="text-secondary-600 max-w-2xl mx-auto text-lg">
              Nos bureaux sont situés à Abidjan dans un quartier facilement accessible. N'hésitez pas à nous rendre visite.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 rounded-3xl overflow-hidden shadow-2xl h-[500px] border border-gray-100">
              <iframe
                src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3972.4736881794175!2d-3.9761723852929284!3d5.3481699371855435!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zNcKwMjAnNTMuNCJOIDPCsDU4JzMzLjEiVw!5e0!3m2!1sfr!2sci!4v1663342965642!5m2!1sfr!2sci"
                width="100%"
                height="100%"
                style={{ border: 0 }}
                allowFullScreen={true}
                loading="lazy"
                referrerPolicy="no-referrer-when-downgrade"
                title="Emplacement des bureaux de ChapeChape Residence"
                className="grayscale hover:grayscale-0 transition-all duration-500"
              ></iframe>
            </div>

            <div className="bg-secondary-900 rounded-3xl p-10 shadow-2xl flex flex-col justify-center text-white relative overflow-hidden">
              <div className="absolute top-0 right-0 p-10 opacity-10">
                <MapPinIcon className="w-32 h-32" />
              </div>

              <div className="relative z-10">
                <div className="flex items-center justify-center h-16 w-16 rounded-2xl bg-primary-500/20 text-primary-400 mb-8 backdrop-blur-sm border border-primary-500/30">
                  <MapPinIcon className="h-8 w-8" />
                </div>

                <h3 className="text-2xl font-bold mb-6 font-display">Notre adresse</h3>
                <p className="text-gray-300 leading-relaxed mb-8 text-lg">
                  Angré, Rond-point CNPS<br />
                  En face du restaurant La Shish<br />
                  92HH+CVM Riviera, Abidjan<br />
                  Côte d'Ivoire
                </p>

                <div className="flex flex-col space-y-4">
                  <a
                    href="https://maps.app.goo.gl/1iBVEeDp6Q58RSB69"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center px-6 py-3 rounded-xl bg-white/10 hover:bg-white/20 backdrop-blur-sm border border-white/10 transition-all duration-300 group"
                  >
                    <span className="font-bold">Ouvrir Google Maps</span>
                    <svg className="ml-auto h-5 w-5 transform group-hover:translate-x-1 transition-transform" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                      <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z" />
                      <path d="M5 5a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2v-3a1 1 0 10-2 0v3H5V7h3a1 1 0 000-2H5z" />
                    </svg>
                  </a>
                  <a
                    href="https://waze.com/ul?ll=5.348169,3.976172&navigate=yes"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center px-6 py-3 rounded-xl bg-white/10 hover:bg-white/20 backdrop-blur-sm border border-white/10 transition-all duration-300 group"
                  >
                    <span className="font-bold">Ouvrir Waze</span>
                    <svg className="ml-auto h-5 w-5 transform group-hover:translate-x-1 transition-transform" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                      <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z" />
                      <path d="M5 5a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2v-3a1 1 0 10-2 0v3H5V7h3a1 1 0 000-2H5z" />
                    </svg>
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}

export default Contact