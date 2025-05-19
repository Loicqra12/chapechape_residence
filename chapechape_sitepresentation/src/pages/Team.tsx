import { useEffect } from 'react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';

const Team = () => {
  useEffect(() => {
    window.scrollTo(0, 0);
    
    // Nettoyer tout texte parasite qui pourrait être généré
    const cleanup = () => {
      // Sélectionner et supprimer tout texte inattendu dans les conteneurs d'images
      const imageContainers = document.querySelectorAll('.image-container, .advisor-image-container, .team-image-container');
      imageContainers.forEach(container => {
        // Ne garder que l'image et supprimer les autres nœuds texte
        const img = container.querySelector('img');
        if (img && container.childNodes.length > 1) {
          container.innerHTML = '';
          container.appendChild(img);
        }
      });
    };
    
    // Exécuter le nettoyage après rendu
    cleanup();
    // Et périodiquement pour s'assurer qu'aucun texte n'apparaît
    const interval = setInterval(cleanup, 1000);
    
    return () => clearInterval(interval);
  }, []);

  // Données de l'équipe dirigeante
  const coreTeam = [
    {
      name: "Adams Diaby",
      role: "CEO & Co-fondateur",
      description: "Fondateur de Onloutou, une plateforme de location d'équipements, Adams est un visionnaire du numérique en Afrique de l'Ouest. Il apporte son expertise en gestion de projets digitaux et sa connaissance approfondie du marché ivoirien.",
      image: "/assets/team/adams-diaby.jpg",
      linkedin: "https://ci.linkedin.com/in/ousmane-adams-diaby-6b8a72156",
    },
    {
      name: "Sidney Jordan",
      role: "CTO & Co-fondateur",
      description: "Fondateur de Soutrali Deals, une plateforme numérique ivoirienne qui valorise les produits, services et talents issus de l'économie informelle et artisanale. Sidney est responsable de la stratégie technologique et du développement de la plateforme.",
      image: "/assets/team/sidney-jordan.jpg",
      linkedin: "https://ci.linkedin.com/in/sidney-jordan-39587a283",
      github: "loicqra12",
    }
  ];

  // Données de l'équipe élargie
  const extendedTeam = [
    {
      name: "Marie Konan",
      role: "Responsable Relations Clients",
      description: "Avec plus de 8 ans d'expérience dans le service client, Marie assure une expérience exceptionnelle pour tous les utilisateurs de ChapeChape Residence.",
      image: "/assets/team/team-placeholder.jpg",
    },
    {
      name: "Jean Kouassi",
      role: "Responsable Marketing",
      description: "Expert en stratégies marketing digitales, Jean développe et met en œuvre des campagnes innovantes pour accroître la visibilité de ChapeChape Residence.",
      image: "/assets/team/team-placeholder.jpg",
    },
    {
      name: "Aya Touré",
      role: "Spécialiste Immobilier",
      description: "Avec une solide expérience dans le secteur immobilier ivoirien, Aya assure la qualité et la conformité des résidences proposées sur notre plateforme.",
      image: "/assets/team/team-placeholder.jpg",
    },
    {
      name: "Kofi Mensah",
      role: "Développeur Frontend",
      description: "Passionné par l'expérience utilisateur, Kofi crée des interfaces élégantes et intuitives qui font de ChapeChape Residence un plaisir à utiliser.",
      image: "/assets/team/team-placeholder.jpg",
    }
  ];

  // Données des conseillers
  const advisors = [
    {
      name: "Dr. Amina Sanogo",
      role: "Conseillère Stratégique",
      description: "Professeure en économie numérique à l'Université de Cocody, Dr. Sanogo apporte son expertise académique et sa vision du développement digital en Afrique de l'Ouest.",
      image: "/assets/team/team-placeholder.jpg",
    },
    {
      name: "Pascal Affi",
      role: "Conseiller Immobilier",
      description: "Avec 20 ans d'expérience dans l'immobilier de luxe à Abidjan, Pascal guide notre stratégie de sélection des propriétés et notre développement commercial.",
      image: "/assets/team/team-placeholder.jpg",
    }
  ];

  // Animation variants
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.2
      }
    }
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: 0.5
      }
    }
  };

  return (
    <div className="bg-white min-h-screen">
      {/* Hero Section */}
      <section className="relative py-20 bg-secondary-50 overflow-hidden">
        {/* Background decoration */}
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(212,175,55,0.05),transparent_70%)] -z-10" />
        <div className="absolute inset-0 bg-[linear-gradient(135deg,rgba(212,175,55,0.03)_1px,transparent_1px),linear-gradient(45deg,rgba(212,175,55,0.03)_1px,transparent_1px)] bg-[size:40px_40px] -z-10" />
        
        <div className="container-custom">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center max-w-3xl mx-auto"
          >
            <h1 className="text-4xl md:text-5xl font-bold text-secondary-900 mb-6 font-display">Notre Équipe</h1>
            <p className="text-lg text-secondary-600 mb-8">
              Découvrez les visionnaires et experts qui font de ChapeChape Residence une référence dans la location de résidences meublées en Afrique de l'Ouest.
            </p>
            <motion.div 
              initial={{ width: 0 }}
              animate={{ width: "120px" }}
              transition={{ duration: 0.8, delay: 0.4 }}
              className="h-1 bg-primary-300 mx-auto mt-2 mb-6"
            />
          </motion.div>
        </div>
      </section>

      {/* Leadership Section */}
      <section className="py-16 bg-white">
        <div className="container-custom">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="text-center mb-12"
          >
            <h2 className="text-3xl font-bold text-secondary-900 mb-4 font-display">Direction</h2>
            <p className="text-secondary-600 max-w-2xl mx-auto">
              Notre équipe fondatrice combine expertise technologique et connaissance approfondie du marché immobilier ouest-africain.
            </p>
          </motion.div>

          <motion.div
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-50px" }}
            className="grid grid-cols-1 md:grid-cols-2 gap-8"
          >
            {coreTeam.map((member) => (
              <motion.div
                key={member.name}
                variants={itemVariants}
                className="bg-white rounded-xl overflow-hidden shadow-xl hover:shadow-2xl transition-all duration-300"
                style={{ willChange: 'auto' }}
              >
                <div className="flex flex-col md:flex-row">
                  <div 
                    className="image-container md:w-2/5 h-64 md:h-auto relative overflow-hidden bg-gradient-to-br from-primary-200 to-primary-300"
                    style={{ 
                      minHeight: '300px',
                      height: '100%',
                      position: 'relative',
                      // Style pour masquer tout texte indésirable
                      color: 'transparent',
                      fontSize: 0,
                      lineHeight: 0,
                      textIndent: '-9999px'
                    }}
                  >
                    <img 
                      src={member.image}
                      alt={member.name}
                      className="w-full h-full object-cover object-center" 
                      style={{ 
                        position: 'absolute', 
                        top: 0, 
                        left: 0, 
                        width: '100%', 
                        height: '100%',
                        zIndex: 5
                      }}
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.src = "/assets/team/placeholder.jpg";
                      }}
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent opacity-60 z-10" />
                  </div>
                  <div className="p-8 md:w-3/5">
                    <h3 className="text-2xl font-bold text-secondary-900 mb-1">{member.name}</h3>
                    <p className="text-primary-500 font-medium mb-4">{member.role}</p>
                    <p className="text-secondary-600 mb-6">{member.description}</p>
                    {member.linkedin && (
                      <a 
                        href={member.linkedin}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-2 text-primary-500 hover:text-primary-600 transition-colors mr-4"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                          <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z"/>
                        </svg>
                        <span>LinkedIn</span>
                      </a>
                    )}
                    {member.github && (
                      <a 
                        href={`https://github.com/${member.github}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-2 text-primary-500 hover:text-primary-600 transition-colors"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                          <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                        </svg>
                        <span>GitHub</span>
                      </a>
                    )}
                  </div>
                </div>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Team Section */}
      <section className="py-16 bg-secondary-50">
        <div className="container-custom">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="text-center mb-12"
          >
            <h2 className="text-3xl font-bold text-secondary-900 mb-4 font-display">Notre Équipe</h2>
            <p className="text-secondary-600 max-w-2xl mx-auto">
              Des professionnels talentueux qui travaillent chaque jour pour offrir une expérience exceptionnelle à nos utilisateurs.
            </p>
          </motion.div>

          <motion.div
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-50px" }}
            className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6"
          >
            {extendedTeam.map((member) => (
              <motion.div
                key={member.name}
                variants={itemVariants}
                whileHover={{ y: -10, transition: { duration: 0.3 } }}
                className="bg-white rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-all duration-300"
                style={{ willChange: 'auto' }}
              >
                <div 
                  className="team-image-container h-56 bg-gradient-to-br from-primary-100 to-primary-200 relative overflow-hidden"
                  style={{ 
                    height: '224px', 
                    position: 'relative',
                    // Style pour masquer tout texte indésirable
                    color: 'transparent',
                    fontSize: 0,
                    lineHeight: 0,
                    textIndent: '-9999px'
                  }}
                >
                  <img 
                    src={member.image}
                    alt={member.name}
                    className="w-full h-full object-cover object-center"
                    style={{ 
                      position: 'absolute', 
                      top: 0, 
                      left: 0, 
                      width: '100%', 
                      height: '100%',
                      zIndex: 5
                    }}
                    onError={(e) => {
                      const target = e.target as HTMLImageElement;
                      target.src = "/assets/team/placeholder.jpg";
                    }}
                  />
                </div>
                <div className="p-6">
                  <h3 className="text-xl font-bold text-secondary-900 mb-1">{member.name}</h3>
                  <p className="text-primary-500 font-medium mb-3">{member.role}</p>
                  <p className="text-secondary-600 text-sm">{member.description}</p>
                </div>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Advisors Section */}
      <section className="py-16 bg-white">
        <div className="container-custom">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="text-center mb-12"
          >
            <h2 className="text-3xl font-bold text-secondary-900 mb-4 font-display">Nos Conseillers</h2>
            <p className="text-secondary-600 max-w-2xl mx-auto">
              Des experts qui nous guident et nous conseillent dans notre vision stratégique.
            </p>
          </motion.div>

          <motion.div
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-50px" }}
            className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-4xl mx-auto"
          >
            {advisors.map((advisor) => (
              <motion.div
                key={advisor.name}
                variants={itemVariants}
                whileHover={{ y: -5, transition: { duration: 0.2 } }}
                className="bg-secondary-50 rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-all duration-300 border border-secondary-100"
                style={{ willChange: 'auto' }}
              >
                <div className="p-8 flex flex-col md:flex-row items-center gap-6">
                  <div 
                    className="advisor-image-container w-24 h-24 rounded-full bg-primary-100 flex-shrink-0 overflow-hidden" 
                    style={{ 
                      minWidth: '96px', 
                      minHeight: '96px', 
                      position: 'relative',
                      // Style pour masquer tout texte indésirable
                      color: 'transparent',
                      fontSize: 0,
                      lineHeight: 0,
                      textIndent: '-9999px'
                    }}
                  >
                    <img 
                      src={advisor.image}
                      alt={advisor.name}
                      className="w-full h-full object-cover object-center"
                      style={{ 
                        position: 'absolute', 
                        top: 0, 
                        left: 0, 
                        width: '100%', 
                        height: '100%', 
                        zIndex: 5 
                      }}
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.src = "/assets/team/placeholder.jpg";
                      }}
                    />
                  </div>
                  <div>
                    <h3 className="text-xl font-bold text-secondary-900 mb-1">{advisor.name}</h3>
                    <p className="text-primary-500 font-medium mb-2">{advisor.role}</p>
                    <p className="text-secondary-600 text-sm">{advisor.description}</p>
                  </div>
                </div>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Join Us Section */}
      <section className="py-16 bg-gradient-to-b from-secondary-50 to-white">
        <div className="container-custom">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="text-center max-w-3xl mx-auto"
          >
            <h2 className="text-3xl font-bold text-secondary-900 mb-6 font-display">Rejoignez Notre Équipe</h2>
            <p className="text-lg text-secondary-600 mb-8">
              Vous êtes passionné par l'innovation et le secteur immobilier ? Nous sommes toujours à la recherche de talents pour nous aider à transformer l'expérience de location en Afrique de l'Ouest.
            </p>
            <motion.div
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              transition={{ duration: 0.2 }}
            >
              <Link 
                to="/contact"
                className="inline-block px-8 py-4 bg-primary-500 text-white font-semibold rounded-lg shadow-md hover:bg-primary-600 transition-colors duration-300"
              >
                Postuler Maintenant
              </Link>
            </motion.div>
          </motion.div>
        </div>
      </section>
    </div>
  );
};

export default Team; 