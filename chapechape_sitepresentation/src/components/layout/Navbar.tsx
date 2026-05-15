import { useState, useEffect } from 'react'
import { createPortal } from 'react-dom'
import { Link } from 'react-router-dom'
import { Bars3Icon, XMarkIcon, ChevronDownIcon } from '@heroicons/react/24/outline'
import ThemeToggle from '../ui/ThemeToggle'

const navigation = [
  { name: 'Accueil', href: '/' },
  { name: 'Résidences', href: '/residences' },
  { name: 'Services', href: '/services' },
  {
    name: 'À propos',
    href: '/about',
    submenu: [
      { name: 'Notre vision', href: '/about' },
      { name: 'Équipe', href: '/team' },
      { name: 'Partenaires', href: '/partners' },
    ]
  },
  { name: 'Applications', href: '/apps' },
  {
    name: 'Ressources',
    href: '/resources',
    submenu: [
      { name: 'Blog', href: '/blog' },
      { name: 'Témoignages', href: '/testimonials' },
      { name: 'FAQ', href: '/faq' },
    ]
  },
  { name: 'Contact', href: '/contact' },
  { name: 'Partenaires', href: '/partenaires', highlight: true },
]

const partnerIcon = (
  <svg className="h-5 w-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5} aria-hidden>
    <path strokeLinecap="round" strokeLinejoin="round" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
  </svg>
)

type NavItem = (typeof navigation)[number] & { highlight?: boolean }

