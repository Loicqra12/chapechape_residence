import React, { useState, useEffect } from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  Avatar,
  LinearProgress,
} from '@mui/material';
import {
  Schedule as PendingIcon,
  CheckCircle as ConfirmedIcon,
  Done as CompletedIcon,
  Cancel as CancelledIcon,
  MoneyOff as RefundedIcon,
  TrendingUp as ConversionIcon,
  AccessTime as DurationIcon,
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

const BookingStats = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const response = await analyticsService.getPerformanceMetrics();
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

  // Données pour le graphique de distribution des statuts
  const statusData = [
    { name: 'En attente', value: stats.pendingBookings },
    { name: 'Confirmées', value: stats.confirmedBookings },
    { name: 'Complétées', value: stats.completedBookings },
    { name: 'Annulées', value: stats.cancelledBookings },
    { name: 'Remboursées', value: stats.refundedBookings },
  ];

  // Données pour le graphique des taux
  const ratesData = [
    {
      name: 'Taux',
      conversion: stats.conversionRate,
      annulation: stats.cancellationRate,
    }
  ];

  return (
    <Box sx={{ py: 2 }}>
      <Grid container spacing={3}>
        {/* Statistiques des réservations */}
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="En attente"
            value={stats.pendingBookings}
            icon={PendingIcon}
            color="#ff9800"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Confirmées"
            value={stats.confirmedBookings}
            icon={ConfirmedIcon}
            color="#2196f3"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Complétées"
            value={stats.completedBookings}
            icon={CompletedIcon}
            color="#4caf50"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Annulées"
            value={stats.cancelledBookings}
            icon={CancelledIcon}
            color="#f44336"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Remboursées"
            value={stats.refundedBookings}
            icon={RefundedIcon}
            color="#9c27b0"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Taux de conversion"
            value={`${Math.round(stats.conversionRate)}%`}
            subtitle="Réservations confirmées et complétées"
            icon={ConversionIcon}
            color="#00bcd4"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Durée moyenne"
            value={stats.averageDuration}
            subtitle="Durée des séjours"
            icon={DurationIcon}
            color="#795548"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total"
            value={stats.totalBookings}
            subtitle="Toutes réservations confondues"
            icon={PendingIcon}
            color="#607d8b"
          />
        </Grid>

        {/* Graphiques */}
        <Grid item xs={12} md={6}>
          <AnalyticsChart
            type="pie"
            title="Distribution des réservations"
            subtitle="Répartition par statut"
            data={statusData}
            xAxisKey="name"
            series={[{ dataKey: 'value', name: 'Réservations' }]}
          />
        </Grid>
        <Grid item xs={12} md={6}>
          <AnalyticsChart
            type="bar"
            title="Performance des réservations"
            subtitle="Taux de conversion et d'annulation"
            data={ratesData}
            xAxisKey="name"
            series={[
              { dataKey: 'conversion', name: 'Taux de conversion' },
              { dataKey: 'annulation', name: "Taux d'annulation" },
            ]}
            valueSuffix="%"
          />
        </Grid>
      </Grid>
    </Box>
  );
};

export default BookingStats;
