import React from 'react';
import {
  List,
  ListItem,
  ListItemText,
  Typography,
  Box,
  Chip,
  IconButton,
  Tooltip,
  Collapse,
  Paper,
  Button,
  TextField,
  Stack,
} from '@mui/material';
import {
  ExpandMore as ExpandMoreIcon,
  ExpandLess as ExpandLessIcon,
  Send as SendIcon,
  AttachFile as AttachFileIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';

const TicketList = ({ tickets, onReply, onClose }) => {
  const [expandedId, setExpandedId] = React.useState(null);
  const [replyText, setReplyText] = React.useState('');

  const handleExpand = (ticketId) => {
    setExpandedId(expandedId === ticketId ? null : ticketId);
    setReplyText('');
  };

  const handleReply = (ticketId) => {
    onReply(ticketId, replyText);
    setReplyText('');
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'open':
        return 'error';
      case 'in_progress':
        return 'warning';
      case 'resolved':
        return 'success';
      case 'closed':
        return 'default';
      default:
        return 'default';
    }
  };

  const getStatusLabel = (status) => {
    switch (status) {
      case 'open':
        return 'Ouvert';
      case 'in_progress':
        return 'En cours';
      case 'resolved':
        return 'Résolu';
      case 'closed':
        return 'Fermé';
      default:
        return status;
    }
  };

  const getPriorityColor = (priority) => {
    switch (priority) {
      case 'urgent':
        return 'error';
      case 'high':
        return 'warning';
      case 'normal':
        return 'info';
      case 'low':
        return 'success';
      default:
        return 'default';
    }
  };

  const getPriorityLabel = (priority) => {
    switch (priority) {
      case 'urgent':
        return 'Urgente';
      case 'high':
        return 'Haute';
      case 'normal':
        return 'Normale';
      case 'low':
        return 'Basse';
      default:
        return priority;
    }
  };

  const formatDate = (date) => {
    return format(new Date(date), 'dd MMMM yyyy HH:mm', { locale: fr });
  };

  return (
    <List>
      {tickets.map((ticket) => (
        <Paper
          key={ticket._id}
          elevation={1}
          sx={{ mb: 2, overflow: 'hidden' }}
        >
          <ListItem
            button
            onClick={() => handleExpand(ticket._id)}
            sx={{
              borderLeft: 6,
              borderColor: (theme) => theme.palette[getStatusColor(ticket.status)].main,
            }}
          >
            <ListItemText
              primary={
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                  <Typography variant="subtitle1" component="span">
                    {ticket.subject}
                  </Typography>
                  <Chip
                    size="small"
                    label={getStatusLabel(ticket.status)}
                    color={getStatusColor(ticket.status)}
                  />
                  <Chip
                    size="small"
                    label={getPriorityLabel(ticket.priority)}
                    color={getPriorityColor(ticket.priority)}
                  />
                  {ticket.category && (
                    <Chip
                      size="small"
                      label={ticket.category}
                      variant="outlined"
                    />
                  )}
                </Box>
              }
              secondary={
                <Box sx={{ mt: 1 }}>
                  <Typography variant="body2" color="text.secondary">
                    Créé le {formatDate(ticket.createdAt)}
                  </Typography>
                  {ticket.lastUpdate && (
                    <Typography variant="body2" color="text.secondary">
                      Dernière mise à jour le {formatDate(ticket.lastUpdate)}
                    </Typography>
                  )}
                </Box>
              }
            />
            {expandedId === ticket._id ? <ExpandLessIcon /> : <ExpandMoreIcon />}
          </ListItem>

          <Collapse in={expandedId === ticket._id} timeout="auto" unmountOnExit>
            <Box sx={{ p: 3, bgcolor: 'action.hover' }}>
              <Typography variant="body1" paragraph>
                {ticket.description}
              </Typography>

              {/* Messages du ticket */}
              {ticket.messages?.length > 0 && (
                <Stack spacing={2} sx={{ mt: 3 }}>
                  <Typography variant="subtitle2">
                    Historique des messages
                  </Typography>
                  {ticket.messages.map((message, index) => (
                    <Paper
                      key={index}
                      sx={{
                        p: 2,
                        bgcolor: message.isStaff ? 'primary.lighter' : 'background.paper',
                      }}
                    >
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                        <Typography variant="subtitle2">
                          {message.author}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {formatDate(message.createdAt)}
                        </Typography>
                      </Box>
                      <Typography variant="body2">
                        {message.content}
                      </Typography>
                      {message.attachments?.length > 0 && (
                        <Box sx={{ mt: 1, display: 'flex', gap: 1 }}>
                          {message.attachments.map((attachment, i) => (
                            <Chip
                              key={i}
                              size="small"
                              icon={<AttachFileIcon />}
                              label={attachment.name}
                              onClick={() => window.open(attachment.url)}
                              variant="outlined"
                            />
                          ))}
                        </Box>
                      )}
                    </Paper>
                  ))}
                </Stack>
              )}

              {/* Formulaire de réponse */}
              {ticket.status !== 'closed' && (
                <Box sx={{ mt: 3 }}>
                  <TextField
                    fullWidth
                    multiline
                    rows={3}
                    placeholder="Votre réponse..."
                    value={replyText}
                    onChange={(e) => setReplyText(e.target.value)}
                    sx={{ mb: 2 }}
                  />
                  <Box sx={{ display: 'flex', gap: 2 }}>
                    <Button
                      variant="contained"
                      startIcon={<SendIcon />}
                      onClick={() => handleReply(ticket._id)}
                      disabled={!replyText.trim()}
                    >
                      Répondre
                    </Button>
                    {ticket.status === 'resolved' && (
                      <Button
                        variant="outlined"
                        onClick={() => onClose(ticket._id)}
                      >
                        Fermer le ticket
                      </Button>
                    )}
                  </Box>
                </Box>
              )}
            </Box>
          </Collapse>
        </Paper>
      ))}
    </List>
  );
};

export default TicketList;
