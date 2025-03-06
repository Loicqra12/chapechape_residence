import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Grid,
  Button,
  Stack,
  CircularProgress,
  Tabs,
  Tab,
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { analyticsService } from '../../services/analyticsService';
import BookingStats from '../../components/analytics/BookingStats';
import ResidenceStats from '../../components/analytics/ResidenceStats';
import CommunicationStats from '../../components/analytics/CommunicationStats';
import AnalyticsChart from '../../components/analytics/AnalyticsChart';
import toast from 'react-hot-toast';

const DashboardPage = () => {
  const [loading, setLoading] = useState(true);
  const [currentTab, setCurrentTab] = useState('overview');
  const [dashboardData, setDashboardData] = useState({
    bookingStats: null,
    residenceStats: null,
    communicationStats: null,
    revenueData: null,
  });

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);

      const [
        bookingsResponse,
        revenueResponse,
        residenceResponse,
        communicationResponse
      ] = await Promise.all([
        analyticsService.getPerformanceMetrics(),
        analyticsService.getRevenueAnalytics(),
        analyticsService.getResidenceStats(),
        analyticsService.getCommunicationStats()
      ]);

      setDashboardData({
        bookingStats: bookingsResponse.success ? bookingsResponse.data : null,
        revenueData: revenueResponse.success ? revenueResponse.data : null,
        residenceStats: residenceResponse.success ? residenceResponse.data : null,
        communicationStats: communicationResponse.success ? communicationResponse.data : null,
      });
    } catch (error) {
      console.error('Erreur lors du chargement du tableau de bord:', error);
      toast.error('Erreur lors du chargement du tableau de bord');
    } finally {
      setLoading(false);
    }
  };

  const handleTabChange = (event, newValue) => {
    setCurrentTab(newValue);
  };

  const handleRefresh = () => {
    loadDashboardData();
  };

  const formatCurrency = (value) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'XOF',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
        <CircularProgress />
      </Box>
    );
  }

  const { bookingStats, revenueData } = dashboardData;

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Stack direction="row" justifyContent="space-between" alignItems="center">
          <Box>
            <Typography variant="h4" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <DashboardIcon fontSize="large" />
              Tableau de bord
            </Typography>
            <Typography variant="subtitle1" color="text.secondary">
              Vue d'ensemble des performances et statistiques
            </Typography>
          </Box>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={handleRefresh}
          >
            Actualiser
          </Button>
        </Stack>
      </Box>

      {/* Onglets */}
      <Box sx={{ mb: 4 }}>
        <Tabs
          value={currentTab}
          onChange={handleTabChange}
          variant="scrollable"
          scrollButtons="auto"
        >
          <Tab label="Vue d'ensemble" value="overview" />
          <Tab label="Réservations" value="bookings" />
          <Tab label="Résidences" value="residences" />
          <Tab label="Communication" value="communication" />
        </Tabs>
      </Box>

      {/* Contenu des onglets */}
      {currentTab === 'overview' && (
        <Grid container spacing={3}>
          {/* Statistiques des réservations */}
          {bookingStats && (
            <>
              <Grid item xs={12}>
                <Typography variant="h5" gutterBottom>
                  Réservations
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6} md={4}>
                <AnalyticsChart
                  type="pie"
                  title="Statut des réservations"
                  data={[
                    { name: 'En attente', value: bookingStats.pendingBookings },
                    { name: 'Confirmées', value: bookingStats.confirmedBookings },
                    { name: 'Complétées', value: bookingStats.completedBookings },
                    { name: 'Annulées', value: bookingStats.cancelledBookings },
                    { name: 'Remboursées', value: bookingStats.refundedBookings },
                  ]}
                  xAxisKey="name"
                  series={[{ dataKey: 'value', name: 'Réservations' }]}
                />
              </Grid>
              <Grid item xs={12} sm={6} md={8}>
                <AnalyticsChart
                  type="bar"
                  title="Performance des réservations"
                  data={[
                    {
                      name: 'Taux',
                      conversion: bookingStats.conversionRate,
                      annulation: bookingStats.cancellationRate,
                    }
                  ]}
                  xAxisKey="name"
                  series={[
                    { dataKey: 'conversion', name: 'Taux de conversion' },
                    { dataKey: 'annulation', name: "Taux d'annulation" },
                  ]}
                  valueSuffix="%"
                />
              </Grid>
            </>
          )}

          {/* Statistiques des revenus */}
          {revenueData && (
            <>
              <Grid item xs={12}>
                <Typography variant="h5" gutterBottom>
                  Revenus
                </Typography>
              </Grid>
              <Grid item xs={12}>
                <AnalyticsChart
                  type="line"
                  title="Évolution des revenus"
                  subtitle={`Total: ${formatCurrency(revenueData.totalRevenue)}`}
                  data={revenueData.revenueByPeriod}
                  xAxisKey="period"
                  series={[
                    { dataKey: 'revenue', name: 'Revenus' },
                    { dataKey: 'bookings', name: 'Réservations' },
                  ]}
                  valuePrefix="XOF "
                />
              </Grid>
              <Grid item xs={12}>
                <AnalyticsChart
                  type="bar"
                  title="Revenus par type de résidence"
                  data={revenueData.revenueByResidenceType}
                  xAxisKey="type"
                  series={[
                    { dataKey: 'revenue', name: 'Revenus' },
                    { dataKey: 'bookings', name: 'Réservations' },
                    { dataKey: 'hasPool', name: 'Avec piscine' },
                  ]}
                  valuePrefix="XOF "
                />
              </Grid>
            </>
          )}
        </Grid>
      )}

      {currentTab === 'bookings' && (
        <BookingStats />
      )}

      {currentTab === 'residences' && (
        <ResidenceStats />
      )}

      {currentTab === 'communication' && (
        <CommunicationStats />
      )}
    </Container>
  );
};

export default DashboardPage;
