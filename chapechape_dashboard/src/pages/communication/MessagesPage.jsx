import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Button,
  Card,
  CardContent,
  Grid,
  Drawer,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Divider,
  IconButton,
  InputAdornment,
  TextField,
  CircularProgress,
  Badge,
  Chip,
} from '@mui/material';
import {
  Email as EmailIcon,
  Inbox as InboxIcon,
  Send as SendIcon,
  Star as StarIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  Add as AddIcon,
  Refresh as RefreshIcon,
  FilterList as FilterIcon,
} from '@mui/icons-material';
import { communicationService } from '../../services/communicationService';
import MessageList from '../../components/communication/MessageList';
import ComposeMessage from '../../components/communication/ComposeMessage';
import toast from 'react-hot-toast';

const drawerWidth = 280;

const MessagesPage = () => {
  const [loading, setLoading] = useState(false);
  const [messages, setMessages] = useState([]);
  const [selectedFolder, setSelectedFolder] = useState('inbox');
  const [searchTerm, setSearchTerm] = useState('');
  const [composeOpen, setComposeOpen] = useState(false);
  const [replyTo, setReplyTo] = useState(null);
  const [stats, setStats] = useState({
    inbox: 0,
    unread: 0,
    starred: 0,
    sent: 0,
    trash: 0,
  });

  useEffect(() => {
    loadMessages();
  }, [selectedFolder]);

  const loadMessages = async () => {
    try {
      setLoading(true);
      const response = await communicationService.getMessages();
      
      if (response.success) {
        let filteredMessages = response.data;

        // Filtrer selon le dossier sélectionné
        switch (selectedFolder) {
          case 'inbox':
            filteredMessages = filteredMessages.filter(m => !m.sent && !m.deleted);
            break;
          case 'sent':
            filteredMessages = filteredMessages.filter(m => m.sent);
            break;
          case 'starred':
            filteredMessages = filteredMessages.filter(m => m.starred);
            break;
          case 'trash':
            filteredMessages = filteredMessages.filter(m => m.deleted);
            break;
          default:
            break;
        }

        // Appliquer la recherche
        if (searchTerm) {
          const term = searchTerm.toLowerCase();
          filteredMessages = filteredMessages.filter(m =>
            m.subject?.toLowerCase().includes(term) ||
            m.content?.toLowerCase().includes(term) ||
            m.sender.name.toLowerCase().includes(term)
          );
        }

        setMessages(filteredMessages);
        
        // Mettre à jour les statistiques
        setStats({
          inbox: response.data.filter(m => !m.sent && !m.deleted).length,
          unread: response.data.filter(m => !m.read && !m.deleted).length,
          starred: response.data.filter(m => m.starred).length,
          sent: response.data.filter(m => m.sent).length,
          trash: response.data.filter(m => m.deleted).length,
        });
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des messages:', error);
      toast.error('Erreur lors du chargement des messages');
    } finally {
      setLoading(false);
    }
  };

  const handleCompose = () => {
    setReplyTo(null);
    setComposeOpen(true);
  };

  const handleReply = (message) => {
    setReplyTo(message);
    setComposeOpen(true);
  };

  const handleSend = async (messageData) => {
    try {
      const response = await communicationService.sendMessage(messageData);
      if (response.success) {
        toast.success('Message envoyé avec succès');
        loadMessages();
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors de l\'envoi du message:', error);
      toast.error('Erreur lors de l\'envoi du message');
    }
  };

  const handleStar = async (messageId) => {
    try {
      const message = messages.find(m => m._id === messageId);
      const response = await communicationService.toggleMessageStar(messageId);
      if (response.success) {
        setMessages(messages.map(m =>
          m._id === messageId ? { ...m, starred: !m.starred } : m
        ));
        toast.success(message.starred ? 'Retiré des favoris' : 'Ajouté aux favoris');
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors de la modification du message:', error);
      toast.error('Erreur lors de la modification du message');
    }
  };

  const handleDelete = async (messageId) => {
    try {
      const response = await communicationService.deleteMessage(messageId);
      if (response.success) {
        setMessages(messages.filter(m => m._id !== messageId));
        toast.success('Message supprimé');
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors de la suppression du message:', error);
      toast.error('Erreur lors de la suppression du message');
    }
  };

  const folders = [
    { id: 'inbox', label: 'Boîte de réception', icon: InboxIcon, count: stats.inbox },
    { id: 'sent', label: 'Messages envoyés', icon: SendIcon, count: stats.sent },
    { id: 'starred', label: 'Favoris', icon: StarIcon, count: stats.starred },
    { id: 'trash', label: 'Corbeille', icon: DeleteIcon, count: stats.trash },
  ];

  return (
    <Box sx={{ display: 'flex', minHeight: '100%' }}>
      {/* Barre latérale */}
      <Drawer
        variant="permanent"
        sx={{
          width: drawerWidth,
          flexShrink: 0,
          '& .MuiDrawer-paper': {
            width: drawerWidth,
            boxSizing: 'border-box',
            position: 'relative',
            height: '100%',
          },
        }}
      >
        <Box sx={{ p: 2 }}>
          <Button
            fullWidth
            variant="contained"
            startIcon={<AddIcon />}
            onClick={handleCompose}
            sx={{ mb: 2 }}
          >
            Nouveau message
          </Button>
        </Box>
        <Divider />
        <List>
          {folders.map((folder) => {
            const Icon = folder.icon;
            return (
              <ListItem
                key={folder.id}
                button
                selected={selectedFolder === folder.id}
                onClick={() => setSelectedFolder(folder.id)}
              >
                <ListItemIcon>
                  <Badge badgeContent={folder.count} color="primary">
                    <Icon color={selectedFolder === folder.id ? 'primary' : 'inherit'} />
                  </Badge>
                </ListItemIcon>
                <ListItemText primary={folder.label} />
              </ListItem>
            );
          })}
        </List>
      </Drawer>

      {/* Contenu principal */}
      <Box sx={{ flexGrow: 1, p: 3, width: { sm: `calc(100% - ${drawerWidth}px)` } }}>
        {/* En-tête */}
        <Box sx={{ mb: 4 }}>
          <Typography variant="h4" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <EmailIcon fontSize="large" />
            Messages
            {stats.unread > 0 && (
              <Chip
                label={`${stats.unread} non lu${stats.unread > 1 ? 's' : ''}`}
                color="error"
                size="small"
              />
            )}
          </Typography>
        </Box>

        {/* Barre d'outils */}
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Grid container spacing={2} alignItems="center">
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  placeholder="Rechercher dans les messages..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  InputProps={{
                    startAdornment: (
                      <InputAdornment position="start">
                        <SearchIcon />
                      </InputAdornment>
                    ),
                  }}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <Box sx={{ display: 'flex', gap: 1, justifyContent: 'flex-end' }}>
                  <Button
                    startIcon={<RefreshIcon />}
                    onClick={loadMessages}
                    disabled={loading}
                  >
                    Actualiser
                  </Button>
                  <Button
                    startIcon={<FilterIcon />}
                    variant="outlined"
                  >
                    Filtrer
                  </Button>
                </Box>
              </Grid>
            </Grid>
          </CardContent>
        </Card>

        {/* Liste des messages */}
        <Card>
          <CardContent>
            {loading ? (
              <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
                <CircularProgress />
              </Box>
            ) : messages.length === 0 ? (
              <Box sx={{ textAlign: 'center', py: 3 }}>
                <Typography variant="body1" color="text.secondary">
                  Aucun message dans ce dossier
                </Typography>
              </Box>
            ) : (
              <MessageList
                messages={messages}
                onStar={handleStar}
                onReply={handleReply}
                onDelete={handleDelete}
              />
            )}
          </CardContent>
        </Card>
      </Box>

      {/* Dialog de composition */}
      <ComposeMessage
        open={composeOpen}
        onClose={() => setComposeOpen(false)}
        onSend={handleSend}
        replyTo={replyTo}
      />
    </Box>
  );
};

export default MessagesPage;
