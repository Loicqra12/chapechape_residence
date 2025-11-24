import { useRef } from 'react';
import { motion, useScroll, useTransform } from 'framer-motion';

const AboutSection = () => {
  const containerRef = useRef(null);
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"]
  });

  // Effet de parallaxe
  const y = useTransform(scrollYProgress, [0, 1], [50, -50]);
  const opacity = useTransform(scrollYProgress, [0, 0.2, 0.8, 1], [0.3, 1, 1, 0.3]);

  // Variants d'animation pour les cartes de valeurs
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

  const itemVariants = {
    hidden: { opacity: 0, y: 30 },
    visible: (i: number) => ({
      opacity: 1,
      y: 0,
      transition: {
        type: "spring",
        stiffness: 100,
        damping: 15,
        delay: i * 0.1
      }
    })
  };

  // Données des valeurs
  const values = [
    {
      title: "Accessibilité",
      description: "Rendre la location de résidences meublées simple et rapide pour tous.",
      icon: (
        <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
        </svg>
      )
    },
    {
      title: "Confiance",
      description: "Garantir des transactions sécurisées et des hébergements conformes aux attentes.",
      icon: (
        <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
        </svg>
      )
    },
    {
      title: "Innovation",
      description: "Intégrer des technologies avancées pour améliorer l'expérience utilisateur.",
      icon: (
        <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
        </svg>
      )
    },
    {
      title: "Responsabilité",
      description: "Agir de manière éthique envers nos clients, partenaires et la communauté.",
      icon: (
        <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7" />
        </svg>
      )
    },
    {
      title: "Excellence",
      description: "Offrir un service de qualité supérieure à chaque étape du processus.",
      icon: (
        <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
        </svg>
      )
    }
  ];

  // Données de l'équipe
  const team = [
    {
      name: "Adams Diaby",
      role: "CEO & Co-fondateur",
      description: "Fondateur de Onloutou, une plateforme de location d'équipements, Adams est un visionnaire du numérique en Afrique de l'Ouest. Il apporte son expertise en gestion de projets digitaux et sa connaissance approfondie du marché ivoirien.",
      image: "/assets/team/adams-diaby.jpg"
    },
    {
      name: "Sidney Jordan",
      role: "CTO & Co-fondateur",
      description: "Fondateur de Soutrali Deals, une plateforme numérique ivoirienne qui valorise les produits, services et talents issus de l'économie informelle et artisanale. Sidney est responsable de la stratégie technologique et du développement de la plateforme.",
      image: "/assets/team/sidney-jordan.jpg"
    }
  ];

  // Effet de scintillement pour les particules dorées
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
      className="relative py-20 overflow-hidden bg-gradient-to-b from-primary-50/30 via-white to-primary-50/50"
    >
      {/* Arrière-plan avec dégradé premium */}
      <motion.div
        className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,rgba(212,175,55,0.08),transparent_50%),radial-gradient(ellipse_at_bottom_right,rgba(168,85,247,0.04),transparent_50%)] -z-10"
        style={{ y, opacity }}
      />

      {/* Motif géométrique moderne */}
      <motion.div
        className="absolute inset-0 bg-[linear-gradient(135deg,rgba(212,175,55,0.03)_1px,transparent_1px),linear-gradient(45deg,rgba(168,85,247,0.02)_1px,transparent_1px)] bg-[size:60px_60px] -z-10"
        initial={{ opacity: 0, scale: 1.1 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 2, ease: "easeOut" }}
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

      <div className="mx-auto max-w-6xl px-6 lg:px-8 relative z-10">
        {/* Titre de la section - Style Stripe */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.8, ease: "easeOut" }}
          className="text-center mb-20"
        >
          {/* Badge premium */}
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="inline-flex items-center px-4 py-2 rounded-full bg-white shadow-sm border border-primary-100 text-primary-800 text-xs font-bold tracking-widest uppercase mb-6"
          >
            <span className="w-2 h-2 bg-primary-500 rounded-full mr-2 animate-pulse"></span>
            Excellence & Innovation
          </motion.div>

          <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold text-secondary-900 mb-6 font-display tracking-tight">
            À propos de <br className="md:hidden" />
            <span className="relative inline-block">
              <span className="relative z-10">ChapeChape Residence</span>
              <motion.span
                initial={{ width: 0 }}
                whileInView={{ width: "100%" }}
                viewport={{ once: true }}
                transition={{ duration: 1, delay: 0.5 }}
                className="absolute bottom-2 left-0 h-3 bg-primary-200/50 -z-10"
              />
            </span>
          </h2>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.8, delay: 0.4 }}
            className="text-xl text-secondary-600 max-w-2xl mx-auto leading-relaxed font-light"
          >
            Découvrez notre vision, nos valeurs et l'équipe qui fait de ChapeChape Residence
            <span className="text-primary-600 font-medium"> une référence en Afrique de l'Ouest</span>.
          </motion.p>
        </motion.div>

        {/* Section Notre Vision avec Animation Futuriste */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center mb-24">
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.8, delay: 0.1 }}
            className="bg-white/80 backdrop-blur-sm p-8 rounded-3xl shadow-xl border border-gray-100 hover:shadow-2xl transition-all duration-500 group"
          >
            <motion.h3
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="text-2xl font-bold bg-gradient-to-r from-gray-900 to-primary-600 bg-clip-text text-transparent mb-4 inline-flex items-center group-hover:scale-105 transition-transform duration-300"
            >
              <motion.span
                initial={{ rotate: 0 }}
                whileInView={{ rotate: 360 }}
                viewport={{ once: true }}
                transition={{ duration: 1, delay: 0.3 }}
                className="text-2xl mr-3"
              >
                🌟
              </motion.span>
              Notre Vision
            </motion.h3>
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="text-gray-700 mb-6 text-base leading-relaxed"
            >
              ChapeChapeRésidence aspire à devenir
              <span className="font-semibold text-primary-600">la référence en Afrique de l'Ouest</span>
              pour la réservation, la gestion et la valorisation de résidences meublées et de logements temporaires.
              Nous visons à simplifier l'accès à des hébergements de qualité, en connectant efficacement
              propriétaires et locataires grâce à une
              <span className="font-semibold text-secondary-600">plateforme numérique intuitive et sécurisée</span>.
            </motion.p>
          </motion.div>

          {/* Animation Ville 3D Futuriste */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="rounded-xl overflow-hidden shadow-lg"
          >
            <div className="relative w-full h-[300px] bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-800 dark:to-slate-900 overflow-hidden">
              {/* Background Grid */}
              <div className="absolute inset-0 opacity-20">
                <svg className="w-full h-full" viewBox="0 0 400 300">
                  <defs>
                    <pattern id="grid-vision" width="20" height="20" patternUnits="userSpaceOnUse">
                      <path d="M 20 0 L 0 0 0 20" fill="none" stroke="currentColor" strokeWidth="0.5" />
                    </pattern>
                  </defs>
                  <rect width="100%" height="100%" fill="url(#grid-vision)" className="text-slate-400" />
                </svg>
              </div>

              {/* Mini-ville 3D Isométrique */}
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="relative w-80 h-60">
                  {/* Buildings avec illumination séquentielle */}
                  {[
                    { x: 60, y: 120, w: 25, h: 50, delay: 0, color: 'from-blue-400 to-blue-600' },
                    { x: 95, y: 100, w: 20, h: 70, delay: 1, color: 'from-indigo-400 to-indigo-600' },
                    { x: 125, y: 110, w: 30, h: 60, delay: 2, color: 'from-purple-400 to-purple-600' },
                    { x: 165, y: 90, w: 22, h: 80, delay: 3, color: 'from-blue-500 to-blue-700' },
                    { x: 195, y: 105, w: 28, h: 65, delay: 4, color: 'from-indigo-500 to-indigo-700' },
                    { x: 230, y: 95, w: 24, h: 75, delay: 5, color: 'from-purple-500 to-purple-700' },
                  ].map((building, index) => (
                    <motion.div
                      key={index}
                      className="absolute"
                      style={{ left: building.x, top: building.y }}
                      animate={{
                        boxShadow: [
                          '0 0 0 rgba(251, 191, 36, 0)',
                          '0 0 15px rgba(251, 191, 36, 0.6)',
                          '0 0 0 rgba(251, 191, 36, 0)'
                        ]
                      }}
                      transition={{
                        duration: 6,
                        repeat: Infinity,
                        delay: building.delay
                      }}
                    >
                      {/* Building Face */}
                      <div
                        className={`bg-gradient-to-b ${building.color} rounded-t-sm`}
                        style={{ width: building.w, height: building.h }}
                      />
                      {/* Building Side */}
                      <div
                        className={`absolute top-0 bg-gradient-to-b ${building.color.replace('400', '300').replace('500', '400').replace('600', '500').replace('700', '600')}`}
                        style={{
                          left: building.w,
                          width: building.w * 0.25,
                          height: building.h,
                          transform: 'skewY(-30deg) scaleY(0.866)',
                          filter: 'brightness(0.8)'
                        }}
                      />
                      {/* Building Top */}
                      <div
                        className={`absolute bg-gradient-to-br ${building.color.replace('400', '200').replace('500', '300').replace('600', '400').replace('700', '500')}`}
                        style={{
                          top: -building.w * 0.12,
                          width: building.w,
                          height: building.w * 0.25,
                          transform: 'skewX(-30deg) scaleX(1.366)',
                          filter: 'brightness(1.2)'
                        }}
                      />

                      {/* Windows avec éclairage */}
                      {Array.from({ length: Math.floor(building.h / 12) }).map((_, windowRow) => (
                        <div key={windowRow} className="absolute flex gap-0.5" style={{ top: 8 + windowRow * 12, left: 3 }}>
                          {Array.from({ length: Math.floor(building.w / 6) }).map((_, windowCol) => (
                            <motion.div
                              key={windowCol}
                              className="w-1 h-1.5 bg-yellow-300 rounded-sm"
                              animate={{
                                opacity: [0.2, 1, 0.2],
                                backgroundColor: ['#fde047', '#facc15', '#fde047']
                              }}
                              transition={{
                                duration: 2 + Math.random(),
                                repeat: Infinity,
                                delay: building.delay + windowRow * 0.1 + windowCol * 0.05
                              }}
                            />
                          ))}
                        </div>
                      ))}
                    </motion.div>
                  ))}

                  {/* Drones de livraison */}
                  {[0, 1, 2].map((droneIndex) => (
                    <motion.div
                      key={droneIndex}
                      className="absolute w-2 h-2 bg-primary-500 rounded-full shadow-lg"
                      animate={{
                        x: [40, 280, 40],
                        y: [40 + droneIndex * 25, 60 + droneIndex * 15, 40 + droneIndex * 25],
                      }}
                      transition={{
                        duration: 8,
                        repeat: Infinity,
                        delay: droneIndex * 2,
                        ease: "easeInOut"
                      }}
                    >
                      {/* Hélices */}
                      <motion.div
                        className="absolute -top-0.5 -left-0.5 w-3 h-3 border border-primary-400 rounded-full"
                        animate={{ rotate: 360 }}
                        transition={{ duration: 0.1, repeat: Infinity, ease: "linear" }}
                      />
                    </motion.div>
                  ))}

                  {/* Hologramme Smartphone Central */}
                  <motion.div
                    className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2"
                    animate={{
                      y: [0, -8, 0],
                      rotateY: [0, 360]
                    }}
                    transition={{
                      y: { duration: 3, repeat: Infinity, ease: "easeInOut" },
                      rotateY: { duration: 6, repeat: Infinity, ease: "linear" }
                    }}
                  >
                    <div className="w-12 h-18 bg-gradient-to-b from-slate-800 to-slate-900 rounded-lg shadow-xl border border-primary-400 relative overflow-hidden">
                      {/* Écran */}
                      <div className="absolute inset-0.5 bg-gradient-to-b from-blue-900 to-blue-800 rounded-md p-0.5">
                        {/* Données qui changent */}
                        <motion.div
                          className="text-xs text-white font-mono leading-tight text-center"
                          animate={{
                            opacity: [1, 0, 1]
                          }}
                          transition={{
                            duration: 2,
                            repeat: Infinity
                          }}
                        >
                          <div className="text-xs">€850</div>
                          <div className="text-green-400 text-xs">Libre</div>
                          <div className="text-xs">3ch</div>
                        </motion.div>
                      </div>

                      {/* Glow effect */}
                      <motion.div
                        className="absolute inset-0 bg-primary-400 rounded-lg opacity-30 blur-sm"
                        animate={{
                          scale: [1, 1.1, 1],
                          opacity: [0.3, 0.5, 0.3]
                        }}
                        transition={{
                          duration: 2,
                          repeat: Infinity
                        }}
                      />
                    </div>
                  </motion.div>

                  {/* Particules dorées connectant les bâtiments */}
                  {Array.from({ length: 6 }).map((_, particleIndex) => (
                    <motion.div
                      key={particleIndex}
                      className="absolute w-0.5 h-0.5 bg-primary-400 rounded-full"
                      animate={{
                        x: [Math.random() * 300, Math.random() * 300],
                        y: [Math.random() * 180, Math.random() * 180],
                        opacity: [0, 1, 0]
                      }}
                      transition={{
                        duration: 4,
                        repeat: Infinity,
                        delay: particleIndex * 0.7,
                        ease: "easeInOut"
                      }}
                    />
                  ))}
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Section Notre Culture d'Entreprise avec Animation Collaborative */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center mb-20 md:flex-row-reverse">
          <motion.div
            initial={{ opacity: 0, x: 50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.1 }}
            className="md:order-2 bg-white p-6 rounded-xl shadow-md border border-primary-100"
          >
            <motion.h3
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5 }}
              className="text-2xl font-bold text-secondary-900 mb-4 inline-flex items-center"
            >
              <span className="text-primary-300 mr-2">🤝</span>
              Notre Culture d'Entreprise
            </motion.h3>
            <motion.p
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: 0.2 }}
              className="text-secondary-700 mb-6"
            >
              Nous cultivons une culture d'innovation, de proximité et de responsabilité. Chez ChapeChapeRésidence, chaque membre de l'équipe est encouragé à proposer des idées novatrices, à rester à l'écoute des besoins des utilisateurs et à agir avec intégrité. Nous valorisons la collaboration, l'agilité et l'engagement envers l'excellence du service.
            </motion.p>
          </motion.div>

          {/* Animation Équipe Collaborative */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="rounded-xl overflow-hidden shadow-lg md:order-1"
          >
            <div className="relative w-full h-[300px] bg-gradient-to-br from-white to-gray-50 dark:from-gray-800 dark:to-gray-900 overflow-hidden">
              {/* Confettis dorés subtils en arrière-plan */}
              {Array.from({ length: 12 }).map((_, index) => (
                <motion.div
                  key={index}
                  className="absolute w-1 h-1 bg-primary-400 rounded-full"
                  style={{
                    left: `${Math.random() * 100}%`,
                    top: `${Math.random() * 100}%`
                  }}
                  animate={{
                    y: [0, -20, 0],
                    opacity: [0.3, 0.8, 0.3],
                    scale: [0.5, 1, 0.5]
                  }}
                  transition={{
                    duration: 3 + Math.random() * 2,
                    repeat: Infinity,
                    delay: index * 0.2,
                    ease: "easeInOut"
                  }}
                />
              ))}

              {/* 5 Avatars en cercle */}
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="relative w-48 h-48">
                  {[
                    { angle: 0, name: 'A', color: 'from-blue-400 to-blue-600', value: 'innovation' },
                    { angle: 72, name: 'S', color: 'from-green-400 to-green-600', value: 'proximite' },
                    { angle: 144, name: 'M', color: 'from-purple-400 to-purple-600', value: 'responsabilite' },
                    { angle: 216, name: 'L', color: 'from-orange-400 to-orange-600', value: 'collaboration' },
                    { angle: 288, name: 'K', color: 'from-pink-400 to-pink-600', value: 'excellence' }
                  ].map((avatar, index) => {
                    const radius = 80;
                    const x = Math.cos((avatar.angle * Math.PI) / 180) * radius;
                    const y = Math.sin((avatar.angle * Math.PI) / 180) * radius;

                    return (
                      <motion.div
                        key={index}
                        className="absolute w-12 h-12 rounded-full flex items-center justify-center text-white font-bold shadow-lg"
                        style={{
                          left: `calc(50% + ${x}px - 24px)`,
                          top: `calc(50% + ${y}px - 24px)`
                        }}
                        animate={{
                          scale: [1, 1.1, 1],
                          boxShadow: [
                            '0 4px 6px rgba(0, 0, 0, 0.1)',
                            '0 8px 25px rgba(251, 191, 36, 0.3)',
                            '0 4px 6px rgba(0, 0, 0, 0.1)'
                          ]
                        }}
                        transition={{
                          duration: 2,
                          repeat: Infinity,
                          delay: index * 0.4,
                          ease: "easeInOut"
                        }}
                      >
                        <div className={`w-full h-full rounded-full bg-gradient-to-br ${avatar.color} flex items-center justify-center`}>
                          {avatar.name}
                        </div>

                        {/* Badge de valeur qui apparaît/disparaît */}
                        <motion.div
                          className="absolute -top-8 left-1/2 transform -translate-x-1/2 bg-primary-500 text-white text-xs px-2 py-1 rounded-full whitespace-nowrap"
                          animate={{
                            opacity: [0, 1, 1, 0],
                            y: [5, 0, 0, 5],
                            scale: [0.8, 1, 1, 0.8]
                          }}
                          transition={{
                            duration: 4,
                            repeat: Infinity,
                            delay: index * 0.8,
                            ease: "easeInOut"
                          }}
                        >
                          {avatar.value}
                        </motion.div>
                      </motion.div>
                    );
                  })}

                  {/* Icônes dorées qui se passent entre les avatars */}
                  {[
                    { icon: '💡', path: [0, 72], delay: 0 }, // Innovation
                    { icon: '❤️', path: [72, 144], delay: 1 }, // Proximité
                    { icon: '🛡️', path: [144, 216], delay: 2 }, // Responsabilité
                    { icon: '🤝', path: [216, 288], delay: 3 }, // Collaboration
                    { icon: '⭐', path: [288, 0], delay: 4 } // Excellence
                  ].map((iconData, index) => {
                    const startAngle = iconData.path[0];
                    const endAngle = iconData.path[1];
                    const radius = 80;

                    const startX = Math.cos((startAngle * Math.PI) / 180) * radius;
                    const startY = Math.sin((startAngle * Math.PI) / 180) * radius;
                    const endX = Math.cos((endAngle * Math.PI) / 180) * radius;
                    const endY = Math.sin((endAngle * Math.PI) / 180) * radius;

                    return (
                      <motion.div
                        key={index}
                        className="absolute w-6 h-6 flex items-center justify-center text-lg"
                        style={{
                          left: `calc(50% + ${startX}px - 12px)`,
                          top: `calc(50% + ${startY}px - 12px)`
                        }}
                        animate={{
                          x: [0, endX - startX],
                          y: [0, endY - startY],
                          scale: [0.8, 1.2, 0.8],
                          rotate: [0, 180, 360]
                        }}
                        transition={{
                          duration: 5,
                          repeat: Infinity,
                          delay: iconData.delay,
                          ease: "easeInOut"
                        }}
                      >
                        {iconData.icon}
                      </motion.div>
                    );
                  })}

                  {/* Lignes de connexion animées entre les personnages */}
                  <svg className="absolute inset-0 w-full h-full" viewBox="0 0 192 192">
                    {[0, 1, 2, 3, 4].map((index) => {
                      const nextIndex = (index + 1) % 5;
                      const angle1 = index * 72;
                      const angle2 = nextIndex * 72;
                      const radius = 80;

                      const x1 = 96 + Math.cos((angle1 * Math.PI) / 180) * radius;
                      const y1 = 96 + Math.sin((angle1 * Math.PI) / 180) * radius;
                      const x2 = 96 + Math.cos((angle2 * Math.PI) / 180) * radius;
                      const y2 = 96 + Math.sin((angle2 * Math.PI) / 180) * radius;

                      return (
                        <motion.line
                          key={index}
                          x1={x1}
                          y1={y1}
                          x2={x2}
                          y2={y2}
                          stroke="#f59e0b"
                          strokeWidth="2"
                          strokeDasharray="5,5"
                          animate={{
                            strokeDashoffset: [0, -10],
                            opacity: [0.3, 0.8, 0.3]
                          }}
                          transition={{
                            strokeDashoffset: {
                              duration: 2,
                              repeat: Infinity,
                              ease: "linear"
                            },
                            opacity: {
                              duration: 3,
                              repeat: Infinity,
                              delay: index * 0.6
                            }
                          }}
                        />
                      );
                    })}
                  </svg>
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Section Nos Valeurs */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="mb-20"
        >
          <div className="text-center mb-10">
            <motion.h3
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5 }}
              className="text-2xl font-bold text-secondary-900 mb-4 inline-flex items-center justify-center"
            >
              <span className="text-primary-300 mr-2">💎</span>
              Nos Valeurs
            </motion.h3>
          </div>

          <motion.div
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-50px" }}
            className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-6"
          >
            {values.map((value, index) => (
              <motion.div
                key={value.title}
                custom={index}
                variants={itemVariants}
                whileHover={{ y: -10, scale: 1.02, transition: { duration: 0.3 } }}
                className="relative bg-white/70 backdrop-blur-sm p-6 rounded-2xl shadow-lg border border-primary-100/30 hover:shadow-2xl hover:shadow-primary-200/40 hover:border-primary-300/60 transition-all duration-300 group overflow-hidden"
              >
                {/* Glow effect on hover */}
                <motion.div
                  className="absolute inset-0 bg-gradient-to-br from-primary-100/20 to-primary-200/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-2xl"
                />
                <div className="relative z-10">
                  <motion.div
                    className="rounded-full bg-gradient-to-br from-primary-100 to-primary-200 w-14 h-14 flex items-center justify-center text-primary-600 mb-4 shadow-md group-hover:shadow-lg group-hover:shadow-primary-300/50 transition-all duration-300"
                    whileHover={{ rotate: 360 }}
                    transition={{ duration: 0.6 }}
                  >
                    {value.icon}
                  </motion.div>
                  <h4 className="text-lg font-bold text-secondary-900 mb-2">{value.title}</h4>
                  <p className="text-secondary-600 text-sm leading-relaxed">{value.description}</p>
                </div>
              </motion.div>
            ))}
          </motion.div>
        </motion.div>

        {/* Section Qui sommes-nous */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
          className="mb-10"
        >
          <div className="text-center mb-10">
            <motion.h3
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5 }}
              className="text-2xl font-bold text-secondary-900 mb-4 inline-flex items-center justify-center"
            >
              <span className="text-primary-300 mr-2">👥</span>
              Qui sommes-nous ?
            </motion.h3>
            <motion.p
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: 0.2 }}
              className="text-secondary-600 max-w-2xl mx-auto"
            >
              ChapeChapeRésidence est le fruit de la collaboration entre deux entrepreneurs passionnés par la transformation digitale du secteur immobilier en Afrique.
            </motion.p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {team.map((member, index) => (
              <motion.div
                key={member.name}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-50px" }}
                transition={{ duration: 0.5, delay: index * 0.2 }}
                whileHover={{ y: -8, scale: 1.02, transition: { duration: 0.3 } }}
                className="bg-white/90 backdrop-blur-sm rounded-2xl overflow-hidden shadow-xl hover:shadow-2xl hover:shadow-primary-200/30 border border-primary-100/30 group transition-all duration-300"
              >
                <div className="flex flex-col md:flex-row">
                  <div className="md:w-1/3 relative overflow-hidden">
                    <div className="bg-gradient-to-br from-primary-300 via-primary-400 to-primary-500 h-48 md:h-full flex items-center justify-center shadow-inner">
                      <motion.div
                        className="text-6xl font-bold text-white drop-shadow-lg"
                        whileHover={{ scale: 1.1, rotate: 5 }}
                        transition={{ duration: 0.3 }}
                      >
                        {member.name.charAt(0)}
                      </motion.div>
                    </div>
                    <motion.div
                      className="absolute inset-0 bg-gradient-to-br from-white/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                    />
                    {/* Golden accent line */}
                    <div className="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-transparent via-primary-200 to-transparent group-hover:via-primary-300 transition-all duration-300" />
                  </div>
                  <div className="p-8 md:w-2/3 relative">
                    <h4 className="text-2xl font-bold text-secondary-900 mb-2 group-hover:text-primary-700 transition-colors duration-300">{member.name}</h4>
                    <p className="text-primary-600 font-bold mb-4 text-sm tracking-wide uppercase">{member.role}</p>
                    <p className="text-secondary-600 text-sm leading-relaxed">{member.description}</p>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* Bouton de navigation */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.6 }}
          className="flex justify-center mt-8"
        >
          <a
            href="/about"
            className="inline-flex items-center gap-2 px-6 py-3 bg-primary-50 text-primary-500 rounded-full border border-primary-200 hover:bg-primary-100 transition-colors duration-300"
          >
            <span>En savoir plus sur notre entreprise</span>
            <motion.span
              initial={{ x: 0 }}
              whileHover={{ x: 5 }}
              transition={{ duration: 0.2 }}
            >
              →
            </motion.span>
          </a>
        </motion.div>
      </div>
    </section>
  );
}

export default AboutSection; 