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
          {/* Section de gauche - Visualisation */}
          <motion.div
            className="relative aspect-[4/3] rounded-xl overflow-hidden shadow-xl group"
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
                {/* Utiliser une condition plus fiable pour vérifier si l'image est chargée */}
                {selectedType.imageUrl && (imagesLoaded[selectedType.id] !== false) ? (
                  <div 
                    className="w-full h-full bg-cover bg-center transform transition-transform duration-1000 group-hover:scale-110"
                    style={{ backgroundImage: `url(${selectedType.imageUrl})` }}
                  ></div>
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
              <div className="flex flex-wrap gap-3">
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
                      className={`relative inline-flex items-center justify-center px-5 py-2 rounded-full text-sm font-medium transition-all duration-300 shadow-sm border cursor-pointer ${
                        isSelected 
                          ? 'bg-primary-300 text-secondary-900 shadow-lg border-primary-400 font-semibold' 
                          : 'bg-white text-secondary-700 hover:bg-primary-50 hover:text-secondary-900 border-secondary-200 hover:border-primary-200'
                      }`}
                      whileHover={{ y: -2, boxShadow: "0 4px 8px rgba(0,0,0,0.1)" }}
                      whileTap={{ scale: 0.95 }}
                    >
                      {isSelected && (
                        <motion.span
                          className="absolute inset-0 bg-primary-200 opacity-20 rounded-full"
                          layoutId="activeButton"
                          initial={false}
                          transition={{ type: "spring", bounce: 0.2, duration: 0.6 }}
                        />
                      )}
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
              <ul className="space-y-2 mb-6">
                {selectedType.features.map((feature, index) => (
                  <motion.li 
                    key={index}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.1 }}
                    className="flex items-center text-secondary-600"
                  >
                    <span className="text-primary-300 mr-2">✓</span>
                    {feature}
                  </motion.li>
                ))}
              </ul>
              
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.5 }}
                className="flex justify-center md:justify-start"
              >
                <a 
                  href="/residences" 
                  className="inline-flex items-center gap-2 px-6 py-3 bg-primary-300 text-secondary-900 rounded-full hover:bg-primary-400 transition-colors duration-300 font-medium"
                >
                  <span>Explorer cette option</span>
                  <motion.span 
                    initial={{ x: 0 }}
                    whileHover={{ x: 5 }}
                    transition={{ duration: 0.2 }}
                  >
                    →
                  </motion.span>
                </a>
              </motion.div>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default ResidenceTypes; 