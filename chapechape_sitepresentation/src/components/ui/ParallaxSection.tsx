import { useRef } from 'react'
import { motion, useScroll, useTransform } from 'framer-motion'

interface ParallaxSectionProps {
  image: string
  height?: string
  overlayOpacity?: number
  children?: React.ReactNode
}

export default function ParallaxSection({
  image,
  height = "50vh",
  overlayOpacity = 0.4,
  children
}: ParallaxSectionProps) {
  const ref = useRef(null)
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"]
  })

  const y = useTransform(scrollYProgress, [0, 1], ["-20%", "20%"])
  const scale = useTransform(scrollYProgress, [0, 0.5, 1], [1, 1.1, 1])

  return (
    <div
      ref={ref}
      className="relative overflow-hidden w-full"
      style={{ height }}
    >
      <motion.div
        className="absolute inset-0 w-full h-[140%] -top-[20%]"
        style={{
          y,
          scale,
          backgroundImage: `url(${image})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
        }}
      />

      <div
        className="absolute inset-0 bg-secondary-900"
        style={{ opacity: overlayOpacity }}
      />

      <div className="relative z-10 h-full flex items-center justify-center">
        {children}
      </div>
    </div>
  )
}
