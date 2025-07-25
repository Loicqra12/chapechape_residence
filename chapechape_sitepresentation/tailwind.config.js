/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      screens: {
        'xs': '475px',
        '3xl': '1600px',
      },
      colors: {
        // Palette ChapeChape Premium inspirée de Stripe
        primary: {
          50: '#fefdf8',
          100: '#fefbf0',
          200: '#fdf6d9',
          300: '#fbf0c2', // Or élégant principal
          400: '#f9e89b',
          500: '#f7df74',
          600: '#f5d54d',
          700: '#d4af37', // Or classique ChapeChape
          800: '#b8941f',
          900: '#9c7a07',
          950: '#7a5f05',
        },
        secondary: {
          25: '#fcfcfd',
          50: '#f9fafb',
          100: '#f2f4f7',
          200: '#eaecf0',
          300: '#d0d5dd',
          400: '#98a2b3',
          500: '#667085',
          600: '#475467',
          700: '#344054',
          800: '#1d2939',
          900: '#101828',
          950: '#0c111d',
        },
        // Couleurs d'accent premium
        accent: {
          blue: '#635bff',
          purple: '#7c3aed',
          green: '#00d924',
          orange: '#ff6b35',
          red: '#e11d48',
        },
        // Gradients Stripe-like
        gradient: {
          from: '#667eea',
          via: '#764ba2',
          to: '#f093fb',
        },
      },
      fontFamily: {
        'display': ['Cabinet Grotesk', 'Inter', 'system-ui', 'sans-serif'],
        'body': ['Plus Jakarta Sans', 'Inter', 'system-ui', 'sans-serif'],
        'mono': ['JetBrains Mono', 'Menlo', 'Monaco', 'monospace'],
      },
      fontSize: {
        'xs': ['0.75rem', { lineHeight: '1rem' }],
        'sm': ['0.875rem', { lineHeight: '1.25rem' }],
        'base': ['1rem', { lineHeight: '1.5rem' }],
        'lg': ['1.125rem', { lineHeight: '1.75rem' }],
        'xl': ['1.25rem', { lineHeight: '1.75rem' }],
        '2xl': ['1.5rem', { lineHeight: '2rem' }],
        '3xl': ['1.875rem', { lineHeight: '2.25rem' }],
        '4xl': ['2.25rem', { lineHeight: '2.5rem' }],
        '5xl': ['3rem', { lineHeight: '1.16' }],
        '6xl': ['3.75rem', { lineHeight: '1.16' }],
        '7xl': ['4.5rem', { lineHeight: '1.16' }],
        '8xl': ['6rem', { lineHeight: '1.16' }],
        '9xl': ['8rem', { lineHeight: '1.16' }],
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem',
        '144': '36rem',
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