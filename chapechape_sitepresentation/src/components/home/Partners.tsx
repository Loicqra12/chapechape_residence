import { motion } from 'framer-motion'

const fadeIn = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      duration: 0.6
    }
  }
}

const partners = [
  { name: 'Partenaire 1', logo: '/assets/partners/partner1_logo.png' },
  { name: 'Partenaire 2', logo: '/assets/partners/partner2_logo.png' },
  { name: 'Partenaire 3', logo: '/assets/partners/partner3_logo.png' },
  { name: 'Partenaire 4', logo: '/assets/partners/partner4_logo.png' },
  { name: 'Partenaire 5', logo: '/assets/partners/partner5_logo.png' },
  { name: 'Partenaire 6', logo: '/assets/partners/partner6_logo.png' },
]

const Partners = () => {
  return (
    <section className="py-12 bg-secondary-50 dark:bg-secondary-800">
      <div className="container-custom">
        <motion.div
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={fadeIn}
          className="text-center mb-8"
        >
          <h2 className="text-2xl font-bold text-secondary-800 dark:text-white">Nos Partenaires</h2>
          <p className="mt-2 text-secondary-600 dark:text-secondary-300">
            Ils nous font confiance pour révolutionner le secteur immobilier
          </p>
        </motion.div>

        <div className="flex flex-wrap items-center justify-center gap-8 md:gap-12">
          {partners.map((partner, index) => (
            <motion.div
              key={index}
              initial="hidden"
              whileInView="visible"
              viewport={{ once: true }}
              variants={{
                hidden: { opacity: 0, y: 10 },
                visible: {
                  opacity: 1,
                  y: 0,
                  transition: {
                    delay: index * 0.1,
                    duration: 0.5,
                  }
                }
              }}
              className="flex items-center justify-center w-32 h-16 bg-white dark:bg-secondary-700 p-2 rounded-lg shadow-sm hover:shadow-md transition-all"
            >
              <img
                src={partner.logo}
                alt={`Logo ${partner.name}`}
                className="max-h-12 max-w-full object-contain"
              />
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}

export default Partners 