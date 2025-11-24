import { useState, useEffect, useRef } from 'react'
import { motion } from 'framer-motion'

interface SmartImageProps {
  src: string
  alt: string
  className?: string
  blurDataURL?: string
  priority?: boolean
}

export default function SmartImage({
  src,
  alt,
  className = '',
  blurDataURL,
  priority = false
}: SmartImageProps) {
  const [isLoaded, setIsLoaded] = useState(false)
  const [isInView, setIsInView] = useState(priority)
  const imgRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (priority) return

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setIsInView(true)
            observer.disconnect()
          }
        })
      },
      {
        rootMargin: '50px'
      }
    )

    if (imgRef.current) {
      observer.observe(imgRef.current)
    }

    return () => {
      observer.disconnect()
    }
  }, [priority])

  // Generate WebP source from original src
  const webpSrc = src.replace(/\.(jpg|jpeg|png)$/i, '.webp')
  const avifSrc = src.replace(/\.(jpg|jpeg|png)$/i, '.avif')

  return (
    <div ref={imgRef} className={`relative overflow-hidden ${className}`}>
      {/* Blur placeholder */}
      {blurDataURL && !isLoaded && (
        <div
          className="absolute inset-0 bg-cover bg-center filter blur-lg scale-110"
          style={{ backgroundImage: `url(${blurDataURL})` }}
        />
      )}

      {/* Progressive image with modern formats */}
      {isInView && (
        <motion.picture
          initial={{ opacity: 0 }}
          animate={{ opacity: isLoaded ? 1 : 0 }}
          transition={{ duration: 0.3 }}
        >
          {/* Modern formats (browsers will pick the first supported format) */}
          <source srcSet={avifSrc} type="image/avif" />
          <source srcSet={webpSrc} type="image/webp" />

          {/* Fallback to original */}
          <img
            src={src}
            alt={alt}
            loading={priority ? 'eager' : 'lazy'}
            onLoad={() => setIsLoaded(true)}
            className={`w-full h-full object-cover ${isLoaded ? 'opacity-100' : 'opacity-0'} transition-opacity duration-300`}
          />
        </motion.picture>
      )}

      {/* Loading skeleton */}
      {!isLoaded && (
        <div className="absolute inset-0 bg-gradient-to-r from-secondary-200 via-secondary-100 to-secondary-200 animate-pulse" />
      )}
    </div>
  )
}
