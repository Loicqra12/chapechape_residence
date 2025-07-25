import { motion } from 'framer-motion'
import { useTheme } from '../../contexts/ThemeContext'

const ThemeToggle = () => {
  const { toggleTheme, isDark } = useTheme()

  return (
    <motion.button
      onClick={toggleTheme}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      className={`
        relative inline-flex h-10 w-20 items-center rounded-full border-2 transition-colors duration-300 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2
        ${isDark 
          ? 'bg-secondary-800 border-secondary-600' 
          : 'bg-primary-100 border-primary-200'
        }
      `}
      aria-label={`Passer en mode ${isDark ? 'clair' : 'sombre'}`}
    >
      {/* Slider */}
      <motion.div
        layout
        className={`
          h-7 w-7 transform rounded-full shadow-lg transition-transform duration-300 flex items-center justify-center
          ${isDark 
            ? 'bg-secondary-900 translate-x-11' 
            : 'bg-white translate-x-1'
          }
        `}
      >
        {/* Icône */}
        <motion.div
          initial={false}
          animate={{ rotate: isDark ? 180 : 0 }}
          transition={{ duration: 0.3 }}
          className={`w-4 h-4 ${isDark ? 'text-primary-400' : 'text-primary-600'}`}
        >
          {isDark ? (
            // Icône lune
            <svg fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" clipRule="evenodd" />
            </svg>
          ) : (
            // Icône soleil
            <svg fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clipRule="evenodd" />
            </svg>
          )}
        </motion.div>
      </motion.div>

      {/* Labels */}
      <div className="absolute inset-0 flex items-center justify-between px-2 text-xs font-medium pointer-events-none">
        <span className={`transition-opacity duration-300 ${!isDark ? 'opacity-0' : 'opacity-70 text-primary-300'}`}>
          🌙
        </span>
        <span className={`transition-opacity duration-300 ${isDark ? 'opacity-0' : 'opacity-70 text-primary-600'}`}>
          ☀️
        </span>
      </div>
    </motion.button>
  )
}

export default ThemeToggle
