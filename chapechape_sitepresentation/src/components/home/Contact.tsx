import { motion, AnimatePresence, useScroll, useTransform } from 'framer-motion'
import { useState, useRef } from 'react'
import { MapPinIcon, EnvelopeIcon } from '@heroicons/react/24/outline'
import { apiService, getErrorMessage, type ContactFormData } from '../../services/api.service'
import { trackContactForm } from '../analytics/GoogleAnalytics'
import { useToast } from '../../components/ui/ToastProvider'

const Contact = () => {
  const [formState, setFormState] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    company: '',
    subject: '',
    message: '',
  })

  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isSubmitted, setIsSubmitted] = useState(false)
  const [submitError, setSubmitError] = useState<string | null>(null)
  const [focusedField, setFocusedField] = useState<string | null>(null)
  const [errors, setErrors] = useState<{ [key: string]: string }>({})
  const containerRef = useRef(null)

  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"]
  })

  const y = useTransform(scrollYProgress, [0, 1], [100, -100])
  const opacity = useTransform(scrollYProgress, [0, 0.3, 0.7, 1], [0.3, 1, 1, 0.3])

  const validateField = (name: string, value: string) => {
    const newErrors = { ...errors }

    switch (name) {
      case 'firstName':
        if (!value.trim()) newErrors.firstName = 'Le prénom est requis'
        else if (value.trim().length < 2) newErrors.firstName = 'Le prénom doit contenir au moins 2 caractères'
        else delete newErrors.firstName
        break
      case 'lastName':
        if (!value.trim()) newErrors.lastName = 'Le nom est requis'
        else if (value.trim().length < 2) newErrors.lastName = 'Le nom doit contenir au moins 2 caractères'
        else delete newErrors.lastName
        break
      case 'email':
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
        if (!value.trim()) newErrors.email = 'L\'email est requis'
        else if (!emailRegex.test(value)) newErrors.email = 'Format d\'email invalide'
        else delete newErrors.email
        break
      case 'phone':
        if (value && !/^[+]?[0-9\s\-()]{8,}$/.test(value)) {
          newErrors.phone = 'Format de téléphone invalide'
        } else delete newErrors.phone
        break
      case 'company':
        // Champ optionnel, pas de validation
        delete newErrors.company
        break
      case 'subject':
        if (!value) newErrors.subject = 'Veuillez sélectionner un sujet'
        else delete newErrors.subject
        break
      case 'message':
        if (!value.trim()) newErrors.message = 'Le message est requis'
        else if (value.trim().length < 10) newErrors.message = 'Le message doit contenir au moins 10 caractères'
        else delete newErrors.message
        break
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormState(prev => ({ ...prev, [name]: value }))
    validateField(name, value)
  }

  const handleFocus = (fieldName: string) => {
    setFocusedField(fieldName)
  }

  const handleBlur = () => {
    setFocusedField(null)
  }

  const { showToast } = useToast()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    // Valider tous les champs requis
    const isValid = ['firstName', 'lastName', 'email', 'subject', 'message'].every(key => {
      return validateField(key, formState[key as keyof typeof formState])
    })

    // Valider le téléphone s'il est renseigné
    if (formState.phone) {
      validateField('phone', formState.phone)
    }

    if (!isValid || Object.keys(errors).length > 0) {
      showToast('Veuillez corriger les erreurs dans le formulaire', 'error')
      return
    }

    setIsSubmitting(true)
    setSubmitError(null)

    try {
      // Préparer les données pour l'API
      const contactData: ContactFormData = {
        firstName: formState.firstName,
        lastName: formState.lastName,
        email: formState.email,
        phone: formState.phone || undefined,
        company: formState.company || undefined,
        subject: formState.subject || undefined,
        message: formState.message,
      }

      // Envoyer à l'API backend
      const response = await apiService.submitContactForm(contactData)

      if (response.success) {
        setIsSubmitted(true)
        showToast('Votre message a été envoyé avec succès !', 'success')

        // Tracker l'événement Google Analytics
        trackContactForm('contact')

        setFormState({
          firstName: '',
          lastName: '',
          email: '',
          phone: '',
          company: '',
          subject: '',
          message: '',
        })
        setErrors({})

        // Reset le message de succès après 5 secondes
        setTimeout(() => {
          setIsSubmitted(false)
        }, 5000)
      } else {
        const errorMsg = response.message || 'Erreur lors de l\'envoi du message'
        setSubmitError(errorMsg)
        showToast(errorMsg, 'error')
      }
    } catch (error) {
      console.error('Erreur lors de l\'envoi du formulaire:', error)
      const errorMsg = getErrorMessage(error)
      setSubmitError(errorMsg)
      showToast(errorMsg, 'error')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <section id="contact" className="py-24 bg-white dark:bg-secondary-900">
      <div className="container-custom max-w-5xl mx-auto">
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
            className="bg-white dark:bg-secondary-800 rounded-xl shadow-2xl p-8 border border-secondary-100 dark:border-secondary-700 relative overflow-hidden"
          >
            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-primary-300 via-primary-500 to-primary-300"></div>
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
                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.3, delay: 0.1 }}
                  >
                    <label htmlFor="firstName" className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-2">
                      Prénom *
                    </label>
                    <div className="relative">
                      <input
                        type="text"
                        id="firstName"
                        name="firstName"
                        value={formState.firstName}
                        onChange={handleChange}
                        onFocus={() => handleFocus('firstName')}
                        onBlur={handleBlur}
                        required
                        className={`w-full px-4 py-3 rounded-lg border-2 transition-all duration-300 dark:bg-secondary-700 dark:text-white ${focusedField === 'firstName'
                          ? 'border-primary-300 shadow-lg shadow-primary-300/25 ring-4 ring-primary-300/10'
                          : errors.firstName
                            ? 'border-red-300 shadow-lg shadow-red-300/25'
                            : 'border-secondary-300 dark:border-secondary-600 hover:border-primary-200 dark:hover:border-primary-400'
                          }`}
                        placeholder="Votre prénom"
                      />
                      <AnimatePresence>
                        {errors.firstName && (
                          <motion.p
                            initial={{ opacity: 0, y: -10 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -10 }}
                            className="text-red-500 text-sm mt-1 flex items-center"
                          >
                            <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                            </svg>
                            {errors.firstName}
                          </motion.p>
                        )}
                      </AnimatePresence>
                    </div>
                  </motion.div>
                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.3, delay: 0.15 }}
                  >
                    <label htmlFor="lastName" className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-2">
                      Nom *
                    </label>
                    <div className="relative">
                      <input
                        type="text"
                        id="lastName"
                        name="lastName"
                        value={formState.lastName}
                        onChange={handleChange}
                        onFocus={() => handleFocus('lastName')}
                        onBlur={handleBlur}
                        required
                        className={`w-full px-4 py-3 rounded-lg border-2 transition-all duration-300 dark:bg-secondary-700 dark:text-white ${focusedField === 'lastName'
                          ? 'border-primary-300 shadow-lg shadow-primary-300/25 ring-4 ring-primary-300/10'
                          : errors.lastName
                            ? 'border-red-300 shadow-lg shadow-red-300/25'
                            : 'border-secondary-300 dark:border-secondary-600 hover:border-primary-200 dark:hover:border-primary-400'
                          }`}
                        placeholder="Votre nom"
                      />
                      <AnimatePresence>
                        {errors.lastName && (
                          <motion.p
                            initial={{ opacity: 0, y: -10 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -10 }}
                            className="text-red-500 text-sm mt-1 flex items-center"
                          >
                            <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                            </svg>
                            {errors.lastName}
                          </motion.p>
                        )}
                      </AnimatePresence>
                    </div>
                  </motion.div>
                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.3, delay: 0.2 }}
                  >
                    <label htmlFor="email" className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-2">
                      Adresse e-mail *
                    </label>
                    <div className="relative">
                      <input
                        type="email"
                        id="email"
                        name="email"
                        value={formState.email}
                        onChange={handleChange}
                        onFocus={() => handleFocus('email')}
                        onBlur={handleBlur}
                        required
                        className={`w-full px-4 py-3 rounded-lg border-2 transition-all duration-300 dark:bg-secondary-700 dark:text-white ${focusedField === 'email'
                          ? 'border-primary-300 shadow-lg shadow-primary-300/25 ring-4 ring-primary-300/10'
                          : errors.email
                            ? 'border-red-300 shadow-lg shadow-red-300/25'
                            : 'border-secondary-300 dark:border-secondary-600 hover:border-primary-200 dark:hover:border-primary-400'
                          }`}
                        placeholder="votre@email.com"
                      />
                      <AnimatePresence>
                        {errors.email && (
                          <motion.p
                            initial={{ opacity: 0, y: -10 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -10 }}
                            className="text-red-500 text-sm mt-1 flex items-center"
                          >
                            <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                            </svg>
                            {errors.email}
                          </motion.p>
                        )}
                      </AnimatePresence>
                    </div>
                  </motion.div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.3, delay: 0.25 }}
                  >
                    <label htmlFor="phone" className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-2">
                      Téléphone
                    </label>
                    <div className="relative">
                      <input
                        type="tel"
                        id="phone"
                        name="phone"
                        value={formState.phone}
                        onChange={handleChange}
                        onFocus={() => handleFocus('phone')}
                        onBlur={handleBlur}
                        className={`w-full px-4 py-3 rounded-lg border-2 transition-all duration-300 dark:bg-secondary-700 dark:text-white ${focusedField === 'phone'
                          ? 'border-primary-300 shadow-lg shadow-primary-300/25 ring-4 ring-primary-300/10'
                          : errors.phone
                            ? 'border-red-300 shadow-lg shadow-red-300/25'
                            : 'border-secondary-300 dark:border-secondary-600 hover:border-primary-200 dark:hover:border-primary-400'
                          }`}
                        placeholder="+33 1 23 45 67 89"
                      />
                      <AnimatePresence>
                        {errors.phone && (
                          <motion.p
                            initial={{ opacity: 0, y: -10 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -10 }}
                            className="text-red-500 text-sm mt-1 flex items-center"
                          >
                            <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                            </svg>
                            {errors.phone}
                          </motion.p>
                        )}
                      </AnimatePresence>
                    </div>
                  </motion.div>
                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.3, delay: 0.3 }}
                  >
                    <label htmlFor="company" className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-2">
                      Entreprise
                    </label>
                    <div className="relative">
                      <input
                        type="text"
                        id="company"
                        name="company"
                        value={formState.company}
                        onChange={handleChange}
                        onFocus={() => handleFocus('company')}
                        onBlur={handleBlur}
                        className={`w-full px-4 py-3 rounded-lg border-2 transition-all duration-300 dark:bg-secondary-700 dark:text-white ${focusedField === 'company'
                          ? 'border-primary-300 shadow-lg shadow-primary-300/25 ring-4 ring-primary-300/10'
                          : 'border-secondary-300 dark:border-secondary-600 hover:border-primary-200 dark:hover:border-primary-400'
                          }`}
                        placeholder="Votre entreprise (optionnel)"
                      />
                    </div>
                  </motion.div>
                </div>

                {/* Affichage des erreurs de soumission */}
                <AnimatePresence>
                  {submitError && (
                    <motion.div
                      initial={{ opacity: 0, y: -10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -10 }}
                      className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4"
                    >
                      <div className="flex items-center">
                        <svg className="w-5 h-5 text-red-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                        </svg>
                        <p className="text-red-700 dark:text-red-300 text-sm font-medium">
                          {submitError}
                        </p>
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>

                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.3, delay: 0.4 }}
                >
                  <label htmlFor="subject" className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-2">
                    Sujet *
                  </label>
                  <div className="relative">
                    <select
                      id="subject"
                      name="subject"
                      value={formState.subject}
                      onChange={handleChange}
                      onFocus={() => handleFocus('subject')}
                      onBlur={handleBlur}
                      required
                      className={`w-full px-4 py-3 rounded-lg border-2 transition-all duration-300 dark:bg-secondary-700 dark:text-white appearance-none cursor-pointer ${focusedField === 'subject'
                        ? 'border-primary-300 shadow-lg shadow-primary-300/25 ring-4 ring-primary-300/10'
                        : errors.subject
                          ? 'border-red-300 shadow-lg shadow-red-300/25'
                          : 'border-secondary-300 dark:border-secondary-600 hover:border-primary-200 dark:hover:border-primary-400'
                        }`}
                    >
                      <option value="">Sélectionnez un sujet</option>
                      <option value="general">Renseignement général</option>
                      <option value="partnership">Devenir partenaire</option>
                      <option value="support">Support technique</option>
                      <option value="other">Autre</option>
                    </select>
                    <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                      <svg className="w-5 h-5 text-secondary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                      </svg>
                    </div>
                    <AnimatePresence>
                      {errors.subject && (
                        <motion.p
                          initial={{ opacity: 0, y: -10 }}
                          animate={{ opacity: 1, y: 0 }}
                          exit={{ opacity: 0, y: -10 }}
                          className="text-red-500 text-sm mt-1 flex items-center"
                        >
                          <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                          </svg>
                          {errors.subject}
                        </motion.p>
                      )}
                    </AnimatePresence>
                  </div>
                </motion.div>

                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.3, delay: 0.5 }}
                >
                  <label htmlFor="message" className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-2">
                    Message *
                  </label>
                  <div className="relative">
                    <textarea
                      id="message"
                      name="message"
                      rows={5}
                      value={formState.message}
                      onChange={handleChange}
                      onFocus={() => handleFocus('message')}
                      onBlur={handleBlur}
                      required
                      className={`w-full px-4 py-3 rounded-lg border-2 transition-all duration-300 dark:bg-secondary-700 dark:text-white resize-none ${focusedField === 'message'
                        ? 'border-primary-300 shadow-lg shadow-primary-300/25 ring-4 ring-primary-300/10'
                        : errors.message
                          ? 'border-red-300 shadow-lg shadow-red-300/25'
                          : 'border-secondary-300 dark:border-secondary-600 hover:border-primary-200 dark:hover:border-primary-400'
                        }`}
                      placeholder="Décrivez votre demande en détail..."
                    ></textarea>
                    <div className="absolute bottom-3 right-3 text-xs text-secondary-400">
                      {formState.message.length}/500
                    </div>
                    <AnimatePresence>
                      {errors.message && (
                        <motion.p
                          initial={{ opacity: 0, y: -10 }}
                          animate={{ opacity: 1, y: 0 }}
                          exit={{ opacity: 0, y: -10 }}
                          className="text-red-500 text-sm mt-1 flex items-center"
                        >
                          <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                          </svg>
                          {errors.message}
                        </motion.p>
                      )}
                    </AnimatePresence>
                  </div>
                </motion.div>

                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.3, delay: 0.6 }}
                >
                  <motion.button
                    type="submit"
                    disabled={isSubmitting}
                    whileHover={{ scale: isSubmitting ? 1 : 1.02 }}
                    whileTap={{ scale: isSubmitting ? 1 : 0.98 }}
                    className="w-full btn-primary disabled:opacity-70 disabled:cursor-not-allowed group relative overflow-hidden"
                  >
                    <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-1000"></div>
                    <div className="relative flex items-center justify-center">
                      {isSubmitting ? (
                        <>
                          <motion.svg
                            className="animate-spin -ml-1 mr-3 h-5 w-5"
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            animate={{ rotate: 360 }}
                            transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                          >
                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                          </motion.svg>
                          Envoi en cours...
                        </>
                      ) : (
                        <>
                          Envoyer le message
                          <motion.svg
                            className="ml-2 w-5 h-5"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                            xmlns="http://www.w3.org/2000/svg"
                            initial={{ x: -10, opacity: 0 }}
                            animate={{ x: 0, opacity: 1 }}
                            transition={{ duration: 0.3, delay: 0.8 }}
                          >
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path>
                          </motion.svg>
                        </>
                      )}
                    </div>
                  </motion.button>
                </motion.div>
              </form>
            )}
          </motion.div>

          {/* Informations de contact */}
          <motion.div
            ref={containerRef}
            initial={{ opacity: 0, x: 20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="space-y-8 relative"
          >
            {/* Background parallax elements */}
            <motion.div
              className="absolute -top-10 -right-10 w-32 h-32 bg-gradient-to-br from-primary-200/20 to-primary-300/20 rounded-full blur-xl"
              style={{ y, opacity }}
            />
            <motion.div
              className="absolute top-1/2 -left-10 w-24 h-24 bg-gradient-to-br from-primary-300/20 to-primary-400/20 rounded-full blur-lg"
              style={{ y: useTransform(scrollYProgress, [0, 1], [-50, 50]), opacity }}
            />
            {/* Email Card */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: 0.1 }}
              whileHover={{ scale: 1.02, y: -5 }}
              className="relative bg-white dark:bg-secondary-800 rounded-2xl p-8 shadow-lg hover:shadow-2xl transition-all duration-500 border border-primary-100 dark:border-secondary-700 group overflow-hidden"
            >
              {/* Gradient overlay on hover */}
              <div className="absolute inset-0 bg-gradient-to-br from-primary-50/50 to-primary-100/50 dark:from-primary-900/20 dark:to-primary-800/20 opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

              <div className="relative flex items-start">
                <motion.div
                  className="flex-shrink-0"
                  whileHover={{ rotate: 360, scale: 1.1 }}
                  transition={{ duration: 0.6, type: "spring", stiffness: 300 }}
                >
                  <div className="flex items-center justify-center h-16 w-16 rounded-2xl bg-gradient-to-br from-primary-300 to-primary-400 text-white shadow-lg group-hover:shadow-primary-300/50 transition-all duration-300">
                    <EnvelopeIcon className="h-8 w-8" />
                  </div>
                </motion.div>
                <div className="ml-6">
                  <motion.h3
                    className="text-xl font-bold text-secondary-900 dark:text-white mb-2"
                    whileHover={{ x: 5 }}
                    transition={{ type: "spring", stiffness: 400, damping: 10 }}
                  >
                    Email
                  </motion.h3>
                  <p className="text-secondary-600 dark:text-secondary-300 mb-3">
                    Vous préférez l'email ? Contactez-nous à :
                  </p>
                  <motion.a
                    href="mailto:contact@chapechaperesidence.com"
                    className="inline-flex items-center text-primary-400 hover:text-primary-500 font-semibold group/link"
                    whileHover={{ x: 5 }}
                    transition={{ type: "spring", stiffness: 400, damping: 10 }}
                  >
                    contact@chapechaperesidence.com
                    <motion.svg
                      className="ml-2 w-4 h-4"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                      whileHover={{ x: 3 }}
                      transition={{ type: "spring", stiffness: 400, damping: 10 }}
                    >
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                    </motion.svg>
                  </motion.a>
                </div>
              </div>
            </motion.div>

            {/* Address Card */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: 0.3 }}
              whileHover={{ scale: 1.02, y: -5 }}
              className="relative bg-white dark:bg-secondary-800 rounded-2xl p-8 shadow-lg hover:shadow-2xl transition-all duration-500 border border-primary-100 dark:border-secondary-700 group overflow-hidden"
            >
              {/* Gradient overlay on hover */}
              <div className="absolute inset-0 bg-gradient-to-br from-blue-50/50 to-blue-100/50 dark:from-blue-900/20 dark:to-blue-800/20 opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

              <div className="relative flex items-start">
                <motion.div
                  className="flex-shrink-0"
                  whileHover={{ scale: 1.1, rotate: [0, -5, 5, 0] }}
                  transition={{ duration: 0.6, type: "spring", stiffness: 300 }}
                >
                  <div className="flex items-center justify-center h-16 w-16 rounded-2xl bg-gradient-to-br from-blue-400 to-blue-500 text-white shadow-lg group-hover:shadow-blue-400/50 transition-all duration-300">
                    <MapPinIcon className="h-8 w-8" />
                  </div>
                </motion.div>
                <div className="ml-6">
                  <motion.h3
                    className="text-xl font-bold text-secondary-900 dark:text-white mb-2"
                    whileHover={{ x: 5 }}
                    transition={{ type: "spring", stiffness: 400, damping: 10 }}
                  >
                    Adresse
                  </motion.h3>
                  <p className="text-secondary-600 dark:text-secondary-300 mb-3">
                    Visitez nos bureaux à Abidjan :
                  </p>
                  <motion.div
                    className="text-secondary-700 dark:text-secondary-300 mb-4 leading-relaxed"
                    whileHover={{ x: 3 }}
                    transition={{ type: "spring", stiffness: 400, damping: 10 }}
                  >
                    Angré, Rond-point CNPS<br />
                    En face du restaurant La Shish<br />
                    92HH+CVM Riviera, Abidjan<br />
                    Côte d'Ivoire
                  </motion.div>
                  <motion.a
                    href="https://maps.app.goo.gl/1iBVEeDp6Q58RSB69"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center text-blue-500 hover:text-blue-600 font-semibold group/link"
                    whileHover={{ x: 5 }}
                    transition={{ type: "spring", stiffness: 400, damping: 10 }}
                  >
                    Voir sur Google Maps
                    <motion.svg
                      className="ml-2 w-4 h-4"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                      whileHover={{ rotate: 45, scale: 1.1 }}
                      transition={{ type: "spring", stiffness: 400, damping: 10 }}
                    >
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                    </motion.svg>
                  </motion.a>
                </div>
              </div>
            </motion.div>

            {/* Support Card */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: 0.4 }}
              whileHover={{ scale: 1.02, y: -5 }}
              className="relative bg-white dark:bg-secondary-800 rounded-2xl p-8 shadow-lg hover:shadow-2xl transition-all duration-500 border border-primary-100 dark:border-secondary-700 group overflow-hidden"
            >
              {/* Gradient overlay on hover */}
              <div className="absolute inset-0 bg-gradient-to-br from-purple-50/50 to-purple-100/50 dark:from-purple-900/20 dark:to-purple-800/20 opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

              <div className="relative flex items-start">
                <motion.div
                  className="flex-shrink-0"
                  whileHover={{ scale: 1.1, rotate: 360 }}
                  transition={{ duration: 0.8, type: "spring", stiffness: 200 }}
                >
                  <div className="flex items-center justify-center h-16 w-16 rounded-2xl bg-gradient-to-br from-purple-400 to-purple-500 text-white shadow-lg group-hover:shadow-purple-400/50 transition-all duration-300">
                    <svg className="h-8 w-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                  </div>
                </motion.div>
                <div className="ml-6">
                  <motion.h3
                    className="text-xl font-bold text-secondary-900 dark:text-white mb-2"
                    whileHover={{ x: 5 }}
                    transition={{ type: "spring", stiffness: 400, damping: 10 }}
                  >
                    Support technique
                  </motion.h3>
                  <p className="text-secondary-600 dark:text-secondary-300 mb-3">
                    Besoin d'aide avec nos applications ?
                  </p>
                  <motion.a
                    href="mailto:support@chapechaperesidence.com"
                    className="inline-flex items-center text-purple-500 hover:text-purple-600 font-semibold group/link"
                    whileHover={{ x: 5 }}
                    transition={{ type: "spring", stiffness: 400, damping: 10 }}
                  >
                    support@chapechaperesidence.com
                    <motion.svg
                      className="ml-2 w-4 h-4"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                      whileHover={{ x: 3 }}
                      transition={{ type: "spring", stiffness: 400, damping: 10 }}
                    >
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                    </motion.svg>
                  </motion.a>
                </div>
              </div>
            </motion.div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}

export default Contact 