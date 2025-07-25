import { useRef } from 'react'
import { motion, useScroll, useTransform } from 'framer-motion'

type LocationData = {
  id: string
  name: string
  country: string
  coordinates: [number, number] // [x, y] coordinates in percentage from top-left
  active: boolean
  properties: number
  comingSoon?: boolean
}

const locations: LocationData[] = [
  { id: 'abidjan', name: 'Abidjan', country: 'Côte d\'Ivoire', coordinates: [39, 42], active: true, properties: 850 },
  { id: 'yamoussoukro', name: 'Yamoussoukro', country: 'Côte d\'Ivoire', coordinates: [36, 35], active: true, properties: 210 },
  { id: 'dakar', name: 'Dakar', country: 'Sénégal', coordinates: [14, 30], active: true, properties: 320 },
  { id: 'cotonou', name: 'Cotonou', country: 'Bénin', coordinates: [45, 43], active: true, properties: 180 },
  { id: 'lome', name: 'Lomé', country: 'Togo', coordinates: [43, 47], active: true, properties: 150 },
  { id: 'accra', name: 'Accra', country: 'Ghana', coordinates: [40, 50], active: true, properties: 220 },
  { id: 'ouagadougou', name: 'Ouagadougou', country: 'Burkina Faso', coordinates: [31, 29], active: true, properties: 120 },
  { id: 'bamako', name: 'Bamako', country: 'Mali', coordinates: [23, 28], active: true, properties: 90 },
  { id: 'conakry', name: 'Conakry', country: 'Guinée', coordinates: [16, 39], active: true, properties: 70 },
  { id: 'niamey', name: 'Niamey', country: 'Niger', coordinates: [38, 20], active: true, properties: 45 },
  { id: 'lagos', name: 'Lagos', country: 'Nigeria', coordinates: [48, 50], active: true, properties: 420 },
  { id: 'libreville', name: 'Libreville', country: 'Gabon', coordinates: [55, 60], active: false, properties: 0, comingSoon: true },
  { id: 'douala', name: 'Douala', country: 'Cameroun', coordinates: [62, 50], active: false, properties: 0, comingSoon: true },
]

