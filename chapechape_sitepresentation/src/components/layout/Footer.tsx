import { useRef } from 'react'
import { Link } from 'react-router-dom'
import { motion, useMotionValue, useSpring, useTransform } from 'framer-motion'

/** Fiche Google Business — avis & « Laisser un avis » (surcharge possible via VITE_GOOGLE_PLACE_ID dans .env) */
const GOOGLE_PLACE_ID =
  (import.meta as any).env?.VITE_GOOGLE_PLACE_ID?.trim() || 'ChIJvZp7d6ftwQ8RElv1-AJy7zU'
const GOOGLE_WRITE_REVIEW_URL = `https://search.google.com/local/writereview?placeid=${encodeURIComponent(GOOGLE_PLACE_ID)}`

const navigation = {
  company: [
    { name: 'À propos', href: '/about' },
    { name: 'Équipe', href: '/team' },
    { name: 'Carrières', href: '/careers' },
  ],
  products: [
    { name: 'App Client', href: '/apps' },
    { name: 'App Partner', href: '/apps' },
    { name: 'Télécharger', href: '/apps' },
  ],
  support: [
    { name: 'Centre d\'aide', href: '/faq' },
    { name: 'Contact', href: '/contact' },
    { name: 'Support', href: 'mailto:contact@chapechaperesidence.com' },
  ],
  legal: [
    { name: 'Politique de Confidentialité', href: '/politique-de-confidentialite' },
    { name: 'Conditions d\'utilisation', href: '/conditions' },
    { name: 'Politique de cookies', href: '/cookies' },
    { name: 'Suppression du compte', href: '/suppression-compte' },
  ],
  social: [
    {
      name: 'Facebook',
      href: 'https://www.facebook.com/share/16DerPURN9/',
      icon: (props: any) => (
        <svg fill="currentColor" viewBox="0 0 24 24" {...props}>
          <path
            fillRule="evenodd"
            d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.988C18.343 21.128 22 16.991 22 12z"
            clipRule="evenodd"
          />
        </svg>
      ),
    },
    {
      name: 'Instagram',
      href: 'https://www.instagram.com/chapechaperesidence?igsh=MWJuZXNva3NrMHU4eg==',
      icon: (props: any) => (
        <svg fill="currentColor" viewBox="0 0 24 24" {...props}>
          <path
            fillRule="evenodd"
            d="M12.315 2c2.43 0 2.784.013 3.808.06 1.064.049 1.791.218 2.427.465a4.902 4.902 0 011.772 1.153 4.902 4.902 0 011.153 1.772c.247.636.416 1.363.465 2.427.048 1.067.06 1.407.06 4.123v.08c0 2.643-.012 2.987-.06 4.043-.049 1.064-.218 1.791-.465 2.427a4.902 4.902 0 01-1.153 1.772 4.902 4.902 0 01-1.772 1.153c-.636.247-1.363.416-2.427.465-1.067.048-1.407.06-4.123.06h-.08c-2.643 0-2.987-.012-4.043-.06-1.064-.049-1.791-.218-2.427-.465a4.902 4.902 0 01-1.772-1.153 4.902 4.902 0 01-1.153-1.772c-.247-.636-.416-1.363-.465-2.427-.047-1.024-.06-1.379-.06-3.808v-.63c0-2.43.013-2.784.06-3.808.049-1.064.218-1.791.465-2.427a4.902 4.902 0 011.153-1.772A4.902 4.902 0 015.45 2.525c.636-.247 1.363-.416 2.427-.465C8.901 2.013 9.256 2 11.685 2h.63zm-.081 1.802h-.468c-2.456 0-2.784.011-3.807.058-.975.045-1.504.207-1.857.344-.467.182-.8.398-1.15.748-.35.35-.566.683-.748 1.15-.137.353-.3.882-.344 1.857-.047 1.023-.058 1.351-.058 3.807v.468c0 2.456.011 2.784.058 3.807.045.975.207 1.504.344 1.857.182.466.399.8.748 1.15.35.35.683.566 1.15.748.353.137.882.3 1.857.344 1.054.048 1.37.058 4.041.058h.08c2.597 0 2.917-.01 3.96-.058.976-.045 1.505-.207 1.858-.344.466-.182.8-.398 1.15-.748.35-.35.566-.683.748-1.15.137-.353.3-.882.344-1.857.048-1.055.058-1.37.058-4.041v-.08c0-2.597-.01-2.917-.058-3.96-.045-.976-.207-1.505-.344-1.858a3.097 3.097 0 00-.748-1.15 3.098 3.098 0 00-1.15-.748c-.353-.137-.882-.3-1.857-.344-1.023-.047-1.351-.058-3.807-.058zM12 6.865a5.135 5.135 0 110 10.27 5.135 5.135 0 010-10.27zm0 1.802a3.333 3.333 0 100 6.666 3.333 3.333 0 000-6.666zm5.338-3.205a1.2 1.2 0 110 2.4 1.2 1.2 0 010-2.4z"
            clipRule="evenodd"
          />
        </svg>
      ),
    },
    {
      name: 'LinkedIn',
      href: 'https://www.linkedin.com/company/chapechaperesidence/',
      icon: (props: any) => (
        <svg fill="currentColor" viewBox="0 0 24 24" {...props}>
          <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" />
        </svg>
      ),
    },
    {
      name: 'TikTok',
      href: 'https://www.tiktok.com/@chapechape.reside?_t=ZM-8wUYljxZXeQ&_r=1',
      icon: (props: any) => (
        <svg fill="currentColor" viewBox="0 0 24 24" {...props}>
          <path d="M19.59 6.69a4.83 4.83 0 01-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 01-5.2 1.74 2.89 2.89 0 012.31-4.64 2.93 2.93 0 01.88.13V9.4a6.84 6.84 0 00-1-.05A6.33 6.33 0 005 20.1a6.34 6.34 0 0010.86-4.43v-7a8.16 8.16 0 004.77 1.52v-3.4a4.85 4.85 0 01-1-.1z" />
        </svg>
      ),
    },
  ],
}

