import React from 'react';
import { BellIcon } from '@heroicons/react/24/outline';
import { getCurrentUser } from '../../services/auth';

const Header = () => {
  const user = getCurrentUser();
  const notifications = []; // À implémenter plus tard

  return (
    <header className="bg-white shadow-sm h-16 flex items-center justify-between px-6 fixed top-0 right-0 left-64 z-40">
      {/* Titre de la page */}
      <div>
        <h1 className="text-2xl font-semibold text-gray-800">
          Tableau de bord
        </h1>
      </div>

      {/* Actions */}
      <div className="flex items-center space-x-4">
        {/* Notifications */}
        <div className="relative">
          <button className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-full transition-all duration-200">
            <BellIcon className="w-6 h-6" />
            {notifications.length > 0 && (
              <span className="absolute top-0 right-0 transform translate-x-1/2 -translate-y-1/2 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                {notifications.length}
              </span>
            )}
          </button>
        </div>

        {/* Profil */}
        <div className="flex items-center space-x-3">
          <div className="text-right">
            <p className="text-sm font-medium text-gray-900">
              {user?.firstName} {user?.lastName}
            </p>
            <p className="text-xs text-gray-500">
              {user?.role === 'superadmin' ? 'Super Admin' : 'Administrateur'}
            </p>
          </div>
          <div className="h-10 w-10 rounded-full bg-gradient-to-r from-[#1A237E] to-[#283593] flex items-center justify-center text-white font-medium">
            {user?.firstName?.[0]}{user?.lastName?.[0]}
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;
