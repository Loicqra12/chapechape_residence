import { motion, useScroll, useTransform } from 'framer-motion'
import { useInView } from 'react-intersection-observer'
import { useEffect, useState, useRef, useId } from 'react'

const CountUp = ({ end, duration = 1800, suffix = '' }: { end: number; duration?: number; suffix?: string }) => {
  const [count, setCount] = useState(0)
  const { ref, inView } = useInView({ triggerOnce: true, threshold: 0.12 })

  useEffect(() => {
    let startTimestamp: number | null = null
    let animationFrameId: number | null = null

    const step = (timestamp: number) => {
      if (!startTimestamp) startTimestamp = timestamp
      const progress = Math.min((timestamp - startTimestamp) / duration, 1)
      const eased = 1 - (1 - progress) ** 3
      setCount(Math.floor(eased * end))
      if (progress < 1) {
        animationFrameId = requestAnimationFrame(step)
      }
    }

    if (inView) {
      animationFrameId = requestAnimationFrame(step)
    }

    return () => {
      if (animationFrameId) cancelAnimationFrame(animationFrameId)
    }
  }, [end, duration, inView])

  return (
    <span ref={ref} className="tabular-nums tracking-tight">
      {count.toLocaleString('fr-FR')}
      {suffix}
    </span>
  )
}

type IconName = 'users' | 'home' | 'chart-bar' | 'map'

const stats: {
  value: number
  label: string
  icon: IconName
  suffix: string
  hint?: string
}[] = [
  {
    value: 10000,
    label: 'Utilisateurs',
    icon: 'users',
    suffix: '+',
    hint: 'Locataires et voyageurs actifs sur la plateforme',
  },
  { value: 1500, label: 'Propriétés', icon: 'home', suffix: '' },
  { value: 8000, label: 'Transactions', icon: 'chart-bar', suffix: '' },
  { value: 12, label: 'Villes', icon: 'map', suffix: '' },
]

function StatIcon({ name, className }: { name: IconName; className?: string }) {
  const cn = className ?? 'h-7 w-7'
  switch (name) {
    case 'users':
      return (
        <svg className={cn} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
      )
    case 'home':
      return (
        <svg className={cn} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
        </svg>
      )
    case 'chart-bar':
      return (
        <svg className={cn} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        </svg>
      )
    case 'map':
      return (
        <svg className={cn} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
        </svg>
      )
    default:
      return null
  }
}

