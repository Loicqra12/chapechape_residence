import React, { useState, useEffect } from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  Avatar,
  LinearProgress,
  Tooltip,
} from '@mui/material';
import {
  Message as MessageIcon,
  MarkEmailUnread as UnreadIcon,
  QuestionAnswer as TicketIcon,
  CheckCircle as ResolvedIcon,
  AccessTime as TimeIcon,
  Email as ResponseIcon,
} from '@mui/icons-material';
import { analyticsService } from '../../services/analyticsService';
import AnalyticsChart from './AnalyticsChart';

const StatCard = ({ title, value, subtitle, icon: Icon, color }) => (
  <Card>
    <CardContent>
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
        <Avatar sx={{ bgcolor: color, mr: 2 }}>
          <Icon />
        </Avatar>
        <Box>
          <Typography variant="h6" component="div">
            {title}
          </Typography>
          {subtitle && (
            <Typography variant="body2" color="text.secondary">
              {subtitle}
            </Typography>
          )}
        </Box>
      </Box>
      <Typography variant="h4" component="div" sx={{ textAlign: 'right' }}>
        {value}
      </Typography>
    </CardContent>
  </Card>
);

const CommunicationStats = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const response = await analyticsService.getCommunicationStats();
        if (response.success) {
          setStats(response.data);
        } else {
          setError(response.error);
        }
      } catch (err) {
        setError('Erreur lors de la récupération des statistiques');
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, []);

  if (loading) {
    return <LinearProgress />;
  }

  if (error) {
    return (
      <Typography color="error" variant="body1">
        {error}
      </Typography>
    );
  }

  if (!stats) {
    return null;
  }

  const { messages, tickets } = stats;

  // Données pour le graphique des messages par jour
  const messageChartData = messages.byDay.map(day => ({
    date: new Date(day.date).toLocaleDateString('fr-FR', { weekday: 'short', day: 'numeric' }),
    total: day.total,
    unread: day.unread,
    responded: day.responded,
  }));

  // Données pour le graphique des tickets par type
  const ticketChartData = tickets.byType.map(type => ({
    name: type.type,
    total: type.total,
    resolved: type.resolved,
    pending: type.pending,
  }));

  return (
    <Box sx={{ py: 2 }}>
      <Grid container spacing={3}>
        {/* Statistiques des messages */}
        <Grid item xs={12}>
          <Typography variant="h5" gutterBottom>
            Messages
          </Typography>
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Total des messages"
            value={messages.total}
            icon={MessageIcon}
            color="#1976d2"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Messages non lus"
            value={messages.unread}
            icon={UnreadIcon}
            color="#f44336"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Taux de réponse"
            value={`${Math.round(messages.responseRate)}%`}
            icon={ResponseIcon}
            color="#4caf50"
          />
        </Grid>

        {/* Graphique des messages par jour */}
        <Grid item xs={12}>
          <AnalyticsChart
            type="line"
            title="Activité des messages sur 7 jours"
            subtitle="Evolution du nombre de messages"
            data={messageChartData}
            xAxisKey="date"
            series={[
              { dataKey: 'total', name: 'Total' },
              { dataKey: 'unread', name: 'Non lus' },
              { dataKey: 'responded', name: 'Répondus' }
            ]}
          />
        </Grid>

        {/* Statistiques des tickets */}
        <Grid item xs={12} sx={{ mt: 4 }}>
          <Typography variant="h5" gutterBottom>
            Tickets de support
          </Typography>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total des tickets"
            value={tickets.total}
            icon={TicketIcon}
            color="#9c27b0"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Tickets ouverts"
            value={tickets.open}
            icon={TicketIcon}
            color="#ff9800"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Tickets résolus"
            value={tickets.resolved}
            icon={ResolvedIcon}
            color="#4caf50"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Tooltip title="Temps moyen de résolution des tickets">
            <div>
              <StatCard
                title="Temps de résolution"
                value={`${Math.round(tickets.averageResolutionTime)}h`}
                subtitle="En moyenne"
                icon={TimeIcon}
                color="#2196f3"
              />
            </div>
          </Tooltip>
        </Grid>

        {/* Graphique des tickets par type */}
        <Grid item xs={12}>
          <AnalyticsChart
            type="bar"
            title="Distribution des tickets par type"
            subtitle="Répartition des tickets selon leur type et statut"
            data={ticketChartData}
            xAxisKey="name"
            series={[
              { dataKey: 'total', name: 'Total' },
              { dataKey: 'resolved', name: 'Résolus' },
              { dataKey: 'pending', name: 'En attente' }
            ]}
          />
        </Grid>
      </Grid>
    </Box>
  );
};

export default CommunicationStats;