export default function Footer() {
  const preFooterRef = useRef<HTMLDivElement | null>(null)
  const mouseX = useMotionValue(0)
  const mouseY = useMotionValue(0)
  const springX = useSpring(mouseX, { stiffness: 120, damping: 18, mass: 0.4 })
  const springY = useSpring(mouseY, { stiffness: 120, damping: 18, mass: 0.4 })

  const stackShiftX = useTransform(springX, [-0.5, 0.5], [-18, 18])
  const stackShiftY = useTransform(springY, [-0.5, 0.5], [-12, 12])
  const stackRotate = useTransform(springX, [-0.5, 0.5], [-2.5, 2.5])

  const handlePreFooterMouseMove = (event: React.MouseEvent<HTMLDivElement>) => {
    const bounds = preFooterRef.current?.getBoundingClientRect()
    if (!bounds) return

    // Normalise la position du curseur autour du centre du bloc
    const normalizedX = (event.clientX - bounds.left) / bounds.width - 0.5
    const normalizedY = (event.clientY - bounds.top) / bounds.height - 0.5
    mouseX.set(normalizedX)
    mouseY.set(normalizedY)
  }

  const resetPreFooterMouse = () => {
    mouseX.set(0)
    mouseY.set(0)
  }

  return (
    <footer className="bg-secondary-900">
      <div className="mx-auto max-w-7xl px-6 pt-12 pb-10 md:pt-16 lg:px-8">
        {/* Pre-footer CTA */}
        <div
          ref={preFooterRef}
          onMouseMove={handlePreFooterMouseMove}
          onMouseLeave={resetPreFooterMouse}
          className="relative overflow-hidden rounded-3xl border border-primary-300/20 bg-gradient-to-br from-secondary-800 to-secondary-900 p-8 md:p-10 shadow-xl mb-12"
        >
          {/* Pile d'images animée au survol (desktop/tablette) */}
          <motion.div
            aria-hidden
            style={{
              x: stackShiftX,
              y: stackShiftY,
              rotate: stackRotate,
            }}
            className="hidden md:block pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 z-0 opacity-70 w-[320px] h-[220px]"
          >
            <img
              src="/assets/residences/meuble.png"
              alt=""
              className="absolute w-40 h-28 object-cover rounded-xl border border-primary-200/20 shadow-xl left-0 top-2 rotate-[-9deg]"
            />
            <img
              src="/assets/residences/hotel.png"
              alt=""
              className="absolute w-44 h-28 object-cover rounded-xl border border-primary-200/20 shadow-xl left-20 top-10 rotate-[6deg]"
            />
            <img
              src="/assets/residences/longue_duree.png"
              alt=""
              className="absolute w-48 h-32 object-cover rounded-xl border border-primary-200/20 shadow-xl left-12 top-20 rotate-[-4deg]"
            />
          </motion.div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-center">
            <div className="lg:col-span-2 relative z-10">
              <p className="text-xs font-semibold uppercase tracking-widest text-primary-300 mb-3">
                ChapeChape Residence
              </p>
              <h3 className="text-2xl md:text-3xl font-bold text-white leading-tight">
                Trouvez votre residence ideale en quelques clics.
              </h3>
              <p className="mt-3 text-primary-100 max-w-2xl">
                Des logements verifies, des reservations simples et une experience mobile fluide pour locataires et proprietaires.
              </p>
            </div>
            <div className="flex flex-col gap-3 lg:items-end relative z-10">
              <Link
                to="/partenaires"
                className="inline-flex w-full sm:w-auto h-12 justify-center items-center rounded-xl bg-primary-400 text-secondary-900 px-5 text-sm font-semibold hover:bg-primary-300 transition-colors"
              >
                Devenir partenaire
              </Link>
              <Link
                to="/contact?type=devis"
                className="inline-flex w-full sm:w-auto h-12 justify-center items-center rounded-xl border border-primary-300/40 text-primary-200 px-5 text-sm font-semibold hover:bg-secondary-800 transition-colors"
              >
                Demander un devis
              </Link>
            </div>
          </div>
        </div>

        {/* Logo */}
        <div className="mb-10 text-center">
          <Link to="/" aria-label="Retour à l'accueil">
            <img
              src="/assets/logo.png"
              alt="ChapeChape Residence"
              width={140}
              height={48}
              className="h-12 w-auto mx-auto hover:opacity-90 transition-opacity duration-200"
            />
          </Link>
        </div>

        {/* Navigation en 4 colonnes */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-10">
          {/* Société */}
          <div>
            <h3 className="text-xs font-semibold text-primary-300 uppercase tracking-widest mb-4">
              Société
            </h3>
            <ul className="space-y-3">
              {navigation.company.map((item) => (
                <li key={item.name}>
                  <Link 
                    to={item.href} 
                    className="text-sm text-primary-200 hover:text-primary-400 transition-colors duration-200"
                  >
                    {item.name}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Produits */}
          <div>
            <h3 className="text-xs font-semibold text-primary-300 uppercase tracking-widest mb-4">
              Produits
            </h3>
            <ul className="space-y-3">
              {navigation.products.map((item) => (
                <li key={item.name}>
                  <Link 
                    to={item.href} 
                    className="text-sm text-primary-200 hover:text-primary-400 transition-colors duration-200"
                  >
                    {item.name}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Assistance */}
          <div>
            <h3 className="text-xs font-semibold text-primary-300 uppercase tracking-widest mb-4">
              Assistance
            </h3>
            <ul className="space-y-3">
              {navigation.support.map((item) => (
                <li key={item.name}>
                  {item.href.startsWith('mailto:') ? (
                    <a 
                      href={item.href}
                      className="text-sm text-primary-200 hover:text-primary-400 transition-colors duration-200"
                    >
                      {item.name}
                    </a>
                  ) : (
                    <Link 
                      to={item.href} 
                      className="text-sm text-primary-200 hover:text-primary-400 transition-colors duration-200"
                    >
                      {item.name}
                    </Link>
                  )}
                </li>
              ))}
            </ul>
          </div>

          {/* Légal & données */}
          <div>
            <h3 className="text-xs font-semibold text-primary-300 uppercase tracking-widest mb-4">
              Légal & données
            </h3>
            <ul className="space-y-3">
              {navigation.legal.map((item) => (
                <li key={item.name}>
                  <Link 
                    to={item.href} 
                    className="text-sm text-primary-200 hover:text-primary-400 transition-colors duration-200"
                  >
                    {item.name}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Google Avis + Réseaux sociaux */}
        <div className="border-t border-primary-300/10 pt-6">
          <div className="flex flex-col md:flex-row md:justify-between items-center gap-6">

            {/* Copyright */}
            <p className="text-xs text-primary-200 order-3 md:order-1">
              &copy; {new Date().getFullYear()} ChapeChape Residence. Tous droits réservés.
            </p>

            {/* Badge Google Avis */}
            <a
              href={GOOGLE_WRITE_REVIEW_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="order-1 md:order-2 flex items-center gap-3 bg-white/5 border border-white/10 rounded-2xl px-5 py-3 hover:bg-white/10 transition-colors duration-200 group"
            >
              {/* Logo Google */}
              <svg className="w-5 h-5 shrink-0" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
              </svg>
              <div>
                <p className="text-[10px] font-bold text-white/50 uppercase tracking-widest font-body leading-none mb-1">Avis Google</p>
                <div className="flex items-center gap-1.5">
                  {/* Étoiles */}
                  <div className="flex gap-0.5">
                    {[1,2,3,4].map(i => (
                      <svg key={i} className="w-3.5 h-3.5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                      </svg>
                    ))}
                    {/* Demi étoile */}
                    <svg className="w-3.5 h-3.5" viewBox="0 0 20 20">
                      <defs><linearGradient id="half"><stop offset="70%" stopColor="#FACC15"/><stop offset="70%" stopColor="#6B7280"/></linearGradient></defs>
                      <path fill="url(#half)" d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                    </svg>
                  </div>
                  <span className="text-sm font-bold text-white font-body">4,7</span>
                  <span className="text-[10px] text-white/40 font-body">(10 avis)</span>
                </div>
              </div>
              <span className="ml-1 text-[10px] text-primary-400 font-bold font-body group-hover:underline whitespace-nowrap">
                Laisser un avis →
              </span>
            </a>

            {/* Réseaux sociaux */}
            <div className="flex space-x-6 order-2 md:order-3">
              {navigation.social.map((item) => (
                <a
                  key={item.name}
                  href={item.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-primary-300 hover:text-primary-400 transition-all duration-300 hover:scale-110"
                >
                  <span className="sr-only">{item.name}</span>
                  <item.icon className="h-5 w-5" aria-hidden="true" />
                </a>
              ))}
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
} 