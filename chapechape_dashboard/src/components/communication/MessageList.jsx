import React from 'react';
import {
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  Avatar,
  Typography,
  Box,
  Chip,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  Star as StarIcon,
  StarBorder as StarBorderIcon,
  Delete as DeleteIcon,
  Reply as ReplyIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';

const MessageList = ({ messages, onStar, onReply, onDelete, selectedId }) => {
  const formatDate = (date) => {
    const messageDate = new Date(date);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (messageDate.toDateString() === today.toDateString()) {
      return format(messageDate, 'HH:mm', { locale: fr });
    } else if (messageDate.toDateString() === yesterday.toDateString()) {
      return 'Hier ' + format(messageDate, 'HH:mm', { locale: fr });
    } else {
      return format(messageDate, 'dd MMM yyyy', { locale: fr });
    }
  };

  const getInitials = (name) => {
    return name
      .split(' ')
      .map(word => word[0])
      .join('')
      .toUpperCase();
  };

  return (
    <List sx={{ width: '100%', bgcolor: 'background.paper' }}>
      {messages.map((message) => (
        <ListItem
          key={message._id}
          alignItems="flex-start"
          sx={{
            mb: 1,
            bgcolor: message._id === selectedId ? 'action.selected' : 'background.paper',
            borderRadius: 1,
            '&:hover': {
              bgcolor: 'action.hover',
            },
          }}
        >
          <ListItemAvatar>
            {message.sender.avatar ? (
              <Avatar src={message.sender.avatar} alt={message.sender.name} />
            ) : (
              <Avatar>{getInitials(message.sender.name)}</Avatar>
            )}
          </ListItemAvatar>
          <ListItemText
            primary={
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="subtitle1" component="span">
                  {message.sender.name}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {formatDate(message.createdAt)}
                </Typography>
              </Box>
            }
            secondary={
              <Box sx={{ mt: 1 }}>
                <Typography
                  variant="body2"
                  color="text.primary"
                  sx={{
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    display: '-webkit-box',
                    WebkitLineClamp: 2,
                    WebkitBoxOrient: 'vertical',
                  }}
                >
                  {message.subject && (
                    <Typography
                      component="span"
                      variant="body2"
                      color="text.secondary"
                      sx={{ mr: 1 }}
                    >
                      {message.subject}:
                    </Typography>
                  )}
                  {message.content}
                </Typography>
                <Box sx={{ mt: 1, display: 'flex', alignItems: 'center', gap: 1 }}>
                  {message.labels?.map((label) => (
                    <Chip
                      key={label}
                      label={label}
                      size="small"
                      color="primary"
                      variant="outlined"
                    />
                  ))}
                  {message.unread && (
                    <Chip
                      size="small"
                      label="Non lu"
                      color="error"
                      variant="outlined"
                    />
                  )}
                </Box>
              </Box>
            }
          />
          <Box sx={{ display: 'flex', alignItems: 'center', ml: 2 }}>
            <Tooltip title={message.starred ? "Retirer des favoris" : "Ajouter aux favoris"}>
              <IconButton onClick={() => onStar(message._id)} size="small">
                {message.starred ? (
                  <StarIcon color="warning" />
                ) : (
                  <StarBorderIcon />
                )}
              </IconButton>
            </Tooltip>
            <Tooltip title="Répondre">
              <IconButton onClick={() => onReply(message)} size="small">
                <ReplyIcon />
              </IconButton>
            </Tooltip>
            <Tooltip title="Supprimer">
              <IconButton onClick={() => onDelete(message._id)} size="small">
                <DeleteIcon />
              </IconButton>
            </Tooltip>
          </Box>
        </ListItem>
      ))}
    </List>
  );
};

export default MessageList;
