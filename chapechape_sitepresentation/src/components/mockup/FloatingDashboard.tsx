import { motion, useScroll, useTransform } from 'framer-motion'
import { useRef } from 'react'

const FloatingDashboard = () => {
  const containerRef = useRef(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"]
  })
  
  // Effet parallax subtil
  const y = useTransform(scrollYProgress, [0, 1], [20, -20])
  const rotate = useTransform(scrollYProgress, [0, 1], [0, 2])

  // Données mockup pour le dashboard ChapeChape
  const stats = [
    { label: 'Revenus Mensuels', value: '2,450,000', unit: 'FCFA', change: '+12.5%', positive: true },
    { label: 'Propriétés Actives', value: '24', unit: 'biens', change: '+3', positive: true },
    { label: 'Taux d\'Occupation', value: '94.2', unit: '%', change: '+2.1%', positive: true },
    { label: 'Locataires Satisfaits', value: '4.8', unit: '/5', change: '+0.2', positive: true }
  ]

  const recentActivities = [
    { type: 'payment', property: 'Villa Cocody', amount: '450,000 FCFA', time: '2h', icon: '💰' },
    { type: 'booking', property: 'Appartement Plateau', amount: 'Nouvelle réservation', time: '4h', icon: '🏠' },
    { type: 'maintenance', property: 'Studio Marcory', amount: 'Maintenance planifiée', time: '6h', icon: '🔧' }
  ]

  return (
    <motion.div
      ref={containerRef}
      style={{ y, rotate }}
      initial={{ opacity: 0, x: 100, scale: 0.9 }}
      whileInView={{ opacity: 1, x: 0, scale: 1 }}
      viewport={{ once: true, margin: "-100px" }}
      transition={{ duration: 0.8, ease: "easeOut" }}
      className="fixed right-8 top-1/2 -translate-y-1/2 w-96 z-40 hidden xl:block"
    >
      {/* Container principal avec glassmorphism */}
      <motion.div
        whileHover={{ scale: 1.02, y: -5 }}
        transition={{ duration: 0.3, ease: "easeOut" }}
        className="bg-white/90 backdrop-blur-xl rounded-3xl shadow-2xl border border-primary-200/30 overflow-hidden group relative"
        style={{
          boxShadow: '0 25px 50px -12px rgba(212, 175, 55, 0.15), 0 0 0 1px rgba(212, 175, 55, 0.1)'
        }}
      >
        {/* Gradient background subtil */}
        <div className="absolute inset-0 bg-gradient-to-br from-primary-50/50 via-white to-secondary-50/30 -z-10" />
        
        {/* Header avec logo ChapeChape */}
        <div className="p-6 border-b border-primary-100/50 relative">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <motion.div
                whileHover={{ rotate: 360, scale: 1.1 }}
                transition={{ duration: 0.6 }}
                className="w-12 h-12 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-2xl flex items-center justify-center shadow-lg relative overflow-hidden"
              >
                <img 
                  src="/assets/logo.png" 
                  alt="ChapeChape Residence" 
                  className="w-8 h-8 object-contain"
                />
                {/* Effet de brillance */}
                <motion.div
                  initial={{ x: '-100%' }}
                  whileHover={{ x: '100%' }}
                  transition={{ duration: 0.6 }}
                  className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent"
                />
              </motion.div>
              <div>
                <h3 className="text-lg font-bold bg-gradient-to-r from-primary-600 via-secondary-600 to-primary-700 bg-clip-text text-transparent">
                  Dashboard Immobilier
                </h3>
                <p className="text-sm text-primary-600/70 font-medium">ChapeChape Residence</p>
              </div>
            </div>
            <motion.div
              whileHover={{ scale: 1.2 }}
              className="flex items-center space-x-2"
            >
              <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
              <span className="text-xs text-green-600 font-medium">En ligne</span>
            </motion.div>
          </div>
        </div>

        {/* Statistiques principales */}
        <div className="p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h4 className="text-sm font-semibold text-primary-700 uppercase tracking-wide">
              Performances du Mois
            </h4>
            <motion.div
              whileHover={{ rotate: 180 }}
              className="w-6 h-6 text-primary-500 cursor-pointer"
            >
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
            </motion.div>
          </div>
          
          <div className="grid grid-cols-2 gap-3">
            {stats.map((stat, index) => (
              <motion.div
                key={stat.label}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                whileHover={{ 
                  scale: 1.05, 
                  backgroundColor: 'rgba(212, 175, 55, 0.08)'
                }}
                className="bg-gradient-to-br from-primary-25 to-secondary-25 rounded-2xl p-4 border border-primary-100/50 group/stat cursor-pointer"
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs text-primary-600/70 font-medium">{stat.label}</span>
                  <motion.span
                    whileHover={{ scale: 1.1 }}
                    className={`text-xs px-2 py-1 rounded-full font-medium ${
                      stat.positive 
                        ? 'bg-green-100 text-green-700 border border-green-200' 
                        : 'bg-red-100 text-red-700 border border-red-200'
                    }`}
                  >
                    {stat.change}
                  </motion.span>
                </div>
                <div className="flex items-baseline space-x-1">
                  <span className="text-xl font-bold bg-gradient-to-r from-primary-700 to-secondary-700 bg-clip-text text-transparent">
                    {stat.value}
                  </span>
                  <span className="text-sm text-primary-500/70">{stat.unit}</span>
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Graphique de revenus (mockup) */}
        <div className="p-6 border-t border-primary-100/50">
          <h4 className="text-sm font-semibold text-primary-700 uppercase tracking-wide mb-4">
            Revenus des 6 Derniers Mois
          </h4>
          <div className="relative h-24 bg-gradient-to-r from-primary-50 to-secondary-50 rounded-2xl p-4 overflow-hidden border border-primary-100/30">
            {/* Graphique SVG mockup */}
            <svg className="w-full h-full" viewBox="0 0 300 80">
              <motion.path
                initial={{ pathLength: 0 }}
                whileInView={{ pathLength: 1 }}
                transition={{ duration: 2, ease: "easeInOut" }}
                d="M10,60 Q50,40 80,45 T150,35 T220,25 T290,20"
                stroke="url(#chapechapeGradient)"
                strokeWidth="3"
                fill="none"
                strokeLinecap="round"
              />
              <defs>
                <linearGradient id="chapechapeGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                  <stop offset="0%" stopColor="#D4AF37" />
                  <stop offset="50%" stopColor="#B8860B" />
                  <stop offset="100%" stopColor="#8B4513" />
                </linearGradient>
              </defs>
              {/* Points de données */}
              {[10, 80, 150, 220, 290].map((x, i) => (
                <motion.circle
                  key={i}
                  initial={{ scale: 0 }}
                  whileInView={{ scale: 1 }}
                  transition={{ duration: 0.5, delay: i * 0.2 }}
                  whileHover={{ scale: 1.5 }}
                  cx={x}
                  cy={[60, 45, 35, 25, 20][i]}
                  r="4"
                  fill="#D4AF37"
                  className="cursor-pointer drop-shadow-sm"
                />
              ))}
            </svg>
            
            {/* Overlay avec effet de brillance */}
            <motion.div
              initial={{ x: '-100%' }}
              whileInView={{ x: '100%' }}
              transition={{ duration: 2, delay: 0.5 }}
              className="absolute inset-0 bg-gradient-to-r from-transparent via-primary-200/30 to-transparent"
            />
          </div>
        </div>

        {/* Activités récentes */}
        <div className="p-6 border-t border-primary-100/50">
          <h4 className="text-sm font-semibold text-primary-700 uppercase tracking-wide mb-4">
            Activités Récentes
          </h4>
          <div className="space-y-3">
            {recentActivities.map((activity, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: -20 }}
                whileInView={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                whileHover={{ scale: 1.02, backgroundColor: 'rgba(212, 175, 55, 0.05)' }}
                className="flex items-center space-x-3 p-3 rounded-xl border border-primary-100/30 cursor-pointer group/activity"
              >
                <motion.div
                  whileHover={{ scale: 1.2, rotate: 10 }}
                  className="w-10 h-10 bg-gradient-to-br from-primary-100 to-secondary-100 rounded-xl flex items-center justify-center text-lg border border-primary-200/50"
                >
                  {activity.icon}
                </motion.div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-primary-700 group-hover/activity:text-primary-800">
                    {activity.property}
                  </p>
                  <p className="text-xs text-primary-500/70">{activity.amount}</p>
                </div>
                <span className="text-xs text-primary-400 font-medium">
                  Il y a {activity.time}
                </span>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Footer avec CTA */}
        <div className="p-6 border-t border-primary-100/50 bg-gradient-to-r from-primary-25/50 to-secondary-25/50">
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className="w-full bg-gradient-to-r from-primary-500 to-secondary-500 text-white font-semibold py-3 px-4 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 group/btn"
          >
            <span className="flex items-center justify-center space-x-2">
              <span>Voir le Dashboard Complet</span>
              <motion.svg
                className="w-4 h-4 group-hover/btn:translate-x-1 transition-transform"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </motion.svg>
            </span>
          </motion.button>
        </div>
      </motion.div>
    </motion.div>
  )
}

export default FloatingDashboard
