import React, { useState, useEffect } from 'react';
import {
  Bell,
  BellRing,
  CheckCircle,
  Trash2,
  X,
  Eye,
  EyeOff,
  Calendar,
  User,
  Home,
  CreditCard,
  MessageSquare,
  AlertCircle,
  Info,
  CheckCircle2,
  Settings,
  Filter,
  MoreHorizontal
} from 'lucide-react';
import { communicationService } from '../../services/communicationService';
import NotificationList from '../../components/communication/NotificationList';
import toast from 'react-hot-toast';

// ============ COMPOSANTS RÉUTILISABLES ============

// Composant Stats Card pour notifications
const NotificationStatsCard = ({ 
  icon: Icon, 
  title, 
  value, 
  subtitle, 
  color = 'primary' 
}) => {
  const colorClasses = {
    primary: 'bg-gradient-to-br from-blue-50 to-indigo-50 text-blue-600',
    success: 'bg-gradient-to-br from-green-50 to-emerald-50 text-green-600',
    warning: 'bg-gradient-to-br from-yellow-50 to-amber-50 text-yellow-600',
    danger: 'bg-gradient-to-br from-red-50 to-rose-50 text-red-600'
  };

  return (
    <div className="bg-white rounded-2xl p-6 border border-primary-200 hover:border-primary-300 transition-all duration-200 shadow-sm hover:shadow-md">
      <div className="flex items-center justify-between mb-4">
        <div className={`p-3 rounded-xl ${colorClasses[color]}`}>
          <Icon className="w-6 h-6" />
        </div>
      </div>
      
      <div className="mb-2">
        <h3 className="text-sm font-medium text-gray-600 mb-1 uppercase tracking-wide">
          {title}
        </h3>
        <p className="text-3xl font-bold text-gray-900">{value}</p>
      </div>
      
      <div className="text-gray-500 text-sm">{subtitle}</div>
    </div>
  );
};

