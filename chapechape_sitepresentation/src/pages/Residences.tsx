import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Link } from 'react-router-dom';
import { apiService, Residence } from '../services/api.service';
import { useToast } from '../components/ui/ToastProvider';
import SEOHead from '../components/seo/SEOHead';

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com';

const Residences = () => {
  const [residences, setResidences] = useState<Residence[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState('all');
  const { showToast } = useToast();

  useEffect(() => {
    fetchResidences();
  }, []);

  const fetchResidences = async () => {
    try {
      setLoading(true);
      const response = await apiService.getResidences();
      if (response.success && response.data) {
        setResidences(response.data);
      } else {
        const errorMsg = "Impossible de charger les résidences.";
        setError(errorMsg);
        showToast(errorMsg, 'error');
      }
    } catch (err) {
      const errorMsg = "Une erreur est survenue lors du chargement des résidences.";
      setError(errorMsg);
      showToast(errorMsg, 'error');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const filteredResidences = filter === 'all'
    ? residences
    : residences.filter(r => r.type === filter);

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1
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
    <div className="bg-gray-50 min-h-screen">
      <SEOHead
        title="Résidences"
        description="Résidences disponibles à la location : appartements et villas meublés à Abidjan. ChapeChape Residence, Côte d'Ivoire."
        url={`${siteUrl}/residences`}
      />
      {/* Hero Section */}
      <section className="relative py-32 bg-secondary-900 overflow-hidden">
        <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-10 mix-blend-overlay" />
        <div className="absolute inset-0 bg-gradient-to-b from-secondary-900/50 via-secondary-900/80 to-gray-50" />

        {/* Golden particles */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          {[...Array(5)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute rounded-full bg-primary-400/20 blur-xl"
              style={{
                width: Math.random() * 200 + 100 + 'px',
                height: Math.random() * 200 + 100 + 'px',
                left: Math.random() * 100 + '%',
                top: Math.random() * 100 + '%',
              }}
              animate={{
                y: [0, -100, 0],
                x: [0, Math.random() * 50 - 25, 0],
                opacity: [0, 0.3, 0],
              }}
              transition={{
                duration: Math.random() * 10 + 15,
                repeat: Infinity,
                ease: "easeInOut",
              }}
            />
          ))}
        </div>

        <div className="container mx-auto px-4 max-w-6xl relative z-10 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <span className="inline-block py-1 px-3 rounded-full bg-white/10 backdrop-blur-md border border-white/20 text-primary-300 text-xs font-bold tracking-widest uppercase mb-6">
              Collection Exclusive
            </span>
            <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              Nos <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">Résidences</span>
            </h1>
            <p className="text-xl text-gray-300 mb-10 max-w-2xl mx-auto font-light leading-relaxed">
              Découvrez une sélection rigoureuse de propriétés d'exception, alliant confort moderne, sécurité et emplacements stratégiques.
            </p>
          </motion.div>

          {/* Filters */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4, duration: 0.6 }}
            className="flex flex-wrap justify-center gap-4"
          >
            {['all', 'apartment', 'villa', 'studio', 'penthouse'].map((type) => (
              <button
                key={type}
                onClick={() => setFilter(type)}
                className={`px-6 py-2 rounded-full text-sm font-bold uppercase tracking-wide transition-all duration-300 ${filter === type
                  ? 'bg-primary-500 text-white shadow-lg shadow-primary-500/30 transform scale-105'
                  : 'bg-white/10 text-white hover:bg-white/20 backdrop-blur-sm border border-white/10'
                  }`}
              >
                {type === 'all' ? 'Tout' : type}
              </button>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Content Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto max-w-7xl">
          {loading ? (
            <div className="flex justify-center items-center h-64">
              <div className="w-16 h-16 border-4 border-primary-200 border-t-primary-500 rounded-full animate-spin"></div>
            </div>
          ) : error ? (
            <div className="text-center py-20">
              <div className="text-red-500 text-xl mb-4">⚠️ {error}</div>
              <button
                onClick={fetchResidences}
                className="px-6 py-2 bg-secondary-900 text-white rounded-full hover:bg-secondary-800 transition-colors"
              >
                Réessayer
              </button>
            </div>
          ) : (
            <motion.div
              variants={containerVariants}
              initial="hidden"
              animate="visible"
              className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8"
            >
              <AnimatePresence mode='popLayout'>
                {filteredResidences.map((residence) => (
                  <motion.div
                    key={residence._id}
                    layout
                    variants={itemVariants}
                    initial="hidden"
                    animate="visible"
                    exit={{ opacity: 0, scale: 0.9 }}
                    className="group bg-white rounded-2xl overflow-hidden shadow-lg hover:shadow-2xl transition-all duration-500 border border-gray-100 flex flex-col h-full"
                  >
                    {/* Image Container */}
                    <div className="relative h-64 overflow-hidden">
                      <div className="absolute inset-0 bg-gray-200 animate-pulse" />
                      {residence.images && residence.images.length > 0 ? (
                        <img
                          src={residence.images[0]}
                          alt={residence.title}
                          className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center bg-secondary-100 text-secondary-300">
                          <span className="text-4xl">🏠</span>
                        </div>
                      )}

                      {/* Overlay Gradient */}
                      <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/80 via-transparent to-transparent opacity-60 group-hover:opacity-40 transition-opacity duration-300" />

                      {/* Badges */}
                      <div className="absolute top-4 left-4 flex gap-2">
                        <span className="px-3 py-1 bg-white/90 backdrop-blur-md text-secondary-900 text-xs font-bold uppercase tracking-wider rounded-md shadow-sm">
                          {residence.type}
                        </span>
                        {residence.isPopular && (
                          <span className="px-3 py-1 bg-primary-500 text-white text-xs font-bold uppercase tracking-wider rounded-md shadow-sm flex items-center gap-1">
                            ★ Populaire
                          </span>
                        )}
                      </div>

                      {/* Price Tag */}
                      <div className="absolute bottom-4 right-4 px-4 py-2 bg-secondary-900/90 backdrop-blur-md text-white rounded-lg shadow-lg border border-white/10">
                        <span className="text-lg font-bold text-primary-400">{residence.price.toLocaleString()} FCFA</span>
                        <span className="text-xs text-gray-300 ml-1">/ nuit</span>
                      </div>
                    </div>

                    {/* Content */}
                    <div className="p-6 flex-grow flex flex-col">
                      <div className="flex justify-between items-start mb-2">
                        <h3 className="text-xl font-bold text-secondary-900 line-clamp-1 group-hover:text-primary-600 transition-colors">
                          {residence.title}
                        </h3>
                      </div>

                      <div className="flex items-center text-gray-500 text-sm mb-4">
                        <svg className="w-4 h-4 mr-1 text-primary-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                        {residence.city}, {residence.country}
                      </div>

                      <p className="text-gray-600 text-sm line-clamp-2 mb-6 flex-grow">
                        {residence.description}
                      </p>

                      {/* Features */}
                      <div className="flex items-center justify-between border-t border-gray-100 pt-4 mb-6">
                        <div className="flex gap-4 text-gray-500 text-sm">
                          <span className="flex items-center gap-1" title="Chambres">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path></svg>
                            {residence.bedrooms}
                          </span>
                          <span className="flex items-center gap-1" title="Salles de bain">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path></svg>
                            {residence.bathrooms}
                          </span>
                          <span className="flex items-center gap-1" title="Surface">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 4l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"></path></svg>
                            {residence.surface} m²
                          </span>
                        </div>
                      </div>

                      <Link
                        to={`/residences/${residence._id}`}
                        className="w-full py-3 rounded-xl bg-gray-50 text-secondary-900 font-bold text-center hover:bg-primary-500 hover:text-white transition-all duration-300 border border-gray-200 hover:border-primary-500 group-hover:shadow-lg"
                      >
                        Voir les détails
                      </Link>
                    </div>
                  </motion.div>
                ))}
              </AnimatePresence>
            </motion.div>
          )}

          {!loading && filteredResidences.length === 0 && (
            <div className="text-center py-20 bg-white rounded-3xl shadow-sm border border-gray-100">
              <div className="text-6xl mb-4">🔍</div>
              <h3 className="text-2xl font-bold text-secondary-900 mb-2">Aucune résidence trouvée</h3>
              <p className="text-gray-500">Essayez de modifier vos filtres de recherche.</p>
              <button
                onClick={() => setFilter('all')}
                className="mt-6 px-6 py-2 bg-primary-100 text-primary-700 font-bold rounded-full hover:bg-primary-200 transition-colors"
              >
                Tout voir
              </button>
            </div>
          )}
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24 bg-white relative overflow-hidden">
        <div className="container mx-auto px-4 max-w-4xl text-center relative z-10">
          <h2 className="text-4xl font-bold text-secondary-900 mb-6 font-display">
            Vous ne trouvez pas votre bonheur ?
          </h2>
          <p className="text-xl text-gray-600 mb-10">
            Nos experts sont là pour vous aider à trouver la perle rare. Contactez-nous pour une recherche personnalisée.
          </p>
          <Link
            to="/contact"
            className="btn-primary"
          >
            Contacter notre équipe
          </Link>
        </div>
      </section>
    </div>
  );
};

export default Residences;