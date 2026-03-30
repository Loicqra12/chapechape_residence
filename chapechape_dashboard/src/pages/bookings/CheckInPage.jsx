import React, { useState, useEffect } from 'react';
import {
  Box,
  Container,
  Typography,
  Card,
  CardContent,
  Grid,
  TextField,
  Button,
  IconButton,
  Chip,
  Avatar,
  CircularProgress,
  Skeleton
} from '@mui/material';
import {
  Search as SearchIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  AccessTime as AccessTimeIcon,
  LocationOn as LocationIcon,
  Person as PersonIcon
} from '@mui/icons-material';
import { bookingService } from '../../services/bookingService';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import toast from 'react-hot-toast';

const LoadingCard = () => {
  return (
    <Card sx={{ position: 'relative', overflow: 'visible' }}>
      <CardContent>
        <Grid container spacing={3} alignItems="center">
          <Grid item xs={12} sm={2}>
            <Skeleton variant="rounded" width={100} height={100} />
          </Grid>
          <Grid item xs={12} sm={7}>
            <Skeleton variant="text" width="60%" height={32} sx={{ mb: 1 }} />
            <Skeleton variant="text" width="80%" height={24} sx={{ mb: 1 }} />
            <Skeleton variant="text" width="40%" height={24} sx={{ mb: 1 }} />
            <Skeleton variant="text" width="30%" height={24} />
          </Grid>
          <Grid item xs={12} sm={3}>
            <Box sx={{ display: 'flex', gap: 1, justifyContent: 'flex-end' }}>
              <Skeleton variant="rounded" width={100} height={36} />
              <Skeleton variant="circular" width={36} height={36} />
            </Box>
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  );
};

