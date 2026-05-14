import { motion } from 'framer-motion'
import { useState, useRef } from 'react'
import { Link } from 'react-router-dom'
import Contact from '../components/home/Contact'
import SEOHead from '../components/seo/SEOHead'

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com'

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
          className={`h-5 w-5 ${i < rating ? 'text-yellow-400' : 'text-gray-200'}`}
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

/* ── Composant carte compacte pour le ticker ── */
const TickerCard = ({ t }: { t: typeof testimonials[0] }) => (
  <div className="shrink-0 w-80 bg-white rounded-2xl border border-secondary-100 shadow-sm p-6 mx-3 select-none">
    <div className="flex items-center gap-3 mb-3">
      <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary-300 to-primary-500 flex items-center justify-center text-secondary-900 font-bold text-sm shrink-0">
        {t.name.charAt(0)}
      </div>
      <div>
        <p className="font-bold text-secondary-900 text-sm leading-tight">{t.name}</p>
        <p className="text-primary-600 text-xs font-semibold uppercase tracking-wide">{t.role}</p>
      </div>
      <div className="ml-auto flex">
        {[...Array(t.rating)].map((_, i) => (
          <svg key={i} className="w-3.5 h-3.5 text-primary-400" fill="currentColor" viewBox="0 0 20 20">
            <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
          </svg>
        ))}
      </div>
    </div>
    <p className="text-secondary-500 text-sm leading-relaxed line-clamp-3 italic">"{t.content}"</p>
    <p className="text-xs text-secondary-400 mt-3">{t.location} · {t.date}</p>
  </div>
)

/* ── Rangée défilante ── */
const ScrollRow = ({ items, reverse = false, speed = 35 }: { items: typeof testimonials; reverse?: boolean; speed?: number }) => {
  const rowRef = useRef<HTMLDivElement>(null)
  const duplicated = [...items, ...items, ...items]

  return (
    <div
      className="overflow-hidden py-2 group"
      style={{ maskImage: 'linear-gradient(to right, transparent, black 8%, black 92%, transparent)' }}
    >
      <motion.div
        ref={rowRef}
        className="flex"
        animate={{ x: reverse ? ['0%', '33.33%'] : ['0%', '-33.33%'] }}
        transition={{ duration: speed, repeat: Infinity, ease: 'linear' }}
        style={{ width: 'max-content' }}
        whileHover={{ animationPlayState: 'paused' } as any}
      >
        {duplicated.map((t, i) => (
          <TickerCard key={`${t.id}-${i}`} t={t} />
        ))}
      </motion.div>
    </div>
  )
}

