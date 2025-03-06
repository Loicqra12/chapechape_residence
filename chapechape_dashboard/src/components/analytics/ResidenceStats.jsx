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
  Home as HomeIcon,
  Pool as PoolIcon,
  BeachAccess as VacationIcon,
  Star as SpecialIcon,
  CheckCircle as AvailableIcon,
} from '@mui/icons-material';
import { analyticsService } from '../../services/analyticsService';
import AnalyticsChart from './AnalyticsChart';

const StatCard = ({ title, value, icon: Icon, color }) => (
  <Card>
    <CardContent>
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
        <Avatar sx={{ bgcolor: color, mr: 2 }}>
          <Icon />
        </Avatar>
        <Typography variant="h6" component="div">
          {title}
        </Typography>
      </Box>
      <Typography variant="h4" component="div" sx={{ textAlign: 'right' }}>
        {value}
      </Typography>
    </CardContent>
  </Card>
);

const ResidenceStats = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const response = await analyticsService.getResidenceStats();
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

  const occupancyChartData = stats.most_booked.map(residence => ({
    name: residence.title,
    occupancy: Math.round(residence.occupancyRate),
    bookings: residence.totalBookings,
  }));

  return (
    <Box sx={{ py: 2 }}>
      <Grid container spacing={3}>
        {/* Statistiques générales */}
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Total des résidences"
            value={stats.total}
            icon={HomeIcon}
            color="#1976d2"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Résidences disponibles"
            value={stats.available}
            icon={AvailableIcon}
            color="#4caf50"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Avec piscine"
            value={stats.withPool}
            icon={PoolIcon}
            color="#00bcd4"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Résidences de vacances"
            value={stats.vacation}
            icon={VacationIcon}
            color="#ff9800"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Résidences spéciales"
            value={stats.special}
            icon={SpecialIcon}
            color="#9c27b0"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Taux d'occupation"
            value={`${Math.round(stats.occupancy_rate)}%`}
            icon={HomeIcon}
            color="#f44336"
          />
        </Grid>

        {/* Graphique des résidences les plus réservées */}
        <Grid item xs={12}>
          <AnalyticsChart
            type="bar"
            title="Top 5 des résidences les plus réservées"
            subtitle="Taux d'occupation et nombre de réservations"
            data={occupancyChartData}
            xAxisKey="name"
            series={[
              { dataKey: 'occupancy', name: "Taux d'occupation" },
              { dataKey: 'bookings', name: 'Nombre de réservations' }
            ]}
            valueSuffix="%"
          />
        </Grid>

        {/* Liste des résidences les plus réservées */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Détails des résidences les plus réservées
              </Typography>
              <Grid container spacing={2}>
                {stats.most_booked.map((residence) => (
                  <Grid item xs={12} key={residence._id}>
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                      <Avatar
                        src={residence.imageUrl}
                        variant="rounded"
                        sx={{ width: 56, height: 56, mr: 2 }}
                      />
                      <Box sx={{ flexGrow: 1 }}>
                        <Typography variant="subtitle1">
                          {residence.title}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {residence.displayAddress}
                        </Typography>
                        <Box sx={{ display: 'flex', alignItems: 'center', mt: 1 }}>
                          {residence.hasPool && (
                            <PoolIcon fontSize="small" sx={{ mr: 1, color: 'primary.main' }} />
                          )}
                          {residence.isVacationResidence && (
                            <VacationIcon fontSize="small" sx={{ mr: 1, color: 'warning.main' }} />
                          )}
                          {residence.isSpecialResidence && (
                            <SpecialIcon fontSize="small" sx={{ mr: 1, color: 'secondary.main' }} />
                          )}
                        </Box>
                      </Box>
                      <Box sx={{ textAlign: 'right' }}>
                        <Typography variant="h6" color="primary">
                          {Math.round(residence.occupancyRate)}%
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {residence.completedBookings}/{residence.totalBookings} réservations
                        </Typography>
                      </Box>
                    </Box>
                  </Grid>
                ))}
              </Grid>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default ResidenceStats;
