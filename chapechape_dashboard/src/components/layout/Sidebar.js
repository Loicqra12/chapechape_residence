import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import {
  HomeIcon,
  UsersIcon,
  BuildingOfficeIcon,
  Cog6ToothIcon,
  ChartBarIcon,
  CalendarIcon,
  CurrencyDollarIcon,
  ChatBubbleLeftIcon,
  MegaphoneIcon,
  ShieldCheckIcon,
  ChevronDownIcon,
  ArrowLeftOnRectangleIcon,
  ChevronDoubleLeftIcon,
} from '@heroicons/react/24/outline';
import { logout } from '../../services/auth';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { motion } from 'framer-motion';

const Sidebar = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { isSuperAdmin, isAdmin } = useAuth();
  const [expandedMenus, setExpandedMenus] = useState({});
  const [isCollapsed, setIsCollapsed] = useState(false);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const toggleSubmenu = (menuName) => {
    setExpandedMenus(prev => ({
      ...prev,
      [menuName]: !prev[menuName]
    }));
  };

  const toggleSidebar = () => {
    setIsCollapsed(!isCollapsed);
  };

  const getMenuItems = () => {
    const baseMenuItems = [
      {
        name: 'Tableau de bord',
        icon: HomeIcon,
        path: '/dashboard'
      },
      {
        name: 'Réservations',
        icon: CalendarIcon,
        submenu: [
          { name: 'Calendrier', path: '/bookings/calendar' },
          { name: 'Liste des réservations', path: '/bookings/list' },
          { name: 'Check-in', path: '/bookings/checkin' }
        ]
      },
      {
        name: 'Immobilier',
        icon: BuildingOfficeIcon,
        submenu: [
          { name: 'Résidences', path: '/properties' },
          { name: 'Types', path: '/property-types' },
          { name: 'Commodités', path: '/amenities' },
          { name: 'Médias', path: '/media' }
        ]
      },
      {
        name: 'Finance',
        icon: CurrencyDollarIcon,
        submenu: [
          { name: 'Transactions', path: '/finance/transactions' },
          { name: 'Paiements', path: '/finance/payments' },
          { name: 'Rapports', path: '/finance/reports' }
        ]
      },
      {
        name: 'Utilisateurs',
        icon: UsersIcon,
        submenu: [
          { name: 'Clients', path: '/users/clients' },
          { name: 'Partenaires', path: '/users/partners' }
        ]
      },
      {
        name: 'Marketing',
        icon: MegaphoneIcon,
        submenu: [
          { name: 'Promotions', path: '/marketing/promotions' },
          { name: 'Campagnes', path: '/marketing/campaigns' },
          { name: 'Avis', path: '/marketing/reviews' }
        ]
      },
      {
        name: 'Communication',
        icon: ChatBubbleLeftIcon,
        submenu: [
          { name: 'Messages', path: '/communication/messages' },
          { name: 'Notifications', path: '/communication/notifications' },
          { name: 'Support', path: '/communication/support' }
        ]
      },
      {
        name: 'Analytics',
        icon: ChartBarIcon,
        submenu: [
          { name: 'Performance', path: '/analytics/performance' },
          { name: 'Revenus', path: '/analytics/revenue' },
          { name: 'Rapports', path: '/analytics/reports' }
        ]
      }
    ];

    // Ajouter les menus d'administration pour les super admins
    if (isSuperAdmin) {
      baseMenuItems.push({
        name: 'Administration',
        icon: ShieldCheckIcon,
        submenu: [
          { name: 'Administrateurs', path: '/admin/administrators' },
          { name: 'Rôles', path: '/admin/roles' },
          { name: 'Permissions', path: '/admin/permissions' },
          { name: 'Logs système', path: '/admin/logs' }
        ]
      });
    }

    // Ajouter les paramètres système
    baseMenuItems.push({
      name: 'Système',
      icon: Cog6ToothIcon,
      submenu: [
        { name: 'Paramètres', path: '/settings' },
        { name: 'Sécurité', path: '/settings/security' },
        isAdmin && { name: 'Maintenance', path: '/settings/maintenance' }
      ].filter(Boolean)
    });

    return baseMenuItems;
  };

  const renderMenuItem = (item) => {
    const isActive = location.pathname === item.path;
    const hasSubmenu = item.submenu && item.submenu.length > 0;
    const isExpanded = expandedMenus[item.name];

    return (
      <div key={item.name} className="my-1">
        <button
          onClick={() => hasSubmenu ? toggleSubmenu(item.name) : navigate(item.path)}
          className={`w-full flex items-center px-6 py-3 mx-2 rounded-xl transition-all duration-200 group ${
            (hasSubmenu && isExpanded) || (!hasSubmenu && isActive)
              ? 'bg-white bg-opacity-20 text-white'
              : 'text-gray-300 hover:bg-white hover:bg-opacity-10'
          }`}
        >
          <item.icon className="w-6 h-6 flex-shrink-0" />
          {!isCollapsed && (
            <>
              <span className="ml-3 flex-1 text-left">{item.name}</span>
              {hasSubmenu && (
                <ChevronDownIcon
                  className={`w-5 h-5 transition-transform duration-200 ${
                    isExpanded ? 'transform rotate-180' : ''
                  }`}
                />
              )}
            </>
          )}
        </button>

        {hasSubmenu && isExpanded && !isCollapsed && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.2 }}
            className="ml-8 mt-1 space-y-1"
          >
            {item.submenu.map((subItem) => (
              <Link
                key={subItem.path}
                to={subItem.path}
                className={`block px-4 py-2 rounded-lg text-sm ${
                  location.pathname === subItem.path
                    ? 'bg-white bg-opacity-20 text-white'
                    : 'text-gray-300 hover:bg-white hover:bg-opacity-10'
                }`}
              >
                {subItem.name}
              </Link>
            ))}
          </motion.div>
        )}
      </div>
    );
  };

  return (
    <motion.div
      animate={{ width: isCollapsed ? '5rem' : '16rem' }}
      className="bg-gradient-to-b from-[#1A237E] to-[#283593] h-screen transition-all duration-300 ease-in-out fixed left-0 top-0 z-30"
    >
      <div className="flex items-center justify-between h-16 border-b border-white/10">
        <div className="flex items-center px-4 bg-white/10 h-full w-full">
          <Link to="/" className="flex items-center">
            <img
              src="/assets/logo.png"
              alt="ChapeChape"
              className="h-8"
            />
          </Link>
        </div>
        <button
          onClick={toggleSidebar}
          className="absolute -right-4 top-8 bg-white rounded-full p-1 shadow-lg transform transition-transform hover:scale-110"
        >
          <ChevronDoubleLeftIcon 
            className={`w-4 h-4 text-[#1A237E] transition-transform duration-200 ${
              isCollapsed ? 'rotate-180' : ''
            }`}
          />
        </button>
      </div>

      <div className="py-4 flex flex-col h-[calc(100vh-4rem)] overflow-y-auto">
        {getMenuItems().map(renderMenuItem)}
        
        <button
          onClick={handleLogout}
          className="mt-auto mx-2 mb-4 flex items-center px-6 py-3 text-gray-300 hover:bg-white hover:bg-opacity-10 rounded-xl transition-all duration-200"
        >
          <ArrowLeftOnRectangleIcon className="w-6 h-6" />
          {!isCollapsed && <span className="ml-3">Déconnexion</span>}
        </button>
      </div>
    </motion.div>
  );
};

export default Sidebar;
