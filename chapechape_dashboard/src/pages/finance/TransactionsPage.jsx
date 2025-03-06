import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  TableContainer,
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableCell,
  Paper,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  CircularProgress,
} from '@mui/material';
import {
  Refresh as RefreshIcon,
  MoneyOff as MoneyOffIcon,
} from '@mui/icons-material';
import { financeService } from '../../services/financeService';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import toast from 'react-hot-toast';
import StatusChip from '../../components/finance/StatusChip';
import StatsCards from '../../components/finance/StatsCards';
import FilterBar from '../../components/finance/FilterBar';

const TransactionsPage = () => {
  const [loading, setLoading] = useState(false);
  const [transactions, setTransactions] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filters, setFilters] = useState({
    status: '',
    paymentMethod: '',
  });
  const [stats, setStats] = useState(null);

  useEffect(() => {
    loadTransactions();
  }, []);

  const loadTransactions = async () => {
    try {
      setLoading(true);
      const response = await financeService.getPayments({
        page: 1,
        limit: 50,
        ...filters,
        search: searchTerm,
      });

      if (response.success) {
        setTransactions(response.data);
        await loadStats();
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des transactions:', error);
      toast.error('Erreur lors du chargement des transactions');
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      const response = await financeService.getFinancialStats();
      if (response.success) {
        setStats(response.data);
      } else {
        console.error('Erreur lors du chargement des statistiques:', response.error);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des statistiques:', error);
    }
  };

  const formatDate = (date) => {
    return format(new Date(date), 'dd MMMM yyyy HH:mm', { locale: fr });
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'XOF'
    }).format(amount);
  };

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      {/* En-tête */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          Transactions
        </Typography>
        <Typography variant="subtitle1" color="text.secondary">
          Historique des transactions
        </Typography>
      </Box>

      {/* Statistiques */}
      <StatsCards stats={stats} />

      {/* Filtres */}
      <FilterBar
        searchTerm={searchTerm}
        onSearchChange={setSearchTerm}
        filters={filters}
        onFiltersChange={setFilters}
        onApplyFilters={loadTransactions}
        loading={loading}
      />

      {/* Liste des transactions */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Date</TableCell>
              <TableCell>Référence</TableCell>
              <TableCell>Montant</TableCell>
              <TableCell>Méthode</TableCell>
              <TableCell>Client</TableCell>
              <TableCell>Statut</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  <CircularProgress />
                </TableCell>
              </TableRow>
            ) : transactions.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  Aucune transaction trouvée
                </TableCell>
              </TableRow>
            ) : (
              transactions.map((transaction) => (
                <TableRow key={transaction._id}>
                  <TableCell>{formatDate(transaction.createdAt)}</TableCell>
                  <TableCell>{transaction.paymentDetails?.reference || '-'}</TableCell>
                  <TableCell>{formatCurrency(transaction.amount)}</TableCell>
                  <TableCell>
                    {financeService.getPaymentMethods().find(m => m.id === transaction.paymentMethod)?.name}
                  </TableCell>
                  <TableCell>{transaction.phoneNumber || '-'}</TableCell>
                  <TableCell>
                    <StatusChip status={transaction.status} />
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>
    </Container>
  );
};

export default TransactionsPage;
