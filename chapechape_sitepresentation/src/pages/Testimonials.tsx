import { motion } from 'framer-motion'
import { useState } from 'react'

// Données des témoignages
const testimonials = [
  {
    id: 1,
    name: 'Sophie Kouassi',
    role: 'Locataire',
    location: 'Abidjan, Côte d\'Ivoire',
    image: '/assets/testimonials/user1.jpg',
    content: 'ChapeChape Residence a complètement changé ma perception de la location immobilière. Le processus a été simple, transparent et efficace. L\'appartement correspond parfaitement à mes attentes et le service client est toujours disponible pour répondre à mes questions.',
    rating: 5,
    date: 'Octobre 2023'
  },
  {
    id: 2,
    name: 'François Diallo',
    role: 'Propriétaire',
    location: 'Plateau, Abidjan',
    image: '/assets/testimonials/user2.jpg',
    content: 'En tant que propriétaire, je cherchais une solution fiable pour gérer mon bien immobilier sans stress. ChapeChape Residence a dépassé mes attentes avec leur service professionnel et leur communication transparente. Mes revenus locatifs sont désormais prévisibles et la gestion est simplifiée.',
    rating: 5,
    date: 'Décembre 2023'
  },
  {
    id: 3,
    name: 'Amélie Touré',
    role: 'Locataire',
    location: 'Cocody, Abidjan',
    image: '/assets/testimonials/user3.jpg',
    content: 'J\'ai trouvé mon studio parfait grâce à ChapeChape Residence. L\'application est intuitive et j\'ai pu visiter virtuellement plusieurs biens avant de faire mon choix. Le processus de réservation était simple et l\'équipe m\'a guidé à chaque étape. Je recommande vivement !',
    rating: 4,
    date: 'Novembre 2023'
  },
  {
    id: 4,
    name: 'Jean-Marc Koné',
    role: 'Propriétaire',
    location: 'Riviera, Abidjan',
    image: '/assets/testimonials/user4.jpg',
    content: 'La gestion locative par ChapeChape Residence est impeccable. Fini les tracas avec les locataires ou les paiements en retard. Leur équipe s\'occupe de tout et je reçois des rapports mensuels détaillés. Une tranquillité d\'esprit qui n\'a pas de prix !',
    rating: 5,
    date: 'Janvier 2024'
  },
  {
    id: 5,
    name: 'Carine Bamba',
    role: 'Locataire',
    location: 'Yopougon, Abidjan',
    image: '/assets/testimonials/user5.jpg',
    content: 'Après plusieurs mauvaises expériences avec d\'autres agences, ChapeChape Residence a été une bouffée d\'air frais. Leur transparence et leur réactivité sont remarquables. J\'ai pu emménager rapidement dans un appartement propre et bien entretenu.',
    rating: 4,
    date: 'Février 2024'
  },
  {
    id: 6,
    name: 'David Ouattara',
    role: 'Propriétaire',
    location: 'Marcory, Abidjan',
    image: '/assets/testimonials/user6.jpg',
    content: 'ChapeChape Residence a transformé ma villa en une source de revenus stable et sans tracas. Leur approche professionnelle, de la mise en valeur du bien jusqu\'à la sélection des locataires, est exceptionnelle. Je ne peux que les recommander à tous les propriétaires !',
    rating: 5,
    date: 'Mars 2024'
  }
]

// Composant d'étoile pour les évaluations
const StarRating = ({ rating }: { rating: number }) => {
  return (
    <div className="flex">
      {[...Array(5)].map((_, i) => (
        <svg
          key={i}
          className={`h-5 w-5 ${i < rating ? 'text-yellow-400' : 'text-gray-300'}`}
          fill="currentColor"
          viewBox="0 0 20 20"
        >
          <path
            fillRule="evenodd"
            d="M10 15.934l-6.18 3.254a1 1 0 01-1.45-1.054l1.18-6.892-5-4.872a1 1 0 01.553-1.706l6.905-1.003 3.09-6.262a1 1 0 011.804 0l3.09 6.262 6.905 1.003a1 1 0 01.553 1.706l-5 4.872 1.18 6.892a1 1 0 01-1.45 1.054L10 15.934z"
            clipRule="evenodd"
          />
        </svg>
      ))}
    </div>
  )
}