export default function Navbar() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const [openSubMenus, setOpenSubMenus] = useState<string[]>([])
  const [expandedDesktopMenu, setExpandedDesktopMenu] = useState<string | null>(null)

  const closeMobileMenu = () => {
    setMobileMenuOpen(false)
    setOpenSubMenus([])
  }

  useEffect(() => {
    const onEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        closeMobileMenu()
        setExpandedDesktopMenu(null)
      }
    }

    window.addEventListener('keydown', onEscape)
    return () => window.removeEventListener('keydown', onEscape)
  }, [])

  useEffect(() => {
    if (!mobileMenuOpen) return
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.body.style.overflow = previousOverflow
    }
  }, [mobileMenuOpen])

  const toggleSubMenu = (name: string) => {
    setOpenSubMenus(prev =>
      prev.includes(name)
        ? prev.filter(item => item !== name)
        : [...prev, name]
    )
  }

  const mobileNavItems = navigation.filter((item) => !(item as NavItem).highlight)

  return (
    <header className="bg-secondary-900/95 backdrop-blur-xl border-b border-secondary-800 shadow-sm sticky top-0 z-50">
      <nav className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3 lg:px-8" aria-label="Global">
        <div className="flex lg:flex-1">
          <Link to="/" className="-m-1.5 p-1.5 group inline-flex items-center" aria-label="Retour à l'accueil ChapeChape Residence">
            <img
              src="/assets/logo.png"
              alt="ChapeChape Residence"
              width={120}
              height={40}
              className="h-10 w-auto max-w-[8.5rem] object-contain transition-transform duration-200 group-hover:scale-105"
            />
          </Link>
        </div>

        <div className="flex items-center gap-2 lg:hidden">
          <ThemeToggle />
          <button
            type="button"
            className="inline-flex h-11 w-11 items-center justify-center rounded-xl text-primary-300 transition-colors hover:bg-secondary-800 hover:text-primary-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500"
            onClick={() => setMobileMenuOpen(true)}
          >
            <span className="sr-only">Ouvrir le menu principal</span>
            <Bars3Icon className="h-6 w-6 stroke-[2]" aria-hidden="true" />
          </button>
        </div>

        <div className="hidden lg:flex lg:items-center lg:gap-x-2">
          {navigation.map((item) => (
            item.submenu ? (
              <div
                key={item.name}
                className="relative group"
                onMouseEnter={() => setExpandedDesktopMenu(item.name)}
                onMouseLeave={() => setExpandedDesktopMenu(null)}
              >
                <button
                  type="button"
                  className="flex items-center gap-x-1 text-sm font-medium leading-6 text-primary-300 hover:text-primary-400 transition-all duration-200 px-3 py-2 rounded-lg hover:bg-secondary-800 cursor-pointer"
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault()
                      const firstLink = e.currentTarget.nextElementSibling?.querySelector('a')
                      if (firstLink instanceof HTMLElement) {
                        firstLink.focus()
                      }
                    }
                  }}
                  aria-haspopup="true"
                >
                  {item.name}
                  <ChevronDownIcon className="h-4 w-4 transition-transform duration-200 text-primary-400 group-hover:rotate-180 group-hover:text-primary-300" />
                </button>

                <div className="absolute left-1/2 -translate-x-1/2 z-10 mt-3 w-screen max-w-2xl px-4 opacity-0 invisible group-hover:opacity-100 group-hover:visible group-focus-within:opacity-100 group-focus-within:visible transition-all duration-200 ease-out">
                  <div className="overflow-hidden rounded-2xl bg-white/95 backdrop-blur-md shadow-2xl ring-1 ring-gray-200 border border-gray-100">
                    <div className="grid grid-cols-3 gap-0">
                      <div className="col-span-2 p-5">
                        <p className="text-xs font-semibold uppercase tracking-widest text-secondary-500 mb-3">
                          Explorer {item.name.toLowerCase()}
                        </p>
                        <div className="grid grid-cols-2 gap-2">
                          {item.submenu.map((subItem, index) => (
                            <Link
                              key={subItem.name}
                              to={subItem.href}
                              className="flex items-center rounded-xl px-4 py-3 text-sm font-medium text-gray-700 hover:text-primary-600 hover:bg-gradient-to-r hover:from-primary-50 hover:to-secondary-50 transition-all duration-200 group/item"
                              style={{ animationDelay: `${index * 40}ms` }}
                            >
                              <span className="group-hover/item:translate-x-1 transition-transform duration-200">
                                {subItem.name}
                              </span>
                            </Link>
                          ))}
                        </div>
                      </div>
                      <div className="border-l border-gray-100 bg-gradient-to-b from-secondary-900 to-secondary-800 p-5">
                        <p className="text-xs font-semibold uppercase tracking-widest text-primary-300 mb-3">
                          ChapeChape
                        </p>
                        <p className="text-sm text-primary-100 leading-relaxed">
                          Trouvez rapidement la section qui vous intéresse et avancez vers votre prochaine réservation.
                        </p>
                        <Link
                          to="/contact"
                          className="inline-flex mt-4 text-sm font-semibold text-primary-300 hover:text-primary-200"
                        >
                          Nous contacter →
                        </Link>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ) : (item as NavItem).highlight ? (
              <Link
                key={item.name}
                to={item.href}
                className="inline-flex items-center gap-1.5 text-sm font-semibold leading-6 text-secondary-900 bg-primary-400 hover:bg-primary-300 transition-all duration-200 px-4 py-2 rounded-lg"
              >
                {partnerIcon}
                {item.name}
              </Link>
            ) : (
              <Link
                key={item.name}
                to={item.href}
                className="text-sm font-medium leading-6 text-primary-300 hover:text-primary-400 transition-all duration-200 px-3 py-2 rounded-lg hover:bg-secondary-800 relative group"
              >
                {item.name}
                <span className="absolute inset-x-0 -bottom-px h-px bg-gradient-to-r from-primary-500 to-secondary-500 transform scale-x-0 group-hover:scale-x-100 transition-transform duration-200" />
              </Link>
            )
          ))}
        </div>

        <div className="hidden lg:flex lg:items-center lg:gap-x-3 lg:ml-6">
          <ThemeToggle />
          <Link
            to="/apps"
            className="inline-flex items-center rounded-xl bg-primary-400 text-secondary-900 px-4 py-2 text-sm font-semibold hover:bg-primary-300 transition-colors"
          >
            Télécharger l&apos;appli
          </Link>
        </div>
      </nav>

      {mobileMenuOpen && createPortal(
        <div className="lg:hidden fixed inset-0 z-[100]" role="presentation">
          <div
            className="fixed inset-0 z-0 bg-black/60 backdrop-blur-sm"
            aria-hidden="true"
            onClick={closeMobileMenu}
          />
          <div
            className="fixed inset-y-0 right-0 z-10 flex w-full max-w-sm flex-col bg-secondary-900 shadow-2xl ring-1 ring-primary-300/20"
            role="dialog"
            aria-modal="true"
            aria-label="Menu principal"
          >
            <div className="flex w-full min-w-0 shrink-0 items-center justify-between gap-3 border-b border-primary-300/15 px-5 py-4 pt-[max(1rem,env(safe-area-inset-top))]">
              <Link
                to="/"
                onClick={closeMobileMenu}
                className="min-w-0 shrink overflow-hidden rounded-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500"
                aria-label="Retour à l'accueil ChapeChape Residence"
              >
                <img
                  src="/assets/logo.png"
                  alt=""
                  width={120}
                  height={40}
                  className="h-9 w-auto max-w-[8.5rem] object-contain object-left"
                />
              </Link>
              <div className="flex shrink-0 items-center gap-2">
                <ThemeToggle />
                <button
                  type="button"
                  className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-primary-400/50 bg-secondary-800 text-primary-300 shadow-sm transition-colors hover:border-primary-300 hover:bg-secondary-700 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500"
                  onClick={closeMobileMenu}
                >
                  <span className="sr-only">Fermer le menu</span>
                  <XMarkIcon className="h-7 w-7 stroke-[2.5] text-primary-300" aria-hidden="true" />
                </button>
              </div>
            </div>

            <nav
              className="min-h-0 flex-1 overflow-y-auto overflow-x-hidden overscroll-contain px-5 py-4"
              aria-label="Navigation mobile"
            >
              <p className="mb-3 text-xs font-semibold uppercase tracking-widest text-primary-500/90">
                Navigation
              </p>
              <ul className="space-y-1">
                {mobileNavItems.map((item) => {
                  const isSubMenuOpen = item.submenu ? openSubMenus.includes(item.name) : false
                  return (
                  <li key={item.name}>
                    {item.submenu ? (
                      <>
                        <button
                          type="button"
                          className="flex w-full min-w-0 items-center justify-between gap-3 rounded-xl px-4 py-3.5 text-left text-base font-medium text-primary-300 transition-colors hover:bg-secondary-800 hover:text-primary-200"
                          onClick={() => toggleSubMenu(item.name)}
                          {...(isSubMenuOpen
                            ? { 'aria-expanded': 'true' as const }
                            : { 'aria-expanded': 'false' as const })}
                          aria-controls={`submenu-${item.name}`}
                        >
                          <span className="min-w-0 truncate">{item.name}</span>
                          <ChevronDownIcon
                            className={`h-5 w-5 shrink-0 text-primary-400 transition-transform duration-200 ${isSubMenuOpen ? 'rotate-180' : ''}`}
                            aria-hidden="true"
                          />
                        </button>
                        {isSubMenuOpen && (
                          <ul
                            id={`submenu-${item.name}`}
                            className="mb-1 ml-2 mt-1 space-y-0.5 border-l border-primary-300/25 pl-3 animate-fadeIn"
                          >
                            {item.submenu.map((subItem) => (
                              <li key={subItem.name}>
                                <Link
                                  to={subItem.href}
                                  className="block rounded-lg px-3 py-2.5 text-sm font-medium text-primary-200 transition-colors hover:bg-secondary-800 hover:text-primary-300"
                                  onClick={closeMobileMenu}
                                >
                                  {subItem.name}
                                </Link>
                              </li>
                            ))}
                          </ul>
                        )}
                      </>
                    ) : (
                      <Link
                        to={item.href}
                        className="block rounded-xl px-4 py-3.5 text-base font-medium text-primary-300 transition-colors hover:bg-secondary-800 hover:text-primary-200"
                        onClick={closeMobileMenu}
                      >
                        {item.name}
                      </Link>
                    )}
                  </li>
                )})}
              </ul>
            </nav>

            <div className="shrink-0 space-y-3 border-t border-primary-300/15 bg-secondary-900 px-5 py-4 pb-[max(1rem,env(safe-area-inset-bottom))]">
              <Link
                to="/partenaires"
                onClick={closeMobileMenu}
                className="flex w-full min-h-11 items-center justify-center gap-2 rounded-xl border border-primary-400/40 bg-primary-400/15 px-4 py-3 text-sm font-semibold text-primary-200 transition-colors hover:bg-primary-400/25 hover:text-primary-100"
              >
                {partnerIcon}
                Espace partenaires
              </Link>
              <Link
                to="/apps"
                onClick={closeMobileMenu}
                className="flex w-full min-h-11 items-center justify-center rounded-xl bg-primary-400 px-4 py-3 text-sm font-semibold text-secondary-900 shadow-gold transition-colors hover:bg-primary-300"
              >
                Télécharger l&apos;application
              </Link>
            </div>
          </div>
        </div>,
        document.body
      )}
    </header>
  )
}
