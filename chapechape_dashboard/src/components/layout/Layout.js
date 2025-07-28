import React, { useState, useEffect } from 'react';
import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import Header from './Header';

const Layout = ({ children }) => {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  // Écouter les changements de taille de sidebar
  useEffect(() => {
    const handleSidebarToggle = (event) => {
      setSidebarCollapsed(event.detail.isCollapsed);
    };
    
    window.addEventListener('sidebarToggle', handleSidebarToggle);
    return () => window.removeEventListener('sidebarToggle', handleSidebarToggle);
  }, []);

  return (
    <div className="flex min-h-screen font-inter" style={{ backgroundColor: '#FAFBFC' }}>
      <Sidebar onToggle={setSidebarCollapsed} />
      <div 
        className="flex-1 transition-all duration-300 ease-smooth min-h-screen"
        style={{
          marginLeft: sidebarCollapsed ? '72px' : '260px'
        }}
      >
        <Header />
        <main className="flex-1 overflow-hidden" style={{ backgroundColor: '#FAFBFC', minHeight: 'calc(100vh - 80px)' }}>
          <div className="h-full w-full px-6 py-4">
            {children || <Outlet />}
          </div>
        </main>
      </div>
    </div>
  );
};

export default Layout;
