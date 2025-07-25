import { useState, useRef, useEffect } from 'react';
import { motion, useScroll, useTransform, AnimatePresence } from 'framer-motion';
import { residenceTypes, ResidenceType } from '../../data/residences';
import ResidencePlaceholder from './ResidencePlaceholders';

const ResidenceTypes = () => {
  // Vérifier que les données sont correctement importées
  console.log('Types de résidences disponibles:', residenceTypes);
  
  const [selectedType, setSelectedType] = useState<ResidenceType>(residenceTypes[0]);
  const [imagesLoaded, setImagesLoaded] = useState<Record<string, boolean>>({});
  const containerRef = useRef(null);
  
  // Vérification de la disponibilité des images
  useEffect(() => {
    const checkImages = async () => {
      for (const type of residenceTypes) {
        try {
          const img = new Image();
          img.src = type.imageUrl;
          await new Promise((resolve, reject) => {
            img.onload = resolve;
            img.onerror = reject;
            // Si l'image est déjà en cache, onload pourrait ne pas se déclencher
            if (img.complete) resolve(null);
          });
          setImagesLoaded(prev => ({ ...prev, [type.id]: true }));
        } catch (error) {
          console.error(`Impossible de charger l'image pour ${type.id}:`, error);
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
      console.log('Type initial défini:', residenceTypes[0].name);
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
    console.log('Type sélectionné:', type.name);
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
  
  return (
    <section
      ref={containerRef}
      className="relative py-24 overflow-hidden bg-gradient-to-b from-white to-secondary-50"
    >
      {/* Arrière-plan avec dégradé */}
      <motion.div 
        className="absolute inset-0 bg-[radial-gradient(circle_at_50%_30%,rgba(212,175,55,0.03),transparent_70%)] -z-10"
        style={{ y, opacity }}
      />
      
      {/* Motif élégant en arrière-plan */}
      <motion.div 
        className="absolute inset-0 bg-[linear-gradient(135deg,rgba(212,175,55,0.02)_1px,transparent_1px),linear-gradient(45deg,rgba(212,175,55,0.02)_1px,transparent_1px)] bg-[size:50px_50px] -z-10"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 1.5 }}
      />
      
      {/* Particules dorées subtiles */}
      <div className="absolute inset-0 overflow-hidden -z-5">
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
      
      <div className="container-custom">
        {/* Titre de la section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-20"
        >
          <h2 className="text-3xl font-bold text-secondary-900 mb-4 font-display">Nos Types de Résidences</h2>
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-secondary-600 max-w-2xl mx-auto"
          >
            Découvrez notre sélection variée de résidences, conçues pour répondre à tous vos besoins et préférences.
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
        
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Section de gauche - Visualisation avec parallax 3D */}
          <motion.div
            className="relative aspect-[4/3] rounded-xl overflow-hidden shadow-xl group perspective-1000"
            whileHover={{
              rotateY: 5,
              rotateX: 2,
              transition: { duration: 0.4, ease: "easeOut" }
            }}
            style={{
              transformStyle: 'preserve-3d'
            }}
          >
            <AnimatePresence mode="wait">
              <motion.div 
                key={selectedType.id}
                variants={selectedImageVariants}
                initial="initial"
                animate="animate"
                exit="exit"
                className="absolute inset-0"
              >
                {/* Image avec parallax 3D effect */}
                {selectedType.imageUrl && (imagesLoaded[selectedType.id] !== false) ? (
                  <motion.div 
                    className="w-full h-full bg-cover bg-center"
                    style={{ 
                      backgroundImage: `url(${selectedType.imageUrl})`,
                      transform: 'translateZ(20px)'
                    }}
                    whileHover={{
                      scale: 1.1,
                      rotateZ: 1,
                      transition: { duration: 0.6, ease: "easeOut" }
                    }}
                  ></motion.div>
                ) : (
                  <ResidencePlaceholder type={selectedType.id as any} className="w-full h-full" />
                )}
                <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/70 to-transparent">
                  <div className="absolute bottom-0 left-0 p-6">
                    <h3 className="text-2xl font-bold text-white mb-2">{selectedType.name}</h3>
                    <p className="text-primary-300 text-sm mb-3">
                      <span className="inline-block mr-1">★</span>
                      <span className="inline-block mr-1">★</span>
                      <span className="inline-block mr-1">★</span>
                      <span className="inline-block mr-1">★</span>
                      <span className="inline-block mr-1">★</span>
                    </p>
                    <motion.button
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: 0.3 }}
                      className="px-4 py-2 bg-primary-300 text-secondary-900 rounded-full text-sm font-medium hover:bg-primary-400 transition-colors"
                    >
                      Voir disponibilités
                    </motion.button>
                  </div>
                </div>
              </motion.div>
            </AnimatePresence>
          </motion.div>
          
          {/* Section de droite - Sélection et description */}
          <div>
            <motion.div
              variants={containerVariants}
              initial="hidden"
              whileInView="visible"
              viewport={{ once: true }}
              className="space-y-4 mb-6"
            >
              <h3 className="text-xl font-semibold text-secondary-900">Choisissez votre type de résidence</h3>
              {/* Tabs animés avec slider doré - Style Stripe */}
              <div className="relative flex flex-wrap gap-3 p-2 bg-white/80 backdrop-blur-sm rounded-2xl border border-primary-100/30 shadow-lg">
                {/* Slider doré qui glisse */}
                <motion.div
                  className="absolute top-2 left-2 h-10 bg-gradient-to-r from-primary-300 via-primary-400 to-primary-300 rounded-xl shadow-lg"
                  animate={{
                    x: residenceTypes.findIndex(type => type.id === selectedType.id) * (120 + 12), // 120px width + 12px gap
                    width: 120
                  }}
                  transition={{
                    type: "spring",
                    stiffness: 300,
                    damping: 30,
                    duration: 0.6
                  }}
                />
                
                {residenceTypes.map((type, index) => {
                  const isSelected = selectedType.id === type.id;
                  
                  return (
                    <motion.button
                      key={type.id}
                      type="button"
                      onClick={() => {
                        console.log('Clic sur le bouton:', type.name);
                        handleTypeChange(type);
                      }}
                      className={`relative z-10 inline-flex items-center justify-center px-5 py-2 rounded-xl text-sm font-medium transition-all duration-300 cursor-pointer min-w-[120px] ${
                        isSelected 
                          ? 'text-secondary-900 font-semibold' 
                          : 'text-secondary-600 hover:text-secondary-900'
                      }`}
                      whileHover={{ 
                        y: -2, 
                        scale: 1.05,
                        transition: { duration: 0.2 }
                      }}
                      whileTap={{ scale: 0.95 }}
                      animate={{
                        color: isSelected ? '#1a1a1a' : '#666666'
                      }}
                    >
                      {/* Glow effect au hover */}
                      <motion.div 
                        className="absolute inset-0 rounded-xl bg-primary-300/10 opacity-0"
                        whileHover={{ opacity: isSelected ? 0 : 1 }}
                        transition={{ duration: 0.2 }}
                      />
                      
                      {type.name}
                    </motion.button>
                  );
                })}
              </div>
            </motion.div>
            
            <motion.div
              key={selectedType.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
              className="bg-white p-6 rounded-xl shadow-md border border-primary-100/20"
            >
              <h4 className="text-xl font-bold text-secondary-900 mb-3">{selectedType.name}</h4>
              <p className="text-secondary-600 mb-6">{selectedType.description}</p>
              
              <h5 className="text-md font-semibold text-secondary-800 mb-3">Caractéristiques</h5>
              {/* Checklist animée avec icônes en cascade - Style Stripe */}
              <div className="space-y-2 mb-6">
                {selectedType.features.map((feature, index) => (
                  <motion.div 
                    key={`${selectedType.id}-${index}`}
                    initial={{ opacity: 0, x: -20, scale: 0.8 }}
                    animate={{ opacity: 1, x: 0, scale: 1 }}
                    transition={{ 
                      delay: index * 0.15,
                      type: "spring",
                      stiffness: 200,
                      damping: 20
                    }}
                    className="flex items-center text-secondary-600 group/item"
                  >
                    {/* Icône check animée */}
                    <motion.div
                      className="flex-shrink-0 w-5 h-5 rounded-full bg-primary-300/20 flex items-center justify-center mr-3 group-hover/item:bg-primary-300/30 transition-colors"
                      initial={{ scale: 0, rotate: -180 }}
                      animate={{ scale: 1, rotate: 0 }}
                      transition={{ 
                        delay: index * 0.15 + 0.2,
                        type: "spring",
                        stiffness: 300,
                        damping: 15
                      }}
                      whileHover={{
                        scale: 1.2,
                        rotate: 360,
                        transition: { duration: 0.4 }
                      }}
                    >
                      <motion.svg 
                        className="w-3 h-3 text-primary-300"
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
                      className="group-hover/item:text-secondary-800 transition-colors"
                    >
                      {feature}
                    </motion.span>
                  </motion.div>
                ))}
              </div>
              
              {/* Gradient hover button premium - Style Stripe */}
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.5 }}
                className="flex justify-center md:justify-start"
              >
                <motion.a 
                  href="/residences" 
                  className="relative inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-primary-300 via-primary-400 to-primary-300 text-secondary-900 rounded-full font-medium overflow-hidden group cursor-pointer"
                  whileHover={{ 
                    scale: 1.05,
                    boxShadow: "0 20px 40px rgba(212, 175, 55, 0.3)",
                    transition: { duration: 0.3 }
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
                  {/* Effet ripple au hover */}
                  <motion.div 
                    className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent"
                    initial={{ x: '-100%' }}
                    whileHover={{ 
                      x: '100%',
                      transition: { duration: 0.6, ease: "easeInOut" }
                    }}
                  />
                  
                  {/* Glow effect premium */}
                  <motion.div 
                    className="absolute -inset-1 bg-gradient-to-r from-primary-300/50 via-primary-400/50 to-primary-300/50 rounded-full blur-md opacity-0 group-hover:opacity-100"
                    transition={{ duration: 0.3 }}
                  />
                  
                  <span className="relative z-10">Explorer cette option</span>
                  <motion.span 
                    className="relative z-10 bg-secondary-900/20 w-6 h-6 rounded-full flex items-center justify-center"
                    whileHover={{ x: 5, rotate: 90 }}
                    transition={{ duration: 0.2 }}
                  >
                    <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                    </svg>
                  </motion.span>
                </motion.a>
              </motion.div>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default ResidenceTypes; 