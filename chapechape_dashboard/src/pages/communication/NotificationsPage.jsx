import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Button,
  Card,
  CardContent,
  Divider,
  Stack,
  CircularProgress,
  Alert,
  Tabs,
  Tab,
  Badge,
} from '@mui/material';
import {
  Notifications as NotificationsIcon,
  DeleteSweep as DeleteSweepIcon,
  CheckCircle as CheckCircleIcon,
} from '@mui/icons-material';
import { communicationService } from '../../services/communicationService';
import NotificationList from '../../components/communication/NotificationList';
import toast from 'react-hot-toast';

const NotificationsPage = () => {
  const [loading, setLoading] = useState(false);
  const [notifications, setNotifications] = useState([]);
  const [currentTab, setCurrentTab] = useState('all');
  const [stats, setStats] = useState({
    unread: 0,
    total: 0
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
        setStats({
          unread: allNotifications.filter(n => !n.read).length,
          total: allNotifications.length
        });
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
          total: updatedNotifications.length
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
        setStats({
          unread: unreadNotifications.length,
          total: unreadNotifications.length
        });
        toast.success('Notifications lues supprimées');
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors de la suppression des notifications:', error);
      toast.error('Erreur lors de la suppression des notifications');
    }
  };

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <NotificationsIcon fontSize="large" />
          Notifications
          {stats.unread > 0 && (
            <Badge badgeContent={stats.unread} color="error" sx={{ ml: 2 }} />
          )}
        </Typography>
        <Typography variant="subtitle1" color="text.secondary">
          Gérez vos notifications et restez informé
        </Typography>
      </Box>

      {/* Actions */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Stack direction="row" spacing={2} alignItems="center">
            <Button
              variant="contained"
              startIcon={<CheckCircleIcon />}
              onClick={handleMarkAllAsRead}
              disabled={stats.unread === 0}
            >
              Tout marquer comme lu
            </Button>
            <Button
              variant="outlined"
              color="error"
              startIcon={<DeleteSweepIcon />}
              onClick={handleDeleteRead}
              disabled={notifications.filter(n => n.read).length === 0}
            >
              Supprimer les notifications lues
            </Button>
          </Stack>
        </CardContent>
      </Card>

      {/* Onglets */}
      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs
          value={currentTab}
          onChange={(_, newValue) => setCurrentTab(newValue)}
          aria-label="notification tabs"
        >
          <Tab
            label={`Toutes (${stats.total})`}
            value="all"
          />
          <Tab
            label={`Non lues (${stats.unread})`}
            value="unread"
          />
        </Tabs>
      </Box>

      {/* Liste des notifications */}
      <Card>
        <CardContent>
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
              <CircularProgress />
            </Box>
          ) : notifications.length === 0 ? (
            <Alert severity="info">
              Aucune notification {currentTab === 'unread' ? 'non lue' : ''} à afficher
            </Alert>
          ) : (
            <NotificationList
              notifications={notifications}
              onMarkAsRead={handleMarkAsRead}
              onDelete={handleDelete}
            />
          )}
        </CardContent>
      </Card>
    </Container>
  );
};

export default NotificationsPage;
