import React from 'react';
import {
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Typography,
  Box,
  Chip,
  Tooltip,
} from '@mui/material';
import {
  CheckCircle as CheckCircleIcon,
  Delete as DeleteIcon,
  Info as InfoIcon,
  Warning as WarningIcon,
  Error as ErrorIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';

const getNotificationIcon = (type) => {
  switch (type) {
    case 'info':
      return <InfoIcon color="info" />;
    case 'warning':
      return <WarningIcon color="warning" />;
    case 'error':
      return <ErrorIcon color="error" />;
    default:
      return <InfoIcon color="info" />;
  }
};

const NotificationList = ({ notifications, onMarkAsRead, onDelete }) => {
  const formatDate = (date) => {
    return format(new Date(date), 'dd MMMM yyyy HH:mm', { locale: fr });
  };

  return (
    <List>
      {notifications.map((notification) => (
        <ListItem
          key={notification._id}
          sx={{
            mb: 1,
            bgcolor: notification.read ? 'background.paper' : 'action.hover',
            borderRadius: 1,
            '&:hover': {
              bgcolor: 'action.selected',
            },
          }}
        >
          <Box sx={{ mr: 2 }}>
            {getNotificationIcon(notification.type)}
          </Box>
          <ListItemText
            primary={
              <Typography variant="subtitle1" component="div">
                {notification.title}
              </Typography>
            }
            secondary={
              <Box sx={{ mt: 0.5 }}>
                <Typography variant="body2" color="text.secondary">
                  {notification.message}
                </Typography>
                <Box sx={{ mt: 1, display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Chip
                    size="small"
                    label={formatDate(notification.createdAt)}
                    variant="outlined"
                  />
                  {notification.category && (
                    <Chip
                      size="small"
                      label={notification.category}
                      color="primary"
                      variant="outlined"
                    />
                  )}
                </Box>
              </Box>
            }
          />
          <ListItemSecondaryAction>
            {!notification.read && (
              <Tooltip title="Marquer comme lu">
                <IconButton
                  edge="end"
                  aria-label="mark as read"
                  onClick={() => onMarkAsRead(notification._id)}
                  sx={{ mr: 1 }}
                >
                  <CheckCircleIcon color="success" />
                </IconButton>
              </Tooltip>
            )}
            <Tooltip title="Supprimer">
              <IconButton
                edge="end"
                aria-label="delete"
                onClick={() => onDelete(notification._id)}
              >
                <DeleteIcon />
              </IconButton>
            </Tooltip>
          </ListItemSecondaryAction>
        </ListItem>
      ))}
    </List>
  );
};

export default NotificationList;