// Composant Notification Card
const NotificationCard = ({ notification, onMarkAsRead, onDelete }) => {
  const getNotificationIcon = (type) => {
    const icons = {
      booking: Calendar,
      payment: CreditCard,
      message: MessageSquare,
      system: Settings,
      user: User,
      property: Home,
      alert: AlertCircle,
      info: Info,
      success: CheckCircle2
    };
    return icons[type] || Bell;
  };

  const getNotificationColor = (type) => {
    const colors = {
      booking: 'text-blue-600 bg-blue-100',
      payment: 'text-green-600 bg-green-100',
      message: 'text-purple-600 bg-purple-100',
      system: 'text-gray-600 bg-gray-100',
      user: 'text-indigo-600 bg-indigo-100',
      property: 'text-orange-600 bg-orange-100',
      alert: 'text-red-600 bg-red-100',
      info: 'text-blue-600 bg-blue-100',
      success: 'text-green-600 bg-green-100'
    };
    return colors[type] || 'text-gray-600 bg-gray-100';
  };

  const getPriorityStyle = (priority) => {
    const styles = {
      high: 'border-l-red-500 bg-red-25',
      medium: 'border-l-yellow-500 bg-yellow-25',
      low: 'border-l-green-500 bg-green-25'
    };
    return styles[priority] || 'border-l-gray-300';
  };

  const formatTime = (date) => {
    const now = new Date();
    const notifDate = new Date(date);
    const diffInHours = Math.floor((now - notifDate) / (1000 * 60 * 60));
    
    if (diffInHours < 1) {
      const diffInMinutes = Math.floor((now - notifDate) / (1000 * 60));
      return `${diffInMinutes}min`;
    } else if (diffInHours < 24) {
      return `${diffInHours}h`;
    } else {
      const diffInDays = Math.floor(diffInHours / 24);
      return `${diffInDays}j`;
    }
  };

  const Icon = getNotificationIcon(notification.type);

  return (
    <div className={`bg-white border-l-4 rounded-lg transition-all duration-200 hover:shadow-md group ${
      !notification.read 
        ? `${getPriorityStyle(notification.priority)} shadow-sm` 
        : 'border-l-gray-200 opacity-75'
    }`}>
      <div className="p-4">
        <div className="flex items-start justify-between">
          <div className="flex items-start space-x-3 flex-1">
            {/* Icon */}
            <div className={`p-2 rounded-lg ${getNotificationColor(notification.type)}`}>
              <Icon className="w-5 h-5" />
            </div>
            
            {/* Contenu */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center space-x-2 mb-1">
                <h4 className={`font-medium ${!notification.read ? 'text-gray-900' : 'text-gray-600'}`}>
                  {notification.title || 'Notification'}
                </h4>
                {!notification.read && (
                  <div className="w-2 h-2 bg-primary-500 rounded-full"></div>
                )}
                {notification.priority === 'high' && (
                  <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
                    Urgent
                  </span>
                )}
              </div>
              
              <p className={`text-sm leading-relaxed ${
                !notification.read ? 'text-gray-700' : 'text-gray-500'
              }`}>
                {notification.message || notification.content}
              </p>
              
              {/* Metadata */}
              <div className="flex items-center space-x-4 mt-3 text-xs text-gray-500">
                <span className="flex items-center space-x-1">
                  <Calendar className="w-3 h-3" />
                  <span>{formatTime(notification.createdAt)}</span>
                </span>
                
                {notification.category && (
                  <span className="px-2 py-1 bg-gray-100 text-gray-600 rounded-full">
                    {notification.category}
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className="flex items-center space-x-1 opacity-0 group-hover:opacity-100 transition-opacity">
            {!notification.read && (
              <button
                onClick={() => onMarkAsRead(notification._id)}
                className="p-1.5 text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                title="Marquer comme lu"
              >
                <CheckCircle className="w-4 h-4" />
              </button>
            )}
            
            <button
              onClick={() => onDelete(notification._id)}
              className="p-1.5 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
              title="Supprimer"
            >
              <Trash2 className="w-4 h-4" />
            </button>
            
            <button className="p-1.5 text-gray-400 hover:bg-gray-50 rounded-lg transition-colors">
              <MoreHorizontal className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Actions supplémentaires pour notifications non lues */}
        {!notification.read && notification.actionUrl && (
          <div className="mt-4 pt-3 border-t border-gray-100">
            <button className="text-sm text-primary-600 hover:text-primary-700 font-medium">
              Voir les détails →
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

// Composant Tab
const TabButton = ({ isActive, onClick, children, count }) => (
  <button
    onClick={onClick}
    className={`flex items-center space-x-2 px-4 py-2 rounded-lg font-medium transition-colors ${
      isActive
        ? 'bg-primary-500 text-white shadow-md'
        : 'text-gray-600 hover:bg-primary-50 hover:text-primary-700'
    }`}
  >
    <span>{children}</span>
    {count !== undefined && (
      <span className={`text-xs font-bold px-2 py-1 rounded-full ${
        isActive 
          ? 'bg-white bg-opacity-20 text-white' 
          : 'bg-primary-100 text-primary-700'
      }`}>
        {count}
      </span>
    )}
  </button>
);

// Composant Actions Toolbar
const ActionsToolbar = ({ 
  onMarkAllAsRead, 
  onDeleteRead, 
  unreadCount, 
  readCount, 
  onToggleSettings 
}) => (
  <div className="bg-white rounded-2xl p-6 border border-primary-200 shadow-sm mb-8">
    <div className="flex items-center justify-between">
      <div className="flex items-center space-x-4">
        <button
          onClick={onMarkAllAsRead}
          disabled={unreadCount === 0}
          className="flex items-center space-x-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors font-medium"
        >
          <CheckCircle className="w-4 h-4" />
          <span>Tout marquer comme lu</span>
        </button>
        
        <button
          onClick={onDeleteRead}
          disabled={readCount === 0}
          className="flex items-center space-x-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors font-medium"
        >
          <Trash2 className="w-4 h-4" />
          <span>Supprimer les lues</span>
        </button>
      </div>
      
      <div className="flex items-center space-x-2">
        <button className="flex items-center space-x-1 px-3 py-2 text-gray-600 hover:text-gray-800 rounded-lg hover:bg-gray-100 transition-colors">
          <Filter className="w-4 h-4" />
          <span>Filtrer</span>
        </button>
        
        <button
          onClick={onToggleSettings}
          className="flex items-center space-x-1 px-3 py-2 text-gray-600 hover:text-gray-800 rounded-lg hover:bg-gray-100 transition-colors"
        >
          <Settings className="w-4 h-4" />
          <span>Paramètres</span>
        </button>
      </div>
    </div>
  </div>
);

// ============ COMPOSANT PRINCIPAL ============

const NotificationsPage = () => {
  const [loading, setLoading] = useState(false);
  const [notifications, setNotifications] = useState([]);
  const [currentTab, setCurrentTab] = useState('all');
  const [stats, setStats] = useState({
    unread: 0,
    total: 0,
    high: 0,
    today: 0
  });

  useEffect(() => {
    loadNotifications();
  }, [currentTab]);

  const loadNotifications = async () => {
    try {
      setLoading(true);
      const response = await communicationService.getNotifications();
      
      if (response.success) {
        const allNotifications = response.data;
        
        // Filtrer selon l'onglet actif
        const filteredNotifications = currentTab === 'unread' 
          ? allNotifications.filter(n => !n.read)
          : allNotifications;

        setNotifications(filteredNotifications);
        
        // Calculer les statistiques
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        setStats({
          unread: allNotifications.filter(n => !n.read).length,
          total: allNotifications.length,
          high: allNotifications.filter(n => n.priority === 'high').length,
          today: allNotifications.filter(n => {
            const notifDate = new Date(n.createdAt);
            notifDate.setHours(0, 0, 0, 0);
            return notifDate.getTime() === today.getTime();
          }).length
        });

        toast.success('Notifications chargées avec succès');
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des notifications:', error);
      toast.error('Erreur lors du chargement des notifications');
    } finally {
      setLoading(false);
    }
  };

  const handleMarkAsRead = async (notificationId) => {
    try {
      const response = await communicationService.markNotificationAsRead(notificationId);
      if (response.success) {
        setNotifications(notifications.map(notif =>
          notif._id === notificationId ? { ...notif, read: true } : notif
        ));
        setStats(prev => ({ ...prev, unread: prev.unread - 1 }));
        toast.success('Notification marquée comme lue');
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors du marquage de la notification:', error);
      toast.error('Erreur lors du marquage de la notification');
    }
  };

  const handleMarkAllAsRead = async () => {
    try {
      const response = await communicationService.markAllNotificationsAsRead();
      if (response.success) {
        setNotifications(notifications.map(notif => ({ ...notif, read: true })));
        setStats(prev => ({ ...prev, unread: 0 }));
        toast.success('Toutes les notifications ont été marquées comme lues');
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors du marquage des notifications:', error);
      toast.error('Erreur lors du marquage des notifications');
    }
  };

  const handleDelete = async (notificationId) => {
    try {
      const response = await communicationService.deleteNotification(notificationId);
      if (response.success) {
        const updatedNotifications = notifications.filter(
          notif => notif._id !== notificationId
        );
        setNotifications(updatedNotifications);
        setStats(prev => ({
          unread: updatedNotifications.filter(n => !n.read).length,
          total: updatedNotifications.length,
          high: updatedNotifications.filter(n => n.priority === 'high').length,
          today: prev.today // Recalculer si nécessaire
        }));
        toast.success('Notification supprimée');
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors de la suppression de la notification:', error);
      toast.error('Erreur lors de la suppression de la notification');
    }
  };

  const handleDeleteRead = async () => {
    try {
      const response = await communicationService.deleteReadNotifications();
      if (response.success) {
        const unreadNotifications = notifications.filter(n => !n.read);
        setNotifications(unreadNotifications);
        setStats(prev => ({
          unread: unreadNotifications.length,
          total: unreadNotifications.length,
          high: unreadNotifications.filter(n => n.priority === 'high').length,
          today: unreadNotifications.filter(n => {
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            const notifDate = new Date(n.createdAt);
            notifDate.setHours(0, 0, 0, 0);
            return notifDate.getTime() === today.getTime();
          }).length
        }));
        toast.success('Notifications lues supprimées');
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors de la suppression des notifications:', error);
      toast.error('Erreur lors de la suppression des notifications');
    }
  };

  const getNotificationStats = () => [
    {
      icon: Bell,
      title: 'Total Notifications',
      value: stats.total.toString(),
      subtitle: 'Toutes les notifications',
      color: 'primary'
    },
    {
      icon: BellRing,
      title: 'Non Lues',
      value: stats.unread.toString(),
      subtitle: 'À traiter',
      color: 'warning'
    },
    {
      icon: AlertCircle,
      title: 'Priorité Élevée',
      value: stats.high.toString(),
      subtitle: 'Urgent',
      color: 'danger'
    },
    {
      icon: Calendar,
      title: 'Aujourd\'hui',
      value: stats.today.toString(),
      subtitle: 'Reçues aujourd\'hui',
      color: 'success'
    }
  ];

  if (loading && notifications.length === 0) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="flex flex-col items-center space-y-4">
          <div className="relative">
            <div className="w-16 h-16 border-4 border-primary-200 rounded-full animate-spin"></div>
            <div className="absolute top-0 left-0 w-16 h-16 border-4 border-primary-600 border-t-transparent rounded-full animate-spin"></div>
          </div>
          <p className="text-gray-600 font-medium text-lg">Chargement des notifications...</p>
        </div>
      </div>
    );
  }

  const notificationStats = getNotificationStats();
  const readCount = notifications.filter(n => n.read).length;

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="container mx-auto px-6 py-8 max-w-[1200px]">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center space-x-4">
            <div className="w-16 h-16 bg-primary-500 rounded-2xl flex items-center justify-center shadow-lg relative">
              <Bell className="w-8 h-8 text-white" />
              {stats.unread > 0 && (
                <div className="absolute -top-2 -right-2 w-6 h-6 bg-red-500 text-white text-xs font-bold rounded-full flex items-center justify-center">
                  {stats.unread > 99 ? '99+' : stats.unread}
                </div>
              )}
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Notifications</h1>
              <p className="text-lg text-gray-600">
                Gérez vos notifications et restez informé
                {stats.unread > 0 && (
                  <span className="text-primary-600 font-medium ml-2">
                    • {stats.unread} non lue{stats.unread > 1 ? 's' : ''}
                  </span>
                )}
              </p>
            </div>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {notificationStats.map((stat, index) => (
            <NotificationStatsCard key={index} {...stat} />
          ))}
        </div>

        {/* Actions Toolbar */}
        <ActionsToolbar
          onMarkAllAsRead={handleMarkAllAsRead}
          onDeleteRead={handleDeleteRead}
          unreadCount={stats.unread}
          readCount={readCount}
          onToggleSettings={() => toast('Paramètres des notifications')}
        />

        {/* Onglets */}
        <div className="flex items-center space-x-2 mb-8">
          <TabButton
            isActive={currentTab === 'all'}
            onClick={() => setCurrentTab('all')}
            count={stats.total}
          >
            Toutes
          </TabButton>
          <TabButton
            isActive={currentTab === 'unread'}
            onClick={() => setCurrentTab('unread')}
            count={stats.unread}
          >
            Non lues
          </TabButton>
        </div>

        {/* Liste des notifications */}
        <div className="space-y-4">
          {loading ? (
            <div className="flex justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
            </div>
          ) : notifications.length === 0 ? (
            <div className="text-center py-12">
              <div className="w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Bell className="w-12 h-12 text-gray-400" />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">
                Aucune notification
              </h3>
              <p className="text-gray-600">
                {currentTab === 'unread' 
                  ? 'Toutes vos notifications ont été lues.'
                  : 'Vous n\'avez aucune notification pour le moment.'
                }
              </p>
            </div>
          ) : (
            notifications.map((notification) => (
              <NotificationCard
                key={notification._id}
                notification={notification}
                onMarkAsRead={handleMarkAsRead}
                onDelete={handleDelete}
              />
            ))
          )}
        </div>

        {/* Pagination si nécessaire */}
        {notifications.length > 0 && (
          <div className="flex justify-center mt-8">
            <button className="px-6 py-2 text-primary-600 hover:text-primary-700 font-medium">
              Charger plus de notifications
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default NotificationsPage;