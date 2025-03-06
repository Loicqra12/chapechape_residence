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
  IconButton,
  Tabs,
  Tab,
  Divider,
} from '@mui/material';
import {
  Assessment as AssessmentIcon,
  Refresh as RefreshIcon,
  Download as DownloadIcon,
  Share as ShareIcon,
  Print as PrintIcon,
} from '@mui/icons-material';
import { analyticsService } from '../../services/analyticsService';
import AnalyticsChart from '../../components/analytics/AnalyticsChart';
import toast from 'react-hot-toast';

const ReportsPage = () => {
  const [loading, setLoading] = useState(false);
  const [reportType, setReportType] = useState('occupancy');
  const [reportData, setReportData] = useState(null);
  const [dateRange, setDateRange] = useState({
    start: new Date(new Date().setMonth(new Date().getMonth() - 1)).toISOString().split('T')[0],
    end: new Date().toISOString().split('T')[0],
  });

  useEffect(() => {
    loadReportData();
  }, [reportType, dateRange]);

  const loadReportData = async () => {
    try {
      setLoading(true);
      const response = await analyticsService.getReports(reportType, {
        startDate: dateRange.start,
        endDate: dateRange.end,
      });

      if (response.success) {
        setReportData(response.data);
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors du chargement du rapport:', error);
      toast.error('Erreur lors du chargement du rapport');
    } finally {
      setLoading(false);
    }
  };

  const handleExport = (format) => {
    // Implémenter l'exportation du rapport
    toast.success(`Export en ${format.toUpperCase()} en cours...`);
  };

  const formatPercentage = (value) => {
    return `${value.toFixed(1)}%`;
  };

  const formatCurrency = (value) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'XOF',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
  };

  const renderReportContent = () => {
    if (!reportData) return null;

    switch (reportType) {
      case 'occupancy':
        return (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <AnalyticsChart
                type="bar"
                title="Taux d'occupation par résidence"
                subtitle="Pourcentage d'occupation pour chaque résidence"
                data={reportData.occupancyByResidence}
                xAxisKey="residenceName"
                series={[{ dataKey: 'occupancyRate', name: "Taux d'occupation" }]}
                valueSuffix="%"
                height={400}
              />
            </Grid>

            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Résidences les plus occupées
                  </Typography>
                  <Stack spacing={2}>
                    {reportData.occupancyByResidence
                      .sort((a, b) => b.occupancyRate - a.occupancyRate)
                      .slice(0, 5)
                      .map((residence, index) => (
                        <Box key={index}>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                            <Typography variant="body1">
                              {residence.residenceName}
                            </Typography>
                            <Typography variant="body1" color="primary">
                              {formatPercentage(residence.occupancyRate)}
                            </Typography>
                          </Box>
                          <Box
                            sx={{
                              width: '100%',
                              height: 8,
                              bgcolor: 'background.paper',
                              borderRadius: 1,
                              overflow: 'hidden',
                            }}
                          >
                            <Box
                              sx={{
                                width: `${residence.occupancyRate}%`,
                                height: '100%',
                                bgcolor: 'primary.main',
                              }}
                            />
                          </Box>
                        </Box>
                      ))}
                  </Stack>
                </CardContent>
              </Card>
            </Grid>

            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Statistiques d'occupation
                  </Typography>
                  <Stack spacing={3}>
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Taux d'occupation moyen
                      </Typography>
                      <Typography variant="h4">
                        {formatPercentage(
                          reportData.occupancyByResidence.reduce((acc, curr) => acc + curr.occupancyRate, 0) /
                          reportData.occupancyByResidence.length
                        )}
                      </Typography>
                    </Box>
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Total des réservations
                      </Typography>
                      <Typography variant="h4">
                        {reportData.occupancyByResidence.reduce((acc, curr) => acc + curr.totalBookings, 0)}
                      </Typography>
                    </Box>
                  </Stack>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        );

      case 'revenue':
        return (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Card>
                <CardContent>
                  <Stack spacing={3}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                      <Typography variant="h6">
                        Revenus totaux
                      </Typography>
                      <Typography variant="h4">
                        {formatCurrency(reportData.totalRevenue)}
                      </Typography>
                    </Box>
                    <Divider />
                    <Grid container spacing={2}>
                      {reportData.revenueByPaymentMethod.map((method, index) => (
                        <Grid item xs={12} sm={6} md={4} key={index}>
                          <Box>
                            <Typography variant="body2" color="text.secondary">
                              {method.method}
                            </Typography>
                            <Typography variant="h6">
                              {formatCurrency(method.amount)}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {method.count} transactions
                            </Typography>
                          </Box>
                        </Grid>
                      ))}
                    </Grid>
                  </Stack>
                </CardContent>
              </Card>
            </Grid>

            <Grid item xs={12}>
              <AnalyticsChart
                type="line"
                title="Évolution des revenus"
                subtitle="Revenus par période"
                data={reportData.revenueByPeriod}
                xAxisKey="period"
                series={[{ dataKey: 'revenue', name: 'Revenu' }]}
                valuePrefix="XOF "
                height={400}
              />
            </Grid>
          </Grid>
        );

      case 'performance':
        return (
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Indicateurs de performance
                  </Typography>
                  <Grid container spacing={3}>
                    <Grid item xs={12} sm={4}>
                      <Box>
                        <Typography variant="body2" color="text.secondary">
                          Taux de conversion
                        </Typography>
                        <Typography variant="h4" color="success.main">
                          {formatPercentage(reportData.conversionRate)}
                        </Typography>
                      </Box>
                    </Grid>
                    <Grid item xs={12} sm={4}>
                      <Box>
                        <Typography variant="body2" color="text.secondary">
                          Réservations complétées
                        </Typography>
                        <Typography variant="h4">
                          {reportData.performanceByPeriod.reduce((acc, curr) => acc + curr.completedBookings, 0)}
                        </Typography>
                      </Box>
                    </Grid>
                    <Grid item xs={12} sm={4}>
                      <Box>
                        <Typography variant="body2" color="text.secondary">
                          Taux de satisfaction
                        </Typography>
                        <Typography variant="h4" color="primary.main">
                          {formatPercentage(85)} {/* À remplacer par la vraie donnée */}
                        </Typography>
                      </Box>
                    </Grid>
                  </Grid>
                </CardContent>
              </Card>
            </Grid>

            <Grid item xs={12}>
              <AnalyticsChart
                type="line"
                title="Évolution des performances"
                subtitle="Taux de conversion par période"
                data={reportData.performanceByPeriod}
                xAxisKey="period"
                series={[{ dataKey: 'conversionRate', name: 'Taux de conversion' }]}
                valueSuffix="%"
                height={400}
              />
            </Grid>
          </Grid>
        );

      default:
        return null;
    }
  };

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <AssessmentIcon fontSize="large" />
          Rapports
        </Typography>
        <Typography variant="subtitle1" color="text.secondary">
          Générez et analysez des rapports détaillés
        </Typography>
      </Box>

      {/* Filtres et actions */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Grid container spacing={3} alignItems="center">
            <Grid item xs={12} sm={4}>
              <TextField
                select
                fullWidth
                label="Type de rapport"
                value={reportType}
                onChange={(e) => setReportType(e.target.value)}
              >
                <MenuItem value="occupancy">Taux d'occupation</MenuItem>
                <MenuItem value="revenue">Revenus</MenuItem>
                <MenuItem value="performance">Performance</MenuItem>
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

      {/* Actions rapides */}
      <Box sx={{ mb: 4, display: 'flex', gap: 2 }}>
        <Button
          variant="outlined"
          startIcon={<DownloadIcon />}
          onClick={() => handleExport('pdf')}
        >
          Exporter en PDF
        </Button>
        <Button
          variant="outlined"
          startIcon={<DownloadIcon />}
          onClick={() => handleExport('excel')}
        >
          Exporter en Excel
        </Button>
        <Button
          variant="outlined"
          startIcon={<PrintIcon />}
          onClick={() => window.print()}
        >
          Imprimer
        </Button>
        <Button
          variant="outlined"
          startIcon={<ShareIcon />}
        >
          Partager
        </Button>
      </Box>

      {/* Contenu du rapport */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
          <CircularProgress />
        </Box>
      ) : (
        renderReportContent()
      )}

      {/* Bouton de rafraîchissement */}
      <Box sx={{ position: 'fixed', bottom: 16, right: 16 }}>
        <Button
          variant="contained"
          onClick={loadReportData}
          disabled={loading}
          startIcon={<RefreshIcon />}
        >
          Actualiser
        </Button>
      </Box>
    </Container>
  );
};

export default ReportsPage;
