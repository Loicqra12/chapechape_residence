/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#FFF9E6',
          100: '#FFF0C2',
          200: '#FFE499',
          300: '#D4AF37',
          400: '#B8860B',
          500: '#A57C1B',
          600: '#8B6914',
          700: '#705410',
          800: '#55400C',
          900: '#3A2D08',
        },
        secondary: {
          50: '#F5F5F5',
          100: '#E0E0E0',
          200: '#BDBDBD',
          300: '#9E9E9E',
          400: '#757575',
          500: '#616161',
          600: '#424242',
          700: '#212121',
          800: '#1A1A1A',
          900: '#000000',
        },
        accent: {
          50: '#FFF3E0',
          100: '#FFE0B2',
          200: '#FFCC80',
          300: '#FFB74D',
          400: '#FFA726',
          500: '#FF8C00',
          600: '#F57C00',
          700: '#EF6C00',
          800: '#E65100',
          900: '#BF360C',
        },
      },
      fontFamily: {
        sans: ['Plus Jakarta Sans', 'Inter', 'sans-serif'],
        display: ['Cabinet Grotesk', 'Plus Jakarta Sans', 'sans-serif'],
      },
      fontSize: {
        '2xs': ['0.625rem', { lineHeight: '0.75rem' }],
      },
      borderRadius: {
        '4xl': '2rem',
      },
      boxShadow: {
        'soft-xl': '0 20px 27px 0 rgba(0, 0, 0, 0.05)',
        'gold': '0 4px 14px 0 rgba(212, 175, 55, 0.2)',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
} 