const Coverage = () => {
  const containerRef = useRef(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"]
  })
  
  const y = useTransform(scrollYProgress, [0, 1], [50, -50])
  const opacity = useTransform(scrollYProgress, [0, 0.2, 0.8, 1], [0.3, 1, 1, 0.3])
  
  // Animation variants
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
        delayChildren: 0.3,
      }
    }
  }
  
  const mapVariants = {
    hidden: { opacity: 0, scale: 0.9 },
    visible: { 
      opacity: 1,
      scale: 1,
      transition: {
        type: "spring",
        stiffness: 100,
        damping: 20,
        duration: 0.8
      }
    }
  }
  
  const pointVariants = {
    hidden: { scale: 0, opacity: 0 },
    visible: (i: number) => ({
      scale: 1,
      opacity: 1,
      transition: {
        type: "spring",
        stiffness: 300,
        damping: 15,
        delay: 0.5 + i * 0.1
      }
    }),
    hover: { 
      scale: 1.5,
      transition: { duration: 0.3 }
    }
  }
  
  const pulseVariants = {
    initial: { scale: 0.8, opacity: 0.5 },
    animate: {
      scale: [0.8, 1.7, 0.8],
      opacity: [0.5, 0, 0.5],
      transition: {
        duration: 2.5,
        repeat: Infinity,
        ease: "easeInOut"
      }
    }
  }
  
  // Effet de particules dorées
  const glitterVariants = {
    animate: (i: number) => ({
      opacity: [0, 0.5, 0],
      scale: [0.4, 1, 0.4],
      x: [0, Math.random() * 100 - 50, 0],
      y: [0, Math.random() * 100 - 50, 0],
      transition: {
        duration: Math.random() * 3 + 4,
        repeat: Infinity,
        delay: i * 0.3,
      }
    })
  }
  
  // Lignes de connexion entre villes
  const connectionLines = [
    { from: 'abidjan', to: 'dakar' },
    { from: 'abidjan', to: 'accra' },
    { from: 'abidjan', to: 'cotonou' },
    { from: 'dakar', to: 'bamako' },
    { from: 'accra', to: 'lome' },
    { from: 'cotonou', to: 'lagos' },
    { from: 'bamako', to: 'ouagadougou' },
    { from: 'ouagadougou', to: 'niamey' },
  ]
  
  return (
    <section 
      ref={containerRef}
      className="relative py-24 overflow-hidden bg-gradient-to-b from-white to-secondary-50"
    >
      {/* Arrière-plan avec dégradé */}
      <motion.div 
        className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(212,175,55,0.03),transparent_70%)] -z-10"
        style={{ y, opacity }}
      />
      
      {/* Motif élégant en arrière-plan */}
      <motion.div 
        className="absolute inset-0 bg-[linear-gradient(135deg,rgba(212,175,55,0.02)_1px,transparent_1px),linear-gradient(45deg,rgba(212,175,55,0.02)_1px,transparent_1px)] bg-[size:40px_40px] -z-10"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 1.5 }}
      />
      
      {/* Particules dorées subtiles */}
      <div className="absolute inset-0 overflow-hidden -z-5">
        {[...Array(12)].map((_, i) => (
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
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl font-bold text-secondary-900 mb-4 font-display">Notre couverture géographique</h2>
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-secondary-600 max-w-2xl mx-auto"
          >
            Découvrez les villes où ChapeChape Residence est disponible en Afrique de l'Ouest et nos prochaines expansions.
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
        
        <div className="grid grid-cols-1 lg:grid-cols-5 gap-8 items-center">
          {/* Carte interactive */}
          <motion.div 
            className="lg:col-span-3 relative"
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-50px" }}
          >
            <motion.div 
              className="relative"
              variants={mapVariants}
            >
              {/* Carte de l'Afrique de l'Ouest */}
              <div className="relative w-full h-0 pb-[90%] bg-secondary-900 rounded-xl shadow-xl overflow-hidden">
                {/* Image de la carte avec un dégradé */}
                <div className="absolute inset-0 bg-gradient-to-br from-secondary-800 to-secondary-900 p-4">
                  <div className="absolute inset-0 m-4 bg-[url('/assets/west-africa-map.svg')] bg-contain bg-no-repeat bg-center"></div>
                  
                  {/* Points des villes */}
                  {locations.map((location, index) => (
                    <motion.div
                      key={location.id}
                      variants={pointVariants}
                      custom={index}
                      whileHover="hover"
                      className="absolute cursor-pointer transform -translate-x-1/2 -translate-y-1/2 z-20"
                      style={{
                        left: `${location.coordinates[0]}%`,
                        top: `${location.coordinates[1]}%`,
                      }}
                    >
                      {/* Point pulsant pour les emplacements actifs */}
                      {location.active && (
                        <motion.div
                          className="absolute inset-0 rounded-full bg-primary-300 opacity-50"
                          variants={pulseVariants}
                          initial="initial"
                          animate="animate"
                        />
                      )}
                      
                      {/* Point central */}
                      <div className={`w-3 h-3 rounded-full ${location.active ? 'bg-primary-300' : 'bg-secondary-300'} shadow-md z-10 relative`}>
                        {/* Tooltip au survol */}
                        <div className="opacity-0 hover:opacity-100 absolute bottom-full left-1/2 transform -translate-x-1/2 -translate-y-2 transition-opacity duration-300 pointer-events-none z-30">
                          <div className="bg-secondary-900 text-white text-xs rounded-lg py-2 px-3 shadow-lg whitespace-nowrap">
                            <div className="font-semibold mb-1">{location.name}, {location.country}</div>
                            {location.active ? (
                              <div>{location.properties} propriétés</div>
                            ) : (
                              <div className="text-primary-300">Bientôt disponible</div>
                            )}
                            <div className="absolute top-full left-1/2 transform -translate-x-1/2 border-t-4 border-r-4 border-l-4 border-transparent border-t-secondary-900"></div>
                          </div>
                        </div>
                      </div>
                    </motion.div>
                  ))}
                  
                  {/* Lignes de connexion entre les villes */}
                  <svg className="absolute inset-0 w-full h-full z-0">
                    <g className="opacity-20">
                      {locations.filter(l => l.active).map((location, index) => {
                        // Connecter cette ville aux 2 villes les plus proches
                        const otherLocations = [...locations.filter(l => l.active && l.id !== location.id)];
                        otherLocations.sort((a, b) => {
                          const distA = Math.sqrt(
                            Math.pow(a.coordinates[0] - location.coordinates[0], 2) +
                            Math.pow(a.coordinates[1] - location.coordinates[1], 2)
                          );
                          const distB = Math.sqrt(
                            Math.pow(b.coordinates[0] - location.coordinates[0], 2) +
                            Math.pow(b.coordinates[1] - location.coordinates[1], 2)
                          );
                          return distA - distB;
                        });
                        
                        const closest = otherLocations.slice(0, 2);
                        
                        return closest.map((target, i) => (
                          <motion.path
                            key={`${location.id}-${target.id}`}
                            d={`M${location.coordinates[0]} ${location.coordinates[1]} L${target.coordinates[0]} ${target.coordinates[1]}`}
                            stroke="#D4AF37"
                            strokeWidth="0.5"
                            fill="none"
                            strokeDasharray="1 3"
                            initial={{ pathLength: 0, opacity: 0 }}
                            animate={{ 
                              pathLength: 1, 
                              opacity: 0.5,
                              transition: { 
                                delay: 1 + index * 0.1 + i * 0.05,
                                duration: 1.5, 
                                ease: "easeInOut" 
                              } 
                            }}
                          />
                        ));
                      })}
                    </g>
                  </svg>
                </div>
              </div>
            </motion.div>
          </motion.div>
          
          {/* Statistiques avec compteurs animés */}
          <div className="lg:col-span-2">
            <motion.div
              initial={{ opacity: 0, x: 50 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true, margin: "-50px" }}
              transition={{ duration: 0.6, delay: 0.4 }}
              className="bg-white/80 backdrop-blur-sm rounded-xl shadow-xl p-8 border border-primary-100/30 relative overflow-hidden"
            >
              {/* Background géométrique animé */}
              <div className="absolute inset-0 opacity-5">
                <motion.div 
                  className="absolute top-4 right-4 w-20 h-20 border border-primary-300 rounded-full"
                  animate={{ rotate: 360 }}
                  transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
                />
                <motion.div 
                  className="absolute bottom-4 left-4 w-16 h-16 bg-primary-200 rounded-lg"
                  animate={{ 
                    scale: [1, 1.1, 1],
                    rotate: [0, 90, 0]
                  }}
                  transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
                />
              </div>
              
              <h3 className="text-2xl font-bold text-secondary-900 mb-6 font-display relative z-10">Notre présence</h3>
              
              <div className="space-y-6 relative z-10">
                {/* Villes actives avec compteur animé */}
                <div className="flex items-center justify-between">
                  <span className="text-secondary-700 font-medium">Villes actives</span>
                  <motion.span 
                    className="text-2xl font-bold text-secondary-900"
                    initial={{ scale: 0.8, opacity: 0 }}
                    whileInView={{ scale: 1, opacity: 1 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.6, delay: 0.8 }}
                  >
                    {locations.filter(l => l.active).length}
                  </motion.span>
                </div>
                
                <motion.div 
                  className="h-px bg-gradient-to-r from-transparent via-primary-200 to-transparent"
                  initial={{ scaleX: 0 }}
                  whileInView={{ scaleX: 1 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.8, delay: 0.6 }}
                />
                
                {/* Pays couverts avec compteur animé */}
                <div className="flex items-center justify-between">
                  <span className="text-secondary-700 font-medium">Pays couverts</span>
                  <motion.span 
                    className="text-2xl font-bold text-secondary-900"
                    initial={{ scale: 0.8, opacity: 0 }}
                    whileInView={{ scale: 1, opacity: 1 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.6, delay: 1.0 }}
                  >
                    {new Set(locations.filter(l => l.active).map(l => l.country)).size}
                  </motion.span>
                </div>
                
                <motion.div 
                  className="h-px bg-gradient-to-r from-transparent via-primary-200 to-transparent"
                  initial={{ scaleX: 0 }}
                  whileInView={{ scaleX: 1 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.8, delay: 0.8 }}
                />
                
                {/* Total propriétés avec effet counting */}
                <div className="flex items-center justify-between">
                  <span className="text-secondary-700 font-medium">Total des propriétés</span>
                  <motion.span 
                    className="text-2xl font-bold bg-gradient-to-r from-primary-600 to-primary-500 bg-clip-text text-transparent"
                    initial={{ scale: 0.8, opacity: 0 }}
                    whileInView={{ scale: 1, opacity: 1 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.6, delay: 1.2 }}
                  >
                    {locations.reduce((sum, location) => sum + location.properties, 0)}
                  </motion.span>
                </div>
                
                <motion.div 
                  className="h-px bg-gradient-to-r from-transparent via-primary-200 to-transparent"
                  initial={{ scaleX: 0 }}
                  whileInView={{ scaleX: 1 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.8, delay: 1.0 }}
                />
                
                {/* Timeline expansion animée */}
                <motion.div 
                  className="bg-gradient-to-r from-primary-50 to-primary-100 rounded-lg p-4 border border-primary-200"
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.6, delay: 1.4 }}
                >
                  <div className="flex items-center justify-between">
                    <span className="text-secondary-700 font-medium">Expansion 2023</span>
                    <motion.span 
                      className="text-primary-600 font-bold flex items-center gap-2"
                      initial={{ x: -20, opacity: 0 }}
                      whileInView={{ x: 0, opacity: 1 }}
                      viewport={{ once: true }}
                      transition={{ duration: 0.6, delay: 1.6 }}
                    >
                      <motion.span
                        animate={{ scale: [1, 1.1, 1] }}
                        transition={{ duration: 2, repeat: Infinity }}
                      >
                        +{locations.filter(l => l.comingSoon).length}
                      </motion.span>
                      villes
                    </motion.span>
                  </div>
                  
                  {/* Villes à venir */}
                  <motion.div 
                    className="mt-3 flex flex-wrap gap-2"
                    initial={{ opacity: 0 }}
                    whileInView={{ opacity: 1 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.6, delay: 1.8 }}
                  >
                    {locations.filter(l => l.comingSoon).map((city, index) => (
                      <motion.span
                        key={city.id}
                        className="text-xs bg-primary-200 text-primary-700 px-2 py-1 rounded-full"
                        initial={{ scale: 0, opacity: 0 }}
                        whileInView={{ scale: 1, opacity: 1 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.4, delay: 2.0 + index * 0.1 }}
                      >
                        {city.name}
                      </motion.span>
                    ))}
                  </motion.div>
                </motion.div>
              </div>
              
              <motion.div 
                className="mt-8 relative z-10"
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6, delay: 2.2 }}
              >
                <a 
                  href="/about"
                  className="inline-flex items-center text-primary-500 font-medium hover:text-primary-600 transition-colors group"
                >
                  <span>En savoir plus sur notre expansion</span>
                  <motion.span 
                    className="ml-2" 
                    initial={{ x: 0 }}
                    whileHover={{ x: 5 }}
                    transition={{ duration: 0.2 }}
                  >→</motion.span>
                </a>
              </motion.div>
            </motion.div>
            
            {/* Légende modernisée */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-50px" }}
              transition={{ duration: 0.5, delay: 0.6 }}
              className="mt-6 bg-gradient-to-r from-secondary-50 to-primary-50 rounded-lg p-4 flex items-center justify-center space-x-6 border border-primary-100/50"
            >
              <div className="flex items-center">
                <motion.div 
                  className="w-3 h-3 rounded-full bg-primary-400 mr-2"
                  animate={{ 
                    scale: [1, 1.2, 1],
                    boxShadow: [
                      '0 0 0 rgba(212, 175, 55, 0)',
                      '0 0 10px rgba(212, 175, 55, 0.5)',
                      '0 0 0 rgba(212, 175, 55, 0)'
                    ]
                  }}
                  transition={{ duration: 2, repeat: Infinity }}
                />
                <span className="text-sm text-secondary-600 font-medium">Villes actives</span>
              </div>
              <div className="flex items-center">
                <div className="w-3 h-3 rounded-full bg-secondary-300 mr-2"></div>
                <span className="text-sm text-secondary-600 font-medium">Bientôt disponible</span>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  )
}

export default Coverage 