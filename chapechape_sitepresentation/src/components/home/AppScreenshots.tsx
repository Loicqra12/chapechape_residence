import { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence, useScroll, useTransform } from 'framer-motion';

// SVG Icons
const IconSearch = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-5 h-5 text-primary-600">
    <circle cx="11" cy="11" r="7" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
    <line x1="9" y1="11" x2="13" y2="11" /><line x1="11" y1="9" x2="11" y2="13" />
  </svg>
);
const IconPayment = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-5 h-5 text-primary-600">
    <rect x="2" y="5" width="20" height="14" rx="3" /><line x1="2" y1="10" x2="22" y2="10" />
    <line x1="6" y1="15" x2="10" y2="15" />
  </svg>
);
const IconCalendar = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-5 h-5 text-primary-600">
    <rect x="3" y="4" width="18" height="18" rx="2" /><line x1="16" y1="2" x2="16" y2="6" />
    <line x1="8" y1="2" x2="8" y2="6" /><line x1="3" y1="10" x2="21" y2="10" />
    <rect x="8" y="14" width="2" height="2" fill="currentColor" strokeWidth="0" /><rect x="14" y="14" width="2" height="2" fill="currentColor" strokeWidth="0" />
  </svg>
);
const IconDashboard = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-5 h-5 text-secondary-700">
    <rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" />
    <rect x="3" y="14" width="7" height="7" rx="1" /><rect x="14" y="14" width="7" height="7" rx="1" />
  </svg>
);
const IconChat = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-5 h-5 text-secondary-700">
    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
    <line x1="9" y1="10" x2="15" y2="10" /><line x1="9" y1="14" x2="13" y2="14" />
  </svg>
);
const IconStats = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-5 h-5 text-secondary-700">
    <polyline points="22 7 13.5 15.5 8.5 10.5 2 17" />
    <polyline points="16 7 22 7 22 13" />
  </svg>
);

const clientAndroid = (import.meta as any).env?.VITE_CLIENT_ANDROID_URL || '#'
const clientIos = (import.meta as any).env?.VITE_CLIENT_IOS_URL || '#'
const partnerAndroid = (import.meta as any).env?.VITE_PARTNER_ANDROID_URL || '#'
const partnerIos = (import.meta as any).env?.VITE_PARTNER_IOS_URL || '#'

// Configuration des applications
const apps = [
  {
    id: 'client',
    name: 'Pour les Locataires',
    title: 'Trouvez votre résidence idéale',
    description: 'Une expérience de recherche fluide et intuitive. Réservez votre prochain séjour en quelques clics.',
    features: [
      { Icon: IconSearch, title: 'Recherche Intelligente', text: 'Filtres avancés par prix, localisation et équipements' },
      { Icon: IconPayment, title: 'Paiement Sécurisé', text: 'Transactions cryptées et multiples moyens de paiement' },
      { Icon: IconCalendar, title: 'Gestion Simplifiée', text: 'Suivez vos réservations et historiques en temps réel' }
    ],
    color: 'from-primary-500 to-secondary-500',
    accent: 'text-primary-600',
    bgGradient: 'from-primary-50/50 via-white to-secondary-50/30',
    screenshots: [
      '/assets/apps/client/client-01.jpg',
      '/assets/apps/client/client-02.jpg',
      '/assets/apps/client/client-03.jpg'
    ]
  },
  {
    id: 'partner',
    name: 'Pour les Propriétaires',
    title: 'Gérez vos biens en toute sérénité',
    description: 'Un tableau de bord complet pour maximiser vos revenus et gérer vos locations sans effort.',
    features: [
      { Icon: IconDashboard, title: 'Dashboard Complet', text: 'Vue d\'ensemble de vos performances et revenus' },
      { Icon: IconChat, title: 'Messagerie Directe', text: 'Communiquez facilement avec vos locataires' },
      { Icon: IconStats, title: 'Statistiques Détaillées', text: 'Analysez vos taux d\'occupation et revenus' }
    ],
    color: 'from-secondary-800 to-secondary-900',
    accent: 'text-secondary-800',
    bgGradient: 'from-secondary-50 via-white to-primary-50/30',
    screenshots: [
      '/assets/apps/partner/partner-01.jpg',
      '/assets/apps/partner/partner-02.jpg',
      '/assets/apps/partner/partner-03.jpg'
    ]
  }
];

