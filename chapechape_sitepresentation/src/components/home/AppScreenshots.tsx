import { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

// Configuration des applications
const apps = [
  {
    id: 'client',
    name: 'Application Client',
    description: 'Notre application pour les locataires permet de trouver et réserver facilement la résidence idéale pour votre séjour.',
    features: [
      'Recherche avancée de résidences',
      'Réservation en quelques clics',
      'Paiement sécurisé',
      'Messagerie avec les propriétaires',
      'Gestion de vos séjours'
    ],
    color: 'primary', // Couleur dorée pour le client
  },
  {
    id: 'partner',
    name: 'Application Partenaire',
    description: 'Notre application pour les propriétaires offre tous les outils nécessaires pour gérer efficacement vos résidences.',
    features: [
      'Gestion de vos propriétés',
      'Calendrier des réservations',
      'Suivi des revenus',
      'Communication avec les locataires',
      'Statistiques de performance'
    ],
    color: 'secondary', // Couleur foncée pour les partenaires
  }
];

const AppScreenshots: React.FC = () => {
  const [activeApp, setActiveApp] = useState(apps[0]);
  const [screenshots, setScreenshots] = useState<Record<string, string[]>>({ client: [], partner: [] });
  const [currentIndex, setCurrentIndex] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);
  
  // Simuler le chargement des captures d'écran
  useEffect(() => {
    // Dans une application réelle, vous chargeriez dynamiquement les images du dossier
    // Pour cet exemple, nous utilisons des tableaux statiques
    
    // Les images devraient être au format /assets/apps/client/client-01-xx.jpg
    const clientScreenshots = Array.from({ length: 5 }, (_, i) => 
      `/assets/apps/client/client-${String(i + 1).padStart(2, '0')}.jpg`
    );
    
    const partnerScreenshots = Array.from({ length: 5 }, (_, i) => 
      `/assets/apps/partner/partner-${String(i + 1).padStart(2, '0')}.jpg`
    );
    
    setScreenshots({ 
      client: clientScreenshots,
      partner: partnerScreenshots
    });
  }, []);
  
  const handleScreenshotChange = (direction: 'next' | 'prev') => {
    const currentScreenshots = screenshots[activeApp.id] || [];
    if (currentScreenshots.length === 0) return;
    
    if (direction === 'next') {
      setCurrentIndex((prev) => (prev + 1) % currentScreenshots.length);
    } else {
      setCurrentIndex((prev) => (prev - 1 + currentScreenshots.length) % currentScreenshots.length);
    }
  };
  
  const checkImageExistence = (url: string): Promise<boolean> => {
    return new Promise((resolve) => {
      const img = new Image();
      img.onload = () => resolve(true);
      img.onerror = () => resolve(false);
      img.src = url;
    });
  };
  
  // Vérifier si l'image existe
  const [imageExists, setImageExists] = useState<Record<string, boolean>>({});
  
  useEffect(() => {
    const checkImages = async () => {
      const newImageStatus: Record<string, boolean> = {};
      
      for (const appId of ['client', 'partner']) {
        for (const screenshot of screenshots[appId] || []) {
          const exists = await checkImageExistence(screenshot);
          newImageStatus[screenshot] = exists;
        }
      }
      
      setImageExists(newImageStatus);
    };
    
    if (screenshots.client.length > 0 || screenshots.partner.length > 0) {
      checkImages();
    }
  }, [screenshots]);
  
  // Auto-rotation du carrousel - Style Stripe
  useEffect(() => {
    const currentScreenshots = screenshots[activeApp.id] || [];
    if (currentScreenshots.length <= 1) return;
    
    const interval = setInterval(() => {
      setCurrentIndex((prev) => (prev + 1) % currentScreenshots.length);
    }, 4000); // Change toutes les 4 secondes
    
    return () => clearInterval(interval);
  }, [activeApp.id, screenshots]);
  
  // Variants d'animation pour les transitions - Style Stripe
  const phoneVariants = {
    initial: { 
      opacity: 0,
      y: 80,
      rotateY: -15,
      rotateX: 10,
      scale: 0.8
    },
    animate: { 
      opacity: 1,
      y: 0,
      rotateY: 0,
      rotateX: 0,
      scale: 1,
      transition: { 
        duration: 0.8,
        type: 'spring',
        stiffness: 120,
        damping: 20
      }
    },
    exit: { 
      opacity: 0,
      y: -80,
      rotateY: 15,
      rotateX: -10,
      scale: 0.8,
      transition: { 
        duration: 0.4
      }
    },
    hover: {
      rotateY: 5,
      rotateX: -2,
      scale: 1.02,
      transition: {
        duration: 0.4,
        ease: "easeOut"
      }
    }
  };
  
  // Placeholder pour les captures d'écran non disponibles
  const ScreenshotPlaceholder = ({ appId }: { appId: string }) => {
    const colors = appId === 'client' 
      ? { bg: 'from-primary-50 to-primary-100', text: 'text-primary-800', accent: 'bg-primary-200' }
      : { bg: 'from-secondary-50 to-secondary-100', text: 'text-secondary-800', accent: 'bg-secondary-200' };
      
    return (
      <div className={`w-full h-full rounded-2xl overflow-hidden bg-gradient-to-b ${colors.bg} flex flex-col items-center justify-center p-6`}>
        <div className={`w-16 h-16 ${colors.accent} rounded-full mb-4 flex items-center justify-center`}>
          <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
          </svg>
        </div>
        <h3 className={`text-xl font-bold ${colors.text} mb-2`}>
          {appId === 'client' ? 'Application Client' : 'Application Partenaire'}
        </h3>
        <p className="text-sm text-secondary-500 text-center">
          Captures d'écran à venir
        </p>
      </div>
    );
  };
  
  return (
    <section className="py-24 bg-gradient-to-b from-secondary-50 to-white overflow-hidden">
      <div className="container-custom">
        {/* Titre de la section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl font-bold text-secondary-900 mb-4 font-display">Nos Applications Mobiles</h2>
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-secondary-600 max-w-2xl mx-auto"
          >
            Gérez vos résidences ou trouvez votre logement idéal où que vous soyez grâce à nos applications dédiées.
          </motion.p>
          
          {/* Ligne décorative dorée */}
          <motion.div 
            initial={{ width: 0 }}
            whileInView={{ width: "80px" }}
            viewport={{ once: true }}
            transition={{ duration: 0.8, delay: 0.4 }}
            className="h-1 bg-primary-300 mx-auto mt-6"
          />
        </motion.div>
        
        {/* Sélecteur d'application */}
        <div className="flex justify-center mb-12">
          <div className="inline-flex bg-secondary-100 rounded-full p-1">
            {apps.map((app) => (
              <motion.button
                key={app.id}
                onClick={() => {
                  setActiveApp(app);
                  setCurrentIndex(0);
                }}
                className={`px-6 py-2 rounded-full text-sm font-medium transition-all duration-300 ${
                  activeApp.id === app.id 
                    ? app.id === 'client' 
                      ? 'bg-primary-400 text-secondary-900 shadow-md' 
                      : 'bg-secondary-700 text-white shadow-md'
                    : 'text-secondary-700 hover:bg-secondary-200'
                }`}
                whileHover={{ y: -2 }}
                whileTap={{ scale: 0.95 }}
              >
                {app.name}
              </motion.button>
            ))}
          </div>
        </div>
        
        {/* Contenu principal */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Téléphone avec captures d'écran */}
          <motion.div
            ref={containerRef}
            className="flex justify-center"
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
          >
            <div className="relative">
              {/* Cadre de téléphone */}
              <div className="relative w-64 h-[500px] mx-auto">
                <div className="absolute inset-0 bg-secondary-900 rounded-[3rem] shadow-2xl overflow-hidden border-8 border-secondary-800">
                  {/* Encoche du téléphone */}
                  <div className="absolute top-0 left-1/2 transform -translate-x-1/2 w-32 h-6 bg-secondary-900 rounded-b-xl"></div>
                  
                  {/* Écran du téléphone */}
                  <div className="absolute inset-0 mt-4 mb-8 overflow-hidden rounded-3xl bg-white">
                    <AnimatePresence mode="wait">
                      <motion.div
                        key={`${activeApp.id}-${currentIndex}`}
                        variants={phoneVariants}
                        initial="initial"
                        animate="animate"
                        exit="exit"
                        className="absolute inset-0"
                      >
                        {screenshots[activeApp.id] && screenshots[activeApp.id].length > 0 && 
                         imageExists[screenshots[activeApp.id][currentIndex]] ? (
                          <img 
                            src={screenshots[activeApp.id][currentIndex]} 
                            alt={`Capture d'écran ${activeApp.name}`} 
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <ScreenshotPlaceholder appId={activeApp.id} />
                        )}
                      </motion.div>
                    </AnimatePresence>
                  </div>
                  
                  {/* Bouton home */}
                  <div className="absolute bottom-2 left-1/2 transform -translate-x-1/2 w-16 h-1 bg-secondary-700 rounded-full"></div>
                </div>
                
                {/* Contrôles de navigation */}
                {screenshots[activeApp.id] && screenshots[activeApp.id].length > 1 && (
                  <div className="absolute left-1/2 transform -translate-x-1/2 bottom-[-2rem] flex space-x-2">
                    <motion.button
                      whileHover={{ scale: 1.1 }}
                      whileTap={{ scale: 0.9 }}
                      className="w-10 h-10 rounded-full bg-secondary-100 flex items-center justify-center shadow-md"
                      onClick={() => handleScreenshotChange('prev')}
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 text-secondary-700" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                      </svg>
                    </motion.button>
                    <motion.button
                      whileHover={{ scale: 1.1 }}
                      whileTap={{ scale: 0.9 }}
                      className="w-10 h-10 rounded-full bg-secondary-100 flex items-center justify-center shadow-md"
                      onClick={() => handleScreenshotChange('next')}
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 text-secondary-700" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                      </svg>
                    </motion.button>
                  </div>
                )}
                
                {/* Indicateurs de pages */}
                {screenshots[activeApp.id] && screenshots[activeApp.id].length > 1 && (
                  <div className="absolute left-1/2 transform -translate-x-1/2 bottom-[-4rem] flex space-x-1">
                    {screenshots[activeApp.id].map((_, i) => (
                      <motion.button
                        key={i}
                        className={`w-2 h-2 rounded-full ${
                          i === currentIndex 
                            ? activeApp.id === 'client' ? 'bg-primary-400' : 'bg-secondary-700'
                            : 'bg-secondary-300'
                        }`}
                        onClick={() => setCurrentIndex(i)}
                        whileHover={{ scale: 1.2 }}
                      />
                    ))}
                  </div>
                )}
              </div>
            </div>
          </motion.div>
          
          {/* Description de l'application */}
          <motion.div
            initial={{ opacity: 0, x: 30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.3 }}
          >
            <h3 className={`text-2xl font-bold mb-4 ${
              activeApp.id === 'client' ? 'text-primary-500' : 'text-secondary-800'
            }`}>
              {activeApp.name}
            </h3>
            <p className="text-secondary-600 mb-6">
              {activeApp.description}
            </p>
            
            <h4 className="text-lg font-semibold text-secondary-800 mb-4">Fonctionnalités principales</h4>
            {/* Icônes check animées en cascade - Style Stripe */}
            <div className="space-y-3 mb-8">
              {activeApp.features.map((feature, index) => (
                <motion.div
                  key={`${activeApp.id}-${feature}`}
                  initial={{ opacity: 0, x: -20, scale: 0.8 }}
                  animate={{ opacity: 1, x: 0, scale: 1 }}
                  transition={{ 
                    delay: index * 0.15,
                    type: "spring",
                    stiffness: 200,
                    damping: 20
                  }}
                  className="flex items-start group/feature"
                >
                  {/* Icône check animée premium */}
                  <motion.div
                    className={`inline-flex items-center justify-center w-6 h-6 rounded-full mr-3 flex-shrink-0 ${
                      activeApp.id === 'client' ? 'bg-primary-100 text-primary-700' : 'bg-secondary-100 text-secondary-700'
                    } group-hover/feature:scale-110 transition-transform`}
                    initial={{ scale: 0, rotate: -180 }}
                    animate={{ scale: 1, rotate: 0 }}
                    transition={{ 
                      delay: index * 0.15 + 0.2,
                      type: "spring",
                      stiffness: 300,
                      damping: 15
                    }}
                    whileHover={{
                      scale: 1.3,
                      rotate: 360,
                      transition: { duration: 0.4 }
                    }}
                  >
                    <motion.svg 
                      xmlns="http://www.w3.org/2000/svg" 
                      className="h-4 w-4" 
                      fill="none" 
                      viewBox="0 0 24 24" 
                      stroke="currentColor"
                      initial={{ pathLength: 0 }}
                      animate={{ pathLength: 1 }}
                      transition={{ 
                        delay: index * 0.15 + 0.4,
                        duration: 0.3
                      }}
                    >
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </motion.svg>
                  </motion.div>
                  
                  {/* Texte avec effet de typing */}
                  <motion.span
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ 
                      delay: index * 0.15 + 0.3,
                      duration: 0.4
                    }}
                    className="text-secondary-700 group-hover/feature:text-secondary-900 transition-colors"
                  >
                    {feature}
                  </motion.span>
                </motion.div>
              ))}
            </div>
            
            {/* Store buttons premium avec glow et icon movement - Style Stripe */}
            <div className="flex flex-wrap gap-4">
              {/* Google Play Button */}
              <motion.a 
                href="#" 
                className={`relative inline-flex items-center px-5 py-3 rounded-full text-sm font-medium shadow-md overflow-hidden group cursor-pointer ${
                  activeApp.id === 'client' 
                    ? 'bg-gradient-to-r from-primary-400 via-primary-500 to-primary-400 text-secondary-900' 
                    : 'bg-gradient-to-r from-secondary-800 via-secondary-900 to-secondary-800 text-white'
                }`}
                whileHover={{ 
                  scale: 1.05,
                  boxShadow: activeApp.id === 'client' 
                    ? "0 20px 40px rgba(212, 175, 55, 0.3)" 
                    : "0 20px 40px rgba(0, 0, 0, 0.3)"
                }}
                whileTap={{ scale: 0.98 }}
                animate={{
                  backgroundPosition: ['0% 50%', '100% 50%', '0% 50%'],
                }}
                transition={{
                  backgroundPosition: {
                    duration: 3,
                    repeat: Infinity,
                    ease: "linear"
                  }
                }}
                style={{
                  backgroundSize: '200% 100%'
                }}
              >
                {/* Glow effect premium */}
                <motion.div 
                  className={`absolute -inset-1 rounded-full blur-md opacity-0 group-hover:opacity-100 ${
                    activeApp.id === 'client' 
                      ? 'bg-gradient-to-r from-primary-400/50 via-primary-500/50 to-primary-400/50' 
                      : 'bg-gradient-to-r from-secondary-800/50 via-secondary-900/50 to-secondary-800/50'
                  }`}
                  transition={{ duration: 0.3 }}
                />
                
                {/* Icône animée */}
                <motion.svg 
                  xmlns="http://www.w3.org/2000/svg" 
                  className="h-5 w-5 mr-2 relative z-10" 
                  fill="currentColor" 
                  viewBox="0 0 24 24"
                  whileHover={{ 
                    x: 3,
                    rotate: 10,
                    transition: { duration: 0.2 }
                  }}
                >
                  <path d="M17.5,1.5A1.5,1.5,0,0,0,16,0H8A1.5,1.5,0,0,0,6.5,1.5v21A1.5,1.5,0,0,0,8,24h8a1.5,1.5,0,0,0,1.5-1.5ZM12,23a1.5,1.5,0,1,1,1.5-1.5A1.5,1.5,0,0,1,12,23Zm4.5-4H7.5V5h9Z"/>
                </motion.svg>
                <span className="relative z-10">Télécharger sur Google Play</span>
              </motion.a>
              
              {/* App Store Button */}
              <motion.a 
                href="#" 
                className={`relative inline-flex items-center px-5 py-3 rounded-full text-sm font-medium shadow-md overflow-hidden group cursor-pointer ${
                  activeApp.id === 'client' 
                    ? 'bg-gradient-to-r from-primary-400 via-primary-500 to-primary-400 text-secondary-900' 
                    : 'bg-gradient-to-r from-secondary-800 via-secondary-900 to-secondary-800 text-white'
                }`}
                whileHover={{ 
                  scale: 1.05,
                  boxShadow: activeApp.id === 'client' 
                    ? "0 20px 40px rgba(212, 175, 55, 0.3)" 
                    : "0 20px 40px rgba(0, 0, 0, 0.3)"
                }}
                whileTap={{ scale: 0.98 }}
                animate={{
                  backgroundPosition: ['0% 50%', '100% 50%', '0% 50%'],
                }}
                transition={{
                  backgroundPosition: {
                    duration: 3,
                    repeat: Infinity,
                    ease: "linear"
                  }
                }}
                style={{
                  backgroundSize: '200% 100%'
                }}
              >
                {/* Glow effect premium */}
                <motion.div 
                  className={`absolute -inset-1 rounded-full blur-md opacity-0 group-hover:opacity-100 ${
                    activeApp.id === 'client' 
                      ? 'bg-gradient-to-r from-primary-400/50 via-primary-500/50 to-primary-400/50' 
                      : 'bg-gradient-to-r from-secondary-800/50 via-secondary-900/50 to-secondary-800/50'
                  }`}
                  transition={{ duration: 0.3 }}
                />
                
                {/* Icône animée */}
                <motion.svg 
                  xmlns="http://www.w3.org/2000/svg" 
                  className="h-5 w-5 mr-2 relative z-10" 
                  fill="currentColor" 
                  viewBox="0 0 24 24"
                  whileHover={{ 
                    x: 3,
                    rotate: -10,
                    transition: { duration: 0.2 }
                  }}
                >
                  <path d="M22,17.28a4.19,4.19,0,0,1-2-3.51A4.06,4.06,0,0,1,22,10.24v-.8a4.15,4.15,0,0,0-2,.35A4.53,4.53,0,0,0,17.5,6,4.39,4.39,0,0,0,14,7.47a7.34,7.34,0,0,0-2,.28,7.26,7.26,0,0,0-2-.28A4.38,4.38,0,0,0,6.5,6,4.51,4.51,0,0,0,4,9.78a4.31,4.31,0,0,0-2-.34v.8a4,4,0,0,1,2,3.53,4.13,4.13,0,0,1-2,3.51v.8a4.29,4.29,0,0,0,2-.34,4.52,4.52,0,0,0,2.5,3.77A4.38,4.38,0,0,0,10,18.53a7.14,7.14,0,0,0,2-.28,7.15,7.15,0,0,0,2,.28,4.39,4.39,0,0,0,3.5-1.47,4.53,4.53,0,0,0,2.5-3.77,4.22,4.22,0,0,0,2,.34Z"/>
                </motion.svg>
                <span className="relative z-10">Télécharger sur App Store</span>
              </motion.a>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
};

export default AppScreenshots; 