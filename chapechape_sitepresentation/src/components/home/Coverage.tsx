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
      className="relative py-24 overflow-hidden bg-secondary-50"
    >
      {/* Arrière-plan avec dégradé */}
      <div className="absolute inset-0 bg-white/50 -z-10" />

      {/* Motif de fond */}
      <div className="absolute inset-0 opacity-[0.03] bg-[radial-gradient(#D4AF37_1px,transparent_1px)] [background-size:20px_20px] -z-10" />

      <div className="mx-auto max-w-7xl px-6 lg:px-8">
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
            transition={{ duration: 0.6, delay: 0.1 }}
            className="inline-flex items-center px-4 py-2 bg-white border border-primary-100 rounded-full mb-6 shadow-sm"
          >
            <span className="text-primary-600 text-xs font-bold tracking-widest uppercase">Expansion</span>
          </motion.div>

          <h2 className="text-4xl md:text-5xl font-bold text-secondary-900 mb-6 font-display tracking-tight">
            Notre présence <span className="text-primary-600">en Afrique</span>
          </h2>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-xl text-secondary-600 max-w-2xl mx-auto leading-relaxed font-light"
          >
            Une couverture grandissante pour vous accompagner partout en Afrique de l'Ouest.
          </motion.p>
        </motion.div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-12 items-start">
          {/* Carte interactive */}
          <motion.div
            className="lg:col-span-8 relative"
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-50px" }}
          >
            <motion.div
              className="relative rounded-3xl overflow-hidden shadow-2xl border border-primary-100/50 bg-secondary-900"
              variants={mapVariants}
            >
              {/* Effet de scan radar */}
              <div className="absolute inset-0 z-0 overflow-hidden">
                <motion.div
                  className="absolute inset-0 bg-gradient-to-r from-transparent via-primary-500/10 to-transparent w-[200%]"
                  animate={{ x: ['-100%', '100%'] }}
                  transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
                />
              </div>

              {/* Carte de l'Afrique de l'Ouest */}
              <div className="relative w-full h-0 pb-[75%]">
                {/* Image de la carte */}
                <div className="absolute inset-0 m-8 bg-[url('/assets/west-africa-map.svg')] bg-contain bg-no-repeat bg-center opacity-80 mix-blend-overlay"></div>

                {/* Grille décorative */}
                <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.05)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.05)_1px,transparent_1px)] bg-[size:40px_40px] pointer-events-none" />

                {/* Points des villes */}
                {locations.map((location, index) => (
                  <motion.div
                    key={location.id}
                    variants={pointVariants}
                    custom={index}
                    whileHover="hover"
                    className="absolute cursor-pointer transform -translate-x-1/2 -translate-y-1/2 z-20 group"
                    style={{
                      left: `${location.coordinates[0]}%`,
                      top: `${location.coordinates[1]}%`,
                    }}
                  >
                    {/* Point pulsant pour les emplacements actifs */}
                    {location.active && (
                      <motion.div
                        className="absolute inset-0 -m-4 rounded-full bg-primary-500/30"
                        variants={pulseVariants}
                        initial="initial"
                        animate="animate"
                      />
                    )}

                    {/* Point central */}
                    <div className={`w-3 h-3 md:w-4 md:h-4 rounded-full ${location.active ? 'bg-primary-400 shadow-[0_0_15px_rgba(212,175,55,0.6)]' : 'bg-secondary-600'} border-2 border-secondary-900 z-10 relative transition-colors duration-300 group-hover:bg-white`} />

                    {/* Tooltip au survol */}
                    <div className="opacity-0 group-hover:opacity-100 absolute bottom-full left-1/2 transform -translate-x-1/2 -translate-y-4 transition-all duration-300 pointer-events-none z-30 min-w-[150px]">
                      <div className="bg-white/95 backdrop-blur-md text-secondary-900 text-xs rounded-xl py-3 px-4 shadow-xl border border-primary-100 text-center">
                        <div className="font-bold text-sm mb-1 font-display">{location.name}</div>
                        <div className="text-secondary-500 text-[10px] uppercase tracking-wider mb-2">{location.country}</div>
                        {location.active ? (
                          <div className="inline-flex items-center gap-1 bg-primary-50 px-2 py-1 rounded-md border border-primary-100">
                            <span className="w-1.5 h-1.5 rounded-full bg-primary-500 animate-pulse"></span>
                            <span className="font-semibold text-primary-700">{location.properties} biens</span>
                          </div>
                        ) : (
                          <div className="text-secondary-400 italic">Bientôt disponible</div>
                        )}
                        <div className="absolute top-full left-1/2 transform -translate-x-1/2 -mt-px border-t-[6px] border-r-[6px] border-l-[6px] border-transparent border-t-white/95"></div>
                      </div>
                    </div>
                  </motion.div>
                ))}

                {/* Lignes de connexion */}
                <svg className="absolute inset-0 w-full h-full z-0 pointer-events-none">
                  <g className="opacity-30">
                    {locations.filter(l => l.active).map((location, index) => {
                      const otherLocations = [...locations.filter(l => l.active && l.id !== location.id)];
                      otherLocations.sort((a, b) => {
                        const distA = Math.sqrt(Math.pow(a.coordinates[0] - location.coordinates[0], 2) + Math.pow(a.coordinates[1] - location.coordinates[1], 2));
                        const distB = Math.sqrt(Math.pow(b.coordinates[0] - location.coordinates[0], 2) + Math.pow(b.coordinates[1] - location.coordinates[1], 2));
                        return distA - distB;
                      });
                      const closest = otherLocations.slice(0, 2);

                      return closest.map((target, i) => (
                        <motion.path
                          key={`${location.id}-${target.id}`}
                          d={`M${location.coordinates[0]} ${location.coordinates[1]} L${target.coordinates[0]} ${target.coordinates[1]}`}
                          stroke="url(#lineGradient)"
                          strokeWidth="1"
                          fill="none"
                          strokeDasharray="4 4"
                          initial={{ pathLength: 0, opacity: 0 }}
                          animate={{
                            pathLength: 1,
                            opacity: 0.4,
                            transition: { delay: 1 + index * 0.1, duration: 2, ease: "easeInOut" }
                          }}
                        />
                      ));
                    })}
                    <defs>
                      <linearGradient id="lineGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                        <stop offset="0%" stopColor="#D4AF37" stopOpacity="0" />
                        <stop offset="50%" stopColor="#D4AF37" stopOpacity="1" />
                        <stop offset="100%" stopColor="#D4AF37" stopOpacity="0" />
                      </linearGradient>
                    </defs>
                  </g>
                </svg>
              </div>

              {/* Légende intégrée */}
              <div className="absolute bottom-6 left-6 flex items-center gap-4 bg-secondary-900/80 backdrop-blur-sm px-4 py-2 rounded-full border border-white/10">
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-primary-400 shadow-[0_0_8px_rgba(212,175,55,0.8)]"></span>
                  <span className="text-xs text-white/90 font-medium">Actif</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-secondary-600"></span>
                  <span className="text-xs text-white/60 font-medium">Bientôt</span>
                </div>
              </div>
            </motion.div>
          </motion.div>

          {/* Statistiques latérales */}
          <div className="lg:col-span-4 space-y-6">
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.4 }}
              className="bg-white rounded-2xl p-8 shadow-xl border border-primary-100 relative overflow-hidden group hover:border-primary-300 transition-colors duration-300"
            >
              <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity duration-300">
                <svg className="w-24 h-24 text-primary-500" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z" />
                </svg>
              </div>

              <h3 className="text-2xl font-bold text-secondary-900 mb-2 font-display">Statistiques</h3>
              <p className="text-secondary-500 text-sm mb-8">Notre impact en chiffres</p>

              <div className="space-y-8">
                <div>
                  <div className="flex justify-between items-end mb-2">
                    <span className="text-secondary-600 font-medium">Villes couvertes</span>
                    <span className="text-3xl font-bold text-secondary-900">{locations.filter(l => l.active).length}</span>
                  </div>
                  <div className="h-2 bg-secondary-100 rounded-full overflow-hidden">
                    <motion.div
                      className="h-full bg-primary-500 rounded-full"
                      initial={{ width: 0 }}
                      whileInView={{ width: '70%' }}
                      transition={{ duration: 1, delay: 0.6 }}
                    />
                  </div>
                </div>

                <div>
                  <div className="flex justify-between items-end mb-2">
                    <span className="text-secondary-600 font-medium">Propriétés</span>
                    <span className="text-3xl font-bold text-secondary-900">
                      {locations.reduce((sum, location) => sum + location.properties, 0)}+
                    </span>
                  </div>
                  <div className="h-2 bg-secondary-100 rounded-full overflow-hidden">
                    <motion.div
                      className="h-full bg-primary-500 rounded-full"
                      initial={{ width: 0 }}
                      whileInView={{ width: '85%' }}
                      transition={{ duration: 1, delay: 0.8 }}
                    />
                  </div>
                </div>

                <div>
                  <div className="flex justify-between items-end mb-2">
                    <span className="text-secondary-600 font-medium">Pays</span>
                    <span className="text-3xl font-bold text-secondary-900">
                      {new Set(locations.filter(l => l.active).map(l => l.country)).size}
                    </span>
                  </div>
                  <div className="h-2 bg-secondary-100 rounded-full overflow-hidden">
                    <motion.div
                      className="h-full bg-primary-500 rounded-full"
                      initial={{ width: 0 }}
                      whileInView={{ width: '60%' }}
                      transition={{ duration: 1, delay: 1 }}
                    />
                  </div>
                </div>
              </div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, x: 20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.6 }}
              className="bg-secondary-900 rounded-2xl p-8 shadow-xl text-white relative overflow-hidden"
            >
              <div className="absolute inset-0 bg-[url('/assets/pattern-dot.svg')] opacity-10"></div>
              <div className="relative z-10">
                <h4 className="text-lg font-bold mb-4 font-display text-primary-300">Prochaines Ouvertures</h4>
                <div className="flex flex-wrap gap-2">
                  {locations.filter(l => l.comingSoon).map((city, index) => (
                    <span key={city.id} className="px-3 py-1 rounded-full bg-white/10 text-sm border border-white/10 text-white/90">
                      {city.name}
                    </span>
                  ))}
                </div>
                <div className="mt-6 pt-6 border-t border-white/10">
                  <a href="/contact" className="text-sm text-primary-300 hover:text-white transition-colors flex items-center gap-2 group">
                    Devenir partenaire local
                    <span className="group-hover:translate-x-1 transition-transform">→</span>
                  </a>
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  )
}

export default Coverage 