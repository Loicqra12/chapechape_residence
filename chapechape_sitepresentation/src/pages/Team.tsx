import { useEffect } from 'react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';

const Team = () => {
  useEffect(() => {
    window.scrollTo(0, 0);
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
      <section className="relative py-24 bg-secondary-900 overflow-hidden">
        {/* Background decoration */}
        <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-10 mix-blend-overlay" />
        <div className="absolute inset-0 bg-gradient-to-b from-secondary-900/50 via-secondary-900/80 to-white" />

        {/* Golden particles */}
        <div className="absolute inset-0 overflow-hidden">
          {[...Array(8)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute rounded-full bg-primary-400/30 blur-sm"
              style={{
                width: Math.random() * 100 + 50 + 'px',
                height: Math.random() * 100 + 50 + 'px',
                left: Math.random() * 100 + '%',
                top: Math.random() * 100 + '%',
              }}
              animate={{
                y: [0, -100, 0],
                x: [0, Math.random() * 50 - 25, 0],
                opacity: [0, 0.5, 0],
              }}
              transition={{
                duration: Math.random() * 10 + 10,
                repeat: Infinity,
                ease: "easeInOut",
              }}
            />
          ))}
        </div>

        <div className="container mx-auto px-4 max-w-6xl relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            className="text-center max-w-4xl mx-auto"
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="inline-flex items-center px-4 py-2 rounded-full bg-white/10 backdrop-blur-md border border-primary-400/30 text-primary-300 text-xs font-bold tracking-widest uppercase mb-8"
            >
              <span className="w-2 h-2 bg-primary-400 rounded-full mr-2 animate-pulse"></span>
              Excellence & Expertise
            </motion.div>

            <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-8 font-display tracking-tight">
              Les Visages de <br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">
                l'Innovation
              </span>
            </h1>

            <p className="text-xl text-gray-300 mb-10 leading-relaxed font-light max-w-2xl mx-auto">
              Découvrez les visionnaires et experts qui font de ChapeChape Residence une référence dans la location de résidences meublées en Afrique de l'Ouest.
            </p>

            <motion.div
              initial={{ width: 0 }}
              animate={{ width: "120px" }}
              transition={{ duration: 0.8, delay: 0.6 }}
              className="h-1 bg-gradient-to-r from-transparent via-primary-400 to-transparent mx-auto"
            />
          </motion.div>
        </div>
      </section>

      {/* Leadership Section */}
      <section className="py-20 bg-white relative">
        <div className="container mx-auto px-4 max-w-6xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl font-bold text-secondary-900 mb-4 font-display">Direction</h2>
            <p className="text-secondary-600 max-w-2xl mx-auto text-lg">
              Notre équipe fondatrice combine expertise technologique et connaissance approfondie du marché immobilier ouest-africain.
            </p>
          </motion.div>

          <motion.div
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-50px" }}
            className="grid grid-cols-1 md:grid-cols-2 gap-10"
          >
            {coreTeam.map((member) => (
              <motion.div
                key={member.name}
                variants={itemVariants}
                whileHover={{ y: -10, transition: { duration: 0.3 } }}
                className="bg-white rounded-2xl overflow-hidden shadow-2xl border border-primary-100/50 group relative"
              >
                <div className="flex flex-col md:flex-row h-full">
                  <div className="md:w-2/5 relative overflow-hidden min-h-[300px]">
                    <div className="absolute inset-0 bg-gradient-to-br from-primary-300 via-primary-400 to-primary-500 flex items-center justify-center">
                      <span className="text-8xl font-bold text-white/20 font-display select-none">
                        {member.name.charAt(0)}
                      </span>
                    </div>
                    <img
                      src={member.image}
                      alt={member.name}
                      className="absolute inset-0 w-full h-full object-cover object-center transition-transform duration-700 group-hover:scale-110 mix-blend-overlay opacity-80"
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.style.display = 'none';
                      }}
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/80 via-transparent to-transparent opacity-60" />

                    {/* Social Links Overlay */}
                    <div className="absolute bottom-0 left-0 right-0 p-6 translate-y-full group-hover:translate-y-0 transition-transform duration-300 flex gap-4 justify-center bg-white/10 backdrop-blur-md border-t border-white/20">
                      {member.linkedin && (
                        <a href={member.linkedin} target="_blank" rel="noopener noreferrer" className="text-white hover:text-primary-300 transition-colors">
                          <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" /></svg>
                        </a>
                      )}
                      {member.github && (
                        <a href={`https://github.com/${member.github}`} target="_blank" rel="noopener noreferrer" className="text-white hover:text-primary-300 transition-colors">
                          <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" /></svg>
                        </a>
                      )}
                    </div>
                  </div>

                  <div className="p-8 md:w-3/5 flex flex-col justify-center relative">
                    <div className="absolute top-0 right-0 p-4 opacity-10">
                      <svg className="w-24 h-24 text-primary-500" fill="currentColor" viewBox="0 0 24 24"><path d="M12 0c-6.627 0-12 5.373-12 12s5.373 12 12 12 12-5.373 12-12-5.373-12-12-12zm0 22c-5.514 0-10-4.486-10-10s4.486-10 10-10 10 4.486 10 10-4.486 10-10 10z" /></svg>
                    </div>

                    <h3 className="text-3xl font-bold text-secondary-900 mb-2 font-display">{member.name}</h3>
                    <div className="inline-block px-3 py-1 bg-primary-50 text-primary-600 rounded-full text-sm font-bold tracking-wide uppercase mb-6 w-fit">
                      {member.role}
                    </div>
                    <p className="text-secondary-600 leading-relaxed text-lg">
                      {member.description}
                    </p>
                  </div>
                </div>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Team Section */}
      <section className="py-20 bg-secondary-50 relative overflow-hidden">
        {/* Decorative elements */}
        <div className="absolute top-0 left-0 w-64 h-64 bg-primary-200/20 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2" />
        <div className="absolute bottom-0 right-0 w-96 h-96 bg-primary-300/10 rounded-full blur-3xl translate-x-1/3 translate-y-1/3" />

        <div className="container mx-auto px-4 max-w-6xl relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
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
            className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8"
          >
            {extendedTeam.map((member) => (
              <motion.div
                key={member.name}
                variants={itemVariants}
                whileHover={{ y: -10, transition: { duration: 0.3 } }}
                className="bg-white rounded-2xl overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300 group border border-gray-100"
              >
                <div className="h-64 relative overflow-hidden">
                  <div className="absolute inset-0 bg-gradient-to-br from-primary-100 to-primary-200 flex items-center justify-center">
                    <span className="text-6xl font-bold text-primary-300/50">{member.name.charAt(0)}</span>
                  </div>
                  <img
                    src={member.image}
                    alt={member.name}
                    className="absolute inset-0 w-full h-full object-cover object-center transition-transform duration-500 group-hover:scale-110"
                    onError={(e) => {
                      const target = e.target as HTMLImageElement;
                      target.style.display = 'none';
                    }}
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                </div>
                <div className="p-6 relative">
                  <div className="absolute -top-10 right-4 w-12 h-12 bg-white rounded-full flex items-center justify-center shadow-lg text-2xl">
                    ✨
                  </div>
                  <h3 className="text-xl font-bold text-secondary-900 mb-1">{member.name}</h3>
                  <p className="text-primary-500 font-bold text-xs uppercase tracking-wider mb-3">{member.role}</p>
                  <p className="text-secondary-600 text-sm leading-relaxed">{member.description}</p>
                </div>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Advisors Section */}
      <section className="py-20 bg-white">
        <div className="container mx-auto px-4 max-w-6xl">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
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
                className="bg-white rounded-2xl p-8 shadow-lg border border-gray-100 hover:shadow-xl hover:border-primary-100 transition-all duration-300 flex flex-col md:flex-row items-center gap-8"
              >
                <div className="relative w-28 h-28 flex-shrink-0">
                  <div className="absolute inset-0 bg-primary-100 rounded-full animate-pulse opacity-50" />
                  <div className="relative w-full h-full rounded-full overflow-hidden border-4 border-white shadow-md bg-primary-50 flex items-center justify-center">
                    <span className="text-3xl font-bold text-primary-300">{advisor.name.charAt(0)}</span>
                    <img
                      src={advisor.image}
                      alt={advisor.name}
                      className="absolute inset-0 w-full h-full object-cover"
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.style.display = 'none';
                      }}
                    />
                  </div>
                </div>
                <div className="text-center md:text-left">
                  <h3 className="text-xl font-bold text-secondary-900 mb-1">{advisor.name}</h3>
                  <p className="text-primary-500 font-bold text-sm uppercase tracking-wide mb-3">{advisor.role}</p>
                  <p className="text-secondary-600 text-sm leading-relaxed">{advisor.description}</p>
                </div>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Join Us Section */}
      <section className="py-24 relative overflow-hidden">
        <div className="absolute inset-0 bg-secondary-900" />
        <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] opacity-5 mix-blend-overlay" />
        <div className="absolute inset-0 bg-gradient-to-br from-primary-900/20 to-secondary-900/90" />

        <div className="container mx-auto px-4 max-w-6xl relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.6 }}
            className="text-center max-w-3xl mx-auto"
          >
            <h2 className="text-4xl font-bold text-white mb-6 font-display">Rejoignez Notre Équipe</h2>
            <p className="text-xl text-gray-300 mb-10 font-light">
              Vous êtes passionné par l'innovation et le secteur immobilier ? Nous sommes toujours à la recherche de talents pour nous aider à transformer l'expérience de location en Afrique de l'Ouest.
            </p>
            <motion.div
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              transition={{ duration: 0.2 }}
            >
              <Link
                to="/contact"
                className="btn-primary"
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