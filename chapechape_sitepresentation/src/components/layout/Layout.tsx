import { Outlet, useLocation } from 'react-router-dom'
import { useEffect } from 'react'
import Navbar from './Navbar'
import Newsletter from './Newsletter'
import Footer from './Footer'

const Layout = () => {
  const location = useLocation()
  useEffect(() => {
    window.scrollTo(0, 0)
  }, [location.pathname])

  return (
    <div className="flex flex-col min-h-screen bg-white dark:bg-secondary-900 font-body">
      <Navbar />
      <main className="flex-grow">
        <Outlet />
      </main>
      <Newsletter />
      <Footer />
    </div>
  )
}

export default Layout 