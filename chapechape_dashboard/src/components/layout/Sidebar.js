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
    const newCollapsedState = !isCollapsed;
    setIsCollapsed(newCollapsedState);
    
    // Émettre un événement pour notifier le Layout
    window.dispatchEvent(new CustomEvent('sidebarToggle', {
      detail: { isCollapsed: newCollapsedState }
    }));
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
          { name: 'Check-in', path: '/bookings/checkin' },
          { name: 'Inventaire', path: '/ops/inventory' },
          { name: 'Anomalies', path: '/ops/anomalies' }
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
          { name: 'Refunds', path: '/finance/refunds' },
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
    if (typeof isSuperAdmin === 'function' ? isSuperAdmin() : isSuperAdmin) {
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
        <motion.button
          onClick={() => hasSubmenu ? toggleSubmenu(item.name) : navigate(item.path)}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          className={`w-full flex items-center px-4 py-3 mx-3 rounded-card transition-all duration-200 group relative ${
            (hasSubmenu && isExpanded) || (!hasSubmenu && isActive)
              ? 'bg-white/20 text-white border-l-3 border-accent-500'
              : 'text-gray-200 hover:bg-white/10 hover:text-white'
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
        </motion.button>

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
      animate={{ width: isCollapsed ? '72px' : '260px' }}
      className="h-screen transition-all duration-300 ease-smooth fixed left-0 top-0 z-30 shadow-2xl font-inter"
      style={{
        background: 'linear-gradient(180deg, #1E1B4B 0%, #312E81 50%, #1E293B 100%)',
        boxShadow: '4px 0 24px rgba(0, 0, 0, 0.12), 0 0 0 1px rgba(255, 255, 255, 0.05)'
      }}
    >
      <div className="flex items-center justify-between h-20 border-b border-white/10 relative">
        <div className="flex items-center justify-center px-6 h-full w-full">
          <Link to="/" className="flex items-center group">
            <motion.img
              src="/assets/logo.png"
              alt="ChapeChape"
              className="h-10 transition-all duration-300 group-hover:scale-105"
              whileHover={{ scale: 1.05, rotate: 2 }}
              style={{ filter: 'brightness(1.1) contrast(1.1)' }}
            />
            {!isCollapsed && (
              <motion.span 
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                className="ml-3 text-white font-semibold text-lg tracking-wide"
              >
                ChapeChape
              </motion.span>
            )}
          </Link>
        </div>
        <button
          onClick={toggleSidebar}
          className="absolute -right-3 top-8 bg-gradient-to-r from-amber-400 to-yellow-500 rounded-full p-2 shadow-lg transform transition-all duration-300 hover:scale-110 hover:shadow-xl hover:from-amber-300 hover:to-yellow-400"
          style={{
            boxShadow: '0 4px 15px rgba(217, 119, 6, 0.4)'
          }}
        >
          <ChevronDoubleLeftIcon 
            className={`w-3 h-3 text-slate-800 transition-transform duration-200 ${
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
