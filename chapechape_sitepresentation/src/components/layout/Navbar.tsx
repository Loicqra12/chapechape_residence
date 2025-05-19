import { useState, Fragment } from 'react'
import { Link } from 'react-router-dom'
import { Bars3Icon, XMarkIcon, ChevronDownIcon } from '@heroicons/react/24/outline'
import { Popover, Transition } from '@headlessui/react'

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

  const toggleSubMenu = (name: string) => {
    setOpenSubMenus(prev => 
      prev.includes(name) 
        ? prev.filter(item => item !== name) 
        : [...prev, name]
    )
  }

  return (
    <header className="bg-secondary-900 shadow-md">
      <nav className="mx-auto flex max-w-7xl items-center justify-between p-4 lg:px-8" aria-label="Global">
        <div className="flex lg:flex-1">
          <Link to="/" className="-m-1.5 p-1.5">
            <img 
              src="/assets/logo.png" 
              alt="ChapeChape Residence" 
              className="h-12 w-auto" 
            />
          </Link>
        </div>
        <div className="flex lg:hidden">
          <button
            type="button"
            className="-m-2.5 inline-flex items-center justify-center rounded-md p-2.5 text-primary-300"
            onClick={() => setMobileMenuOpen(true)}
          >
            <span className="sr-only">Ouvrir le menu principal</span>
            <Bars3Icon className="h-6 w-6" aria-hidden="true" />
          </button>
        </div>
        <div className="hidden lg:flex lg:gap-x-8">
          {navigation.map((item) => (
            item.submenu ? (
              <Popover key={item.name} className="relative">
                {({ open }) => (
                  <>
                    <Popover.Button
                      className={`flex items-center gap-x-1 text-sm font-semibold leading-6 text-primary-300 hover:text-primary-400 transition-colors duration-200 focus:outline-none ${open ? 'text-primary-400' : ''}`}
                    >
                      {item.name}
                      <ChevronDownIcon className={`h-4 w-4 transition ${open ? 'rotate-180 text-primary-400' : 'text-primary-300'}`} />
                    </Popover.Button>
                    <Transition
                      as={Fragment}
                      enter="transition ease-out duration-200"
                      enterFrom="opacity-0 translate-y-1"
                      enterTo="opacity-100 translate-y-0"
                      leave="transition ease-in duration-150"
                      leaveFrom="opacity-100 translate-y-0"
                      leaveTo="opacity-0 translate-y-1"
                    >
                      <Popover.Panel className="absolute z-10 mt-3 w-screen max-w-md transform px-4 sm:px-0 lg:max-w-xs">
                        <div className="overflow-hidden rounded-lg shadow-lg ring-1 ring-black ring-opacity-5">
                          <div className="relative grid gap-1 bg-secondary-800 p-3">
                            {item.submenu.map((subItem) => (
                              <Link
                                key={subItem.name}
                                to={subItem.href}
                                className="flex items-center rounded-lg p-2 text-sm font-medium text-primary-300 hover:bg-secondary-700 transition-colors duration-200"
                              >
                                {subItem.name}
                              </Link>
                            ))}
                          </div>
                        </div>
                      </Popover.Panel>
                    </Transition>
                  </>
                )}
              </Popover>
            ) : (
              <Link
                key={item.name}
                to={item.href}
                className="text-sm font-semibold leading-6 text-primary-300 hover:text-primary-400 transition-colors duration-200"
              >
                {item.name}
              </Link>
            )
          ))}
        </div>
      </nav>
      {/* Mobile menu */}
      <div className={`lg:hidden ${mobileMenuOpen ? 'fixed inset-0 z-50' : 'hidden'}`}>
        <div className="fixed inset-0 bg-secondary-900/80" onClick={() => setMobileMenuOpen(false)} />
        <div className="fixed inset-y-0 right-0 z-50 w-full overflow-y-auto bg-secondary-900 px-6 py-6 sm:max-w-sm sm:ring-1 sm:ring-primary-300/10">
          <div className="flex items-center justify-between">
            <Link to="/" className="-m-1.5 p-1.5">
              <img 
                src="/assets/logo.png" 
                alt="ChapeChape Residence" 
                className="h-12 w-auto" 
              />
            </Link>
            <button
              type="button"
              className="-m-2.5 rounded-md p-2.5 text-primary-300"
              onClick={() => setMobileMenuOpen(false)}
            >
              <span className="sr-only">Fermer le menu</span>
              <XMarkIcon className="h-6 w-6" aria-hidden="true" />
            </button>
          </div>
          <div className="mt-6 flow-root">
            <div className="-my-6 divide-y divide-primary-300/10">
              <div className="space-y-2 py-6">
                {navigation.map((item) => (
                  <Fragment key={item.name}>
                    {item.submenu ? (
                      <>
                        <div 
                          className="flex items-center justify-between -mx-3 rounded-lg px-3 py-2 text-base font-semibold leading-7 text-primary-300 hover:bg-secondary-800/50 cursor-pointer"
                          onClick={() => toggleSubMenu(item.name)}
                        >
                          <span>{item.name}</span>
                          <ChevronDownIcon
                            className={`h-5 w-5 text-primary-300 transition-transform duration-200 ${openSubMenus.includes(item.name) ? 'rotate-180' : ''}`}
                            aria-hidden="true"
                          />
                        </div>
                        {openSubMenus.includes(item.name) && (
                          <div className="ml-4 mt-1 space-y-1 animate-fadeIn">
                            {item.submenu.map((subItem) => (
                              <Link
                                key={subItem.name}
                                to={subItem.href}
                                className="block rounded-lg py-2 pl-2 pr-3 text-sm font-medium text-primary-200 hover:bg-secondary-800 hover:text-primary-400"
                                onClick={() => setMobileMenuOpen(false)}
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
                        className="-mx-3 block rounded-lg px-3 py-2 text-base font-semibold leading-7 text-primary-300 hover:bg-secondary-800 hover:text-primary-400"
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
      </div>
    </header>
  )
} 