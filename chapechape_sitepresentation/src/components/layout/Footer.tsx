import { Link } from 'react-router-dom'

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
  return (
    <footer className="bg-secondary-900">
      <div className="mx-auto max-w-7xl px-6 py-12 md:py-16 lg:px-8">
        {/* Logo */}
        <div className="mb-12 text-center">
          <Link to="/" aria-label="Retour à l'accueil">
            <img 
              src="/assets/logo.png" 
              alt="ChapeChape Residence" 
              className="h-12 w-auto mx-auto hover:opacity-90 transition-opacity duration-200"
            />
          </Link>
        </div>

        {/* Navigation en 4 colonnes */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-12">
          {/* Société */}
          <div>
            <h3 className="text-sm font-semibold text-primary-300 uppercase tracking-wider mb-4">
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
            <h3 className="text-sm font-semibold text-primary-300 uppercase tracking-wider mb-4">
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
            <h3 className="text-sm font-semibold text-primary-300 uppercase tracking-wider mb-4">
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
            <h3 className="text-sm font-semibold text-primary-300 uppercase tracking-wider mb-4">
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

        {/* Bandeau bas avec réseaux sociaux */}
        <div className="border-t border-primary-300/10 pt-8">
          <div className="flex flex-col md:flex-row md:justify-between items-center space-y-4 md:space-y-0">
            {/* Copyright */}
            <p className="text-xs text-primary-200">
              &copy; {new Date().getFullYear()} ChapeChape Residence. Tous droits réservés.
            </p>
            
            {/* Réseaux sociaux */}
            <div className="flex space-x-6">
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
            
            {/* Sélecteur langue (placeholder) */}
            <div className="flex items-center space-x-4 text-xs text-primary-200">
              <span>🇫🇷 FR</span>
              <span className="opacity-50">|</span>
              <span className="opacity-50">🇬🇧 EN</span>
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
} 