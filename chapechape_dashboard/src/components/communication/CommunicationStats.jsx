import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  LinearProgress,
  Stack,
  Chip,
} from '@mui/material';
import {
  Email as EmailIcon,
  QuestionAnswer as QuestionAnswerIcon,
  CheckCircle as CheckCircleIcon,
  AccessTime as AccessTimeIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';

const StatCard = ({ icon: Icon, title, value, subtitle, progress, color = 'primary' }) => (
  <Card>
    <CardContent>
      <Stack spacing={2}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Icon color={color} />
          <Typography variant="overline" color="text.secondary">
            {title}
          </Typography>
        </Box>

        <Typography variant="h4">
          {value}
        </Typography>

        {subtitle && (
          <Typography variant="body2" color="text.secondary">
            {subtitle}
          </Typography>
        )}

        {progress !== undefined && (
          <Box sx={{ width: '100%', mt: 1 }}>
            <LinearProgress
              variant="determinate"
              value={progress}
              color={color}
              sx={{ height: 8, borderRadius: 1 }}
            />
          </Box>
        )}
      </Stack>
    </CardContent>
  </Card>
);

const CommunicationStats = ({
  messageStats = {
    total: 0,
    unread: 0,
    sent: 0,
    response_rate: 0,
  },
  ticketStats = {
    total: 0,
    open: 0,
    resolved: 0,
    resolution_rate: 0,
    average_response_time: '0h',
  }
}) => {
  return (
    <Grid container spacing={3}>
      {/* Statistiques des messages */}
      <Grid item xs={12}>
        <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <EmailIcon fontSize="small" />
          Statistiques des messages
        </Typography>
      </Grid>

      <Grid item xs={12} sm={6} md={3}>
        <StatCard
          icon={EmailIcon}
          title="Total des messages"
          value={messageStats.total}
          subtitle="Messages reçus et envoyés"
        />
      </Grid>

      <Grid item xs={12} sm={6} md={3}>
        <StatCard
          icon={AccessTimeIcon}
          title="Messages non lus"
          value={messageStats.unread}
          subtitle="En attente de lecture"
          color={messageStats.unread > 0 ? 'warning' : 'success'}
        />
      </Grid>

      <Grid item xs={12} sm={6} md={3}>
        <StatCard
          icon={CheckCircleIcon}
          title="Messages envoyés"
          value={messageStats.sent}
          subtitle="Messages envoyés avec succès"
          color="success"
        />
      </Grid>

      <Grid item xs={12} sm={6} md={3}>
        <StatCard
          icon={QuestionAnswerIcon}
          title="Taux de réponse"
          value={`${messageStats.response_rate}%`}
          subtitle="Messages ayant reçu une réponse"
          progress={messageStats.response_rate}
          color={messageStats.response_rate >= 80 ? 'success' : 'warning'}
        />
      </Grid>

      {/* Statistiques des tickets */}
      <Grid item xs={12} sx={{ mt: 4 }}>
        <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <QuestionAnswerIcon fontSize="small" />
          Statistiques des tickets de support
        </Typography>
      </Grid>

      <Grid item xs={12} sm={6} md={3}>
        <StatCard
          icon={QuestionAnswerIcon}
          title="Total des tickets"
          value={ticketStats.total}
          subtitle="Tickets créés"
        />
      </Grid>

      <Grid item xs={12} sm={6} md={3}>
        <StatCard
          icon={WarningIcon}
          title="Tickets ouverts"
          value={ticketStats.open}
          subtitle="En attente de résolution"
          color={ticketStats.open > 5 ? 'error' : 'warning'}
        />
      </Grid>

      <Grid item xs={12} sm={6} md={3}>
        <StatCard
          icon={CheckCircleIcon}
          title="Tickets résolus"
          value={ticketStats.resolved}
          subtitle="Problèmes résolus"
          color="success"
        />
      </Grid>

      <Grid item xs={12} sm={6} md={3}>
        <StatCard
          icon={AccessTimeIcon}
          title="Taux de résolution"
          value={`${ticketStats.resolution_rate}%`}
          subtitle={`Temps moyen: ${ticketStats.average_response_time}`}
          progress={ticketStats.resolution_rate}
          color={ticketStats.resolution_rate >= 80 ? 'success' : 'warning'}
        />
      </Grid>

      {/* Légende des statuts */}
      <Grid item xs={12} sx={{ mt: 2 }}>
        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          <Chip
            size="small"
            icon={<CheckCircleIcon />}
            label="Excellent"
            color="success"
          />
          <Chip
            size="small"
            icon={<WarningIcon />}
            label="À améliorer"
            color="warning"
          />
          <Chip
            size="small"
            icon={<WarningIcon />}
            label="Critique"
            color="error"
          />
        </Box>
      </Grid>
    </Grid>
  );
};

export default CommunicationStats;
