import { useState, useRef, useEffect } from 'react';
import { motion, useScroll, useTransform, AnimatePresence } from 'framer-motion';
import { residenceTypes, ResidenceType } from '../../data/residences';
import ResidencePlaceholder, { type ResidencePlaceholderType } from './ResidencePlaceholders';

const ResidenceTypes = () => {
  const [selectedType, setSelectedType] = useState<ResidenceType>(residenceTypes[0]);
  const [imagesLoaded, setImagesLoaded] = useState<Record<string, boolean>>({});
  const containerRef = useRef<HTMLElement>(null);
  const tabsScrollRef = useRef<HTMLDivElement>(null);

  const scrollTabs = (direction: 'left' | 'right') => {
    const el = tabsScrollRef.current;
    if (!el) return;
    const step = el.clientWidth * 0.6;
    el.scrollBy({ left: direction === 'left' ? -step : step, behavior: 'smooth' });
  };

  // Vérification de la disponibilité des images (URL absolue pour éviter les échecs de chargement)
  useEffect(() => {
    const checkImages = async () => {
      const base = typeof window !== 'undefined' ? window.location.origin : '';
      for (const type of residenceTypes) {
        try {
          const img = new Image();
          const url = type.imageUrl.startsWith('http') ? type.imageUrl : base + type.imageUrl;
          img.src = url;
          await new Promise((resolve, reject) => {
            img.onload = () => resolve(null);
            img.onerror = reject;
            if (img.complete && img.naturalWidth > 0) resolve(null);
          });
          setImagesLoaded(prev => ({ ...prev, [type.id]: true }));
        } catch {
          setImagesLoaded(prev => ({ ...prev, [type.id]: false }));
        }
      }
    };

    checkImages();
  }, []);

  // S'assurer que le type est toujours sélectionné
  useEffect(() => {
    if (residenceTypes.length > 0 && !selectedType) {
      setSelectedType(residenceTypes[0]);
    }
  }, [residenceTypes, selectedType]);

  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"]
  });

  // Effet de parallaxe
  const y = useTransform(scrollYProgress, [0, 1], [50, -50]);
  const opacity = useTransform(scrollYProgress, [0, 0.2, 0.8, 1], [0.3, 1, 1, 0.3]);

  // Variants d'animation pour le conteneur
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
        delayChildren: 0.3
      }
    }
  };

  // Fonction de gestion du changement de type
  const handleTypeChange = (type: ResidenceType) => {
    setSelectedType(type);
  };

  // Variants d'animation pour les cartes
  const cardVariants = {
    hidden: {
      opacity: 0,
      y: 50,
    },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        type: "spring",
        stiffness: 100,
        damping: 15
      }
    },
    hover: {
      y: -10,
      boxShadow: "0 20px 25px -5px rgba(212, 175, 55, 0.1), 0 10px 10px -5px rgba(212, 175, 55, 0.04)",
      transition: {
        type: "spring",
        stiffness: 400,
        damping: 10
      }
    }
  };

  // Variants d'animation pour l'image sélectionnée
  const selectedImageVariants = {
    initial: { opacity: 0, scale: 0.8 },
    animate: {
      opacity: 1,
      scale: 1,
      transition: {
        type: "spring",
        stiffness: 300,
        damping: 20
      }
    },
    exit: {
      opacity: 0,
      scale: 0.8,
      transition: {
        duration: 0.3
      }
    }
  };

  // Variants pour l'effet de particules dorées
  const glitterVariants = {
    animate: (i: number) => ({
      opacity: [0, 0.7, 0],
      scale: [0.4, 1, 0.4],
      x: [0, Math.random() * 50 - 25, 0],
      y: [0, Math.random() * 50 - 25, 0],
      transition: {
        duration: Math.random() * 3 + 4,
        repeat: Infinity,
        delay: i * 0.3,
      }
    })
  };

  const bgImageUrl = '/assets/images/background_categorie.png';

  return (
    <section
      ref={containerRef}
      className="relative py-16 overflow-hidden"
    >
      {/* Image de fond catégories (couche la plus basse) */}
      <div className="absolute inset-0 z-0 overflow-hidden">
        <img
          src={bgImageUrl}
          alt=""
          className="h-full w-full object-cover object-center"
          aria-hidden
        />
      </div>
      {/* Overlay très léger pour que l'image reste bien visible */}
      <div className="absolute inset-0 z-[1] bg-white/15 pointer-events-none" aria-hidden />

      {/* Légère teinte dorée (très subtile) */}
      <motion.div
        className="absolute inset-0 z-[1] bg-[radial-gradient(ellipse_80%_50%_at_50%_20%,rgba(212,175,55,0.08),transparent_60%)] pointer-events-none"
        style={{ y, opacity }}
      />

      {/* Particules dorées subtiles */}
      <div className="absolute inset-0 z-[1] overflow-hidden pointer-events-none">
        {[...Array(15)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute rounded-full bg-primary-300"
            style={{
              width: Math.random() * 4 + 2 + 'px',
              height: Math.random() * 4 + 2 + 'px',
              left: Math.random() * 100 + '%',
              top: Math.random() * 100 + '%',
            }}
            variants={glitterVariants}
            custom={i}
            animate="animate"
          />
        ))}
      </div>

      <div className="mx-auto max-w-6xl px-6 lg:px-8 relative z-10">
        {/* Titre de la section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="inline-flex items-center px-4 py-2 rounded-full bg-white shadow-sm border border-primary-100 text-primary-800 text-xs font-bold tracking-widest uppercase mb-6"
          >
            <span className="w-2 h-2 bg-primary-500 rounded-full mr-2 animate-pulse"></span>
            6 catégories, 28 types
          </motion.div>

          <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold text-secondary-900 mb-6 font-display tracking-tight">
            Tous types d'hébergement
          </h2>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-lg text-secondary-600 max-w-2xl mx-auto font-light leading-relaxed"
          >
            Du studio au villa, de l'hôtel de passage au lodge : trouvez ou proposez l'hébergement qui vous correspond, <span className="text-primary-600 font-medium">tous budgets et toutes durées</span>.
          </motion.p>
        </motion.div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-start">
          {/* Section de gauche - Visualisation avec parallax 3D */}
          <motion.div
            className="relative aspect-[4/3] rounded-2xl overflow-hidden shadow-2xl group perspective-1000 transition-all duration-500 border border-white/20"
            whileHover={{
              scale: 1.02,
              transition: { duration: 0.4, ease: "easeOut" }
            }}
          >
            <div className="absolute inset-0 bg-secondary-900/10 group-hover:bg-transparent transition-colors duration-500 z-10 pointer-events-none" />

            <AnimatePresence mode="wait">
              <motion.div
                key={selectedType.id}
                variants={selectedImageVariants}
                initial="initial"
                animate="animate"
                exit="exit"
                className="absolute inset-0"
              >
                {/* Image avec parallax 3D effect ; fallback placeholder si chargement échoue */}
                {selectedType.imageUrl && (imagesLoaded[selectedType.id] !== false) ? (
                  <motion.div
                    className="w-full h-full bg-cover bg-center relative"
                    whileHover={{
                      scale: 1.1,
                      transition: { duration: 0.8, ease: "easeOut" }
                    }}
                  >
                    <img
                      src={selectedType.imageUrl}
                      alt=""
                      className="absolute inset-0 w-full h-full object-cover object-center"
                      onError={() => setImagesLoaded(prev => ({ ...prev, [selectedType.id]: false }))}
                    />
                  </motion.div>
                ) : (
                  <ResidencePlaceholder type={selectedType.id as ResidencePlaceholderType} className="w-full h-full" />
                )}

                {/* Overlay gradient + titre, étoiles, CTA (style maquette) */}
                <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/90 via-secondary-900/20 to-transparent opacity-90">
                  <div className="absolute bottom-0 left-0 p-8 w-full">
                    <motion.div
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: 0.2 }}
                      className="flex flex-col items-start"
                    >
                      <h3 className="text-3xl font-display font-bold text-white mb-2 tracking-wide">{selectedType.name}</h3>
                      <div className="flex gap-0.5 mb-4" aria-hidden>
                        {[...Array(5)].map((_, i) => (
                          <span key={i} className="text-primary-400 text-lg leading-none">★</span>
                        ))}
                      </div>
                      <motion.a
                        href="/residences"
                        whileHover={{ scale: 1.03 }}
                        whileTap={{ scale: 0.98 }}
                        className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-primary-700 via-primary-600 to-primary-400 text-white rounded-full text-sm font-semibold shadow-lg hover:shadow-xl transition-shadow"
                      >
                        Voir les offres
                        <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                        </svg>
                      </motion.a>
                    </motion.div>
                  </div>
                </div>
              </motion.div>
            </AnimatePresence>
          </motion.div>

          {/* Section de droite - Onglets soulignés + contenu (style maquette) */}
          <div className="flex flex-col lg:min-h-[380px]">
            {/* Barre d'onglets avec flèches et soulignement actif */}
            <motion.div
              variants={containerVariants}
              initial="hidden"
              whileInView="visible"
              viewport={{ once: true }}
              className="flex items-center gap-1 mb-6 border-b border-secondary-200"
            >
              <button
                type="button"
                onClick={() => scrollTabs('left')}
                className="flex-shrink-0 p-2 rounded-lg text-secondary-500 hover:text-secondary-800 hover:bg-secondary-100 transition-colors"
                aria-label="Onglets précédents"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
                </svg>
              </button>
              <div
                ref={tabsScrollRef}
                className="flex flex-1 flex-nowrap gap-0 min-w-0 overflow-x-auto scroll-smooth scrollbar-hide"
              >
                {residenceTypes.map((type) => {
                  const isSelected = selectedType.id === type.id;
                  return (
                    <button
                      key={type.id}
                      type="button"
                      onClick={() => handleTypeChange(type)}
                      className={`flex-shrink-0 py-3 px-4 text-sm font-medium transition-colors cursor-pointer whitespace-nowrap border-b-2 -mb-[2px] ${
                        isSelected
                          ? 'text-secondary-900 font-semibold border-primary-500'
                          : 'text-secondary-500 border-transparent hover:text-secondary-700'
                      }`}
                    >
                      {type.name}
                    </button>
                  );
                })}
              </div>
              <button
                type="button"
                onClick={() => scrollTabs('right')}
                className="flex-shrink-0 p-2 rounded-lg text-secondary-500 hover:text-secondary-800 hover:bg-secondary-100 transition-colors"
                aria-label="Onglets suivants"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                </svg>
              </button>
            </motion.div>

            <motion.div
              key={selectedType.id}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.35 }}
              className="flex-1 bg-white/95 backdrop-blur-sm p-6 rounded-2xl shadow-md border border-secondary-100"
            >
              <h4 className="text-2xl font-bold text-secondary-900 mb-3 font-display tracking-tight">{selectedType.name}</h4>
              <p className="text-secondary-600 text-base leading-relaxed mb-6">{selectedType.description}</p>

              <h5 className="text-xs font-semibold text-secondary-800 uppercase tracking-widest mb-3">Caractéristiques</h5>
              <ul className="space-y-3 mb-8 list-none">
                {selectedType.features.map((feature, index) => (
                  <li key={`${selectedType.id}-${index}`} className="flex items-center gap-3 text-secondary-700">
                    <motion.span
                      initial={{ opacity: 0, x: -8 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: index * 0.06 }}
                      className="flex-shrink-0 text-primary-500"
                      aria-hidden
                    >
                      <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                        <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                      </svg>
                    </motion.span>
                    <span className="text-[15px] leading-snug">{feature}</span>
                  </li>
                ))}
              </ul>

              <a
                href="/residences"
                className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-primary-100 to-primary-50 text-secondary-800 rounded-full text-sm font-semibold border border-primary-200/60 hover:from-primary-200 hover:to-primary-100 transition-colors"
              >
                Voir les offres
                <svg className="w-4 h-4 text-secondary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                </svg>
              </a>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default ResidenceTypes; 