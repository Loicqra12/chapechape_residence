import { type ReactNode } from 'react'
import { motion } from 'framer-motion'
import AppScreenshotCardsCarousel from './AppScreenshotCardsCarousel'
import AppFeatureCard from './AppFeatureCard'

export type AppFeature = {
  title: string
  description: string
  icon: ReactNode
}

export type AppScreenSlide = {
  src: string
  label: string
  caption?: string
}

type AppProductSectionProps = {
  eyebrow: string
  title: string
  description: string
  features: AppFeature[]
  screenshots: AppScreenSlide[]
  androidUrl: string
  iosUrl: string
  variant: 'client' | 'partner'
}

export default function AppProductSection({
  eyebrow,
  title,
  description,
  features,
  screenshots,
  androidUrl,
  iosUrl,
  variant,
}: AppProductSectionProps) {
  const isClient = variant === 'client'

  return (
    <section className={isClient ? 'bg-white' : 'bg-secondary-50'}>
      <div className="mx-auto max-w-7xl px-6 py-24 sm:py-32 lg:px-8">
        <div className="mx-auto max-w-2xl text-center lg:max-w-3xl">
          <motion.p
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
            className={`text-base font-semibold uppercase tracking-widest ${isClient ? 'text-primary-500' : 'text-secondary-600'}`}
          >
            {eyebrow}
          </motion.p>
          <motion.h2
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.05 }}
            className="mt-2 font-display text-3xl font-bold tracking-tight text-secondary-900 sm:text-4xl"
          >
            {title}
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="mt-6 text-lg leading-8 text-secondary-600"
          >
            {description}
          </motion.p>
        </div>

        <motion.div
          className="mt-14 lg:mt-16"
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.55 }}
        >
          <AppScreenshotCardsCarousel screenshots={screenshots} appTitle={title} />
        </motion.div>

        <div className="mt-16 grid grid-cols-1 gap-8 sm:grid-cols-2 lg:mt-20">
          {features.map((feature, i) => (
            <AppFeatureCard
              key={feature.title}
              title={feature.title}
              description={feature.description}
              icon={feature.icon}
              index={i}
              variant={variant}
              animationDelay={i * 0.08}
            />
          ))}
        </div>

        <div className="mt-14 flex justify-center">
          <div className="flex flex-wrap justify-center gap-3">
            <a
              href={androidUrl}
              target={androidUrl !== '#' ? '_blank' : undefined}
              rel={androidUrl !== '#' ? 'noopener noreferrer' : undefined}
              className="inline-block overflow-hidden rounded-xl shadow-lg transition-all hover:-translate-y-1 hover:shadow-xl"
            >
              <img src="/assets/googleplay.png" alt="Disponible sur Google Play" className="h-10 w-auto" />
            </a>
            <a
              href={iosUrl}
              target={iosUrl !== '#' ? '_blank' : undefined}
              rel={iosUrl !== '#' ? 'noopener noreferrer' : undefined}
              className="inline-block overflow-hidden rounded-xl shadow-lg transition-all hover:-translate-y-1 hover:shadow-xl"
            >
              <img src="/assets/appstore.png" alt="Télécharger sur l'App Store" className="h-10 w-auto" />
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}
