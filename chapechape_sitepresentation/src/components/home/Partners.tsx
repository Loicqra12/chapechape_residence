import { motion } from 'framer-motion'

const partners = [
  { name: 'Partenaire 1', logo: '/assets/partners/partner1_logo.png' },
  { name: 'Partenaire 2', logo: '/assets/partners/partner2_logo.png' },
  { name: 'Partenaire 3', logo: '/assets/partners/partner3_logo.png' },
  { name: 'Partenaire 4', logo: '/assets/partners/partner4_logo.png' },
  { name: 'Partenaire 5', logo: '/assets/partners/partner5_logo.png' },
  { name: 'Partenaire 6', logo: '/assets/partners/partner6_logo.png' },
]

const Partners = () => {
  // Dupliquer les partenaires pour l'effet de défilement infini
  const duplicatedPartners = [...partners, ...partners, ...partners]

  return (
    <section className="py-20 bg-white overflow-hidden border-y border-secondary-100/50">
      <div className="container-custom mb-12 text-center">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
        >
          <span className="text-primary-600 font-bold tracking-widest uppercase text-xs mb-2 block">Confiance</span>
          <h2 className="text-2xl md:text-3xl font-bold text-secondary-900 font-display">
            Ils nous font confiance
          </h2>
        </motion.div>
      </div>

      <div className="relative w-full">
        {/* Gradients de fondu sur les côtés pour un effet premium */}
        <div className="absolute left-0 top-0 bottom-0 w-24 md:w-40 bg-gradient-to-r from-white to-transparent z-10" />
        <div className="absolute right-0 top-0 bottom-0 w-24 md:w-40 bg-gradient-to-l from-white to-transparent z-10" />

        {/* Marquee Container */}
        <div className="flex overflow-hidden">
          <motion.div
            className="flex gap-12 md:gap-20 items-center py-4 px-4"
            animate={{
              x: ['0%', '-33.33%'],
            }}
            transition={{
              duration: 30,
              ease: "linear",
              repeat: Infinity,
            }}
          >
            {duplicatedPartners.map((partner, index) => (
              <div
                key={`${partner.name}-${index}`}
                className="flex-shrink-0 group relative"
              >
                <div className="w-32 h-16 md:w-40 md:h-20 flex items-center justify-center transition-all duration-300 filter grayscale opacity-60 group-hover:grayscale-0 group-hover:opacity-100 group-hover:scale-110">
                  <img
                    src={partner.logo}
                    alt={`Logo ${partner.name}`}
                    className="max-h-full max-w-full object-contain"
                  />
                </div>
              </div>
            ))}
          </motion.div>
        </div>
      </div>
    </section>
  )
}

export default Partners