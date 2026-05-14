import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'

interface CTABannerProps {
  title?: string
  description?: string
  primaryCTA?: {
    text: string
    href: string
    external?: boolean
  }
  secondaryCTA?: {
    text: string
    href: string
    external?: boolean
  }
  className?: string
}

const CTABanner: React.FC<CTABannerProps> = ({
  title = "Prêt à trouver votre résidence idéale ?",
  description = "Rejoignez des milliers d'utilisateurs qui font confiance à ChapeChape Residence pour leurs besoins en logement.",
  primaryCTA = {
    text: "Télécharger l'app Client",
    href: "https://play.google.com/store/apps/details?id=com.chapechape.client",
    external: true
  },
  secondaryCTA = {
    text: "Devenir Partenaire",
    href: "https://play.google.com/store/apps/details?id=com.chapechape.chapechape_partner",
    external: true
  },
  className = ""
}) => {
  const containerVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: 0.6,
        staggerChildren: 0.2
      }
    }
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { opacity: 1, y: 0 }
  }

  const ButtonComponent = ({ cta, isPrimary }: { cta: any, isPrimary: boolean }) => {
    const buttonContent = (
      <motion.button
        variants={itemVariants}
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        className={`
          px-8 py-4 rounded-lg font-semibold text-lg transition-all duration-300 shadow-lg
          ${isPrimary 
            ? 'bg-primary-300 text-secondary-900 hover:bg-primary-400 shadow-primary-300/30' 
            : 'bg-transparent border-2 border-primary-300 text-primary-300 hover:bg-primary-300 hover:text-secondary-900'
          }
        `}
      >
        {cta.text}
      </motion.button>
    )

    if (cta.external) {
      return (
        <a href={cta.href} target="_blank" rel="noopener noreferrer">
          {buttonContent}
        </a>
      )
    }

    return (
      <Link to={cta.href}>
        {buttonContent}
      </Link>
    )
  }

  return (
    <section className={`py-20 bg-gradient-to-br from-secondary-900 via-secondary-800 to-secondary-900 relative overflow-hidden ${className}`}>
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute inset-0 bg-[linear-gradient(45deg,transparent_35%,rgba(212,175,55,0.1)_50%,transparent_65%)] bg-[length:20px_20px]" />
      </div>

      <div className="container mx-auto px-6 relative z-10">
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          className="text-center max-w-4xl mx-auto"
        >
          <motion.h2 
            variants={itemVariants}
            className="text-4xl md:text-5xl font-bold text-primary-300 mb-6 font-display"
          >
            {title}
          </motion.h2>
          
          <motion.p 
            variants={itemVariants}
            className="text-xl text-primary-100 mb-10 max-w-2xl mx-auto leading-relaxed"
          >
            {description}
          </motion.p>

          <motion.div 
            variants={itemVariants}
            className="flex flex-col sm:flex-row gap-6 justify-center items-center"
          >
            <ButtonComponent cta={primaryCTA} isPrimary={true} />
            <ButtonComponent cta={secondaryCTA} isPrimary={false} />
          </motion.div>

          {/* Trust indicators */}
          <motion.div 
            variants={itemVariants}
            className="mt-12 flex flex-col sm:flex-row items-center justify-center gap-8 text-primary-200"
          >
            <div className="flex items-center gap-2">
              <svg className="w-5 h-5 text-primary-300" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
              <span>100% Sécurisé</span>
            </div>
            <div className="flex items-center gap-2">
              <svg className="w-5 h-5 text-primary-300" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
              <span>Support 24/7</span>
            </div>
            <div className="flex items-center gap-2">
              <svg className="w-5 h-5 text-primary-300" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
              <span>Gratuit à télécharger</span>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  )
}

export default CTABanner