const AppScreenshots: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0);
  const [currentScreenshot, setCurrentScreenshot] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);

  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"]
  });

  const y = useTransform(scrollYProgress, [0, 1], [100, -100]);
  const opacity = useTransform(scrollYProgress, [0, 0.2, 0.8, 1], [0, 1, 1, 0]);

  // Rotation automatique des screenshots
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentScreenshot((prev) => (prev + 1) % apps[activeTab].screenshots.length);
    }, 4000);
    return () => clearInterval(interval);
  }, [activeTab]);

  // Reset screenshot index on tab change
  useEffect(() => {
    setCurrentScreenshot(0);
  }, [activeTab]);

  const activeApp = apps[activeTab];

  return (
    <section ref={containerRef} className="relative py-32 overflow-hidden">
      {/* Background dynamique */}
      <motion.div
        className={`absolute inset-0 bg-gradient-to-br ${activeApp.bgGradient} transition-colors duration-1000`}
      />

      {/* Motif de fond */}
      <div className="absolute inset-0 opacity-[0.03] bg-[radial-gradient(#D4AF37_1px,transparent_1px)] [background-size:20px_20px]" />

      <div className="mx-auto max-w-7xl px-6 lg:px-8 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">

          {/* Colonne Texte */}
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
          >
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white shadow-sm border border-primary-100 mb-8">
              <span className="w-2 h-2 rounded-full bg-primary-500 animate-pulse" />
              <span className="text-xs font-bold tracking-widest uppercase text-secondary-600">Disponible sur iOS et Android</span>
            </div>

            <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold text-secondary-900 mb-6 font-display leading-tight">
              L'immobilier <br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-500 to-secondary-600">
                au bout des doigts
              </span>
            </h2>

            {/* Tabs Switcher */}
            <div className="flex flex-wrap gap-1 p-1 bg-secondary-100/50 rounded-full w-fit mb-10 backdrop-blur-sm border border-secondary-200/50">
              {apps.map((app, index) => (
                <button
                  key={app.id}
                  onClick={() => setActiveTab(index)}
                  className={`px-6 py-3 rounded-full text-sm font-semibold transition-all duration-300 ${activeTab === index
                      ? 'bg-white text-secondary-900 shadow-md scale-105'
                      : 'text-secondary-500 hover:text-secondary-700'
                    }`}
                >
                  {app.name}
                </button>
              ))}
            </div>

            <AnimatePresence mode="wait">
              <motion.div
                key={activeApp.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
                transition={{ duration: 0.5 }}
              >
                <h3 className="text-2xl font-bold text-secondary-800 mb-4 font-display">
                  {activeApp.title}
                </h3>
                <p className="text-lg text-secondary-600 mb-10 leading-relaxed max-w-lg">
                  {activeApp.description}
                </p>

                <div className="space-y-6 mb-12">
                  {activeApp.features.map((feature, idx) => (
                    <motion.div
                      key={idx}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: idx * 0.1 + 0.3 }}
                      className="flex items-start gap-4 group"
                    >
                      <div className="w-12 h-12 rounded-2xl flex items-center justify-center bg-white shadow-md border border-primary-100 group-hover:scale-110 transition-transform duration-300 shrink-0">
                        <feature.Icon />
                      </div>
                      <div>
                        <h4 className="font-bold text-secondary-900 mb-1">{feature.title}</h4>
                        <p className="text-sm text-secondary-500">{feature.text}</p>
                      </div>
                    </motion.div>
                  ))}
                </div>

                <div className="flex flex-wrap gap-3">
                  <motion.a
                    whileHover={{ scale: 1.05, y: -2 }} whileTap={{ scale: 0.95 }}
                    href={activeApp.id === 'client' ? clientAndroid : partnerAndroid}
                    target={(activeApp.id === 'client' ? clientAndroid : partnerAndroid) !== '#' ? '_blank' : undefined}
                    rel={(activeApp.id === 'client' ? clientAndroid : partnerAndroid) !== '#' ? 'noopener noreferrer' : undefined}
                    className="inline-block rounded-xl overflow-hidden shadow-lg hover:shadow-xl transition-shadow"
                  >
                    <img src="/assets/googleplay.png" alt="Disponible sur Google Play" className="h-10 w-auto" />
                  </motion.a>
                  <motion.a
                    whileHover={{ scale: 1.05, y: -2 }} whileTap={{ scale: 0.95 }}
                    href={activeApp.id === 'client' ? clientIos : partnerIos}
                    target={(activeApp.id === 'client' ? clientIos : partnerIos) !== '#' ? '_blank' : undefined}
                    rel={(activeApp.id === 'client' ? clientIos : partnerIos) !== '#' ? 'noopener noreferrer' : undefined}
                    className="inline-block rounded-xl overflow-hidden shadow-lg hover:shadow-xl transition-shadow"
                  >
                    <img src="/assets/appstore.png" alt="Télécharger sur l'App Store" className="h-10 w-auto" />
                  </motion.a>
                </div>
              </motion.div>
            </AnimatePresence>
          </motion.div>

          {/* Colonne Téléphone */}
          <motion.div
            style={{ y }}
            className="relative flex justify-center lg:justify-end"
          >
            {/* Cercles décoratifs */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-gradient-to-br from-primary-200/20 to-secondary-200/20 rounded-full blur-3xl -z-10 animate-pulse" />

            {/* Phone Mockup */}
            <div className="relative w-[min(300px,85vw)] h-[600px] bg-secondary-900 rounded-[3rem] border-8 border-secondary-800 shadow-2xl overflow-hidden ring-1 ring-white/20">
              {/* Dynamic Island / Notch */}
              <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-7 bg-black rounded-b-2xl z-20" />

              {/* Screen Content */}
              <div className="absolute inset-0 bg-white overflow-hidden">
                <AnimatePresence mode="wait">
                  <motion.img
                    key={`${activeApp.id}-${currentScreenshot}`}
                    src={activeApp.screenshots[currentScreenshot]}
                    alt="App Screenshot"
                    initial={{ opacity: 0, scale: 1.1 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{ duration: 0.5 }}
                    className="w-full h-full object-cover"
                  />
                </AnimatePresence>

                {/* Gradient Overlay Bottom */}
                <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-black/50 to-transparent pointer-events-none" />
              </div>

              {/* Floating Elements - Notifications */}
              <AnimatePresence>
                {activeTab === 0 && (
                  <motion.div
                    initial={{ opacity: 0, x: 50, y: -20 }}
                    animate={{ opacity: 1, x: 20, y: 100 }}
                    exit={{ opacity: 0, scale: 0.8 }}
                    transition={{ delay: 1, duration: 0.8 }}
                    className="absolute -right-16 top-24 bg-white/90 backdrop-blur-md p-4 rounded-2xl shadow-xl border border-white/50 w-48 z-30 hidden md:block"
                  >
                    <div className="flex items-center gap-3 mb-2">
                      <div className="w-8 h-8 rounded-full bg-green-100 flex items-center justify-center text-green-600">✓</div>
                      <div>
                        <div className="text-xs text-secondary-500">Réservation</div>
                        <div className="text-sm font-bold text-secondary-900">Confirmée</div>
                      </div>
                    </div>
                    <div className="text-xs text-secondary-400">Votre séjour à Abidjan est validé !</div>
                  </motion.div>
                )}

                {activeTab === 1 && (
                  <motion.div
                    initial={{ opacity: 0, x: -50, y: 20 }}
                    animate={{ opacity: 1, x: -20, y: 150 }}
                    exit={{ opacity: 0, scale: 0.8 }}
                    transition={{ delay: 1, duration: 0.8 }}
                    className="absolute -left-16 top-32 bg-white/90 backdrop-blur-md p-4 rounded-2xl shadow-xl border border-white/50 w-48 z-30 hidden md:block"
                  >
                    <div className="flex items-center gap-3 mb-2">
                      <div className="w-8 h-8 rounded-full bg-primary-100 flex items-center justify-center text-primary-600">
                          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="w-4 h-4">
                            <polyline points="22 7 13.5 15.5 8.5 10.5 2 17" /><polyline points="16 7 22 7 22 13" />
                          </svg>
                        </div>
                      <div>
                        <div className="text-xs text-secondary-500">Revenus</div>
                        <div className="text-sm font-bold text-secondary-900">+ 15.4%</div>
                      </div>
                    </div>
                    <div className="w-full bg-secondary-100 h-1.5 rounded-full overflow-hidden">
                      <div className="bg-primary-500 h-full w-[70%]" />
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
};

export default AppScreenshots; 