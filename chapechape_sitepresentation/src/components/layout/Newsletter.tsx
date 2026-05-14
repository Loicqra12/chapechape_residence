import { useState } from 'react'
import { motion } from 'framer-motion'
import { apiService } from '../../services/api.service'

export default function Newsletter() {
  const [email, setEmail] = useState('')
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle')
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!email.trim()) return
    setStatus('loading')
    setErrorMessage(null)
    try {
      await apiService.subscribeNewsletter({ email: email.trim() })
      setStatus('success')
      setEmail('')
    } catch (err) {
      setStatus('error')
      setErrorMessage(err instanceof Error ? err.message : 'Une erreur est survenue, réessayez.')
    }
  }

  return (
    <section className="relative bg-white py-16 sm:py-20">
      {/* Décor subtil */}
      <div className="absolute inset-0 bg-[radial-gradient(circle,#D4AF37_1px,transparent_1px)] [background-size:32px_32px] opacity-[0.04] pointer-events-none" />

      <div className="relative max-w-7xl mx-auto px-6 lg:px-12">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-80px' }}
          transition={{ duration: 0.6, ease: 'easeOut' }}
          className="relative overflow-hidden rounded-3xl bg-secondary-900 p-8 sm:p-12 lg:p-16 shadow-xl"
        >
          {/* Glow doré animé */}
          <motion.div
            className="absolute -top-24 -right-24 w-72 h-72 rounded-full bg-primary-500/15 blur-3xl pointer-events-none"
            animate={{ scale: [1, 1.2, 1], opacity: [0.4, 0.7, 0.4] }}
            transition={{ duration: 8, repeat: Infinity, ease: 'easeInOut' }}
          />
          <div className="absolute inset-0 bg-[radial-gradient(circle,#D4AF37_1px,transparent_1px)] [background-size:32px_32px] opacity-[0.05] pointer-events-none" />

          <div className="relative grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12 items-center">
            {/* Texte */}
            <div>
              <span className="inline-block py-1.5 px-4 rounded-full bg-white/10 backdrop-blur-md border border-white/15 text-primary-300 text-[10px] font-bold tracking-widest uppercase mb-5 font-body">
                Newsletter
              </span>
              <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-white font-display leading-tight mb-4">
                Restez informé des nouvelles{' '}
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">
                  résidences
                </span>
              </h2>
              <p className="text-white/60 font-body text-[15px] leading-relaxed max-w-md">
                Recevez en avant-première nos nouvelles annonces, offres exclusives et conseils
                pour bien louer en Côte d'Ivoire.
              </p>
            </div>

            {/* Formulaire */}
            <div className="lg:pl-8">
              <form onSubmit={handleSubmit} className="flex flex-col sm:flex-row gap-3">
                <input
                  type="email"
                  value={email}
                  onChange={(e) => { setEmail(e.target.value); setStatus('idle') }}
                  placeholder="Votre adresse email"
                  required
                  disabled={status === 'loading' || status === 'success'}
                  className="flex-1 px-5 py-3.5 rounded-full bg-white/10 backdrop-blur-md border border-white/15 text-white placeholder-white/40 text-sm font-body focus:outline-none focus:border-primary-400 focus:bg-white/15 transition-colors disabled:opacity-50"
                />
                <button
                  type="submit"
                  disabled={status === 'loading' || status === 'success'}
                  className="px-7 py-3.5 rounded-full bg-primary-500 text-secondary-900 text-sm font-bold font-body hover:bg-primary-400 transition-colors disabled:opacity-60 whitespace-nowrap inline-flex items-center justify-center gap-2"
                >
                  {status === 'loading' && '...'}
                  {status === 'success' && (
                    <>
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="3" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                      </svg>
                      Inscrit
                    </>
                  )}
                  {(status === 'idle' || status === 'error') && (
                    <>
                      S'inscrire
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M17 8l4 4m0 0l-4 4m4-4H3" />
                      </svg>
                    </>
                  )}
                </button>
              </form>

              {/* Messages d'état */}
              <div className="mt-3 min-h-[20px]">
                {status === 'success' && (
                  <p className="text-xs text-primary-300 font-body">
                    Merci ! Votre inscription a bien été enregistrée.
                  </p>
                )}
                {status === 'error' && (
                  <p className="text-xs text-red-400 font-body">
                    {errorMessage || 'Une erreur est survenue, réessayez.'}
                  </p>
                )}
                {status === 'idle' && (
                  <p className="text-xs text-white/40 font-body">
                    Pas de spam. Désinscription en un clic.
                  </p>
                )}
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  )
}
