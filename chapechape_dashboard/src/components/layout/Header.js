import React from 'react';
import { BellIcon } from '@heroicons/react/24/outline';
import { getCurrentUser } from '../../services/auth';

const Header = () => {
  const user = getCurrentUser();
  const notifications = []; // À implémenter plus tard

  return (
    <header 
      className="h-20 flex items-center justify-between px-8 sticky top-0 z-40 font-inter border-b"
      style={{
        background: 'rgba(255, 255, 255, 0.95)',
        backdropFilter: 'blur(24px)',
        borderColor: 'rgba(226, 232, 240, 0.6)',
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.05), 0 1px 2px rgba(0, 0, 0, 0.1)'
      }}
    >
      {/* Breadcrumbs & Titre */}
      <div>
        <nav className="flex items-center space-x-2 text-sm text-gray-500 mb-1">
          <span className="hover:text-gray-700 cursor-pointer transition-colors">Dashboard</span>
          <span className="text-gray-300">•</span>
          <span className="text-indigo-600 font-medium">Accueil</span>
        </nav>
        <h1 className="text-2xl font-semibold text-gray-900 tracking-tight">
          Tableau de bord
        </h1>
        <p className="text-sm text-gray-600 mt-0.5">
          Vue d'ensemble des performances et statistiques
        </p>
      </div>

      {/* Actions */}
      <div className="flex items-center space-x-6">
        {/* Quick Actions */}
        <div className="flex items-center space-x-3">
          <button className="p-2.5 text-gray-500 hover:text-indigo-600 hover:bg-indigo-50 rounded-xl transition-all duration-200 group">
            <svg className="w-5 h-5 group-hover:scale-110 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
          </button>
          <button className="p-2.5 text-gray-500 hover:text-indigo-600 hover:bg-indigo-50 rounded-xl transition-all duration-200 group">
            <svg className="w-5 h-5 group-hover:scale-110 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </button>
        </div>

        {/* Notifications */}
        <div className="relative">
          <button className="p-2.5 text-gray-500 hover:text-amber-600 hover:bg-amber-50 rounded-xl transition-all duration-200 group relative">
            <BellIcon className="w-5 h-5 group-hover:scale-110 transition-transform" />
            {notifications.length > 0 && (
              <span className="absolute -top-1 -right-1 bg-gradient-to-r from-red-500 to-pink-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center font-medium shadow-lg animate-pulse">
                {notifications.length}
              </span>
            )}
          </button>
        </div>

        {/* Profil Premium */}
        <div className="flex items-center space-x-4">
          <div className="text-right">
            <p className="text-sm font-semibold text-gray-900">
              {user?.firstName} {user?.lastName}
            </p>
            <p className="text-xs text-gray-600 flex items-center justify-end">
              <span className="w-2 h-2 bg-green-500 rounded-full mr-1.5 animate-pulse"></span>
              {user?.role === 'superadmin' ? 'Super Admin' : 'Administrateur'}
            </p>
          </div>
          <div className="relative">
            <div className="h-11 w-11 rounded-xl bg-gradient-to-br from-indigo-500 via-purple-500 to-indigo-600 flex items-center justify-center text-white font-semibold text-sm shadow-lg ring-2 ring-white/20 hover:scale-105 transition-all duration-200 cursor-pointer">
              {user?.firstName?.[0]}{user?.lastName?.[0]}
            </div>
            <div className="absolute -bottom-0.5 -right-0.5 w-4 h-4 bg-green-500 rounded-full border-2 border-white shadow-sm">
              <div className="w-full h-full bg-green-400 rounded-full animate-ping opacity-75"></div>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;
