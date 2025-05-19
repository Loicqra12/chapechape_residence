import { motion } from 'framer-motion'
import { residenceTypes } from '../data/residences'

const Residences = () => {
  return (
    <div className="bg-white">
      {/* Hero section */}
      <div className="relative bg-secondary-900 py-24 px-6 sm:py-32 sm:px-12">
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-secondary-900 to-secondary-800 opacity-90" />
          <div 
            className="absolute inset-0 bg-cover bg-center opacity-20" 
            style={{ backgroundImage: 'url(/assets/residences/hero-bg.jpg)' }}
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
              Nos Résidences
            </h1>
            <p className="mt-6 max-w-lg mx-auto text-xl text-primary-200">
              Découvrez notre sélection de résidences élégantes et confortables adaptées à tous vos besoins.
            </p>
          </motion.div>
        </div>
      </div>

      {/* Main content */}
      <div className="container-custom py-16 sm:py-24">
        {/* Introduction */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-3xl font-bold text-secondary-900 mb-6">
            Votre Confort, Notre Priorité
          </h2>
          <p className="text-lg text-secondary-600">
            ChapeChape Residence vous propose une gamme variée de logements de qualité, 
            soigneusement sélectionnés pour répondre à vos attentes en matière de confort, 
            de sécurité et d'emplacement. Que vous recherchiez un appartement moderne, 
            une villa luxueuse ou un studio pratique, nous avons la solution idéale pour vous.
          </p>
        </div>

        {/* Types de résidences */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-16">
          {residenceTypes.map((type, index) => (
            <motion.div
              key={type.id}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className="bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-shadow duration-300"
            >
              <div className="h-48 bg-secondary-200 overflow-hidden">
                <img 
                  src={type.imageUrl} 
                  alt={type.name}
                  className="w-full h-full object-cover transform hover:scale-105 transition-transform duration-500"
                />
              </div>
              <div className="p-6">
                <h3 className="text-xl font-semibold text-secondary-900 mb-2">{type.name}</h3>
                <p className="text-secondary-600 mb-4 line-clamp-3">{type.description}</p>
                <a
                  href={`/residences/${type.id}`}
                  className="inline-flex items-center text-primary-500 hover:text-primary-600 font-medium"
                >
                  En savoir plus
                  <svg className="ml-2 h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M10.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L12.586 11H5a1 1 0 110-2h7.586l-2.293-2.293a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                </a>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Appel à l'action */}
        <div className="bg-primary-50 rounded-2xl p-8 sm:p-12 text-center">
          <h2 className="text-2xl font-bold text-secondary-900 mb-4">
            Prêt à trouver votre résidence idéale ?
          </h2>
          <p className="text-lg text-secondary-600 mb-8 max-w-2xl mx-auto">
            Contactez-nous dès aujourd'hui pour discuter de vos besoins en matière de logement 
            et découvrir nos offres exclusives.
          </p>
          <a
            href="/contact"
            className="btn-primary"
          >
            Nous contacter
          </a>
        </div>
      </div>
    </div>
  )
}

export default Residences 