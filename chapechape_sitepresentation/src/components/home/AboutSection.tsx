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
      className="relative py-24 overflow-hidden bg-gradient-to-b from-secondary-50 to-white"
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
          <h2 className="text-3xl font-bold text-secondary-900 mb-4 font-display">À propos de ChapeChape Residence</h2>
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-secondary-600 max-w-2xl mx-auto"
          >
            Découvrez notre vision, nos valeurs et l'équipe qui fait de ChapeChape Residence une référence en Afrique de l'Ouest.
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
        
        {/* Section Notre Vision */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center mb-20">
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.1 }}
            className="bg-white p-6 rounded-xl shadow-md border border-primary-100"
          >
            <motion.h3 
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5 }}
              className="text-2xl font-bold text-secondary-900 mb-4 inline-flex items-center"
            >
              <span className="text-primary-300 mr-2">🌟</span>
              Notre Vision
            </motion.h3>
            <motion.p 
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: 0.2 }}
              className="text-secondary-700 mb-6"
            >
              ChapeChapeRésidence aspire à devenir la référence en Afrique de l'Ouest pour la réservation, la gestion et la valorisation de résidences meublées et de logements temporaires. Nous visons à simplifier l'accès à des hébergements de qualité, en connectant efficacement propriétaires et locataires grâce à une plateforme numérique intuitive et sécurisée.
            </motion.p>
            
            {/* Ajout d'une illustration distinctive */}
            <div className="mt-4 flex justify-center">
              <motion.div
                initial={{ opacity: 0, scale: 0.8 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.3 }}
                className="w-24 h-24 bg-primary-50 rounded-full flex items-center justify-center"
              >
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-12 h-12 text-primary-400">
                  <path d="M11.7 2.805a.75.75 0 01.6 0A60.65 60.65 0 0122.83 8.72a.75.75 0 01-.231 1.337 49.949 49.949 0 00-9.902 3.912l-.003.002-.34.18a.75.75 0 01-.707 0A50.009 50.009 0 007.5 12.174v-.224c0-.131.067-.248.172-.311a54.614 54.614 0 014.653-2.52.75.75 0 00-.65-1.352 56.129 56.129 0 00-4.78 2.589 1.858 1.858 0 00-.859 1.228 49.803 49.803 0 00-4.634-1.527.75.75 0 01-.231-1.337A60.653 60.653 0 0111.7 2.805z" />
                  <path d="M13.06 15.473a48.45 48.45 0 017.666-3.282c.134 1.414.22 2.843.255 4.285a.75.75 0 01-.46.71 47.878 47.878 0 00-8.105 4.342.75.75 0 01-.832 0 47.877 47.877 0 00-8.104-4.342.75.75 0 01-.461-.71c.035-1.442.121-2.87.255-4.286A48.4 48.4 0 016 13.18v1.27a1.5 1.5 0 00-.14 2.508c-.09.38-.222.753-.397 1.11.452.213.901.434 1.346.661a6.729 6.729 0 00.551-1.608 1.5 1.5 0 00.14-2.67v-.645a48.549 48.549 0 013.44 1.668 2.25 2.25 0 002.12 0z" />
                  <path d="M4.462 19.462c.42-.419.753-.89 1-1.394.453.213.902.434 1.347.661a6.743 6.743 0 01-1.286 1.794.75.75 0 11-1.06-1.06z" />
                </svg>
              </motion.div>
            </div>
          </motion.div>
          
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="rounded-xl overflow-hidden shadow-lg"
          >
            <div className="bg-[url('/assets/vision.jpg')] h-[300px] bg-cover bg-center"></div>
          </motion.div>
        </div>
        
        {/* Section Notre Culture d'Entreprise */}
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
            
            {/* Ajout d'une illustration distinctive */}
            <div className="mt-4 flex justify-center">
              <motion.div
                initial={{ opacity: 0, scale: 0.8 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: 0.3 }}
                className="w-24 h-24 bg-primary-50 rounded-full flex items-center justify-center"
              >
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-12 h-12 text-primary-400">
                  <path fillRule="evenodd" d="M8.25 6.75a3.75 3.75 0 117.5 0 3.75 3.75 0 01-7.5 0zM15.75 9.75a3 3 0 116 0 3 3 0 01-6 0zM2.25 9.75a3 3 0 116 0 3 3 0 01-6 0zM6.31 15.117A6.745 6.745 0 0112 12a6.745 6.745 0 016.709 7.498.75.75 0 01-.372.568A12.696 12.696 0 0112 21.75c-2.305 0-4.47-.612-6.337-1.684a.75.75 0 01-.372-.568 6.787 6.787 0 011.019-4.38z" />
                  <path d="M5.082 14.254a8.287 8.287 0 00-1.308 5.135 9.687 9.687 0 01-1.764-.44l-.115-.04a.563.563 0 01-.373-.487l-.01-.121a3.75 3.75 0 013.57-4.047zM20.226 19.389a8.287 8.287 0 00-1.308-5.135 3.75 3.75 0 013.57 4.047l-.01.121a.563.563 0 01-.373.486l-.115.04c-.567.2-1.156.349-1.764.441z" />
                </svg>
              </motion.div>
            </div>
          </motion.div>
          
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="rounded-xl overflow-hidden shadow-lg md:order-1"
          >
            <div className="bg-[url('/assets/culture.jpg')] h-[300px] bg-cover bg-center"></div>
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
                whileHover={{ y: -10, transition: { duration: 0.2 } }}
                className="bg-white p-6 rounded-xl shadow-md border border-primary-100/20 hover:shadow-lg hover:border-primary-200/40 transition-all duration-300"
              >
                <div className="rounded-full bg-primary-100 w-12 h-12 flex items-center justify-center text-primary-500 mb-4">
                  {value.icon}
                </div>
                <h4 className="text-lg font-semibold text-secondary-900 mb-2">{value.title}</h4>
                <p className="text-secondary-600 text-sm">{value.description}</p>
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
                whileHover={{ y: -5, transition: { duration: 0.2 } }}
                className="bg-white rounded-xl overflow-hidden shadow-lg group"
              >
                <div className="flex flex-col md:flex-row">
                  <div className="md:w-1/3 relative overflow-hidden">
                    <div className="bg-gradient-to-br from-primary-200 to-primary-300 h-48 md:h-full flex items-center justify-center">
                      <div className="text-4xl font-bold text-secondary-800">{member.name.charAt(0)}</div>
                    </div>
                    <motion.div
                      className="absolute inset-0 bg-gradient-to-br from-primary-300/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                    />
                  </div>
                  <div className="p-6 md:w-2/3">
                    <h4 className="text-xl font-semibold text-secondary-900 mb-1">{member.name}</h4>
                    <p className="text-primary-500 font-medium mb-3">{member.role}</p>
                    <p className="text-secondary-600 text-sm">{member.description}</p>
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