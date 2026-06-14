/** Filigrane style blocs numérotés (néo-brutaliste) pour le fond des cartes */
type Props = {
  number: string
  /** Variante alternée : fond noir ou fond clair */
  variant?: 'dark' | 'light'
  className?: string
}

export default function AppFeatureCardDecor({
  number,
  variant = 'dark',
  className = '',
}: Props) {
  const isDark = variant === 'dark'
  const fill = isDark ? '#1a1a1a' : '#fffdf5'
  const numFill = isDark ? '#D4AF37' : '#1a1a1a'
  const stroke = '#1a1a1a'

  return (
    <svg
      viewBox="0 0 120 120"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      aria-hidden
    >
      {/* Étoiles décoratives */}
      <path
        d="M18 22h2v2h-2zM94 18l1.2 2.4 2.4 1.2-2.4 1.2L94 25l-1.2-2.4-2.4-1.2 2.4-1.2L94 18zM72 8l.8 1.6 1.6.8-1.6.8L72 13l-.8-1.6-1.6-.8 1.6-.8L72 8z"
        fill={stroke}
        opacity="0.35"
      />

      {/* Face latérale 3D */}
      <path
        d="M52 38 L72 28 L72 88 L52 98 Z"
        fill={isDark ? '#2d2d2d' : '#e8e0c8'}
        stroke={stroke}
        strokeWidth="2.5"
        strokeLinejoin="round"
      />

      {/* Bloc principal */}
      <rect
        x="14"
        y="32"
        width="52"
        height="56"
        rx="3"
        fill={fill}
        stroke={stroke}
        strokeWidth="3"
      />

      {/* Numéro */}
      <text
        x="40"
        y="72"
        textAnchor="middle"
        fill={numFill}
        fontFamily="system-ui, sans-serif"
        fontSize="26"
        fontWeight="800"
        letterSpacing="-0.02em"
      >
        {number}
      </text>

      {/* Petit trait sketch */}
      <path
        d="M8 95 Q20 88 32 95"
        stroke={stroke}
        strokeWidth="2"
        strokeLinecap="round"
        opacity="0.25"
      />
    </svg>
  )
}