/** Courbe d’engagement — palette primary */
function SparklineUsers({ className }: { className?: string }) {
  const id = useId().replace(/:/g, '')
  return (
    <svg viewBox="0 0 240 56" className={className} preserveAspectRatio="none" aria-hidden>
      <defs>
        <linearGradient id={`${id}-fill`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#f7df74" stopOpacity="0.45" />
          <stop offset="100%" stopColor="#d4af37" stopOpacity="0" />
        </linearGradient>
        <linearGradient id={`${id}-stroke`} x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#b8941f" />
          <stop offset="50%" stopColor="#f7df74" />
          <stop offset="100%" stopColor="#d4af37" />
        </linearGradient>
      </defs>
      <path
        d="M0 44 C40 38 72 42 100 28 S168 8 240 12 L240 56 L0 56 Z"
        fill={`url(#${id}-fill)`}
      />
      <path
        d="M0 44 C40 38 72 42 100 28 S168 8 240 12"
        fill="none"
        stroke={`url(#${id}-stroke)`}
        strokeWidth="2.25"
        strokeLinecap="round"
      />
    </svg>
  )
}

/** Barres stylisées (type volume de transactions) */
function BarChartGold({ className }: { className?: string }) {
  const id = useId().replace(/:/g, '')
  const bars = [22, 34, 28, 46, 40, 58, 52]
  return (
    <svg viewBox="0 0 160 72" className={className} aria-hidden>
      <defs>
        <linearGradient id={`${id}-bar`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#fbf0c2" />
          <stop offset="40%" stopColor="#f7df74" />
          <stop offset="100%" stopColor="#d4af37" />
        </linearGradient>
        <filter id={`${id}-glow`} x="-30%" y="-30%" width="160%" height="160%">
          <feGaussianBlur stdDeviation="1.8" result="b" />
          <feMerge>
            <feMergeNode in="b" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
      </defs>
      {bars.map((h, i) => (
        <motion.rect
          key={i}
          x={8 + i * 20}
          width="12"
          rx="3"
          fill={`url(#${id}-bar)`}
          filter={`url(#${id}-glow)`}
          initial={{ height: 0, y: 64 }}
          whileInView={{ height: h, y: 64 - h }}
          viewport={{ once: true, amount: 0.5 }}
          transition={{ delay: i * 0.06, duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
        />
      ))}
    </svg>
  )
}

/** Petites barres pour le parc logements */
function BarsProperties({ className }: { className?: string }) {
  const id = useId().replace(/:/g, '')
  const h = [16, 24, 20, 32]
  return (
    <svg viewBox="0 0 88 44" className={className} aria-hidden>
      <defs>
        <linearGradient id={`${id}-p`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#eaecf0" />
          <stop offset="100%" stopColor="#d4af37" stopOpacity="0.85" />
        </linearGradient>
      </defs>
      {h.map((height, i) => (
        <rect key={i} x={8 + i * 20} y={36 - height} width="14" height={height} rx="2" fill={`url(#${id}-p)`} opacity={0.5 + i * 0.12} />
      ))}
    </svg>
  )
}

/** Points = villes couvertes */
function DotsCities({ className }: { className?: string }) {
  const positions = [8, 22, 36, 50, 64, 78, 92, 106, 120, 134, 148, 162]
  return (
    <svg viewBox="0 0 172 28" className={className} aria-hidden>
      <path
        d="M4 18 Q86 4 168 16"
        fill="none"
        stroke="#eaecf0"
        strokeWidth="1.5"
        strokeDasharray="4 4"
      />
      {positions.map((cx, i) => (
        <g key={i}>
          <circle cx={cx} cy={14 + (i % 3) * 2} r="5" fill="#fefbf0" stroke="#d4af37" strokeWidth="1.5" />
          <circle cx={cx} cy={14 + (i % 3) * 2} r="2" fill="#f7df74" />
        </g>
      ))}
    </svg>
  )
}

const Stats = () => {
  const containerRef = useRef(null)
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ['start end', 'end start'],
  })

  const bgY = useTransform(scrollYProgress, [0, 1], [30, -30])

  const [hero, ...rest] = stats
  const [a, b, c] = rest

  return (
    <section ref={containerRef} className="relative overflow-hidden bg-secondary-100/40 py-24 lg:py-32">
      <motion.div
        className="pointer-events-none absolute inset-0 -z-10 bg-[radial-gradient(ellipse_70%_45%_at_50%_0%,rgba(247,223,116,0.2),transparent)]"
        style={{ y: bgY }}
      />
      <div
        className="pointer-events-none absolute inset-0 -z-10 opacity-40"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23d4af37' fill-opacity='0.06'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
        }}
      />

      <div className="relative z-10 mx-auto max-w-6xl px-6 lg:px-8">
        {/* Encadrement type « bento board » — contraste + or ChapeChape */}
        <div className="relative rounded-[1.75rem] p-[1px] shadow-[0_32px_64px_-28px_rgba(16,24,40,0.25),0_0_0_1px_rgba(212,175,55,0.25)] sm:rounded-[2rem]">
          <div
            className="absolute inset-0 rounded-[1.75rem] bg-gradient-to-br from-primary-400/90 via-primary-600/50 to-secondary-800/80 sm:rounded-[2rem]"
            aria-hidden
          />
          <div className="relative overflow-hidden rounded-[1.7rem] border border-secondary-800/10 bg-gradient-to-b from-secondary-900/[0.97] to-secondary-950 sm:rounded-[1.95rem]">
            <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_100%_80%_at_100%_0%,rgba(247,223,116,0.12),transparent_55%)]" aria-hidden />

            <div className="relative px-5 py-8 sm:px-8 sm:py-10 lg:px-10 lg:py-12">
              <motion.header
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-60px' }}
                transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
                className="mb-12 max-w-3xl lg:mb-14"
              >
                <span className="inline-flex items-center gap-2 rounded-full border border-primary-400/35 bg-primary-500/10 px-4 py-1.5 text-xs font-bold uppercase tracking-[0.2em] text-primary-200">
                  <span className="h-1.5 w-1.5 rounded-full bg-primary-400 shadow-[0_0_14px_rgba(247,223,116,0.85)]" />
                  Impact & croissance
                </span>
                <h2 className="mt-5 font-display text-3xl font-bold tracking-tight text-white md:text-4xl lg:text-5xl">
                  ChapeChape Residence{' '}
                  <span className="bg-gradient-to-r from-primary-200 via-primary-400 to-primary-300 bg-clip-text text-transparent">
                    en chiffres
                  </span>
                </h2>
                <p className="mt-4 max-w-2xl text-base font-light leading-relaxed text-secondary-300 lg:text-lg">
                  Une croissance constante qui témoigne de la confiance de nos utilisateurs et de la qualité de notre service.
                </p>
              </motion.header>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-12 lg:grid-rows-[minmax(0,1fr)_minmax(0,1fr)_auto] lg:gap-5">
                <motion.article
                  initial={{ opacity: 0, y: 24 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true, margin: '-40px' }}
                  transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
                  className="group relative col-span-2 flex min-h-[300px] flex-col justify-between overflow-hidden rounded-2xl border border-white/10 bg-secondary-800/60 p-7 shadow-lg backdrop-blur-md sm:rounded-3xl sm:p-8 lg:col-span-7 lg:row-span-2 lg:col-start-1 lg:row-start-1 lg:min-h-[320px]"
                >
                  <div className="pointer-events-none absolute -right-16 -top-16 h-56 w-56 rounded-full bg-primary-500/15 blur-3xl transition-opacity group-hover:bg-primary-400/25" aria-hidden />

                  <div className="relative flex items-start justify-between gap-4">
                    <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl border border-primary-400/30 bg-primary-500/15 text-primary-200">
                      <StatIcon name={hero.icon} className="h-8 w-8" />
                    </div>
                    <span className="rounded-full border border-primary-400/25 bg-primary-500/10 px-3 py-1 text-[10px] font-semibold uppercase tracking-wider text-primary-200">
                      Live
                    </span>
                  </div>

                  <div className="relative mt-6 flex-1">
                    <p className="text-xs font-semibold uppercase tracking-widest text-secondary-400">{hero.label}</p>
                    <p className="mt-2 font-display text-5xl font-bold leading-none text-white sm:text-6xl lg:text-7xl">
                      <CountUp end={hero.value} suffix={hero.suffix} />
                    </p>
                    {hero.hint && <p className="mt-3 max-w-md text-sm leading-relaxed text-secondary-400 lg:text-base">{hero.hint}</p>}
                    <SparklineUsers className="mt-6 h-14 w-full max-w-[280px] text-primary-400 opacity-90" />
                  </div>
                </motion.article>

                {[a, b].map((stat, i) => (
                  <motion.article
                    key={stat.label}
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true, margin: '-30px' }}
                    transition={{ duration: 0.45, delay: 0.06 * (i + 1), ease: [0.22, 1, 0.36, 1] }}
                    whileHover={{ y: -3, transition: { duration: 0.22 } }}
                    className={`group relative col-span-1 flex flex-col overflow-hidden rounded-2xl border border-white/10 bg-secondary-800/50 p-5 shadow-md backdrop-blur-md sm:p-6 lg:col-span-5 lg:col-start-8 lg:min-h-[150px] ${i === 0 ? 'lg:row-start-1' : 'lg:row-start-2'}`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex h-11 w-11 items-center justify-center rounded-xl border border-primary-400/25 bg-primary-500/10 text-primary-200">
                        <StatIcon name={stat.icon} className="h-6 w-6" />
                      </div>
                    </div>
                    <div className="mt-3">
                      <p className="font-display text-3xl font-bold tabular-nums text-white sm:text-4xl">
                        <CountUp end={stat.value} suffix={stat.suffix} />
                      </p>
                      <p className="mt-1 text-[11px] font-semibold uppercase tracking-wider text-secondary-400">{stat.label}</p>
                    </div>
                    {stat.icon === 'home' && (
                      <BarsProperties className="mt-3 ml-auto h-10 w-24 shrink-0 opacity-80" />
                    )}
                    {stat.icon === 'chart-bar' && (
                      <BarChartGold className="mt-2 h-16 w-full max-w-[200px]" />
                    )}
                    <div className="pointer-events-none absolute inset-x-0 bottom-0 h-px bg-gradient-to-r from-transparent via-primary-400/25 to-transparent opacity-0 transition-opacity group-hover:opacity-100" />
                  </motion.article>
                ))}

                <motion.article
                  initial={{ opacity: 0, y: 18 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true, margin: '-30px' }}
                  transition={{ duration: 0.45, delay: 0.15, ease: [0.22, 1, 0.36, 1] }}
                  className="group relative col-span-2 flex flex-col gap-4 overflow-hidden rounded-2xl border border-primary-300/25 bg-gradient-to-r from-primary-500/15 via-secondary-800/80 to-secondary-800/60 p-6 backdrop-blur-md sm:flex-row sm:items-center sm:justify-between sm:p-8 lg:col-span-12 lg:col-start-1 lg:row-start-3"
                >
                  <div className="flex flex-wrap items-center gap-5 sm:flex-nowrap">
                    <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl border border-primary-400/35 bg-primary-500/20 text-primary-100">
                      <StatIcon name={c.icon} className="h-7 w-7" />
                    </div>
                    <div>
                      <p className="text-xs font-semibold uppercase tracking-wider text-primary-200/90">{c.label}</p>
                      <p className="font-display text-4xl font-bold tabular-nums text-white sm:text-5xl">
                        <CountUp end={c.value} suffix={c.suffix} />
                      </p>
                    </div>
                  </div>
                  <DotsCities className="h-8 w-full max-w-[200px] opacity-90 sm:max-w-[240px]" />
                  <p className="max-w-xs text-sm text-secondary-300 sm:text-right">
                    Présence urbaine en Afrique de l&apos;Ouest pour vous rapprocher de votre prochain séjour.
                  </p>
                </motion.article>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

export default Stats
