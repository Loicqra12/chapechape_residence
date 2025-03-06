import React, { createContext, useContext, useState, useEffect } from 'react';
import io from 'socket.io-client';

const NotificationContext = createContext();
const SOCKET_URL = process.env.REACT_APP_SOCKET_URL || 'http://localhost:4000';

export const NotificationProvider = ({ children }) => {
  const [notifications, setNotifications] = useState([]);
  const [socket, setSocket] = useState(null);

  useEffect(() => {
    const newSocket = io(SOCKET_URL);
    setSocket(newSocket);

    return () => newSocket.close();
  }, []);

  useEffect(() => {
    if (socket) {
      socket.on('notification', (notification) => {
        setNotifications((prev) => [notification, ...prev]);
      });

      socket.on('residenceUpdated', (data) => {
        setNotifications((prev) => [{
          id: Date.now(),
          type: 'residence',
          message: `La résidence ${data.name} a été mise à jour`,
          timestamp: new Date(),
          read: false
        }, ...prev]);
      });

      socket.on('newBooking', (data) => {
        setNotifications((prev) => [{
          id: Date.now(),
          type: 'booking',
          message: `Nouvelle réservation pour ${data.residenceName}`,
          timestamp: new Date(),
          read: false
        }, ...prev]);
      });
    }
  }, [socket]);

  const markAsRead = (notificationId) => {
    setNotifications(notifications.map(notif => 
      notif.id === notificationId ? { ...notif, read: true } : notif
    ));
  };

  const clearNotifications = () => {
    setNotifications([]);
  };

  return (
    <NotificationContext.Provider value={{ 
      notifications, 
      markAsRead, 
      clearNotifications,
      unreadCount: notifications.filter(n => !n.read).length 
    }}>
      {children}
    </NotificationContext.Provider>
  );
};

export const useNotifications = () => useContext(NotificationContext);
