import { useRef } from 'react';
import { motion, useScroll, useTransform } from 'framer-motion';
import {
  SparklesIcon,
  HandRaisedIcon,
  LightBulbIcon,
  HeartIcon,
  ShieldCheckIcon,
  StarIcon,
  UserGroupIcon,
  BuildingOffice2Icon,
  FlagIcon,
  RocketLaunchIcon,
  MapPinIcon,
} from '@heroicons/react/24/outline';

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

  // Données de l'équipe (format capture: initiales, rôle, tags)
  const team = [
    {
      name: "Adams Diaby",
      shortName: "A. Diaby",
      role: "CEO & CO-FONDATEUR",
      description: "Fondateur de Onloutou, une plateforme de location d'équipements, Adams est un visionnaire du numérique en Afrique de l'Ouest. Il apporte son expertise en gestion de projets digitaux et sa connaissance approfondie du marché ivoirien.",
      image: "/assets/team/adams_diaby.jpg",
      techTag: "Tech & Produit",
      location: "Basé à Abidjan",
    },
    {
      name: "Sidney Jordan",
      shortName: "S. Jordan",
      role: "CTO & CO-FONDATEUR",
      description: "Fondateur de Soutrali Deals, une plateforme numérique ivoirienne qui valorise les produits, services et talents issus de l'économie informelle et artisanale. Sidney est responsable de la stratégie technologique et du développement de la plateforme.",
      image: "/assets/team/sidney-jordan.jpg",
      techTag: "Tech & Engineering",
      location: "Basé à Abidjan",
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
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="inline-flex items-center px-4 py-2 rounded-full bg-white shadow-sm border border-primary-100 text-primary-800 text-xs font-bold tracking-widest uppercase mb-6 font-body"
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
            className="bg-white/80 backdrop-blur-sm p-8 rounded-3xl shadow-xl border border-secondary-100 hover:shadow-2xl transition-all duration-500 group"
          >
            <motion.h3
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="text-2xl font-bold bg-gradient-to-r from-secondary-900 to-primary-600 bg-clip-text text-transparent mb-4 inline-flex items-center group-hover:scale-105 transition-transform duration-300 font-display"
            >
              <motion.span
                initial={{ rotate: 0 }}
                whileInView={{ rotate: 360 }}
                viewport={{ once: true }}
                transition={{ duration: 1, delay: 0.3 }}
                className="mr-3 flex shrink-0 text-primary-500"
              >
                <SparklesIcon className="w-7 h-7" strokeWidth={2} aria-hidden />
              </motion.span>
              Notre Vision
            </motion.h3>
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="text-secondary-600 dark:text-secondary-400 mb-6 text-base leading-relaxed font-body"
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
            <div className="relative w-full h-[300px] bg-gradient-to-br from-secondary-50 to-secondary-100 dark:from-secondary-800 dark:to-secondary-900 overflow-hidden">
              {/* Background Grid */}
              <div className="absolute inset-0 opacity-20">
                <svg className="w-full h-full" viewBox="0 0 400 300">
                  <defs>
                    <pattern id="grid-vision" width="20" height="20" patternUnits="userSpaceOnUse">
                      <path d="M 20 0 L 0 0 0 20" fill="none" stroke="currentColor" strokeWidth="0.5" />
                    </pattern>
                  </defs>
                  <rect width="100%" height="100%" fill="url(#grid-vision)" className="text-secondary-400" />
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
              className="text-2xl font-bold text-secondary-900 dark:text-white mb-4 inline-flex items-center font-display"
            >
              <span className="mr-2 flex shrink-0 text-primary-500" aria-hidden>
                <HandRaisedIcon className="w-7 h-7" strokeWidth={2} />
              </span>
              Notre Culture d'Entreprise
            </motion.h3>
            <motion.p
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: 0.2 }}
              className="text-secondary-600 dark:text-secondary-400 mb-6 font-body"
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
            <div className="relative w-full h-[300px] bg-gradient-to-br from-white to-secondary-50 dark:from-secondary-800 dark:to-secondary-900 overflow-hidden">
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
                    { angle: 0, name: 'A', color: 'from-primary-400 to-primary-600', value: 'innovation' },
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

                  {/* Icônes Heroicons qui se passent entre les avatars */}
                  {[
                    { Icon: LightBulbIcon, path: [0, 72], delay: 0 },
                    { Icon: HeartIcon, path: [72, 144], delay: 1 },
                    { Icon: ShieldCheckIcon, path: [144, 216], delay: 2 },
                    { Icon: HandRaisedIcon, path: [216, 288], delay: 3 },
                    { Icon: StarIcon, path: [288, 0], delay: 4 }
                  ].map((iconData, index) => {
                    const startAngle = iconData.path[0];
                    const endAngle = iconData.path[1];
                    const radius = 80;

                    const startX = Math.cos((startAngle * Math.PI) / 180) * radius;
                    const startY = Math.sin((startAngle * Math.PI) / 180) * radius;
                    const endX = Math.cos((endAngle * Math.PI) / 180) * radius;
                    const endY = Math.sin((endAngle * Math.PI) / 180) * radius;

                    const { Icon } = iconData;
                    return (
                      <motion.div
                        key={index}
                        className="absolute w-6 h-6 flex items-center justify-center text-primary-500"
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
                        <Icon className="w-6 h-6" strokeWidth={2} aria-hidden />
                      </motion.div>
                    );
                  })}

                  {/* Lignes de connexion animées entre les personnages */}
                  <svg className="absolute inset-0 w-full h-full text-primary-500" viewBox="0 0 192 192" aria-hidden>
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
                          stroke="currentColor"
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

        {/* Section Nos Valeurs — Bento Grid Dark Premium */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.7 }}
          className="mb-20"
        >
          <div className="relative rounded-3xl overflow-hidden bg-secondary-900 border border-white/10 p-6 md:p-10 shadow-2xl">

            {/* Glow ambiant central */}
            <motion.div
              className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[500px] rounded-full bg-primary-500/8 blur-[120px] pointer-events-none"
              animate={{ scale: [1, 1.12, 1], opacity: [0.5, 0.9, 0.5] }}
              transition={{ duration: 7, repeat: Infinity, ease: "easeInOut" }}
            />

            {/* Grille de points décorative */}
            <div
              className="absolute inset-0 opacity-[0.035] pointer-events-none"
              style={{ backgroundImage: 'radial-gradient(circle, #D4AF37 1px, transparent 1px)', backgroundSize: '32px 32px' }}
            />

            {/* En-tête */}
            <div className="relative z-10 text-center mb-8">
              <motion.div
                initial={{ opacity: 0, scale: 0.8 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5 }}
                className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border border-primary-500/40 bg-primary-500/10 text-primary-300 text-xs font-bold tracking-widest uppercase mb-4 font-body"
              >
                <SparklesIcon className="w-3.5 h-3.5" strokeWidth={2.5} />
                Ce qui nous définit
              </motion.div>
              <h3 className="text-3xl md:text-4xl font-bold text-white mb-2 font-display tracking-tight">
                Nos <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-300 to-primary-500">Valeurs</span>
              </h3>
              <p className="text-secondary-400 text-sm md:text-base max-w-xl mx-auto font-body">
                Les principes qui guident chacune de nos décisions et actions au quotidien.
              </p>
            </div>

            {/* Bento Grid — row 1 : Accessibilité large + Confiance */}
            <div className="relative z-10 grid grid-cols-1 lg:grid-cols-3 gap-4 mb-4">

              {/* Accessibilité — 2/3 avec orbite animée */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.05 }}
                whileHover={{ scale: 1.01 }}
                className="group lg:col-span-2 relative rounded-2xl border border-white/8 bg-white/[0.03] backdrop-blur-sm overflow-hidden transition-all duration-300 hover:border-primary-500/40 hover:bg-white/[0.05]"
              >
                <div className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500 bg-[radial-gradient(ellipse_at_top_left,rgba(212,175,55,0.07),transparent_55%)] pointer-events-none" />
                <div className="absolute top-0 left-10 right-10 h-px bg-gradient-to-r from-transparent via-primary-500/40 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

                <div className="flex items-center justify-between p-7 h-full min-h-[160px]">
                  {/* Contenu gauche */}
                  <div className="flex items-start gap-4 flex-1 min-w-0 pr-6">
                    <div className="shrink-0 w-12 h-12 rounded-xl bg-primary-500/15 border border-primary-500/30 flex items-center justify-center text-primary-400 group-hover:bg-primary-500/25 group-hover:border-primary-400/60 transition-all duration-300">
                      {values[0].icon}
                    </div>
                    <div>
                      <h4 className="text-base font-bold text-white mb-1.5 font-display">{values[0].title}</h4>
                      <p className="text-secondary-400 text-sm leading-relaxed font-body">{values[0].description}</p>
                    </div>
                  </div>

                  {/* Orbite animée droite */}
                  <div className="shrink-0 relative w-28 h-28">
                    {/* Cercle extérieur */}
                    <div className="absolute inset-0 rounded-full border border-primary-500/20" />
                    {/* Cercle intérieur */}
                    <div className="absolute inset-[18px] rounded-full border border-primary-400/15" />
                    {/* Centre */}
                    <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-2.5 h-2.5 rounded-full bg-primary-500/50 shadow-[0_0_10px_#D4AF37]" />
                    {/* Orbe 1 — orbite externe, sens horaire */}
                    <motion.div
                      className="absolute inset-0"
                      animate={{ rotate: 360 }}
                      transition={{ duration: 7, repeat: Infinity, ease: "linear" }}
                    >
                      <div className="absolute -top-[5px] left-1/2 -translate-x-1/2 w-2.5 h-2.5 rounded-full bg-primary-400 shadow-[0_0_10px_rgba(212,175,55,0.9)]" />
                    </motion.div>
                    {/* Orbe 2 — orbite interne, sens anti-horaire */}
                    <motion.div
                      className="absolute inset-[18px]"
                      animate={{ rotate: -360 }}
                      transition={{ duration: 5, repeat: Infinity, ease: "linear" }}
                    >
                      <div className="absolute -top-[4px] left-1/2 -translate-x-1/2 w-2 h-2 rounded-full bg-primary-300/70 shadow-[0_0_6px_rgba(212,175,55,0.6)]" />
                    </motion.div>
                    {/* Trait de connexion orbital (arc SVG) */}
                    <svg className="absolute inset-0 w-full h-full opacity-20" viewBox="0 0 112 112">
                      <circle cx="56" cy="56" r="50" fill="none" stroke="#D4AF37" strokeWidth="0.5" strokeDasharray="3 6" />
                      <circle cx="56" cy="56" r="32" fill="none" stroke="#D4AF37" strokeWidth="0.5" strokeDasharray="2 8" />
                    </svg>
                  </div>
                </div>
              </motion.div>

              {/* Confiance — 1/3 avec forme wave */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.12 }}
                whileHover={{ scale: 1.02 }}
                className="group relative rounded-2xl border border-white/8 bg-white/[0.03] backdrop-blur-sm overflow-hidden transition-all duration-300 hover:border-primary-500/40 hover:bg-white/[0.05]"
              >
                <div className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500 bg-[radial-gradient(ellipse_at_top_right,rgba(212,175,55,0.07),transparent_55%)] pointer-events-none" />
                <div className="absolute top-0 left-6 right-6 h-px bg-gradient-to-r from-transparent via-primary-500/40 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

                {/* Forme wave décorative en fond */}
                <svg className="absolute bottom-0 right-0 opacity-[0.07] group-hover:opacity-[0.14] transition-opacity duration-500 pointer-events-none" width="120" height="100" viewBox="0 0 120 100">
                  <motion.path
                    d="M120 100 C80 60, 60 80, 40 40 C20 0, 0 20, -10 0"
                    fill="none" stroke="#D4AF37" strokeWidth="40"
                    animate={{ pathLength: [0.4, 1, 0.4] }}
                    transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
                  />
                </svg>
                <motion.div
                  className="absolute bottom-2 right-2 w-20 h-20 rounded-full bg-primary-500/10 blur-2xl pointer-events-none"
                  animate={{ scale: [1, 1.3, 1], opacity: [0.3, 0.6, 0.3] }}
                  transition={{ duration: 3.5, repeat: Infinity, ease: "easeInOut" }}
                />

                <div className="p-7 min-h-[160px] flex flex-col justify-between">
                  <div>
                    <div className="w-11 h-11 rounded-xl bg-primary-500/15 border border-primary-500/30 flex items-center justify-center text-primary-400 mb-4 group-hover:bg-primary-500/25 group-hover:border-primary-400/60 transition-all duration-300">
                      {values[1].icon}
                    </div>
                    <h4 className="text-base font-bold text-white mb-1.5 font-display">{values[1].title}</h4>
                    <p className="text-secondary-400 text-sm leading-relaxed font-body">{values[1].description}</p>
                  </div>
                </div>
              </motion.div>
            </div>

            {/* Bento Grid — row 2 : 3 cartes égales */}
            <div className="relative z-10 grid grid-cols-1 sm:grid-cols-3 gap-4">

              {/* Innovation — avec orbite mini */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.18 }}
                whileHover={{ scale: 1.02 }}
                className="group relative rounded-2xl border border-white/8 bg-white/[0.03] backdrop-blur-sm overflow-hidden transition-all duration-300 hover:border-primary-500/40 hover:bg-white/[0.05]"
              >
                <div className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500 bg-[radial-gradient(ellipse_at_bottom_left,rgba(212,175,55,0.07),transparent_55%)] pointer-events-none" />
                <div className="absolute top-0 left-6 right-6 h-px bg-gradient-to-r from-transparent via-primary-500/40 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

                {/* Mini orbite coin bas-droit */}
                <div className="absolute bottom-3 right-3 w-14 h-14 opacity-30 group-hover:opacity-60 transition-opacity duration-300">
                  <div className="absolute inset-0 rounded-full border border-primary-400/50" />
                  <motion.div className="absolute inset-0" animate={{ rotate: 360 }} transition={{ duration: 5, repeat: Infinity, ease: "linear" }}>
                    <div className="absolute -top-[3px] left-1/2 -translate-x-1/2 w-1.5 h-1.5 rounded-full bg-primary-400 shadow-[0_0_6px_#D4AF37]" />
                  </motion.div>
                  <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-1 h-1 rounded-full bg-primary-500" />
                </div>

                <div className="p-7 min-h-[160px] flex flex-col">
                  <div className="w-11 h-11 rounded-xl bg-primary-500/15 border border-primary-500/30 flex items-center justify-center text-primary-400 mb-4 group-hover:bg-primary-500/25 group-hover:border-primary-400/60 transition-all duration-300">
                    {values[2].icon}
                  </div>
                  <h4 className="text-base font-bold text-white mb-1.5 font-display">{values[2].title}</h4>
                  <p className="text-secondary-400 text-sm leading-relaxed font-body">{values[2].description}</p>
                </div>
              </motion.div>

              {/* Responsabilité — avec wave abstract */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.24 }}
                whileHover={{ scale: 1.02 }}
                className="group relative rounded-2xl border border-white/8 bg-white/[0.03] backdrop-blur-sm overflow-hidden transition-all duration-300 hover:border-primary-500/40 hover:bg-white/[0.05]"
              >
                <div className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500 bg-[radial-gradient(ellipse_at_top,rgba(212,175,55,0.07),transparent_55%)] pointer-events-none" />
                <div className="absolute top-0 left-6 right-6 h-px bg-gradient-to-r from-transparent via-primary-500/40 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

                {/* Vagues abstraites en fond (inspiré capture 3) */}
                <svg className="absolute inset-0 w-full h-full opacity-[0.06] group-hover:opacity-[0.12] transition-opacity duration-500 pointer-events-none" viewBox="0 0 200 160" preserveAspectRatio="xMidYMid slice">
                  {[0,1,2].map(i => (
                    <motion.ellipse
                      key={i}
                      cx={100 + i * 20} cy={130 + i * 20} rx={80 + i * 30} ry={50 + i * 15}
                      fill="none" stroke="#D4AF37" strokeWidth="12"
                      animate={{ cy: [130 + i*20, 110 + i*20, 130 + i*20] }}
                      transition={{ duration: 4 + i, repeat: Infinity, ease: "easeInOut", delay: i * 0.8 }}
                    />
                  ))}
                </svg>

                <div className="p-7 min-h-[160px] flex flex-col">
                  <div className="w-11 h-11 rounded-xl bg-primary-500/15 border border-primary-500/30 flex items-center justify-center text-primary-400 mb-4 group-hover:bg-primary-500/25 group-hover:border-primary-400/60 transition-all duration-300">
                    {values[3].icon}
                  </div>
                  <h4 className="text-base font-bold text-white mb-1.5 font-display">{values[3].title}</h4>
                  <p className="text-secondary-400 text-sm leading-relaxed font-body">{values[3].description}</p>
                </div>
              </motion.div>

              {/* Excellence — accentuée or + double orbite */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.30 }}
                whileHover={{ scale: 1.02 }}
                className="group relative rounded-2xl border border-primary-500/30 bg-secondary-800/60 backdrop-blur-sm overflow-hidden transition-all duration-300 hover:border-primary-400/55 hover:bg-secondary-800/70"
              >
                <div className="absolute top-0 left-6 right-6 h-px bg-gradient-to-r from-transparent via-primary-400/60 to-transparent" />
                <div className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500 bg-[radial-gradient(ellipse_at_bottom_right,rgba(212,175,55,0.08),transparent_60%)] pointer-events-none" />

                {/* Double orbite coin haut-droite */}
                <div className="absolute top-4 right-4 w-16 h-16 opacity-40 group-hover:opacity-70 transition-opacity duration-300">
                  <div className="absolute inset-0 rounded-full border border-primary-400/60" />
                  <div className="absolute inset-[10px] rounded-full border border-primary-300/40" />
                  <motion.div className="absolute inset-0" animate={{ rotate: 360 }} transition={{ duration: 6, repeat: Infinity, ease: "linear" }}>
                    <div className="absolute -top-[4px] left-1/2 -translate-x-1/2 w-2 h-2 rounded-full bg-primary-400 shadow-[0_0_8px_rgba(212,175,55,0.9)]" />
                  </motion.div>
                  <motion.div className="absolute inset-[10px]" animate={{ rotate: -360 }} transition={{ duration: 4, repeat: Infinity, ease: "linear" }}>
                    <div className="absolute -top-[3px] left-1/2 -translate-x-1/2 w-1.5 h-1.5 rounded-full bg-primary-300/80 shadow-[0_0_5px_rgba(212,175,55,0.6)]" />
                  </motion.div>
                  <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-full bg-primary-500 shadow-[0_0_8px_#D4AF37]" />
                </div>

                <div className="p-7 min-h-[160px] flex flex-col">
                  <div className="w-11 h-11 rounded-xl bg-primary-500/20 border border-primary-400/50 flex items-center justify-center text-primary-300 mb-4 group-hover:bg-primary-500/30 group-hover:border-primary-400/70 transition-all duration-300">
                    {values[4].icon}
                  </div>
                  <h4 className="text-base font-bold text-white mb-1.5 font-display">{values[4].title}</h4>
                  <p className="text-secondary-400 text-sm leading-relaxed font-body">{values[4].description}</p>
                </div>
              </motion.div>

            </div>
          </div>
        </motion.div>

        {/* Section Qui sommes-nous — Layout zigzag alterné */}
        <div className="mb-16">
          {/* En-tête */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <div className="inline-flex items-center justify-center w-12 h-12 rounded-2xl bg-primary-50 dark:bg-primary-900/30 border border-primary-200 dark:border-primary-700 text-primary-500 mb-5">
              <UserGroupIcon className="w-6 h-6" strokeWidth={2} />
            </div>
            <h3 className="text-2xl md:text-3xl font-bold text-secondary-900 dark:text-white mb-3 font-display">
              Qui sommes-nous ?
            </h3>
            <p className="text-secondary-500 dark:text-secondary-400 text-sm md:text-base max-w-xl mx-auto font-body leading-relaxed">
              ChapeChapeRésidence est le fruit de la collaboration entre deux entrepreneurs passionnés par la transformation digitale du secteur immobilier en Afrique.
            </p>
          </motion.div>

          {/* Membres en zigzag */}
          <div className="space-y-24">
            {team.map((member, index) => {
              const isEven = index % 2 === 0;
              return (
                <motion.div
                  key={member.name}
                  initial={{ opacity: 0, y: 40 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true, margin: "-80px" }}
                  transition={{ duration: 0.7, ease: "easeOut" }}
                  className={`flex flex-col ${isEven ? 'lg:flex-row' : 'lg:flex-row-reverse'} items-center gap-12 lg:gap-16`}
                >
                  {/* Visuel — carte avatar premium */}
                  <div className="w-full lg:w-5/12 shrink-0">
                    <motion.div
                      initial={{ opacity: 0, x: isEven ? -30 : 30 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      viewport={{ once: true }}
                      transition={{ duration: 0.7, delay: 0.15 }}
                      className="relative overflow-hidden aspect-[3/4] rounded-2xl"
                    >
                      {/* Photo plein cadre */}
                      <img
                        src={member.image}
                        alt={member.name}
                        className="absolute inset-0 w-full h-full object-cover object-center"
                      />
                      {/* Overlay dégradé bas pour lisibilité */}
                      <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/75 via-secondary-900/10 to-transparent" />

                      {/* Infos en bas */}
                      <div className="absolute bottom-0 left-0 right-0 p-6 z-10">
                        <p className="text-white font-bold text-xl font-display mb-0.5">{member.name}</p>
                        <p className="text-primary-300 text-xs font-semibold tracking-widest uppercase font-body mb-4">{member.role}</p>
                        <a
                          href="https://www.linkedin.com"
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/10 backdrop-blur-sm border border-white/20 text-white text-xs font-semibold hover:bg-white/20 transition-all duration-200 font-body"
                          aria-label="LinkedIn"
                        >
                          <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24" aria-hidden>
                            <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                          </svg>
                          Voir le profil
                        </a>
                      </div>

                      {/* Badge coin haut-droit */}
                      <div className="absolute top-4 right-4 px-3 py-1 rounded-full bg-secondary-900/50 backdrop-blur-sm text-white/90 text-xs font-bold tracking-wider font-body border border-white/10">
                        Co-fondateur
                      </div>
                    </motion.div>
                  </div>

                  {/* Contenu texte */}
                  <motion.div
                    initial={{ opacity: 0, x: isEven ? 30 : -30 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.7, delay: 0.25 }}
                    className="w-full lg:w-7/12"
                  >
                    {/* Badge rôle */}
                    <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-primary-50 dark:bg-primary-900/20 border border-primary-200 dark:border-primary-700 text-primary-700 dark:text-primary-300 text-xs font-bold tracking-widest uppercase mb-5 font-body">
                      <RocketLaunchIcon className="w-3.5 h-3.5" strokeWidth={2.5} />
                      {member.role}
                    </div>

                    {/* Nom */}
                    <h4 className="text-3xl md:text-4xl font-bold text-secondary-900 dark:text-white mb-4 font-display leading-tight">
                      {member.name}
                    </h4>

                    {/* Séparateur doré */}
                    <div className="flex items-center gap-3 mb-6">
                      <div className="w-10 h-0.5 bg-primary-500 rounded-full" />
                      <div className="w-2 h-2 rounded-full bg-primary-500" />
                    </div>

                    {/* Description */}
                    <p className="text-secondary-600 dark:text-secondary-400 text-base leading-relaxed font-body mb-8">
                      {member.description}
                    </p>

                    {/* Pills */}
                    <div className="flex flex-wrap gap-3">
                      <span className="inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold font-body bg-secondary-900 dark:bg-white/10 text-white border border-secondary-700 dark:border-white/10">
                        <RocketLaunchIcon className="w-4 h-4 text-primary-400" strokeWidth={2} aria-hidden />
                        {member.techTag}
                      </span>
                      <span className="inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold font-body bg-white dark:bg-secondary-800 border border-primary-300 dark:border-primary-600 text-primary-700 dark:text-primary-300">
                        <MapPinIcon className="w-4 h-4" strokeWidth={2} aria-hidden />
                        {member.location}
                      </span>
                    </div>
                  </motion.div>
                </motion.div>
              );
            })}
          </div>

          {/* Séparateur entre les deux membres */}
          <div className="relative my-16 flex items-center justify-center">
            <div className="absolute inset-x-0 h-px bg-gradient-to-r from-transparent via-secondary-200 dark:via-secondary-700 to-transparent" />
            <div className="relative bg-white dark:bg-secondary-900 px-4">
              <div className="w-8 h-8 rounded-full border-2 border-primary-400 flex items-center justify-center">
                <div className="w-2 h-2 rounded-full bg-primary-500" />
              </div>
            </div>
          </div>
        </div>

        {/* Barre Statistiques & Mission — format capture */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="rounded-2xl overflow-hidden border border-secondary-200 dark:border-secondary-700 border-b-0"
        >
          <div className="bg-gradient-to-r from-primary-400 to-primary-600 px-6 py-8 md:py-10">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-8 md:gap-6">
              {[
                { value: '2023', label: 'Année de création', Icon: BuildingOffice2Icon },
                { value: '2', label: 'Co-fondateurs', Icon: UserGroupIcon },
                { value: '100%', label: 'Focus Afrique de l\'Ouest', Icon: FlagIcon },
                { value: 'Mission', label: 'Transformer l\'immobilier', Icon: HeartIcon },
              ].map((stat, index) => {
                const StatIcon = stat.Icon;
                return (
                  <div key={index} className="flex flex-col items-center text-center">
                    <span className="text-secondary-900 mb-2" aria-hidden>
                      <StatIcon className="w-8 h-8 mx-auto" strokeWidth={2} />
                    </span>
                    <span className="text-secondary-900 font-bold text-lg md:text-xl font-display block">{stat.value}</span>
                    <span className="text-secondary-800/90 text-sm font-body">{stat.label}</span>
                  </div>
                );
              })}
            </div>
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
            className="inline-flex items-center gap-2 px-6 py-3 rounded-full border-2 border-primary-500 bg-primary-200 text-secondary-900 font-semibold hover:bg-primary-300 transition-colors duration-300 font-body"
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