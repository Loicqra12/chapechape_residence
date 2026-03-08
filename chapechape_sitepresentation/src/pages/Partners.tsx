import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import Contact from '../components/home/Contact'
import SEOHead from '../components/seo/SEOHead'

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com'

// Données des partenaires
const partners = [
  {
    id: 1,
    name: "Wave",
    category: "fintech",
    description: "Leader des services financiers mobiles en Afrique de l'Ouest, Wave offre à nos clients une solution de paiement simple et sécurisée.",
    logo: "/assets/partners/wave.png",
    website: "https://www.wave.com"
  },
  {
    id: 2,
    name: "Orange Money",
    category: "fintech",
    description: "Partenaire de paiement mobile, Orange Money facilite les transactions financières pour nos propriétaires et locataires.",
    logo: "/assets/partners/orange-money.png",
    website: "https://www.orange.com/fr/orangemoney"
  },
  {
    id: 3,
    name: "MTN Mobile Money",
    category: "fintech",
    description: "Service de transfert d'argent et de paiement électronique qui permet à nos utilisateurs d'effectuer leurs paiements de loyer en toute simplicité.",
    logo: "/assets/partners/mtn.png",
    website: "https://www.mtn.com/what-we-do/mobile-financial-services/"
  },
  {
    id: 4,
    name: "Société Générale",
    category: "banque",
    description: "Notre partenaire bancaire qui offre des solutions financières adaptées pour nos propriétaires et investisseurs.",
    logo: "/assets/partners/societe-generale.png",
    website: "https://www.societegenerale.com"
  },
  {
    id: 5,
    name: "NSIA Banque",
    category: "banque",
    description: "Banque partenaire qui accompagne notre développement et propose des solutions de financement pour les projets immobiliers.",
    logo: "/assets/partners/nsia.png",
    website: "https://www.nsiabanque.com"
  },
  {
    id: 6,
    name: "Homebase",
    category: "immobilier",
    description: "Agence immobilière partenaire qui nous aide à identifier les biens de qualité pour notre plateforme.",
    logo: "/assets/partners/homebase.png",
    website: "https://www.homebase.ci"
  },
  {
    id: 7,
    name: "Kaymu Déco",
    category: "ameublement",
    description: "Spécialiste de la décoration et de l'ameublement, Kaymu Déco équipe nos résidences meublées avec style et confort.",
    logo: "/assets/partners/kaymu.png",
    website: "https://www.kaymudeco.com"
  },
  {
    id: 8,
    name: "CFAO Technologies",
    category: "technologie",
    description: "Fournisseur de solutions technologiques pour l'équipement de nos résidences intelligentes.",
    logo: "/assets/partners/cfao.png",
    website: "https://www.cfao-technologies.com"
  },
  {
    id: 9,
    name: "Securicom",
    category: "sécurité",
    description: "Expert en sécurité qui assure la protection des résidences et des locataires avec des systèmes de surveillance modernes.",
    logo: "/assets/partners/securicom.png",
    website: "https://www.securicom.ci"
  },
  {
    id: 10,
    name: "Jumia Services",
    category: "logistique",
    description: "Partenaire logistique qui assure les livraisons et services à nos résidents dans les délais les plus courts.",
    logo: "/assets/partners/jumia.png",
    website: "https://www.jumia.ci"
  }
]

// Catégories de partenaires
const categories = [
  { id: "tous", name: "Tous les partenaires" },
  { id: "fintech", name: "Services de paiement" },
  { id: "banque", name: "Banques" },
  { id: "immobilier", name: "Immobilier" },
  { id: "ameublement", name: "Ameublement & Décoration" },
  { id: "technologie", name: "Technologie" },
  { id: "sécurité", name: "Sécurité" },
  { id: "logistique", name: "Logistique & Services" }
]

