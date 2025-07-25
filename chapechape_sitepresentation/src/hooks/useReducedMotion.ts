import { useState, useEffect } from 'react'

/**
 * Hook pour détecter les préférences de mouvement réduit de l'utilisateur
 * et optimiser les animations en conséquence
 */
export const useReducedMotion = () => {
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false)
  const [isMobile, setIsMobile] = useState(false)

  useEffect(() => {
    // Détecter les préférences de mouvement réduit
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)')
    setPrefersReducedMotion(mediaQuery.matches)

    // Détecter si c'est un appareil mobile
    const mobileQuery = window.matchMedia('(max-width: 768px)')
    setIsMobile(mobileQuery.matches)

    // Écouter les changements
    const handleMotionChange = (e: MediaQueryListEvent) => {
      setPrefersReducedMotion(e.matches)
    }

    const handleMobileChange = (e: MediaQueryListEvent) => {
      setIsMobile(e.matches)
    }

    mediaQuery.addEventListener('change', handleMotionChange)
    mobileQuery.addEventListener('change', handleMobileChange)

    return () => {
      mediaQuery.removeEventListener('change', handleMotionChange)
      mobileQuery.removeEventListener('change', handleMobileChange)
    }
  }, [])

  return {
    prefersReducedMotion,
    isMobile,
    shouldReduceMotion: prefersReducedMotion || isMobile
  }
}

/**
 * Fonction utilitaire pour créer des variants d'animation optimisés
 */
export const createOptimizedVariants = (
  normalVariants: any,
  reducedVariants: any,
  shouldReduce: boolean
) => {
  return shouldReduce ? reducedVariants : normalVariants
}

/**
 * Fonction pour optimiser les transitions selon les préférences
 */
export const optimizeTransition = (
  transition: any,
  shouldReduce: boolean
) => {
  if (shouldReduce) {
    return {
      ...transition,
      duration: Math.min(transition.duration || 0.3, 0.2),
      type: 'tween',
      ease: 'easeOut'
    }
  }
  return transition
}
