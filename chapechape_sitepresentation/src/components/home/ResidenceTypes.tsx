import { useState, useRef, useEffect, useMemo } from 'react'
import { motion, useScroll, useTransform, AnimatePresence } from 'framer-motion'
import { residenceTypes, ResidenceType } from '../../data/residences'
import ResidencePlaceholder, { type ResidencePlaceholderType } from './ResidencePlaceholders'

function ArrowUpRight({ className }: { className?: string }) {
  return (
    <svg className={className} width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden>
      <path strokeLinecap="round" strokeLinejoin="round" d="M7 17L17 7M17 7H9M17 7V15" />
    </svg>
  )
}

const ResidenceTypes = () => {
  const [selectedType, setSelectedType] = useState<ResidenceType>(residenceTypes[0])
  const [imagesLoaded, setImagesLoaded] = useState<Record<string, boolean>>({})
  const containerRef = useRef<HTMLElement>(null)

  const otherTypes = useMemo(
    () => residenceTypes.filter((t) => t.id !== selectedType.id),
    [selectedType.id],
  )

  useEffect(() => {
    const checkImages = async () => {
      const base = typeof window !== 'undefined' ? window.location.origin : ''
      for (const type of residenceTypes) {
        try {
          const img = new Image()
          const url = type.imageUrl.startsWith('http') ? type.imageUrl : base + type.imageUrl
          img.src = url
          await new Promise<void>((resolve, reject) => {
            img.onload = () => resolve()
            img.onerror = () => reject()
            if (img.complete && img.naturalWidth > 0) resolve()
          })
          setImagesLoaded((prev) => ({ ...prev, [type.id]: true }))
        } catch {
          setImagesLoaded((prev) => ({ ...prev, [type.id]: false }))
        }
      }
    }
    checkImages()
  }, [])

  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ['start end', 'end start'],
  })

  const y = useTransform(scrollYProgress, [0, 1], [40, -40])
  const fade = useTransform(scrollYProgress, [0, 0.2, 0.85, 1], [0.35, 1, 1, 0.4])

  const selectedImageVariants = {
    initial: { opacity: 0, scale: 0.96 },
    animate: {
      opacity: 1,
      scale: 1,
      transition: { type: 'spring', stiffness: 280, damping: 26 },
    },
    exit: {
      opacity: 0,
      scale: 0.96,
      transition: { duration: 0.28 },
    },
  }

  const handleTypeChange = (type: ResidenceType) => {
    setSelectedType(type)
  }

  const bgImageUrl = '/assets/images/background_categorie.png'

  return (
    <section ref={containerRef} className="relative overflow-hidden py-16 lg:py-24">
      <div className="absolute inset-0 z-0 overflow-hidden">
        <img src={bgImageUrl} alt="" className="h-full w-full object-cover object-center" aria-hidden />
      </div>
      <div className="pointer-events-none absolute inset-0 z-[1] bg-white/20" aria-hidden />
      <motion.div
        className="pointer-events-none absolute inset-0 z-[1] bg-[radial-gradient(ellipse_80%_50%_at_50%_18%,rgba(212,175,55,0.1),transparent_58%)]"
        style={{ y, opacity: fade }}
      />

      <div className="relative z-10 mx-auto max-w-6xl px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 18 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-80px' }}
          transition={{ duration: 0.55 }}
          className="mb-12 text-center lg:mb-14"
        >
          <span className="mb-5 inline-flex items-center rounded-full border border-primary-200 bg-white/90 px-4 py-2 text-xs font-bold uppercase tracking-[0.2em] text-primary-800 shadow-sm backdrop-blur-sm">
            <span className="mr-2 h-2 w-2 rounded-full bg-primary-500" aria-hidden />
            6 catégories, 28 types
          </span>
          <h2 className="font-display text-4xl font-bold tracking-tight text-secondary-900 md:text-5xl lg:text-6xl">
            Tous types d&apos;hébergement
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-lg font-light leading-relaxed text-secondary-600">
            Du studio au villa, de l&apos;hôtel de passage au lodge : trouvez ou proposez l&apos;hébergement qui vous correspond,{' '}
            <span className="font-medium text-primary-700">tous budgets et toutes durées</span>.
          </p>
        </motion.div>

        {/* Encadrement type bento : grille + coins larges */}
        <div className="rounded-[1.75rem] border border-white/60 bg-white/50 p-4 shadow-[0_24px_60px_-20px_rgba(16,24,40,0.12)] backdrop-blur-md sm:rounded-[2rem] sm:p-5 lg:p-6">
          <div className="grid grid-cols-12 gap-3 sm:gap-4 lg:gap-5">
            {/* Tuile héro — type sélectionné */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: '-40px' }}
              transition={{ duration: 0.45 }}
              className="group relative col-span-12 min-h-[280px] overflow-hidden rounded-2xl border border-white/40 shadow-lg sm:min-h-[320px] lg:col-span-8 lg:row-span-2 lg:min-h-[440px] lg:rounded-3xl"
            >
              <AnimatePresence mode="wait">
                <motion.div
                  key={selectedType.id}
                  variants={selectedImageVariants}
                  initial="initial"
                  animate="animate"
                  exit="exit"
                  className="absolute inset-0"
                >
                  {selectedType.imageUrl && imagesLoaded[selectedType.id] !== false ? (
                    <motion.div
                      className="relative h-full w-full"
                      whileHover={{ scale: 1.04 }}
                      transition={{ duration: 0.7, ease: 'easeOut' }}
                    >
                      <img
                        src={selectedType.imageUrl}
                        alt=""
                        className="absolute inset-0 h-full w-full object-cover object-center"
                        onError={() => setImagesLoaded((prev) => ({ ...prev, [selectedType.id]: false }))}
                      />
                    </motion.div>
                  ) : (
                    <ResidencePlaceholder type={selectedType.id as ResidencePlaceholderType} className="h-full w-full" />
                  )}
                  <div className="absolute inset-0 bg-gradient-to-t from-secondary-900/92 via-secondary-900/25 to-transparent" />
                  <div className="absolute inset-x-0 bottom-0 p-6 sm:p-8 lg:p-10">
                    <h3 className="font-display text-2xl font-bold tracking-wide text-white sm:text-3xl lg:text-4xl">{selectedType.name}</h3>
                    <div className="mt-2 flex gap-0.5" aria-hidden>
                      {[...Array(5)].map((_, i) => (
                        <span key={i} className="text-lg leading-none text-primary-400">
                          ★
                        </span>
                      ))}
                    </div>
                    <div className="mt-6 flex flex-wrap items-center gap-3">
                      <motion.a
                        href="/residences"
                        whileHover={{ scale: 1.03 }}
                        whileTap={{ scale: 0.98 }}
                        className="inline-flex items-center gap-2 rounded-full bg-gradient-to-r from-primary-700 via-primary-600 to-primary-500 px-6 py-3 text-sm font-semibold text-white shadow-lg"
                      >
                        Voir les offres
                        <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                        </svg>
                      </motion.a>
                    </div>
                  </div>
                </motion.div>
              </AnimatePresence>

              <a
                href="/residences"
                className="absolute right-5 top-5 z-20 flex h-12 w-12 items-center justify-center rounded-full border border-white/30 bg-white/95 text-secondary-900 shadow-md transition hover:bg-primary-50 hover:text-secondary-950"
                aria-label="Voir les résidences"
              >
                <ArrowUpRight className="h-[18px] w-[18px]" />
              </a>
            </motion.div>

            {/* Colonne tuiles — autres catégories */}
            <div className="col-span-12 flex min-h-0 flex-col gap-3 sm:gap-4 lg:col-span-4 lg:row-span-2 lg:overflow-y-auto lg:pr-1">
              {otherTypes.map((type, index) => (
                <motion.div
                  key={type.id}
                  role="button"
                  tabIndex={0}
                  initial={{ opacity: 0, x: 12 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true, margin: '-20px' }}
                  transition={{ delay: index * 0.05, duration: 0.35 }}
                  whileHover={{ y: -2, transition: { duration: 0.2 } }}
                  className="relative cursor-pointer rounded-2xl border border-secondary-200/80 bg-gradient-to-br from-white to-secondary-50/80 p-4 text-left shadow-sm transition hover:border-primary-300/70 hover:shadow-md lg:rounded-3xl lg:p-4"
                  onClick={() => handleTypeChange(type)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault()
                      handleTypeChange(type)
                    }
                  }}
                >
                  <div className="flex gap-3 pr-12">
                    <div className="relative h-14 w-14 shrink-0 overflow-hidden rounded-xl border border-secondary-100 bg-secondary-100">
                      {type.imageUrl && imagesLoaded[type.id] !== false ? (
                        <img
                          src={type.imageUrl}
                          alt=""
                          className="h-full w-full object-cover"
                          onError={() => setImagesLoaded((prev) => ({ ...prev, [type.id]: false }))}
                        />
                      ) : (
                        <ResidencePlaceholder type={type.id as ResidencePlaceholderType} className="h-full w-full" />
                      )}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-semibold leading-snug text-secondary-900 line-clamp-2">{type.name}</p>
                      <p className="mt-1 text-xs leading-relaxed text-secondary-500 line-clamp-2">{type.description}</p>
                    </div>
                  </div>
                  <a
                    href="/residences"
                    className="absolute bottom-3 right-3 z-10 flex h-10 w-10 items-center justify-center rounded-full border border-secondary-200 bg-white text-secondary-800 shadow-sm transition hover:border-primary-300 hover:bg-primary-50"
                    aria-label={`Voir les offres ${type.name}`}
                    onClick={(e) => e.stopPropagation()}
                  >
                    <ArrowUpRight className="h-4 w-4" />
                  </a>
                </motion.div>
              ))}
            </div>

            {/* Carte détail — description + caractéristiques */}
            <motion.div
              key={selectedType.id}
              initial={{ opacity: 0, y: 14 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.35 }}
              className="col-span-12 rounded-2xl border border-secondary-100 bg-white/95 p-6 shadow-sm backdrop-blur-sm sm:p-8 lg:rounded-3xl"
            >
              <h4 className="font-display text-xl font-bold tracking-tight text-secondary-900 sm:text-2xl">{selectedType.name}</h4>
              <p className="mt-3 text-base leading-relaxed text-secondary-600">{selectedType.description}</p>

              <h5 className="mb-3 mt-8 text-xs font-semibold uppercase tracking-widest text-secondary-800">Caractéristiques</h5>
              <ul className="mb-8 grid gap-3 sm:grid-cols-2">
                {selectedType.features.map((feature, index) => (
                  <li key={`${selectedType.id}-${index}`} className="flex items-start gap-3 text-secondary-700">
                    <span className="mt-0.5 shrink-0 text-primary-500" aria-hidden>
                      <svg className="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
                        <path
                          fillRule="evenodd"
                          d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                          clipRule="evenodd"
                        />
                      </svg>
                    </span>
                    <span className="text-[15px] leading-snug">{feature}</span>
                  </li>
                ))}
              </ul>

              <a
                href="/residences"
                className="inline-flex items-center gap-2 rounded-full border border-primary-200/80 bg-gradient-to-r from-primary-50 to-white px-6 py-3 text-sm font-semibold text-secondary-800 transition hover:border-primary-300 hover:from-primary-100"
              >
                Voir les offres
                <svg className="h-4 w-4 text-secondary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                </svg>
              </a>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  )
}

export default ResidenceTypes
