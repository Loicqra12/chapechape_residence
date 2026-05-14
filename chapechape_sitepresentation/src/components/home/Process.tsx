import { useRef } from 'react'
import { Link } from 'react-router-dom'
import { motion, useScroll, useSpring } from 'framer-motion'

type StepIcon = 'download' | 'search' | 'secure' | 'home'

type Step = {
  id: number
  title: string
  description: string
  icon: StepIcon
}

const steps: Step[] = [
  {
    id: 1,
    title: "Téléchargez l'application",
    description:
      "Installez notre application client depuis l'App Store ou Google Play et créez votre compte en quelques minutes.",
    icon: 'download',
  },
  {
    id: 2,
    title: 'Recherchez votre résidence idéale',
    description:
      'Utilisez nos filtres avancés pour trouver la résidence qui correspond à vos besoins et à votre budget.',
    icon: 'search',
  },
  {
    id: 3,
    title: 'Réservez et payez en toute sécurité',
    description:
      'Effectuez votre réservation via notre plateforme sécurisée avec des moyens de paiement adaptés au marché africain.',
    icon: 'secure',
  },
  {
    id: 4,
    title: 'Emménagez dans votre nouvelle résidence',
    description:
      "Recevez les instructions d'accès et profitez de votre résidence avec notre support disponible 24/7.",
    icon: 'home',
  },
]

const stepInactive = {
  opacity: 0.38,
  scale: 0.96,
  filter: 'blur(2px)',
  boxShadow: '0 4px 14px 0 rgba(212, 175, 55, 0.06)',
}

const stepActive = {
  opacity: 1,
  scale: 1,
  filter: 'blur(0px)',
  boxShadow:
    '0 0 0 1px rgba(212, 175, 55, 0.42), 0 0 36px -6px rgba(247, 223, 116, 0.45), 0 18px 40px -16px rgba(212, 175, 55, 0.28)',
}

const viewportFocus = {
  once: false,
  amount: 0.55,
  margin: '-18% 0px -22% 0px',
}

function StepIconSvg({ type, className }: { type: StepIcon; className?: string }) {
  const cn = className ?? 'w-6 h-6'
  switch (type) {
    case 'download':
      return (
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={cn}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
        </svg>
      )
    case 'search':
      return (
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={cn}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
        </svg>
      )
    case 'secure':
      return (
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={cn}>
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z"
          />
        </svg>
      )
    case 'home':
      return (
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className={cn}>
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
          />
        </svg>
      )
    default:
      return null
  }
}

function ProcessStep({ step }: { step: Step }) {
  return (
    <li className="relative pl-14 lg:pl-16 min-h-[42vh] lg:min-h-[48vh] flex items-center">
      <div className="pointer-events-none absolute left-0 top-1/2 z-10 -translate-y-1/2">
        <div className="relative flex h-12 w-12 lg:h-14 lg:w-14 items-center justify-center rounded-xl border-2 border-primary-400/90 bg-primary-50 text-primary-700 shadow-gold">
          <StepIconSvg type={step.icon} className="h-6 w-6 lg:h-7 lg:w-7" />
          <span className="absolute -right-1 -top-1 flex h-6 min-w-[1.5rem] items-center justify-center rounded-full bg-primary-500 px-1 text-[11px] font-bold text-secondary-900 shadow-md ring-2 ring-white">
            {step.id}
          </span>
        </div>
      </div>

      <motion.article
        className="relative w-full overflow-hidden rounded-2xl border border-primary-200/60 bg-white/75 p-5 shadow-soft-xl backdrop-blur-md ring-1 ring-white/60 lg:p-7"
        initial={stepInactive}
        whileInView={stepActive}
        viewport={viewportFocus}
        transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
      >
        <h3 className="relative text-lg font-bold text-secondary-900 lg:text-xl">{step.title}</h3>
        <p className="relative mt-3 text-sm leading-relaxed text-secondary-600 lg:text-base">{step.description}</p>
      </motion.article>
    </li>
  )
}

const Process = () => {
  const scrollTrackRef = useRef<HTMLDivElement | null>(null)

  const { scrollYProgress } = useScroll({
    target: scrollTrackRef,
    offset: ['start end', 'end start'],
  })

  const lineProgress = useSpring(scrollYProgress, { stiffness: 100, damping: 32, mass: 0.35 })

  return (
    <section className="relative bg-gradient-to-b from-secondary-50 via-white to-secondary-50">
      <div ref={scrollTrackRef} className="mx-auto max-w-6xl px-6 py-20 lg:py-28">
        <div className="grid grid-cols-1 gap-14 lg:grid-cols-2 lg:gap-x-16 lg:gap-y-0">
          {/* Colonne gauche : sticky, palette ChapeChape */}
          <header className="space-y-5 text-center lg:sticky lg:top-24 lg:h-fit lg:text-left">
            <span className="inline-flex items-center gap-2 rounded-full border border-primary-300/80 bg-primary-50/90 px-4 py-1.5 text-xs font-bold uppercase tracking-widest text-primary-800 shadow-sm backdrop-blur-sm">
              <span className="h-1.5 w-1.5 rounded-full bg-primary-600 shadow-[0_0_10px_rgba(212,175,55,0.9)]" aria-hidden />
              Processus simple
            </span>
            <h2 className="font-display text-3xl font-bold tracking-tight text-secondary-900 md:text-4xl lg:text-5xl">
              Comment ça marche ?
            </h2>
            <p className="mx-auto max-w-md text-base leading-relaxed text-secondary-600 lg:mx-0 lg:max-w-none lg:text-lg">
              Trouvez et réservez votre résidence en Afrique de l&apos;Ouest : un parcours clair, sécurisé, pensé pour le mobile comme pour le web.
            </p>
            <Link
              to="/apps"
              className="inline-flex items-center gap-2 rounded-xl bg-primary-400 px-6 py-3 text-sm font-semibold text-secondary-900 shadow-gold transition-colors hover:bg-primary-300"
            >
              Télécharger l&apos;application
              <span aria-hidden>→</span>
            </Link>
            <p className="text-xs text-secondary-500 lg:text-sm">Faites défiler — la ligne d&apos;or suit votre progression.</p>
          </header>

          {/* Colonne droite : rail + étapes (défilent pendant que la gauche reste sticky) */}
          <div className="relative lg:min-h-[80vh]">
            {/* Rail : ligne pointillée + remplissage dégradé or ChapeChape */}
            <div
              className="absolute left-[25px] top-0 bottom-0 w-[2px] border-l-2 border-dashed border-secondary-300 lg:left-[29px]"
              aria-hidden
            />
            <motion.div
              className="absolute left-[25px] top-0 h-full w-[2px] origin-top bg-gradient-to-b from-primary-800 via-primary-500 to-primary-300 lg:left-[29px]"
              style={{ scaleY: lineProgress }}
              aria-hidden
            />

            <ol className="relative space-y-0">
              {steps.map((step) => (
                <ProcessStep key={step.id} step={step} />
              ))}
            </ol>
          </div>
        </div>
      </div>
    </section>
  )
}

export default Process