const Testimonials = () => {
  const [filter, setFilter] = useState<'all' | 'locataire' | 'proprietaire'>('all')
  
  // Filtrer les témoignages
  const filteredTestimonials = filter === 'all' 
    ? testimonials 
    : testimonials.filter(t => t.role.toLowerCase().includes(filter))

  return (
    <div className="bg-white">
      {/* Hero section */}
      <div className="relative bg-secondary-900 py-24 px-6 sm:py-32 sm:px-12">
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-secondary-900 to-secondary-800 opacity-90" />
          <div 
            className="absolute inset-0 bg-cover bg-center opacity-20" 
            style={{ backgroundImage: 'url(/assets/testimonials/hero-bg.jpg)' }}
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
              Témoignages
            </h1>
            <p className="mt-6 max-w-lg mx-auto text-xl text-primary-200">
              Découvrez ce que nos clients disent de ChapeChape Residence.
            </p>
          </motion.div>
        </div>
      </div>

      {/* Main content */}
      <div className="container-custom py-16 sm:py-24">
        {/* Introduction */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-3xl font-bold text-secondary-900 mb-6">
            Nos Clients Témoignent
          </h2>
          <p className="text-lg text-secondary-600">
            La satisfaction de nos clients est notre priorité. Voici quelques témoignages 
            de propriétaires et locataires qui nous font confiance pour leurs besoins immobiliers.
          </p>
        </div>

        {/* Filtres */}
        <div className="flex justify-center mb-12">
          <div className="inline-flex rounded-md shadow-sm p-1 bg-secondary-100">
            <button
              type="button"
              className={`px-4 py-2 text-sm font-medium rounded-md ${filter === 'all' ? 'bg-white shadow-sm text-secondary-900' : 'text-secondary-600 hover:text-secondary-900'}`}
              onClick={() => setFilter('all')}
            >
              Tous
            </button>
            <button
              type="button"
              className={`px-4 py-2 text-sm font-medium rounded-md ${filter === 'locataire' ? 'bg-white shadow-sm text-secondary-900' : 'text-secondary-600 hover:text-secondary-900'}`}
              onClick={() => setFilter('locataire')}
            >
              Locataires
            </button>
            <button
              type="button"
              className={`px-4 py-2 text-sm font-medium rounded-md ${filter === 'proprietaire' ? 'bg-white shadow-sm text-secondary-900' : 'text-secondary-600 hover:text-secondary-900'}`}
              onClick={() => setFilter('proprietaire')}
            >
              Propriétaires
            </button>
          </div>
        </div>

        {/* Témoignages */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {filteredTestimonials.map((testimonial, index) => (
            <motion.div
              key={testimonial.id}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className="bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-shadow duration-300 flex flex-col"
            >
              <div className="p-6 flex-grow">
                <div className="flex justify-between items-start mb-4">
                  <div className="flex items-center">
                    <div className="h-12 w-12 rounded-full overflow-hidden bg-primary-100 flex items-center justify-center mr-4">
                      {testimonial.image ? (
                        <img 
                          src={testimonial.image} 
                          alt={testimonial.name} 
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <span className="text-xl font-bold text-primary-500">
                          {testimonial.name.charAt(0)}
                        </span>
                      )}
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-secondary-900">{testimonial.name}</h3>
                      <p className="text-sm text-primary-500">{testimonial.role}</p>
                    </div>
                  </div>
                  <div>
                    <StarRating rating={testimonial.rating} />
                  </div>
                </div>
                <blockquote className="italic text-secondary-600 mb-4">
                  "{testimonial.content}"
                </blockquote>
              </div>
              <div className="px-6 py-4 bg-secondary-50 text-sm text-secondary-500 flex justify-between items-center">
                <span>{testimonial.location}</span>
                <span>{testimonial.date}</span>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Section de soumission de témoignage */}
        <div className="mt-24 bg-primary-50 rounded-2xl p-8 sm:p-12">
          <div className="max-w-3xl mx-auto">
            <motion.div 
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="text-center mb-8"
            >
              <h2 className="text-2xl font-bold text-secondary-900 mb-4">
                Partagez votre expérience
              </h2>
              <p className="text-lg text-secondary-600">
                Nous serions ravis de connaître votre expérience avec ChapeChape Residence. 
                Votre témoignage nous aide à améliorer continuellement nos services.
              </p>
            </motion.div>
            <a
              href="/contact"
              className="block w-full md:w-auto md:mx-auto md:inline-block text-center btn-primary"
            >
              Soumettre un témoignage
            </a>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Testimonials 