import { useState } from 'react'
import { ChevronLeftIcon, ChevronRightIcon, DevicePhoneMobileIcon } from '@heroicons/react/24/outline'
import type { AppScreenSlide } from './AppProductSection'

type Props = {
  screenshots: AppScreenSlide[]
  appTitle: string
}

function wrapIndex(i: number, total: number) {
  return (i + total) % total
}

function ScreenshotCard({
  slide,
  slideIndex,
  appTitle,
  isCenter,
  onSelect,
}: {
  slide: AppScreenSlide
  slideIndex: number
  appTitle: string
  isCenter: boolean
  onSelect: () => void
}) {
  const screenNum = String(slideIndex + 1).padStart(2, '0')

  return (
    <article
      onClick={onSelect}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault()
          onSelect()
        }
      }}
      role="button"
      tabIndex={0}
      className={[
        'flex cursor-pointer flex-col rounded-2xl border bg-[#fffdf5] p-5 transition-all duration-300 lg:p-6',
        isCenter
          ? 'z-10 border-primary-300/90 shadow-2xl md:-translate-y-4 md:scale-[1.03]'
          : 'border-primary-100/90 shadow-md md:scale-[0.94] md:opacity-90',
      ].join(' ')}
      aria-current={isCenter ? 'true' : undefined}
    >
      <div className="mb-4 flex items-start gap-3">
        <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-primary-400 text-secondary-900 shadow-sm">
          <DevicePhoneMobileIcon className="h-5 w-5" aria-hidden />
        </div>
        <div className="min-w-0 pt-0.5">
          <p className="text-xs font-bold uppercase tracking-widest text-secondary-500">
            Écran {screenNum}
          </p>
          <h3 className="mt-1 font-display text-base font-bold leading-snug text-secondary-900 lg:text-lg">
            {slide.label}
          </h3>
        </div>
      </div>

      <p className="mb-5 flex-1 text-sm leading-relaxed text-secondary-600 line-clamp-4">
        {slide.caption}
      </p>

      <div className="mx-auto w-full max-w-[10.5rem] lg:max-w-[12rem]">
        <div
          className={[
            'relative overflow-hidden rounded-[1.35rem] border-[5px] border-secondary-800 bg-secondary-900 shadow-inner',
            isCenter ? 'h-[220px] lg:h-[280px]' : 'h-[190px] lg:h-[230px]',
          ].join(' ')}
        >
          <div
            className="absolute left-1/2 top-0 z-10 h-4 w-14 -translate-x-1/2 rounded-b-lg bg-black"
            aria-hidden
          />
          <img
            src={slide.src}
            alt={`${appTitle} — ${slide.label}`}
            className="h-full w-full object-cover object-top"
            loading="lazy"
          />
        </div>
      </div>

      <p className="mt-5 flex items-center justify-between gap-2 border-t border-primary-100 pt-4 text-sm font-semibold text-secondary-800">
        <span className="underline decoration-primary-400 underline-offset-4">
          Explorer cet écran
        </span>
        <span aria-hidden className="text-primary-600">
          →
        </span>
      </p>
    </article>
  )
}

export default function AppScreenshotCardsCarousel({ screenshots, appTitle }: Props) {
  const [active, setActive] = useState(0)
  const total = screenshots.length

  const go = (delta: number) => setActive((prev) => wrapIndex(prev + delta, total))

  const visible = [
    wrapIndex(active - 1, total),
    active,
    wrapIndex(active + 1, total),
  ]

  const activeSlide = screenshots[active]

  return (
    <div className="rounded-3xl border border-primary-200/60 bg-gradient-to-b from-primary-50 to-primary-100/40 px-4 py-10 sm:px-8 sm:py-14">
      <div className="mx-auto hidden max-w-6xl items-end gap-4 md:grid md:grid-cols-3 md:gap-5 lg:gap-8">
        {visible.map((slideIndex, position) => {
          const slide = screenshots[slideIndex]
          const isCenter = position === 1
          return (
            <ScreenshotCard
              key={`${slide.src}-${position}-${active}`}
              slide={slide}
              slideIndex={slideIndex}
              appTitle={appTitle}
              isCenter={isCenter}
              onSelect={() => setActive(slideIndex)}
            />
          )
        })}
      </div>

      <div className="md:hidden">
        <ScreenshotCard
          slide={activeSlide}
          slideIndex={active}
          appTitle={appTitle}
          isCenter={true}
          onSelect={() => {}}
        />
      </div>

      <div
        className="mt-10 flex items-center justify-center gap-4"
        role="group"
        aria-label="Navigation des captures d'écran"
      >
        <button
          type="button"
          onClick={() => go(-1)}
          className="flex h-11 w-11 items-center justify-center rounded-full border border-primary-200 bg-white text-secondary-800 shadow-sm transition hover:border-primary-400 hover:bg-primary-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500"
          aria-label="Écran précédent"
        >
          <ChevronLeftIcon className="h-5 w-5" aria-hidden />
        </button>
        <span className="min-w-[8rem] text-center text-sm font-bold uppercase tracking-wide text-secondary-800">
          Écran {String(active + 1).padStart(2, '0')} / {String(total).padStart(2, '0')}
        </span>
        <button
          type="button"
          onClick={() => go(1)}
          className="flex h-11 w-11 items-center justify-center rounded-full border border-primary-200 bg-white text-secondary-800 shadow-sm transition hover:border-primary-400 hover:bg-primary-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-500"
          aria-label="Écran suivant"
        >
          <ChevronRightIcon className="h-5 w-5" aria-hidden />
        </button>
      </div>
    </div>
  )
}
