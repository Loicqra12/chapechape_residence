import { motion } from 'framer-motion'

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
      {/* Hero section */}
      <div className="relative bg-secondary-900 py-24 px-6 sm:py-32 sm:px-12">
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-secondary-900 to-secondary-800 opacity-90" />
          <div 
            className="absolute inset-0 bg-cover bg-center opacity-20" 
            style={{ backgroundImage: 'url(/assets/partners/hero-bg.jpg)' }}
          />
        </div>
        <div className="relative mx-auto max-w-7xl">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            <h1 className="text-4xl font-bold tracking-tight text-white sm:text-5xl lg:text-6xl">
              Nos Partenaires
            </h1>
            <p className="mt-6 max-w-lg mx-auto text-xl text-primary-200">
              Découvrez les entreprises qui nous accompagnent dans notre mission.
            </p>
          </motion.div>
        </div>
      </div>

      {/* Main content */}
      <div className="container-custom py-16 sm:py-24">
        {/* Introduction */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-3xl font-bold text-secondary-900 mb-6">
            Un Écosystème de Confiance
          </h2>
          <p className="text-lg text-secondary-600">
            ChapeChape Residence collabore avec des partenaires de confiance pour vous offrir une expérience complète et de qualité. 
            Nos partenaires sont sélectionnés pour leur expertise, leur fiabilité et leur engagement envers l'excellence.
          </p>
        </div>

        {/* Grille de partenaires */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-16">
          {partners.map((partner, index) => (
            <motion.div
              key={partner.id}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className="bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-all duration-300 group"
            >
              <div className="p-8 flex items-center justify-center h-48 bg-secondary-50">
                <img 
                  src={partner.logo} 
                  alt={partner.name}
                  className="max-h-24 max-w-[80%] object-contain transition-transform duration-300 group-hover:scale-110"
                />
              </div>
              <div className="p-6">
                <h3 className="text-xl font-semibold text-secondary-900 mb-2">{partner.name}</h3>
                <p className="text-primary-400 text-sm mb-4 uppercase tracking-wider">
                  {categories.find(cat => cat.id === partner.category)?.name || partner.category}
                </p>
                <p className="text-secondary-600 mb-6">{partner.description}</p>
                <a
                  href={partner.website}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center text-primary-500 hover:text-primary-600 font-medium"
                >
                  Visiter le site
                  <svg className="ml-2 h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M10.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L12.586 11H5a1 1 0 110-2h7.586l-2.293-2.293a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                </a>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Devenez partenaire */}
        <div className="bg-primary-50 rounded-2xl p-8 sm:p-12">
          <div className="max-w-3xl mx-auto">
            <motion.div 
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="md:flex items-center justify-between gap-8"
            >
              <div className="md:w-2/3 mb-6 md:mb-0">
                <h2 className="text-2xl font-bold text-secondary-900 mb-4">
                  Devenez Notre Partenaire
                </h2>
                <p className="text-secondary-600">
                  Vous souhaitez rejoindre notre écosystème de partenaires ? Nous sommes toujours à la recherche 
                  d'entreprises innovantes qui partagent notre vision et nos valeurs. 
                  Contactez-nous pour explorer les opportunités de collaboration.
                </p>
              </div>
              <div className="md:w-1/3 flex justify-center md:justify-end">
                <a
                  href="/contact"
                  className="btn-primary w-full md:w-auto text-center"
                >
                  Nous contacter
                </a>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Partners 