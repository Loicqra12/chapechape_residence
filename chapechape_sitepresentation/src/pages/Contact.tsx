import { motion } from 'framer-motion'
import { useState } from 'react'
import { PhoneIcon, MapPinIcon } from '@heroicons/react/24/outline'
import ContactComponent from '../components/home/Contact'

const Contact = () => {
  return (
    <div className="bg-white">
      {/* Hero section */}
      <div className="relative bg-secondary-900 py-24 px-6 sm:py-32 sm:px-12">
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-secondary-900 to-secondary-800 opacity-90" />
          <div 
            className="absolute inset-0 bg-cover bg-center opacity-20" 
            style={{ backgroundImage: 'url(/assets/contact/hero-bg.jpg)' }}
          />
        </div>
        <div className="relative mx-auto max-w-7xl">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            <h1 className="text-4xl font-bold tracking-tight text-white sm:text-5xl lg:text-6xl">
              Contactez-nous
            </h1>
            <p className="mt-6 max-w-lg mx-auto text-xl text-primary-200">
              Notre équipe est à votre disposition pour répondre à toutes vos questions.
            </p>
          </motion.div>
        </div>
      </div>

      {/* Composant de contact existant */}
      <ContactComponent />

      {/* Section FAQ rapide */}
      <section className="bg-secondary-50 py-16">
        <div className="container-custom">
          <div className="max-w-3xl mx-auto">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="text-center mb-12"
            >
              <h2 className="text-3xl font-bold text-secondary-900 mb-4">Questions fréquentes</h2>
              <p className="text-secondary-600">
                Voici quelques réponses aux questions les plus courantes. Si vous ne trouvez pas l'information que vous cherchez, n'hésitez pas à nous contacter directement.
              </p>
            </motion.div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.1 }}
                className="bg-white p-6 rounded-xl shadow-md"
              >
                <h3 className="text-lg font-semibold text-secondary-900 mb-3">Quels sont vos horaires d'ouverture ?</h3>
                <p className="text-secondary-600">
                  Nos bureaux sont ouverts du lundi au vendredi de 8h à 18h et le samedi de
                  9h à 13h. Notre service client en ligne est disponible 24h/24, 7j/7.
                </p>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.2 }}
                className="bg-white p-6 rounded-xl shadow-md"
              >
                <h3 className="text-lg font-semibold text-secondary-900 mb-3">Comment visiter un logement ?</h3>
                <p className="text-secondary-600">
                  Vous pouvez réserver une visite directement via notre application mobile ou
                  en nous contactant par téléphone. Nous organiserons un rendez-vous à votre convenance.
                </p>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.3 }}
                className="bg-white p-6 rounded-xl shadow-md"
              >
                <h3 className="text-lg font-semibold text-secondary-900 mb-3">Quel est le délai de réponse à une demande ?</h3>
                <p className="text-secondary-600">
                  Nous nous engageons à répondre à toutes les demandes dans un délai de 24h
                  ouvrées. Pour les questions urgentes, nous vous recommandons de nous contacter par téléphone.
                </p>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.4 }}
                className="bg-white p-6 rounded-xl shadow-md"
              >
                <h3 className="text-lg font-semibold text-secondary-900 mb-3">Comment devenir partenaire ?</h3>
                <p className="text-secondary-600">
                  Pour devenir partenaire, veuillez nous contacter directement par email à
                  partners@chapechaperesidence.com ou utiliser notre formulaire de contact en précisant votre demande.
                </p>
              </motion.div>
            </div>

            <div className="text-center mt-10">
              <a href="/faq" className="text-primary-500 hover:text-primary-600 font-medium inline-flex items-center">
                Voir toutes les questions fréquentes
                <svg className="ml-2 h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L12.586 11H5a1 1 0 110-2h7.586l-2.293-2.293a1 1 0 010-1.414z" clipRule="evenodd" />
                </svg>
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* Carte Google Maps */}
      <section className="py-16">
        <div className="container-custom">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-center mb-12"
          >
            <h2 className="text-3xl font-bold text-secondary-900 mb-4">Nous trouver</h2>
            <p className="text-secondary-600 max-w-2xl mx-auto">
              Nos bureaux sont situés à Abidjan dans un quartier facilement accessible. N'hésitez pas à nous rendre visite.
            </p>
          </motion.div>

          <div className="rounded-xl overflow-hidden shadow-lg h-96">
            <iframe
              src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3972.4736881794175!2d-3.9761723852929284!3d5.3481699371855435!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zNcKwMjAnNTMuNCJOIDPCsDU4JzMzLjEiVw!5e0!3m2!1sfr!2sci!4v1663342965642!5m2!1sfr!2sci"
              width="100%"
              height="100%"
              style={{ border: 0 }}
              allowFullScreen={true}
              loading="lazy"
              referrerPolicy="no-referrer-when-downgrade"
              title="Emplacement des bureaux de ChapeChape Residence"
            ></iframe>
          </div>

          <div className="mt-8 bg-white rounded-xl p-6 shadow-md border border-secondary-100 max-w-2xl mx-auto">
            <div className="flex items-start">
              <div className="flex-shrink-0">
                <div className="flex items-center justify-center h-12 w-12 rounded-md bg-primary-300 text-secondary-900">
                  <MapPinIcon className="h-6 w-6" />
                </div>
              </div>
              <div className="ml-4">
                <h3 className="text-lg font-semibold text-secondary-900">Notre adresse</h3>
                <p className="mt-1 text-secondary-600">
                  Angré, Rond-point CNPS<br />
                  En face du restaurant La Shish<br />
                  92HH+CVM Riviera, Abidjan<br />
                  Côte d'Ivoire
                </p>
                <div className="mt-3 flex space-x-4">
                  <a 
                    href="https://maps.app.goo.gl/1iBVEeDp6Q58RSB69" 
                    target="_blank" 
                    rel="noopener noreferrer" 
                    className="text-sm text-primary-500 hover:text-primary-600 transition-colors duration-200 inline-flex items-center"
                  >
                    <span>Google Maps</span>
                    <svg className="ml-1 h-4 w-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                      <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z" />
                      <path d="M5 5a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2v-3a1 1 0 10-2 0v3H5V7h3a1 1 0 000-2H5z" />
                    </svg>
                  </a>
                  <a 
                    href="https://waze.com/ul?ll=5.348169,3.976172&navigate=yes" 
                    target="_blank" 
                    rel="noopener noreferrer" 
                    className="text-sm text-primary-500 hover:text-primary-600 transition-colors duration-200 inline-flex items-center"
                  >
                    <span>Waze</span>
                    <svg className="ml-1 h-4 w-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
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