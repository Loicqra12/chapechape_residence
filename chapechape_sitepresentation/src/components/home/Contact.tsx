import { motion } from 'framer-motion'
import { useState } from 'react'
import { PhoneIcon, MapPinIcon } from '@heroicons/react/24/outline'

const Contact = () => {
  const [formState, setFormState] = useState({
    name: '',
    email: '',
    phone: '',
    subject: '',
    message: '',
  })

  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isSubmitted, setIsSubmitted] = useState(false)

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormState(prev => ({ ...prev, [name]: value }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)
    
    // Simuler une soumission de formulaire
    setTimeout(() => {
      setIsSubmitting(false)
      setIsSubmitted(true)
      setFormState({
        name: '',
        email: '',
        phone: '',
        subject: '',
        message: '',
      })
      
      // Reset le message de succès après 5 secondes
      setTimeout(() => {
        setIsSubmitted(false)
      }, 5000)
    }, 1500)
  }

  return (
    <section id="contact" className="py-24 bg-white dark:bg-secondary-900">
      <div className="container-custom">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl font-bold text-secondary-900 dark:text-white mb-4">Contactez-nous</h2>
          <p className="text-secondary-600 dark:text-secondary-300 max-w-2xl mx-auto">
            Vous avez des questions ou souhaitez en savoir plus sur ChapeChape Residence ?
            Notre équipe est là pour vous répondre.
          </p>
        </motion.div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-start">
          {/* Formulaire de contact */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="bg-white dark:bg-secondary-800 rounded-xl shadow-xl p-8"
          >
            {isSubmitted ? (
              <div className="flex flex-col items-center justify-center h-full py-12">
                <div className="w-16 h-16 bg-green-100 dark:bg-green-900/30 rounded-full flex items-center justify-center mb-4">
                  <svg className="h-8 w-8 text-green-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <h3 className="text-xl font-bold text-secondary-900 dark:text-white mb-2">Message envoyé !</h3>
                <p className="text-secondary-600 dark:text-secondary-300 text-center">
                  Merci de nous avoir contactés. Notre équipe reviendra vers vous dans les plus brefs délais.
                </p>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label htmlFor="name" className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
                      Nom complet
                    </label>
                    <input
                      type="text"
                      id="name"
                      name="name"
                      value={formState.name}
                      onChange={handleChange}
                      required
                      className="w-full rounded-md border-secondary-300 dark:border-secondary-700 shadow-sm focus:border-primary-300 focus:ring focus:ring-primary-300/20 dark:bg-secondary-700 dark:text-white"
                    />
                  </div>
                  <div>
                    <label htmlFor="email" className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
                      Adresse e-mail
                    </label>
                    <input
                      type="email"
                      id="email"
                      name="email"
                      value={formState.email}
                      onChange={handleChange}
                      required
                      className="w-full rounded-md border-secondary-300 dark:border-secondary-700 shadow-sm focus:border-primary-300 focus:ring focus:ring-primary-300/20 dark:bg-secondary-700 dark:text-white"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label htmlFor="phone" className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
                      Téléphone
                    </label>
                    <input
                      type="tel"
                      id="phone"
                      name="phone"
                      value={formState.phone}
                      onChange={handleChange}
                      className="w-full rounded-md border-secondary-300 dark:border-secondary-700 shadow-sm focus:border-primary-300 focus:ring focus:ring-primary-300/20 dark:bg-secondary-700 dark:text-white"
                    />
                  </div>
                  <div>
                    <label htmlFor="subject" className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
                      Sujet
                    </label>
                    <select
                      id="subject"
                      name="subject"
                      value={formState.subject}
                      onChange={handleChange}
                      required
                      className="w-full rounded-md border-secondary-300 dark:border-secondary-700 shadow-sm focus:border-primary-300 focus:ring focus:ring-primary-300/20 dark:bg-secondary-700 dark:text-white"
                    >
                      <option value="">Sélectionnez un sujet</option>
                      <option value="general">Renseignement général</option>
                      <option value="partnership">Devenir partenaire</option>
                      <option value="support">Support technique</option>
                      <option value="other">Autre</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label htmlFor="message" className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
                    Message
                  </label>
                  <textarea
                    id="message"
                    name="message"
                    rows={4}
                    value={formState.message}
                    onChange={handleChange}
                    required
                    className="w-full rounded-md border-secondary-300 dark:border-secondary-700 shadow-sm focus:border-primary-300 focus:ring focus:ring-primary-300/20 dark:bg-secondary-700 dark:text-white"
                  ></textarea>
                </div>

                <div>
                  <button
                    type="submit"
                    disabled={isSubmitting}
                    className="w-full flex items-center justify-center btn-primary disabled:opacity-70"
                  >
                    {isSubmitting ? (
                      <>
                        <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-secondary-900" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        Envoi en cours...
                      </>
                    ) : (
                      'Envoyer le message'
                    )}
                  </button>
                </div>
              </form>
            )}
          </motion.div>

          {/* Informations de contact */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="space-y-8"
          >
            <div className="bg-secondary-50 dark:bg-secondary-800 rounded-xl p-6 shadow-md border border-primary-100">
              <div className="flex items-start">
                <div className="flex-shrink-0">
                  <div className="flex items-center justify-center h-12 w-12 rounded-md bg-primary-300 text-secondary-900">
                    <svg className="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                  </div>
                </div>
                <div className="ml-4">
                  <h3 className="text-lg font-medium text-secondary-900 dark:text-white">Email</h3>
                  <p className="mt-1 text-secondary-600 dark:text-secondary-300">
                    Vous préférez l'email ? Contactez-nous à :
                  </p>
                  <a href="mailto:contact@chapechaperesidence.com" className="mt-2 flex items-center text-primary-300 hover:text-primary-400 transition-colors duration-200">
                    contact@chapechaperesidence.com
                  </a>
                </div>
              </div>
            </div>

            <div className="bg-secondary-50 dark:bg-secondary-800 rounded-xl p-6 shadow-md border border-primary-100">
              <div className="flex items-start">
                <div className="flex-shrink-0">
                  <div className="flex items-center justify-center h-12 w-12 rounded-md bg-primary-300 text-secondary-900">
                    <svg className="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                    </svg>
                  </div>
                </div>
                <div className="ml-4">
                  <h3 className="text-lg font-medium text-secondary-900 dark:text-white">Téléphone</h3>
                  <p className="mt-1 text-secondary-600 dark:text-secondary-300">
                    Du lundi au vendredi, de 8h à 18h (heure locale) :
                  </p>
                  <a href="tel:+2250153049411" className="mt-2 flex items-center text-primary-300 hover:text-primary-400 transition-colors duration-200">
                    <PhoneIcon className="h-5 w-5 mr-2 text-primary-300" />
                    +225 01 53 04 94 11
                  </a>
                </div>
              </div>
            </div>

            <div className="bg-secondary-50 dark:bg-secondary-800 rounded-xl p-6 shadow-md border border-primary-100">
              <div className="flex items-start">
                <div className="flex-shrink-0">
                  <div className="flex items-center justify-center h-12 w-12 rounded-md bg-primary-300 text-secondary-900">
                    <svg className="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                  </div>
                </div>
                <div className="ml-4">
                  <h3 className="text-lg font-medium text-secondary-900 dark:text-white">Adresse</h3>
                  <p className="mt-1 text-secondary-600 dark:text-secondary-300">
                    Visitez nos bureaux à Cotonou :
                  </p>
                  <p className="mt-2 text-primary-300">
                    Angré, Rond-point CNPS<br />
                    En face du restaurant La Shish<br />
                    92HH+CVM Riviera, Abidjan<br />
                    Côte d'Ivoire
                  </p>
                  <a 
                    href="https://maps.app.goo.gl/1iBVEeDp6Q58RSB69" 
                    target="_blank" 
                    rel="noopener noreferrer" 
                    className="mt-3 inline-flex items-center text-sm text-primary-400 hover:text-primary-500 transition-colors duration-200"
                  >
                    <MapPinIcon className="h-4 w-4 mr-1" />
                    Voir sur Google Maps
                  </a>
                </div>
              </div>
            </div>

            <div className="mt-8 bg-secondary-50 dark:bg-secondary-800 rounded-xl p-6 shadow-md border border-primary-100">
              <div className="flex items-start">
                <div className="flex-shrink-0">
                  <div className="flex items-center justify-center h-12 w-12 rounded-md bg-primary-300 text-secondary-900">
                    <svg className="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                  </div>
                </div>
                <div className="ml-4">
                  <h3 className="text-lg font-medium text-secondary-900 dark:text-secondary-100">
                    Support technique
                  </h3>
                  <p className="mt-1 text-secondary-600 dark:text-secondary-400">
                    Besoin d'aide avec nos applications ?
                  </p>
                  <a href="mailto:support@chapechaperesidence.com" className="mt-2 flex items-center text-primary-300 hover:text-primary-400 transition-colors duration-200">
                    support@chapechaperesidence.com
                  </a>
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}

export default Contact 