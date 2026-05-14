import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Link } from 'react-router-dom';
import { apiService, Residence } from '../services/api.service';
import { useToast } from '../components/ui/ToastProvider';
import SEOHead from '../components/seo/SEOHead';

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com';

// Particules définies statiquement pour éviter Math.random() dans le render
const PARTICLES = [
  { width: 220, height: 180, left: 10, top: 15, duration: 18 },
  { width: 140, height: 260, left: 70, top: 5,  duration: 22 },
  { width: 300, height: 120, left: 40, top: 60, duration: 16 },
  { width: 180, height: 200, left: 85, top: 40, duration: 20 },
  { width: 160, height: 150, left: 25, top: 80, duration: 24 },
];

const FILTER_LABELS: Record<string, string> = {
  all:        'Tous',
  apartment:  'Appartements',
  villa:      'Villas',
  studio:     'Studios',
  penthouse:  'Penthouses',
};

const Residences = () => {
  const [residences, setResidences] = useState<Residence[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState('all');
  const { showToast } = useToast();
  const hasFetched = useRef(false);

  useEffect(() => {
    if (!hasFetched.current) {
      hasFetched.current = true;
      fetchResidences();
    }
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
    visible: { opacity: 1, transition: { staggerChildren: 0.1 } },
  };

  const itemVariants = {
    hidden:   { opacity: 0, y: 20 },
    visible:  { opacity: 1, y: 0, transition: { duration: 0.5 } },
  };

  return (
    <div className="bg-white min-h-screen">
      <SEOHead
        title="Résidences"
        description="Résidences disponibles à la location : appartements et villas meublés à Abidjan. ChapeChape Residence, Côte d'Ivoire."
        url={`${siteUrl}/residences`}
      />

      {/* ── HERO ─────────────────────────────── */}
      <section className="relative py-32 bg-secondary-900 overflow-hidden">
        <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-10 mix-blend-overlay" />
        <div className="absolute inset-0 bg-gradient-to-b from-secondary-900/50 via-secondary-900/80 to-white" />

        {/* Particules statiques */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          {PARTICLES.map((p, i) => (
            <motion.div
              key={i}
              className="absolute rounded-full bg-primary-400/20 blur-xl"
              style={{ width: p.width, height: p.height, left: `${p.left}%`, top: `${p.top}%` }}
              animate={{ y: [0, -80, 0], opacity: [0, 0.3, 0] }}
              transition={{ duration: p.duration, repeat: Infinity, ease: 'easeInOut', delay: i * 2 }}
            />
          ))}
        </div>

        <div className="container mx-auto px-4 max-w-6xl relative z-10 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <span className="inline-block py-1.5 px-4 rounded-full bg-white/10 backdrop-blur-md border border-white/15 text-primary-300 text-xs font-bold tracking-widest uppercase mb-6 font-body">
              Collection Exclusive
            </span>
            <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              Nos{' '}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">
                Résidences
              </span>
            </h1>
            <p className="text-lg text-white/60 mb-10 max-w-2xl mx-auto font-body leading-relaxed">
              Découvrez une sélection rigoureuse de propriétés d'exception, alliant confort moderne, sécurité et emplacements stratégiques.
            </p>
          </motion.div>

          {/* Filtres */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4, duration: 0.6 }}
            className="flex flex-wrap justify-center gap-3"
          >
            {Object.entries(FILTER_LABELS).map(([type, label]) => (
              <button
                key={type}
                onClick={() => setFilter(type)}
                className={`px-6 py-2 rounded-full text-sm font-bold uppercase tracking-wide transition-all duration-300 font-body ${
                  filter === type
                    ? 'bg-primary-500 text-white shadow-lg shadow-primary-500/30 scale-105'
                    : 'bg-white/10 text-white hover:bg-white/20 backdrop-blur-sm border border-white/10'
                }`}
              >
                {label}
              </button>
            ))}
          </motion.div>
        </div>
      </section>

      {/* ── GRILLE RÉSIDENCES ─────────────────── */}
      <section className="py-20 px-4 bg-white">
        <div className="container mx-auto max-w-7xl">
          {loading ? (
            <div className="flex justify-center items-center h-64">
              <div className="w-14 h-14 border-4 border-primary-200 border-t-primary-500 rounded-full animate-spin" />
            </div>
          ) : error ? (
            <div className="text-center py-20">
              <div className="flex justify-center mb-4">
                <svg className="w-12 h-12 text-red-400" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
                </svg>
              </div>
              <p className="text-secondary-700 font-body text-base mb-5">{error}</p>
              <button
                onClick={fetchResidences}
                className="px-6 py-2.5 bg-secondary-900 text-white rounded-full font-body font-bold text-sm hover:bg-secondary-800 transition-colors"
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
              <AnimatePresence mode="popLayout">
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
                    {/* Image */}
                    <div className="relative h-64 overflow-hidden">
                      <div className="absolute inset-0 bg-secondary-100 animate-pulse" />
                      {residence.images && residence.images.length > 0 ? (
                        <img
                          src={residence.images[0]}
                          alt={residence.title}
                          className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center bg-secondary-100 text-secondary-300">
                          <svg className="w-12 h-12 opacity-40" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25" />
                          </svg>
                        </div>
                      )}

                      <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/80 via-transparent to-transparent opacity-60 group-hover:opacity-40 transition-opacity duration-300" />

                      {/* Badges */}
                      <div className="absolute top-4 left-4 flex gap-2">
                        <span className="px-3 py-1 bg-white/90 backdrop-blur-md text-secondary-900 text-xs font-bold uppercase tracking-wider rounded-md shadow-sm font-body">
                          {FILTER_LABELS[residence.type] ?? residence.type}
                        </span>
                        {residence.isPopular && (
                          <span className="px-3 py-1 bg-primary-500 text-white text-xs font-bold uppercase tracking-wider rounded-md shadow-sm font-body">
                            ★ Populaire
                          </span>
                        )}
                      </div>

                      {/* Prix */}
                      <div className="absolute bottom-4 right-4 px-4 py-2 bg-secondary-900/90 backdrop-blur-md text-white rounded-lg shadow-lg border border-white/10">
                        <span className="text-lg font-bold text-primary-400 font-display">{residence.price.toLocaleString()} FCFA</span>
                        <span className="text-xs text-white/60 ml-1 font-body">/ nuit</span>
                      </div>
                    </div>

                    {/* Contenu */}
                    <div className="p-6 flex-grow flex flex-col">
                      <h3 className="text-xl font-bold text-secondary-900 line-clamp-1 group-hover:text-primary-600 transition-colors font-display mb-1">
                        {residence.title}
                      </h3>

                      <div className="flex items-center text-secondary-500 text-sm mb-4 font-body">
                        <svg className="w-4 h-4 mr-1 text-primary-500 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                        </svg>
                        {residence.city}, {residence.country}
                      </div>

                      <p className="text-secondary-500 text-sm line-clamp-2 mb-6 flex-grow font-body leading-relaxed">
                        {residence.description}
                      </p>

                      {/* Features */}
                      <div className="flex items-center gap-4 border-t border-secondary-100 pt-4 mb-5 text-secondary-500 text-sm font-body">
                        <span className="flex items-center gap-1" title="Chambres">
                          <svg className="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                          </svg>
                          {residence.bedrooms} ch.
                        </span>
                        <span className="flex items-center gap-1" title="Salles de bain">
                          <svg className="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                          </svg>
                          {residence.bathrooms} sdb.
                        </span>
                        <span className="flex items-center gap-1" title="Surface">
                          <svg className="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 4l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" />
                          </svg>
                          {residence.surface} m²
                        </span>
                      </div>

                      <Link
                        to={`/residences/${residence._id}`}
                        className="w-full py-3 rounded-xl bg-secondary-50 text-secondary-900 font-bold text-center text-sm hover:bg-primary-500 hover:text-white transition-all duration-300 border border-secondary-100 hover:border-primary-500 font-body"
                      >
                        Voir les détails
                      </Link>
                    </div>
                  </motion.div>
                ))}
              </AnimatePresence>
            </motion.div>
          )}

          {/* État vide */}
          {!loading && !error && filteredResidences.length === 0 && (
            <div className="text-center py-20 bg-secondary-50 rounded-3xl border border-secondary-100">
              <div className="flex justify-center mb-4">
                <svg className="w-14 h-14 text-secondary-300" fill="none" stroke="currentColor" strokeWidth="1.5" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 15.803 7.5 7.5 0 0016.803 15.803z" />
                </svg>
              </div>
              <h3 className="text-2xl font-bold text-secondary-900 mb-2 font-display">Aucune résidence trouvée</h3>
              <p className="text-secondary-500 font-body text-sm">Essayez de modifier vos filtres de recherche.</p>
              <button
                onClick={() => setFilter('all')}
                className="mt-6 px-6 py-2 bg-primary-100 text-primary-700 font-bold rounded-full hover:bg-primary-200 transition-colors font-body text-sm"
              >
                Tout voir
              </button>
            </div>
          )}
        </div>
      </section>

      {/* ── CTA FINAL ────────────────────────── */}
      <section className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-6 lg:px-12">
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="relative bg-secondary-900 rounded-3xl p-10 sm:p-16 overflow-hidden"
          >
            <div className="absolute inset-0 bg-[radial-gradient(circle,#D4AF37_1px,transparent_1px)] [background-size:32px_32px] opacity-[0.03]" />
            <motion.div
              className="absolute top-0 right-0 w-80 h-80 rounded-full bg-primary-500/10 blur-3xl"
              animate={{ scale: [1, 1.2, 1], opacity: [0.3, 0.5, 0.3] }}
              transition={{ duration: 7, repeat: Infinity, ease: 'easeInOut' }}
            />
            <div className="relative z-10 flex flex-col md:flex-row items-center justify-between gap-10">
              <div className="md:w-2/3">
                <h2 className="text-3xl font-bold text-white font-display mb-4">
                  Vous ne trouvez pas votre bonheur ?
                </h2>
                <p className="text-white/60 font-body text-[15px] leading-relaxed">
                  Nos experts sont là pour vous aider à trouver la perle rare. Contactez-nous pour une recherche personnalisée.
                </p>
              </div>
              <div className="flex gap-3">
                <Link
                  to="/contact"
                  className="inline-flex items-center gap-2 px-7 py-3.5 rounded-full bg-primary-500 text-secondary-900 font-bold font-body text-sm hover:bg-primary-400 transition-colors whitespace-nowrap"
                >
                  Contacter notre équipe
                </Link>
              </div>
            </div>
          </motion.div>
        </div>
      </section>
    </div>
  );
};

export default Residences;
