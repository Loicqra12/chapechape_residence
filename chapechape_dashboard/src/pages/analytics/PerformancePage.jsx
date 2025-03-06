import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  Stack,
  CircularProgress,
  IconButton,
  TextField,
  MenuItem,
} from '@mui/material';
import {
  TrendingUp as TrendingUpIcon,
  Refresh as RefreshIcon,
  DateRange as DateRangeIcon,
} from '@mui/icons-material';
import { analyticsService } from '../../services/analyticsService';
import AnalyticsChart from '../../components/analytics/AnalyticsChart';
import toast from 'react-hot-toast';

const PerformancePage = () => {
  const [loading, setLoading] = useState(false);
  const [metrics, setMetrics] = useState(null);
  const [timeframe, setTimeframe] = useState('month');
  const [dateRange, setDateRange] = useState({
    start: new Date(new Date().setMonth(new Date().getMonth() - 1)).toISOString().split('T')[0],
    end: new Date().toISOString().split('T')[0],
  });

  useEffect(() => {
    loadPerformanceMetrics();
  }, [timeframe, dateRange]);

  const loadPerformanceMetrics = async () => {
    try {
      setLoading(true);
      const response = await analyticsService.getPerformanceMetrics({
        timeframe,
        startDate: dateRange.start,
        endDate: dateRange.end,
      });

      if (response.success) {
        setMetrics(response.data);
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des métriques:', error);
      toast.error('Erreur lors du chargement des métriques');
    } finally {
      setLoading(false);
    }
  };

  const formatPercentage = (value) => {
    return `${value.toFixed(1)}%`;
  };

  const getPerformanceColor = (value, threshold = 50) => {
    if (value >= threshold) return 'success.main';
    if (value >= threshold * 0.7) return 'warning.main';
    return 'error.main';
  };

  if (loading && !metrics) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <TrendingUpIcon fontSize="large" />
          Performance
        </Typography>
        <Typography variant="subtitle1" color="text.secondary">
          Analyse détaillée des performances des réservations
        </Typography>
      </Box>

      {/* Filtres */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Grid container spacing={3} alignItems="center">
            <Grid item xs={12} sm={4}>
              <TextField
                select
                fullWidth
                label="Période"
                value={timeframe}
                onChange={(e) => setTimeframe(e.target.value)}
              >
                <MenuItem value="week">Cette semaine</MenuItem>
                <MenuItem value="month">Ce mois</MenuItem>
                <MenuItem value="quarter">Ce trimestre</MenuItem>
                <MenuItem value="year">Cette année</MenuItem>
              </TextField>
            </Grid>
            <Grid item xs={12} sm={4}>
              <TextField
                type="date"
                fullWidth
                label="Date de début"
                value={dateRange.start}
                onChange={(e) => setDateRange(prev => ({ ...prev, start: e.target.value }))}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12} sm={4}>
              <TextField
                type="date"
                fullWidth
                label="Date de fin"
                value={dateRange.end}
                onChange={(e) => setDateRange(prev => ({ ...prev, end: e.target.value }))}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {metrics && (
        <>
          {/* KPIs */}
          <Grid container spacing={3} sx={{ mb: 4 }}>
            <Grid item xs={12} sm={6} md={3}>
              <Card>
                <CardContent>
                  <Stack spacing={1}>
                    <Typography variant="overline" color="text.secondary">
                      Total des réservations
                    </Typography>
                    <Typography variant="h4">
                      {metrics.totalBookings}
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
                      Réservations complétées
                    </Typography>
                    <Typography variant="h4" color="success.main">
                      {metrics.completedBookings}
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
                      Taux de conversion
                    </Typography>
                    <Typography 
                      variant="h4"
                      color={getPerformanceColor(metrics.conversionRate)}
                    >
                      {formatPercentage(metrics.conversionRate)}
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
                      Taux d'annulation
                    </Typography>
                    <Typography 
                      variant="h4"
                      color={getPerformanceColor(100 - metrics.cancellationRate)}
                    >
                      {formatPercentage(metrics.cancellationRate)}
                    </Typography>
                  </Stack>
                </CardContent>
              </Card>
            </Grid>
          </Grid>

          {/* Graphiques */}
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <AnalyticsChart
                type="line"
                title="Évolution des réservations"
                subtitle="Nombre de réservations par période"
                data={[
                  { period: 'Jan', completed: 65, cancelled: 28 },
                  { period: 'Fév', completed: 59, cancelled: 24 },
                  { period: 'Mar', completed: 80, cancelled: 29 },
                  { period: 'Avr', completed: 81, cancelled: 31 },
                  { period: 'Mai', completed: 56, cancelled: 21 },
                  { period: 'Juin', completed: 55, cancelled: 23 },
                ]}
                xAxisKey="period"
                series={[
                  { dataKey: 'completed', name: 'Complétées' },
                  { dataKey: 'cancelled', name: 'Annulées' },
                ]}
                height={400}
              />
            </Grid>

            <Grid item xs={12} md={6}>
              <AnalyticsChart
                type="bar"
                title="Taux de conversion par type de résidence"
                subtitle="Pourcentage de réservations complétées"
                data={[
                  { type: 'Appartement', rate: 75 },
                  { type: 'Maison', rate: 68 },
                  { type: 'Villa', rate: 82 },
                  { type: 'Studio', rate: 71 },
                ]}
                xAxisKey="type"
                series={[{ dataKey: 'rate', name: 'Taux de conversion' }]}
                valueSuffix="%"
                height={300}
              />
            </Grid>

            <Grid item xs={12} md={6}>
              <AnalyticsChart
                type="pie"
                title="Distribution des statuts"
                subtitle="Répartition des réservations par statut"
                data={[
                  { name: 'Complétées', value: metrics.completedBookings },
                  { name: 'En attente', value: metrics.pendingBookings },
                  { name: 'Annulées', value: metrics.cancelledBookings },
                ]}
                xAxisKey="name"
                series={[{ dataKey: 'value', name: 'Réservations' }]}
                height={300}
              />
            </Grid>
          </Grid>
        </>
      )}

      {/* Bouton de rafraîchissement */}
      <Box sx={{ position: 'fixed', bottom: 16, right: 16 }}>
        <Button
          variant="contained"
          onClick={loadPerformanceMetrics}
          disabled={loading}
          startIcon={<RefreshIcon />}
        >
          Actualiser
        </Button>
      </Box>
    </Container>
  );
};

export default PerformancePage;
