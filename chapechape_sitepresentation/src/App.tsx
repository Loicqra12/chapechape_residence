import { Routes, Route, useLocation } from 'react-router-dom'
import { AnimatePresence } from 'framer-motion'
import { ThemeProvider } from './contexts/ThemeContext'
import Layout from './components/layout/Layout'
import GoogleAnalytics from './components/analytics/GoogleAnalytics'
import Home from './pages/Home'
import About from './pages/About'
import Apps from './pages/Apps'
import Team from './pages/Team'
import Residences from './pages/Residences'
import Services from './pages/Services'
import Testimonials from './pages/Testimonials'
import Blog from './pages/Blog'
import FAQ from './pages/FAQ'
import Partners from './pages/Partners'
import Contact from './pages/Contact'
import PrivacyPolicy from './pages/PrivacyPolicy'
import TermsOfService from './pages/TermsOfService'
import AccountDeletion from './pages/AccountDeletion'
import CookiePolicy from './pages/CookiePolicy'

function App() {
  const location = useLocation()

  return (
    <ThemeProvider>
      <GoogleAnalytics />
      <AnimatePresence mode="wait">
        <Routes location={location} key={location.pathname}>
          <Route path="/" element={<Layout />}>
            <Route index element={<Home />} />
            <Route path="about" element={<About />} />
            <Route path="apps" element={<Apps />} />
            <Route path="team" element={<Team />} />
            <Route path="residences" element={<Residences />} />
            <Route path="residences/:type" element={<Residences />} />
            <Route path="services" element={<Services />} />
            <Route path="services/:service" element={<Services />} />
            <Route path="testimonials" element={<Testimonials />} />
            <Route path="blog" element={<Blog />} />
            <Route path="faq" element={<FAQ />} />
            <Route path="partners" element={<Partners />} />
            <Route path="contact" element={<Contact />} />
            <Route path="politique-de-confidentialite" element={<PrivacyPolicy />} />
            <Route path="conditions" element={<TermsOfService />} />
            <Route path="suppression-compte" element={<AccountDeletion />} />
            <Route path="cookies" element={<CookiePolicy />} />
          </Route>
        </Routes>
      </AnimatePresence>
    </ThemeProvider>
  )
}

export default App 