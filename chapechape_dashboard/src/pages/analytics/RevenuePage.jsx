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
  TextField,
  MenuItem,
  Divider,
} from '@mui/material';
import {
  AttachMoney as AttachMoneyIcon,
  Refresh as RefreshIcon,
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
} from '@mui/icons-material';
import { analyticsService } from '../../services/analyticsService';
import AnalyticsChart from '../../components/analytics/AnalyticsChart';
import toast from 'react-hot-toast';

const RevenuePage = () => {
  const [loading, setLoading] = useState(false);
  const [revenueData, setRevenueData] = useState(null);
  const [timeframe, setTimeframe] = useState('month');
  const [dateRange, setDateRange] = useState({
    start: new Date(new Date().setMonth(new Date().getMonth() - 1)).toISOString().split('T')[0],
    end: new Date().toISOString().split('T')[0],
  });

  useEffect(() => {
    loadRevenueData();
  }, [timeframe, dateRange]);

  const loadRevenueData = async () => {
    try {
      setLoading(true);
      const response = await analyticsService.getRevenueAnalytics({
        timeframe,
        startDate: dateRange.start,
        endDate: dateRange.end,
      });

      if (response.success) {
        setRevenueData(response.data);
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des données de revenus:', error);
      toast.error('Erreur lors du chargement des données de revenus');
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (value) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'XOF',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
  };

  const calculateGrowth = (current, previous) => {
    if (!previous) return 0;
    return ((current - previous) / previous) * 100;
  };

  if (loading && !revenueData) {
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
          <AttachMoneyIcon fontSize="large" />
          Revenus
        </Typography>
        <Typography variant="subtitle1" color="text.secondary">
          Analyse détaillée des revenus et des performances financières
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

      {revenueData && (
        <>
          {/* KPIs */}
          <Grid container spacing={3} sx={{ mb: 4 }}>
            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Stack spacing={2}>
                    <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                      <Box>
                        <Typography variant="overline" color="text.secondary">
                          Revenu total
                        </Typography>
                        <Typography variant="h4">
                          {formatCurrency(revenueData.totalRevenue)}
                        </Typography>
                      </Box>
                      <Box sx={{ textAlign: 'right' }}>
                        <Typography
                          variant="body2"
                          color={revenueData.growth >= 0 ? 'success.main' : 'error.main'}
                          sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}
                        >
                          {revenueData.growth >= 0 ? <TrendingUpIcon /> : <TrendingDownIcon />}
                          {Math.abs(revenueData.growth).toFixed(1)}%
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          vs période précédente
                        </Typography>
                      </Box>
                    </Box>
                    <Divider />
                    <Grid container spacing={2}>
                      <Grid item xs={6}>
                        <Typography variant="body2" color="text.secondary">
                          Revenu moyen par réservation
                        </Typography>
                        <Typography variant="h6">
                          {formatCurrency(revenueData.averageRevenue)}
                        </Typography>
                      </Grid>
                      <Grid item xs={6}>
                        <Typography variant="body2" color="text.secondary">
                          Nombre de réservations
                        </Typography>
                        <Typography variant="h6">
                          {revenueData.totalBookings}
                        </Typography>
                      </Grid>
                    </Grid>
                  </Stack>
                </CardContent>
              </Card>
            </Grid>

            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Stack spacing={2}>
                    <Typography variant="overline" color="text.secondary">
                      Distribution des revenus par type de résidence
                    </Typography>
                    <AnalyticsChart
                      type="pie"
                      data={revenueData.revenueByResidenceType}
                      xAxisKey="type"
                      series={[{ dataKey: 'revenue', name: 'Revenu' }]}
                      valuePrefix="XOF "
                      height={200}
                    />
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
                title="Évolution des revenus"
                subtitle="Revenus par période"
                data={revenueData.revenueByPeriod}
                xAxisKey="period"
                series={[
                  { dataKey: 'revenue', name: 'Revenu' },
                  { dataKey: 'target', name: 'Objectif' },
                ]}
                valuePrefix="XOF "
                height={400}
              />
            </Grid>

            <Grid item xs={12} md={6}>
              <AnalyticsChart
                type="bar"
                title="Revenus par méthode de paiement"
                subtitle="Distribution des revenus selon le mode de paiement"
                data={revenueData.revenueByPaymentMethod}
                xAxisKey="method"
                series={[{ dataKey: 'amount', name: 'Montant' }]}
                valuePrefix="XOF "
                height={300}
              />
            </Grid>

            <Grid item xs={12} md={6}>
              <AnalyticsChart
                type="bar"
                title="Performance par résidence"
                subtitle="Revenus générés par résidence"
                data={revenueData.revenueByResidence}
                xAxisKey="name"
                series={[{ dataKey: 'revenue', name: 'Revenu' }]}
                valuePrefix="XOF "
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
          onClick={loadRevenueData}
          disabled={loading}
          startIcon={<RefreshIcon />}
        >
          Actualiser
        </Button>
      </Box>
    </Container>
  );
};

export default RevenuePage;
