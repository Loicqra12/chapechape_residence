import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  Tabs,
  Tab,
  CircularProgress,
  Alert,
  Stack,
  Drawer,
} from '@mui/material';
import {
  Support as SupportIcon,
  Add as AddIcon,
  QuestionAnswer as QuestionAnswerIcon,
  Article as ArticleIcon,
} from '@mui/icons-material';
import { communicationService } from '../../services/communicationService';
import TicketForm from '../../components/communication/TicketForm';
import TicketList from '../../components/communication/TicketList';
import toast from 'react-hot-toast';

const drawerWidth = 400;

const SupportPage = () => {
  const [loading, setLoading] = useState(false);
  const [tickets, setTickets] = useState([]);
  const [currentTab, setCurrentTab] = useState('all');
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [stats, setStats] = useState({
    total: 0,
    open: 0,
    inProgress: 0,
    resolved: 0,
    closed: 0,
  });

  useEffect(() => {
    loadTickets();
  }, [currentTab]);

  const loadTickets = async () => {
    try {
      setLoading(true);
      const response = await communicationService.getSupportTickets();
      
      if (response.success) {
        let filteredTickets = response.data;

        // Filtrer selon l'onglet actif
        switch (currentTab) {
          case 'open':
            filteredTickets = filteredTickets.filter(t => t.status === 'open');
            break;
          case 'in_progress':
            filteredTickets = filteredTickets.filter(t => t.status === 'in_progress');
            break;
          case 'resolved':
            filteredTickets = filteredTickets.filter(t => t.status === 'resolved');
            break;
          case 'closed':
            filteredTickets = filteredTickets.filter(t => t.status === 'closed');
            break;
          default:
            break;
        }

        setTickets(filteredTickets);
        
        // Mettre à jour les statistiques
        const allTickets = response.data;
        setStats({
          total: allTickets.length,
          open: allTickets.filter(t => t.status === 'open').length,
          inProgress: allTickets.filter(t => t.status === 'in_progress').length,
          resolved: allTickets.filter(t => t.status === 'resolved').length,
          closed: allTickets.filter(t => t.status === 'closed').length,
        });
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des tickets:', error);
      toast.error('Erreur lors du chargement des tickets');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateTicket = async (ticketData) => {
    try {
      const response = await communicationService.createSupportTicket(ticketData);
      if (response.success) {
        toast.success('Ticket créé avec succès');
        setDrawerOpen(false);
        loadTickets();
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors de la création du ticket:', error);
      toast.error('Erreur lors de la création du ticket');
    }
  };

  const handleReplyToTicket = async (ticketId, message) => {
    try {
      const response = await communicationService.replyToTicket(ticketId, message);
      if (response.success) {
        toast.success('Réponse envoyée avec succès');
        loadTickets();
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors de l\'envoi de la réponse:', error);
      toast.error('Erreur lors de l\'envoi de la réponse');
    }
  };

  const handleCloseTicket = async (ticketId) => {
    try {
      const response = await communicationService.closeTicket(ticketId);
      if (response.success) {
        toast.success('Ticket fermé avec succès');
        loadTickets();
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors de la fermeture du ticket:', error);
      toast.error('Erreur lors de la fermeture du ticket');
    }
  };

  const tabs = [
    { value: 'all', label: 'Tous', count: stats.total },
    { value: 'open', label: 'Ouverts', count: stats.open },
    { value: 'in_progress', label: 'En cours', count: stats.inProgress },
    { value: 'resolved', label: 'Résolus', count: stats.resolved },
    { value: 'closed', label: 'Fermés', count: stats.closed },
  ];

  return (
    <Box sx={{ display: 'flex' }}>
      <Container maxWidth="lg" sx={{ py: 4 }}>
        {/* En-tête */}
        <Box sx={{ mb: 4 }}>
          <Typography variant="h4" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <SupportIcon fontSize="large" />
            Support
          </Typography>
          <Typography variant="subtitle1" color="text.secondary">
            Centre d'assistance et suivi des tickets
          </Typography>
        </Box>

        {/* Statistiques */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Stack spacing={1}>
                  <Typography variant="overline" color="text.secondary">
                    Total des tickets
                  </Typography>
                  <Typography variant="h4">
                    {stats.total}
                  </Typography>
                </Stack>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Stack spacing={1}>
                  <Typography variant="overline" color="text.secondary">
                    En attente
                  </Typography>
                  <Typography variant="h4" color="error.main">
                    {stats.open}
                  </Typography>
                </Stack>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Stack spacing={1}>
                  <Typography variant="overline" color="text.secondary">
                    En cours
                  </Typography>
                  <Typography variant="h4" color="warning.main">
                    {stats.inProgress}
                  </Typography>
                </Stack>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Stack spacing={1}>
                  <Typography variant="overline" color="text.secondary">
                    Résolus
                  </Typography>
                  <Typography variant="h4" color="success.main">
                    {stats.resolved}
                  </Typography>
                </Stack>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Actions */}
        <Box sx={{ mb: 4 }}>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => setDrawerOpen(true)}
          >
            Nouveau ticket
          </Button>
        </Box>

        {/* Onglets et Liste des tickets */}
        <Card>
          <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
            <Tabs
              value={currentTab}
              onChange={(_, newValue) => setCurrentTab(newValue)}
              aria-label="ticket tabs"
            >
              {tabs.map((tab) => (
                <Tab
                  key={tab.value}
                  value={tab.value}
                  label={`${tab.label} (${tab.count})`}
                />
              ))}
            </Tabs>
          </Box>

          <CardContent>
            {loading ? (
              <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
                <CircularProgress />
              </Box>
            ) : tickets.length === 0 ? (
              <Alert
                severity="info"
                icon={<QuestionAnswerIcon />}
                sx={{ display: 'flex', alignItems: 'center' }}
              >
                Aucun ticket {currentTab !== 'all' ? 'dans cette catégorie' : ''}
                <Button
                  size="small"
                  startIcon={<AddIcon />}
                  onClick={() => setDrawerOpen(true)}
                  sx={{ ml: 2 }}
                >
                  Créer un ticket
                </Button>
              </Alert>
            ) : (
              <TicketList
                tickets={tickets}
                onReply={handleReplyToTicket}
                onClose={handleCloseTicket}
              />
            )}
          </CardContent>
        </Card>

        {/* FAQ et Ressources */}
        <Grid container spacing={3} sx={{ mt: 4 }}>
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Stack spacing={2}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <QuestionAnswerIcon color="primary" />
                    <Typography variant="h6">
                      FAQ
                    </Typography>
                  </Box>
                  <Typography variant="body2" color="text.secondary">
                    Consultez notre base de connaissances pour trouver rapidement des réponses à vos questions.
                  </Typography>
                  <Button variant="outlined" fullWidth>
                    Accéder à la FAQ
                  </Button>
                </Stack>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Stack spacing={2}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <ArticleIcon color="primary" />
                    <Typography variant="h6">
                      Documentation
                    </Typography>
                  </Box>
                  <Typography variant="body2" color="text.secondary">
                    Explorez notre documentation détaillée pour mieux comprendre nos services.
                  </Typography>
                  <Button variant="outlined" fullWidth>
                    Voir la documentation
                  </Button>
                </Stack>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Container>

      {/* Drawer pour créer un nouveau ticket */}
      <Drawer
        anchor="right"
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        sx={{
          width: drawerWidth,
          flexShrink: 0,
          '& .MuiDrawer-paper': {
            width: drawerWidth,
            boxSizing: 'border-box',
          },
        }}
      >
        <Box sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>
            Nouveau ticket de support
          </Typography>
          <TicketForm
            onSubmit={handleCreateTicket}
            loading={loading}
          />
        </Box>
      </Drawer>
    </Box>
  );
};

export default SupportPage;