const Partners = () => {
  return (
    <div className="bg-white">
      <SEOHead
        title="Partenaires"
        description="Partenaires ChapeChape Residence : Wave, Orange Money, MTN, banques. Paiements et services en Côte d'Ivoire."
        url={`${siteUrl}/partners`}
      />
      {/* Hero Section Harmonisé */}
      <section className="relative py-32 bg-secondary-900 overflow-hidden">
        <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-10 mix-blend-overlay" />
        <div className="absolute inset-0 bg-gradient-to-b from-secondary-900/50 via-secondary-900/80 to-white" />

        {/* Golden particles */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          {[...Array(6)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute rounded-full bg-primary-400/20 blur-xl"
              style={{
                width: Math.random() * 150 + 50 + 'px',
                height: Math.random() * 150 + 50 + 'px',
                left: Math.random() * 100 + '%',
                top: Math.random() * 100 + '%',
              }}
              animate={{
                y: [0, -100, 0],
                x: [0, Math.random() * 50 - 25, 0],
                opacity: [0, 0.4, 0],
              }}
              transition={{
                duration: Math.random() * 10 + 10,
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
              Confiance & Collaboration
            </span>
            <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              Nos <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">Partenaires</span>
            </h1>
            <p className="text-xl text-gray-300 mb-10 max-w-2xl mx-auto font-light leading-relaxed">
              Découvrez les entreprises leaders qui nous accompagnent dans notre mission d'excellence et d'innovation.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Main content */}
      <div className="container mx-auto px-4 max-w-6xl py-16 sm:py-24">
        {/* Introduction */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-3xl font-bold text-secondary-900 mb-6 font-display">
            Un Écosystème de Confiance
          </h2>
          <p className="text-lg text-secondary-600">
            ChapeChape Residence collabore avec des partenaires de confiance pour vous offrir une expérience complète et de qualité.
            Nos partenaires sont sélectionnés pour leur expertise, leur fiabilité et leur engagement envers l'excellence.
          </p>
        </div>

        {/* Grille de partenaires */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-24">
          {partners.map((partner, index) => (
            <motion.div
              key={partner.id}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className="bg-white rounded-2xl shadow-lg overflow-hidden hover:shadow-2xl transition-all duration-300 group border border-gray-100"
            >
              <div className="p-10 flex items-center justify-center h-56 bg-gradient-to-br from-secondary-50 to-secondary-100 dark:from-secondary-800 dark:to-secondary-700 relative overflow-hidden">
                <div className="absolute inset-0 bg-white/50 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <img
                  src={partner.logo}
                  alt={partner.name}
                  className="max-h-28 max-w-[80%] object-contain transition-transform duration-500 group-hover:scale-110 grayscale group-hover:grayscale-0"
                  onError={(e) => {
                    const target = e.target as HTMLImageElement;
                    target.src = '/assets/images/placeholder-logo.png'; // Fallback
                    target.style.opacity = '0.3';
                  }}
                />
              </div>
              <div className="p-8">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-xl font-bold text-secondary-900">{partner.name}</h3>
                  <span className="text-xs font-bold uppercase tracking-wider text-primary-500 bg-primary-50 px-2 py-1 rounded-md">
                    {categories.find(cat => cat.id === partner.category)?.name || partner.category}
                  </span>
                </div>
                <p className="text-secondary-600 mb-6 leading-relaxed text-sm">{partner.description}</p>
                <a
                  href={partner.website}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center text-primary-600 hover:text-primary-700 font-bold group"
                >
                  Visiter le site
                  <svg className="ml-2 h-5 w-5 transform group-hover:translate-x-1 transition-transform" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M10.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L12.586 11H5a1 1 0 110-2h7.586l-2.293-2.293a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                </a>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Devenez partenaire */}
        <div className="bg-secondary-900 rounded-3xl p-10 sm:p-16 relative overflow-hidden shadow-2xl">
          <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-5 mix-blend-overlay" />
          <div className="absolute top-0 right-0 w-96 h-96 bg-primary-500/10 rounded-full blur-3xl transform translate-x-1/3 -translate-y-1/3" />

          <div className="max-w-4xl mx-auto relative z-10">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="md:flex items-center justify-between gap-12"
            >
              <div className="md:w-2/3 mb-8 md:mb-0 text-left">
                <h2 className="text-3xl font-bold text-white mb-6 font-display">
                  Devenez Notre Partenaire
                </h2>
                <p className="text-primary-100 text-lg leading-relaxed">
                  Vous souhaitez rejoindre notre écosystème de partenaires ? Nous sommes toujours à la recherche
                  d'entreprises innovantes qui partagent notre vision et nos valeurs.
                  Contactez-nous pour explorer les opportunités de collaboration.
                </p>
              </div>
              <div className="md:w-1/3 flex justify-center md:justify-end">
                <Link
                  to="/contact"
                  className="btn-primary w-full md:w-auto text-center px-8 py-4 text-base shadow-lg shadow-primary-500/20"
                >
                  Nous contacter
                </Link>
              </div>
            </motion.div>
          </div>
        </div>
      </div>

      {/* Contact Section */}
      <Contact />
    </div>
  )
}

export default Partners