import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Card,
  CardContent,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
  Button,
} from '@mui/material';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import { financeService } from '../../services/financeService';
import { format, subMonths, startOfMonth, endOfMonth } from 'date-fns';
import { fr } from 'date-fns/locale';
import StatsCards from '../../components/finance/StatsCards';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042'];

const ReportsPage = () => {
  const [loading, setLoading] = useState(false);
  const [stats, setStats] = useState(null);
  const [payments, setPayments] = useState([]);
  const [dateRange, setDateRange] = useState({
    startDate: format(startOfMonth(subMonths(new Date(), 5)), 'yyyy-MM-dd'),
    endDate: format(endOfMonth(new Date()), 'yyyy-MM-dd'),
  });

  useEffect(() => {
    loadData();
  }, [dateRange]);

  const loadData = async () => {
    try {
      setLoading(true);
      const response = await financeService.getPayments({
        limit: 1000,
        filters: {
          startDate: dateRange.startDate,
          endDate: dateRange.endDate,
        },
      });

      if (response.success) {
        setPayments(response.data);
        await loadStats();
      }
    } catch (error) {
      console.error('Erreur lors du chargement des données:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      const response = await financeService.getFinancialStats();
      if (response.success) {
        setStats(response.data);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des statistiques:', error);
    }
  };

  const getMonthlyData = () => {
    const monthlyData = {};
    payments.forEach(payment => {
      const date = new Date(payment.createdAt);
      const monthKey = format(date, 'yyyy-MM');
      const monthLabel = format(date, 'MMMM yyyy', { locale: fr });
      
      if (!monthlyData[monthKey]) {
        monthlyData[monthKey] = {
          name: monthLabel,
          total: 0,
          completed: 0,
          pending: 0,
          failed: 0,
        };
      }

      const amount = payment.amount || 0;
      monthlyData[monthKey].total += amount;

      switch (payment.status) {
        case 'completed':
          monthlyData[monthKey].completed += amount;
          break;
        case 'pending':
          monthlyData[monthKey].pending += amount;
          break;
        case 'failed':
          monthlyData[monthKey].failed += amount;
          break;
      }
    });

    return Object.values(monthlyData).sort((a, b) => 
      new Date(a.name) - new Date(b.name)
    );
  };

  const getPaymentMethodsData = () => {
    const methodsData = {};
    payments.forEach(payment => {
      if (payment.status === 'completed') {
        const method = financeService.getPaymentMethods()
          .find(m => m.id === payment.paymentMethod)?.name || 'Autre';
        
        if (!methodsData[method]) {
          methodsData[method] = {
            name: method,
            value: 0,
            count: 0,
          };
        }
        methodsData[method].value += payment.amount || 0;
        methodsData[method].count += 1;
      }
    });

    return Object.values(methodsData);
  };

  const formatCurrency = (value) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'XOF',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
  };

  const monthlyData = getMonthlyData();
  const paymentMethodsData = getPaymentMethodsData();

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          Rapports financiers
        </Typography>
        <Typography variant="subtitle1" color="text.secondary">
          Analyse des paiements et des transactions
        </Typography>
      </Box>

      {/* Statistiques globales */}
      <StatsCards stats={stats} />

      {/* Filtres */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} sm={4}>
              <TextField
                fullWidth
                type="date"
                label="Date de début"
                value={dateRange.startDate}
                onChange={(e) => setDateRange({ ...dateRange, startDate: e.target.value })}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12} sm={4}>
              <TextField
                fullWidth
                type="date"
                label="Date de fin"
                value={dateRange.endDate}
                onChange={(e) => setDateRange({ ...dateRange, endDate: e.target.value })}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12} sm={4}>
              <Button
                fullWidth
                variant="contained"
                onClick={loadData}
                disabled={loading}
              >
                Mettre à jour
              </Button>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Graphiques */}
      <Grid container spacing={4}>
        {/* Évolution mensuelle */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Évolution mensuelle des paiements
              </Typography>
              <Box sx={{ height: 400, mt: 2 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={monthlyData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" />
                    <YAxis tickFormatter={formatCurrency} />
                    <Tooltip 
                      formatter={(value) => formatCurrency(value)}
                      labelStyle={{ color: 'black' }}
                    />
                    <Legend />
                    <Bar dataKey="completed" name="Complétés" fill="#00C49F" />
                    <Bar dataKey="pending" name="En attente" fill="#FFBB28" />
                    <Bar dataKey="failed" name="Échoués" fill="#FF8042" />
                  </BarChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Distribution des méthodes de paiement */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Distribution des méthodes de paiement
              </Typography>
              <Box sx={{ height: 400, mt: 2 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={paymentMethodsData}
                      dataKey="value"
                      nameKey="name"
                      cx="50%"
                      cy="50%"
                      outerRadius={120}
                      label={({ name, value }) => `${name}: ${formatCurrency(value)}`}
                    >
                      {paymentMethodsData.map((entry, index) => (
                        <Cell key={entry.name} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip formatter={(value) => formatCurrency(value)} />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Statistiques des méthodes de paiement */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Détails par méthode de paiement
              </Typography>
              <Box sx={{ mt: 2 }}>
                {paymentMethodsData.map((method) => (
                  <Box key={method.name} sx={{ mb: 2 }}>
                    <Typography variant="subtitle1">
                      {method.name}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Volume: {formatCurrency(method.value)}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Nombre de transactions: {method.count}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Moyenne par transaction: {formatCurrency(method.value / method.count)}
                    </Typography>
                  </Box>
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Container>
  );
};

export default ReportsPage;