const Testimonials = () => {
  const [filter, setFilter] = useState<'all' | 'locataire' | 'proprietaire'>('all')

  // Filtrer les témoignages
  const normalize = (s: string) => s.toLowerCase().normalize('NFD').replace(/\u0300-\u036f/g, '')
  const filteredTestimonials = filter === 'all'
    ? testimonials
    : testimonials.filter(t => normalize(t.role).includes(normalize(filter)))

  return (
    <div className="bg-white">
      <SEOHead
        title="Témoignages"
        description="Témoignages clients et propriétaires : avis sur ChapeChape Residence, location et gestion à Abidjan, Côte d'Ivoire."
        url={`${siteUrl}/testimonials`}
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
              Avis Clients
            </span>
            <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 font-display tracking-tight">
              Ils nous font <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-200 via-primary-400 to-primary-200">Confiance</span>
            </h1>
            <p className="text-xl text-gray-300 mb-10 max-w-2xl mx-auto font-light leading-relaxed">
              Découvrez les retours d'expérience de nos propriétaires et locataires qui ont choisi ChapeChape Residence.
            </p>
          </motion.div>
        </div>
      </section>

      {/* ── Ticker défilant infini ── */}
      <section className="py-12 bg-secondary-50 overflow-hidden border-y border-secondary-100">
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-8"
        >
          <span className="inline-block px-3 py-1 rounded-full bg-primary-50 border border-primary-200 text-primary-700 text-xs font-bold tracking-widest uppercase">
            Avis en temps réel
          </span>
        </motion.div>
        <ScrollRow items={testimonials} speed={40} />
        <ScrollRow items={[...testimonials].reverse()} reverse speed={32} />
      </section>

      {/* Main content */}
      <div className="container mx-auto px-4 max-w-6xl py-16 sm:py-24">
        {/* Introduction */}
        <div className="max-w-3xl mx-auto text-center mb-16">
          <h2 className="text-3xl font-bold text-secondary-900 mb-6 font-display">
            Nos Clients Témoignent
          </h2>
          <p className="text-lg text-secondary-600">
            La satisfaction de nos clients est notre priorité. Voici quelques témoignages
            de propriétaires et locataires qui nous font confiance pour leurs besoins immobiliers.
          </p>
        </div>

        {/* Filtres */}
        <div className="flex justify-center mb-16">
          <div className="inline-flex rounded-full shadow-md p-1.5 bg-gray-100">
            <button
              type="button"
              className={`px-6 py-2.5 text-sm font-bold rounded-full transition-all duration-300 ${filter === 'all' ? 'bg-white shadow-sm text-secondary-900' : 'text-secondary-500 hover:text-secondary-900'}`}
              onClick={() => setFilter('all')}
            >
              Tous
            </button>
            <button
              type="button"
              className={`px-6 py-2.5 text-sm font-bold rounded-full transition-all duration-300 ${filter === 'locataire' ? 'bg-white shadow-sm text-secondary-900' : 'text-secondary-500 hover:text-secondary-900'}`}
              onClick={() => setFilter('locataire')}
            >
              Locataires
            </button>
            <button
              type="button"
              className={`px-6 py-2.5 text-sm font-bold rounded-full transition-all duration-300 ${filter === 'proprietaire' ? 'bg-white shadow-sm text-secondary-900' : 'text-secondary-500 hover:text-secondary-900'}`}
              onClick={() => setFilter('proprietaire')}
            >
              Propriétaires
            </button>
          </div>
        </div>

        {/* Témoignages */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-24">
          {filteredTestimonials.map((testimonial, index) => (
            <motion.div
              key={testimonial.id}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className="bg-white rounded-2xl shadow-lg overflow-hidden hover:shadow-2xl transition-all duration-300 flex flex-col border border-gray-100 group"
            >
              <div className="p-8 flex-grow">
                <div className="flex justify-between items-start mb-6">
                  <div className="flex items-center">
                    <div className="h-14 w-14 rounded-full overflow-hidden bg-primary-100 flex items-center justify-center mr-4 ring-2 ring-white shadow-md">
                      {testimonial.image ? (
                        <img
                          src={testimonial.image}
                          alt={testimonial.name}
                          className="h-full w-full object-cover"
                          onError={(e) => {
                            const target = e.target as HTMLImageElement;
                            target.style.display = 'none';
                            target.nextElementSibling?.classList.remove('hidden');
                          }}
                        />
                      ) : null}
                      <span className={`text-xl font-bold text-primary-500 ${testimonial.image ? 'hidden' : ''}`}>
                        {testimonial.name.charAt(0)}
                      </span>
                    </div>
                    <div>
                      <h3 className="text-lg font-bold text-secondary-900">{testimonial.name}</h3>
                      <p className="text-sm font-medium text-primary-500 uppercase tracking-wide">{testimonial.role}</p>
                    </div>
                  </div>
                </div>

                <div className="mb-4">
                  <StarRating rating={testimonial.rating} />
                </div>

                <blockquote className="italic text-secondary-600 mb-6 leading-relaxed">
                  "{testimonial.content}"
                </blockquote>
              </div>
              <div className="px-8 py-4 bg-gray-50 border-t border-gray-100 flex justify-between items-center text-xs font-medium text-gray-500">
                <span className="flex items-center">
                  <svg className="w-4 h-4 mr-1 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  {testimonial.location}
                </span>
                <span>{testimonial.date}</span>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Section de soumission de témoignage */}
        <div className="bg-secondary-900 rounded-3xl p-10 sm:p-16 relative overflow-hidden shadow-2xl text-center">
          <div className="absolute inset-0 bg-[url('/assets/images/pattern-luxury.png')] bg-cover bg-center opacity-5 mix-blend-overlay" />
          <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-primary-500/10 rounded-full blur-3xl pointer-events-none" />

          <div className="relative z-10 max-w-3xl mx-auto">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="mb-10"
            >
              <h2 className="text-3xl font-bold text-white mb-6 font-display">
                Partagez votre expérience
              </h2>
              <p className="text-lg text-primary-100 leading-relaxed">
                Nous serions ravis de connaître votre expérience avec ChapeChape Residence.
                Votre témoignage nous aide à améliorer continuellement nos services et à inspirer notre communauté.
              </p>
            </motion.div>
            <Link
              to="/contact"
              className="btn-primary inline-block px-10 py-4 text-base shadow-lg shadow-primary-500/20"
            >
              Soumettre un témoignage
            </Link>
          </div>
        </div>
      </div>

      {/* Contact Section */}
      <Contact />
    </div>
  )
}

export default Testimonials