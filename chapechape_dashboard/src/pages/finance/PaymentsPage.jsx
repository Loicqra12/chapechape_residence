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

const PaymentsPage = () => {
  const [loading, setLoading] = useState(false);
  const [payments, setPayments] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filters, setFilters] = useState({
    status: '',
    paymentMethod: '',
  });
  const [stats, setStats] = useState(null);
  const [confirmDialog, setConfirmDialog] = useState({
    open: false,
    paymentId: null,
  });
  const [otp, setOtp] = useState('');

  useEffect(() => {
    loadPayments();
  }, []);

  const loadPayments = async () => {
    try {
      setLoading(true);
      const response = await financeService.getPayments({
        page: 1,
        limit: 50,
        ...filters,
        search: searchTerm,
      });

      if (response.success) {
        setPayments(response.data);
        await loadStats();
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des paiements:', error);
      toast.error('Erreur lors du chargement des paiements');
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

  const handleConfirmPayment = async () => {
    try {
      const response = await financeService.confirmPayment(confirmDialog.paymentId, otp);
      if (response.success) {
        toast.success('Paiement confirmé avec succès');
        setConfirmDialog({ open: false, paymentId: null });
        setOtp('');
        loadPayments();
      } else {
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Erreur lors de la confirmation:', error);
      toast.error('Erreur lors de la confirmation du paiement');
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
          Paiements
        </Typography>
        <Typography variant="subtitle1" color="text.secondary">
          Gestion des paiements et transactions
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
        onApplyFilters={loadPayments}
        loading={loading}
      />

      {/* Liste des paiements */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Date</TableCell>
              <TableCell>Référence</TableCell>
              <TableCell>Montant</TableCell>
              <TableCell>Méthode</TableCell>
              <TableCell>Téléphone</TableCell>
              <TableCell>Statut</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={7} align="center">
                  <CircularProgress />
                </TableCell>
              </TableRow>
            ) : payments.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} align="center">
                  Aucun paiement trouvé
                </TableCell>
              </TableRow>
            ) : (
              payments.map((payment) => (
                <TableRow key={payment._id}>
                  <TableCell>{formatDate(payment.createdAt)}</TableCell>
                  <TableCell>{payment.paymentDetails?.reference || '-'}</TableCell>
                  <TableCell>{formatCurrency(payment.amount)}</TableCell>
                  <TableCell>
                    {financeService.getPaymentMethods().find(m => m.id === payment.paymentMethod)?.name}
                  </TableCell>
                  <TableCell>{payment.phoneNumber || '-'}</TableCell>
                  <TableCell>
                    <StatusChip status={payment.status} />
                  </TableCell>
                  <TableCell>
                    <IconButton
                      onClick={() => {
                        toast.info(
                          'La validation est automatique via Wave/CinetPay. Utilisez « Vérifier » côté client ou attendez le webhook.',
                        );
                      }}
                      disabled
                      title="Confirmation manuelle désactivée (sécurité PSP)"
                    >
                      <RefreshIcon />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Dialog de confirmation */}
      <Dialog
        open={confirmDialog.open}
        onClose={() => setConfirmDialog({ open: false, paymentId: null })}
      >
        <DialogTitle>Confirmer le paiement</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="Code OTP"
            type="text"
            fullWidth
            value={otp}
            onChange={(e) => setOtp(e.target.value)}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfirmDialog({ open: false, paymentId: null })}>
            Annuler
          </Button>
          <Button onClick={handleConfirmPayment} variant="contained" color="primary">
            Confirmer
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default PaymentsPage;
