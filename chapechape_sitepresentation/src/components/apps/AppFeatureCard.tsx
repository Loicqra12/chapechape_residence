import { type ReactNode } from 'react'
import { motion } from 'framer-motion'
import AppFeatureCardDecor from './AppFeatureCardDecor'

type AppFeatureCardProps = {
  title: string
  description: string
  icon: ReactNode
  index: number
  variant: 'client' | 'partner'
  animationDelay?: number
}

export default function AppFeatureCard({
  title,
  description,
  icon,
  index,
  variant,
  animationDelay = 0,
}: AppFeatureCardProps) {
  const isClient = variant === 'client'
  const number = String(index + 1).padStart(2, '0')
  const decorVariant = index % 2 === 0 ? 'dark' : 'light'

  const iconBoxClass = isClient
    ? 'bg-primary-400 text-secondary-900 ring-2 ring-secondary-900'
    : 'bg-secondary-900 text-primary-400 ring-2 ring-secondary-900'

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ duration: 0.45, delay: animationDelay }}
      className={[
        'group relative overflow-hidden rounded-2xl border-2 border-secondary-900 bg-[#fffdf5] p-6',
        'shadow-[5px_5px_0_0_rgba(26,26,26,1)] transition-all duration-300',
        'hover:-translate-y-1 hover:shadow-[7px_7px_0_0_rgba(26,26,26,1)] sm:p-8',
      ].join(' ')}
    >
      {/* Filigrane bloc numéroté */}
      <AppFeatureCardDecor
        number={number}
        variant={decorVariant}
        className="pointer-events-none absolute -bottom-2 -right-2 h-28 w-28 opacity-[0.14] transition-opacity duration-300 group-hover:opacity-[0.22] sm:h-32 sm:w-32"
      />

      {/* Points discrets */}
      <div
        className="pointer-events-none absolute left-4 top-4 h-12 w-12 opacity-[0.06]"
        style={{
          backgroundImage: 'radial-gradient(circle, #1a1a1a 1.5px, transparent 1.5px)',
          backgroundSize: '8px 8px',
        }}
        aria-hidden
      />

      <div className="relative z-10">
        <div className="flex items-start gap-x-4">
          <div
            className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-lg transition-transform duration-300 group-hover:scale-105 ${iconBoxClass}`}
          >
            {icon}
          </div>
          <div className="min-w-0 pt-0.5">
            <span className="text-[10px] font-bold uppercase tracking-[0.2em] text-secondary-500">
              {number}
            </span>
            <h3 className="mt-1 font-display text-lg font-bold leading-snug text-secondary-900">
              {title}
            </h3>
          </div>
        </div>
        <p className="mt-4 text-base leading-7 text-secondary-600">{description}</p>
      </div>
    </motion.div>
  )
}