const CheckInPage = () => {
  const [bookings, setBookings] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState({ id: null, type: null });

  useEffect(() => {
    loadTodayBookings();
  }, []);

  const loadTodayBookings = async () => {
    try {
      setLoading(true);
      const today = new Date();
      const { bookings } = await bookingService.getBookings({
        filters: {
          startDate: format(today, 'yyyy-MM-dd'),
          endDate: format(today, 'yyyy-MM-dd'),
          status: ['confirmed', 'in_stay']
        }
      });
      setBookings(bookings);
    } catch (error) {
      console.error('Erreur lors du chargement des réservations:', error);
      toast.error('Erreur lors du chargement des réservations');
    } finally {
      setLoading(false);
    }
  };

  const handleCheckIn = async (bookingId, clientName) => {
    try {
      setActionLoading({ id: bookingId, type: 'checkin' });
      await bookingService.checkInReservation(bookingId);
      await loadTodayBookings();
      toast.success(`Check-in effectué pour ${clientName}`);
    } catch (error) {
      console.error('Erreur lors du check-in:', error);
      toast.error('Erreur lors du check-in');
    } finally {
      setActionLoading({ id: null, type: null });
    }
  };

  const handleCheckOut = async (bookingId, clientName) => {
    try {
      setActionLoading({ id: bookingId, type: 'checkout' });
      await bookingService.completeBooking(bookingId);
      await loadTodayBookings();
      toast.success(`Check-out effectué pour ${clientName}`);
    } catch (error) {
      console.error('Erreur lors du check-out:', error);
      toast.error('Erreur lors du check-out');
    } finally {
      setActionLoading({ id: null, type: null });
    }
  };

  const handleCancel = async (bookingId, clientName) => {
    try {
      setActionLoading({ id: bookingId, type: 'cancel' });
      await bookingService.cancelBooking(bookingId, 'No-show');
      await loadTodayBookings();
      toast.success(`Visite marquée comme no-show pour ${clientName}`);
    } catch (error) {
      console.error('Erreur lors de l\'annulation:', error);
      toast.error('Erreur lors du marquage no-show');
    } finally {
      setActionLoading({ id: null, type: null });
    }
  };

  const filteredBookings = bookings.filter(booking =>
    (booking.client?.name || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
    (booking.residence?.title || '').toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          Check-in des visites
        </Typography>
        <Typography variant="subtitle1" color="text.secondary">
          {format(new Date(), 'EEEE d MMMM yyyy', { locale: fr })}
        </Typography>
      </Box>

      <Card sx={{ mb: 4 }}>
        <CardContent>
          <TextField
            fullWidth
            variant="outlined"
            placeholder="Rechercher par nom du client ou de la résidence..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            InputProps={{
              startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
            }}
            sx={{ bgcolor: 'background.paper' }}
          />
        </CardContent>
      </Card>

      <Grid container spacing={3}>
        {loading ? (
          [...Array(3)].map((_, index) => (
            <Grid item xs={12} key={index}>
              <LoadingCard />
            </Grid>
          ))
        ) : (
          filteredBookings.map((booking) => (
            <Grid item xs={12} key={booking._id}>
              <Card
                sx={{
                  position: 'relative',
                  overflow: 'visible',
                  '&:hover': {
                    boxShadow: 8,
                    transform: 'translateY(-2px)',
                    transition: 'all 0.3s ease-in-out'
                  }
                }}
              >
                <CardContent>
                  <Grid container spacing={3} alignItems="center">
                    <Grid item xs={12} sm={2}>
                      <Avatar
                        src={booking.residence?.imageUrl}
                        variant="rounded"
                        sx={{
                          width: 100,
                          height: 100,
                          borderRadius: 2,
                          boxShadow: 2
                        }}
                      />
                    </Grid>

                    <Grid item xs={12} sm={7}>
                      <Box>
                        <Typography variant="h6" gutterBottom>
                          {booking.residence?.title || 'Résidence inconnue'}
                        </Typography>

                        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                          <LocationIcon sx={{ mr: 1, color: 'text.secondary', fontSize: 20 }} />
                          <Typography variant="body2" color="text.secondary">
                            {booking.residence?.address || booking.residence?.location?.address || 'Adresse inconnue'}
                            {(booking.residence?.city || booking.residence?.location?.city) && `, ${booking.residence?.city || booking.residence?.location?.city}`}
                          </Typography>
                        </Box>

                        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                          <PersonIcon sx={{ mr: 1, color: 'text.secondary', fontSize: 20 }} />
                          <Typography variant="body2" color="text.primary">
                            {booking.client?.name || 'Client inconnu'}
                          </Typography>
                          <Chip
                            size="small"
                            label={booking.client?.email || 'Email inconnu'}
                            sx={{ ml: 2, bgcolor: 'primary.main', opacity: 0.1 }}
                          />
                        </Box>

                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                          <AccessTimeIcon sx={{ mr: 1, color: 'text.secondary', fontSize: 20 }} />
                          <Typography variant="body2" color="text.secondary">
                            {booking.visitTime}
                          </Typography>
                        </Box>
                      </Box>
                    </Grid>

                    <Grid item xs={12} sm={3}>
                      <Box sx={{ display: 'flex', gap: 1, justifyContent: 'flex-end' }}>
                        {booking.status === 'confirmed' && (
                          <Button
                            variant="contained"
                            color="success"
                            startIcon={actionLoading.id === booking._id && actionLoading.type === 'checkin' ?
                              <CircularProgress size={20} color="inherit" /> :
                              <CheckCircleIcon />
                            }
                            onClick={() => handleCheckIn(booking._id, booking.client?.name || 'Client')}
                            disabled={!!actionLoading.id}
                            sx={{
                              borderRadius: 2,
                              textTransform: 'none',
                              boxShadow: 'none',
                              '&:hover': {
                                boxShadow: 2
                              }
                            }}
                          >
                            Check-in
                          </Button>
                        )}
                        {booking.status === 'in_stay' && (
                          <Button
                            variant="contained"
                            color="primary"
                            startIcon={actionLoading.id === booking._id && actionLoading.type === 'checkout' ?
                              <CircularProgress size={20} color="inherit" /> :
                              <CheckCircleIcon />
                            }
                            onClick={() => handleCheckOut(booking._id, booking.client?.name || 'Client')}
                            disabled={!!actionLoading.id}
                            sx={{
                              borderRadius: 2,
                              textTransform: 'none',
                              boxShadow: 'none',
                              '&:hover': {
                                boxShadow: 2
                              }
                            }}
                          >
                            Terminer
                          </Button>
                        )}
                        <IconButton
                          color="error"
                          onClick={() => handleCancel(booking._id, booking.client?.name || 'Client')}
                          disabled={!!actionLoading.id}
                          sx={{
                            borderRadius: 2,
                            border: '1px solid',
                            borderColor: 'error.main',
                            '&:hover': {
                              bgcolor: 'error.main',
                              opacity: 0.1
                            }
                          }}
                        >
                          {actionLoading.id === booking._id && actionLoading.type === 'cancel' ? (
                            <CircularProgress size={24} color="error" />
                          ) : (
                            <CancelIcon />
                          )}
                        </IconButton>
                      </Box>
                    </Grid>
                  </Grid>
                </CardContent>
              </Card>
            </Grid>
          ))
        )}

        {filteredBookings.length === 0 && !loading && (
          <Grid item xs={12}>
            <Box
              sx={{
                textAlign: 'center',
                py: 8,
                bgcolor: 'background.paper',
                borderRadius: 2
              }}
            >
              <Typography variant="h6" color="text.secondary">
                Aucune visite prévue pour aujourd'hui
              </Typography>
            </Box>
          </Grid>
        )}
      </Grid>
    </Container>
  );
};

export default CheckInPage;
