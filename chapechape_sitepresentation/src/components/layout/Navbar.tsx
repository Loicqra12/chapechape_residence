import { useState, Fragment } from 'react'
import { createPortal } from 'react-dom'
import { Link } from 'react-router-dom'
import { Bars3Icon, XMarkIcon, ChevronDownIcon } from '@heroicons/react/24/outline'
import ThemeToggle from '../ui/ThemeToggle'

const navigation = [
  { name: 'Accueil', href: '/' },
  {
    name: 'Résidences',
    href: '/residences',
    submenu: [
      { name: 'Tous les types', href: '/residences' },
      { name: 'Appartements', href: '/residences/apartments' },
      { name: 'Villas luxueuses', href: '/residences/villas' },
      { name: 'Studios', href: '/residences/studios' },
      { name: 'Duplex & Lofts', href: '/residences/duplex' },
    ]
  },
  {
    name: 'Services',
    href: '/services',
    submenu: [
      { name: 'Pour propriétaires', href: '/services/owners' },
      { name: 'Pour locataires', href: '/services/tenants' },
      { name: 'Gestion locative', href: '/services/management' },
      { name: 'Conciergerie', href: '/services/concierge' },
    ]
  },
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
]

export default function Navbar() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const [openSubMenus, setOpenSubMenus] = useState<string[]>([])
  const [expandedDesktopMenu, setExpandedDesktopMenu] = useState<string | null>(null)

  const toggleSubMenu = (name: string) => {
    setOpenSubMenus(prev =>
      prev.includes(name)
        ? prev.filter(item => item !== name)
        : [...prev, name]
    )
  }

  return (
    <header className="bg-secondary-900/95 backdrop-blur-xl border-b border-secondary-800 shadow-sm sticky top-0 z-50">
      <nav className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3 lg:px-8" aria-label="Global">
        <div className="flex lg:flex-1">
          <Link to="/" className="-m-1.5 p-1.5 group">
            <img
              src="/assets/logo.png"
              alt="ChapeChape Residence"
              className="h-10 w-auto transition-transform duration-200 group-hover:scale-105"
            />
          </Link>
        </div>

        {/* Theme Toggle - Desktop */}
        <div className="hidden lg:flex lg:items-center lg:gap-x-4">
          <ThemeToggle />
        </div>

        <div className="flex lg:hidden">
          <button
            type="button"
            className="-m-2.5 inline-flex items-center justify-center rounded-xl p-2.5 text-primary-300 hover:text-primary-400 hover:bg-secondary-800 transition-all duration-200"
            onClick={() => setMobileMenuOpen(true)}
          >
            <span className="sr-only">Ouvrir le menu principal</span>
            <Bars3Icon className="h-6 w-6" aria-hidden="true" />
          </button>
        </div>
        <div className="hidden lg:flex lg:gap-x-8">
          {navigation.map((item) => {
            const isExpanded = item.submenu ? expandedDesktopMenu === item.name : false
            const ariaExpanded = isExpanded ? 'true' : 'false' as 'true' | 'false'
            return item.submenu ? (
              <div
                key={item.name}
                className="relative group"
                onMouseEnter={() => setExpandedDesktopMenu(item.name)}
                onMouseLeave={() => setExpandedDesktopMenu(null)}
              >
                <button
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
                  {...{ 'aria-expanded': ariaExpanded }}
                >
                  {item.name}
                  <ChevronDownIcon className="h-4 w-4 transition-transform duration-200 text-primary-400 group-hover:rotate-180 group-hover:text-primary-300" />
                </button>

                {/* Dropdown au survol */}
                <div className="absolute z-10 mt-2 w-screen max-w-md transform px-4 sm:px-0 lg:max-w-xs opacity-0 invisible group-hover:opacity-100 group-hover:visible group-focus-within:opacity-100 group-focus-within:visible transition-all duration-200 ease-out">
                  <div className="overflow-hidden rounded-2xl bg-white shadow-xl ring-1 ring-gray-200 border border-gray-100">
                    <div className="relative grid gap-1 p-4">
                      {item.submenu.map((subItem, index) => (
                        <Link
                          key={subItem.name}
                          to={subItem.href}
                          className="flex items-center rounded-xl px-4 py-3 text-sm font-medium text-gray-700 hover:text-primary-600 hover:bg-gradient-to-r hover:from-primary-50 hover:to-secondary-50 transition-all duration-200 group/item"
                          style={{ animationDelay: `${index * 50}ms` }}
                        >
                          <span className="group-hover/item:translate-x-1 transition-transform duration-200">{subItem.name}</span>
                        </Link>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            ) : (
              <Link
                key={item.name}
                to={item.href}
                className="text-sm font-medium leading-6 text-primary-300 hover:text-primary-400 transition-all duration-200 px-3 py-2 rounded-lg hover:bg-secondary-800 relative group"
              >
                {item.name}
                <span className="absolute inset-x-0 -bottom-px h-px bg-gradient-to-r from-primary-500 to-secondary-500 transform scale-x-0 group-hover:scale-x-100 transition-transform duration-200"></span>
              </Link>
            );
          })}
        </div>
      </nav>
      {/* Mobile menu via React Portal */}
      {mobileMenuOpen && createPortal(
        <div className="lg:hidden fixed inset-0" style={{ zIndex: 999999 }}>
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm" onClick={() => setMobileMenuOpen(false)} />
          <div className="fixed inset-y-0 left-0 w-full overflow-y-auto bg-secondary-900 px-6 py-6 sm:max-w-sm border-r border-primary-300/20 shadow-2xl" style={{ zIndex: 999999 }}>
            <div className="flex items-center justify-between">
              <Link to="/" className="-m-1.5 p-1.5">
                <img
                  src="/assets/logo.png"
                  alt="ChapeChape Residence"
                  className="h-10 w-auto"
                />
              </Link>
              <button
                type="button"
                className="-m-2.5 rounded-xl p-2.5 text-primary-300 hover:text-primary-400 hover:bg-secondary-800 transition-all duration-200"
                onClick={() => setMobileMenuOpen(false)}
              >
                <span className="sr-only">Fermer le menu</span>
                <XMarkIcon className="h-6 w-6" aria-hidden="true" />
              </button>
            </div>
            <div className="mt-8 flow-root">
              <div className="-my-6 divide-y divide-primary-300/20">
                <div className="space-y-1 py-6">
                  {navigation.map((item) => (
                    <Fragment key={item.name}>
                      {item.submenu ? (
                        <>
                          <div
                            className="flex items-center justify-between -mx-3 rounded-xl px-4 py-3 text-base font-medium leading-7 text-primary-300 hover:bg-secondary-800 hover:text-primary-400 cursor-pointer transition-all duration-200"
                            onClick={() => toggleSubMenu(item.name)}
                          >
                            <span>{item.name}</span>
                            <ChevronDownIcon
                              className={`h-5 w-5 text-primary-400 transition-transform duration-200 ${openSubMenus.includes(item.name) ? 'rotate-180 text-primary-500' : ''}`}
                              aria-hidden="true"
                            />
                          </div>
                          {openSubMenus.includes(item.name) && (
                            <div className="ml-4 mt-2 space-y-1 animate-fadeIn">
                              {item.submenu.map((subItem, index) => (
                                <Link
                                  key={subItem.name}
                                  to={subItem.href}
                                  className="block rounded-xl py-3 pl-4 pr-3 text-sm font-medium text-primary-200 hover:bg-secondary-800 hover:text-primary-400 transition-all duration-200"
                                  onClick={() => setMobileMenuOpen(false)}
                                  style={{ animationDelay: `${index * 100}ms` }}
                                >
                                  {subItem.name}
                                </Link>
                              ))}
                            </div>
                          )}
                        </>
                      ) : (
                        <Link
                          to={item.href}
                          className="-mx-3 block rounded-xl px-4 py-3 text-base font-medium leading-7 text-primary-300 hover:bg-secondary-800 hover:text-primary-400 transition-all duration-200"
                          onClick={() => setMobileMenuOpen(false)}
                        >
                          {item.name}
                        </Link>
                      )}
                    </Fragment>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>,
        document.body
      )}
    </header>
  )
} 