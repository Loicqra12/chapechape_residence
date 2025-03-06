import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Rating,
  Avatar,
  Chip,
  Button,
  LinearProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  IconButton,
} from '@mui/material';
import {
  Check as CheckIcon,
  Close as CloseIcon,
  Flag as FlagIcon,
  Reply as ReplyIcon,
} from '@mui/icons-material';
import { marketingService } from '../../services/marketingService';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';

const ReviewsPage = () => {
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedReview, setSelectedReview] = useState(null);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    loadReviews();
  }, []);

  const loadReviews = async () => {
    setLoading(true);
    try {
      const response = await marketingService.getReviews();
      if (response.success) {
        setReviews(response.data);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des avis:', error);
    }
    setLoading(false);
  };

  const handleOpenDialog = (review = null) => {
    setSelectedReview(review);
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setSelectedReview(null);
    setOpenDialog(false);
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'approved':
        return 'success';
      case 'pending':
        return 'warning';
      case 'rejected':
        return 'error';
      default:
        return 'default';
    }
  };

  const getStatusLabel = (status) => {
    switch (status) {
      case 'approved':
        return 'Approuvé';
      case 'pending':
        return 'En attente';
      case 'rejected':
        return 'Rejeté';
      default:
        return status;
    }
  };

  const filteredReviews = reviews.filter(review => {
    if (filter === 'all') return true;
    return review.status === filter;
  });

  if (loading) {
    return <LinearProgress />;
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Avis Clients
        </Typography>
        <FormControl sx={{ minWidth: 200 }}>
          <InputLabel>Filtrer par statut</InputLabel>
          <Select
            value={filter}
            label="Filtrer par statut"
            onChange={(e) => setFilter(e.target.value)}
          >
            <MenuItem value="all">Tous les avis</MenuItem>
            <MenuItem value="pending">En attente</MenuItem>
            <MenuItem value="approved">Approuvés</MenuItem>
            <MenuItem value="rejected">Rejetés</MenuItem>
          </Select>
        </FormControl>
      </Box>

      <Grid container spacing={3}>
        {filteredReviews.map((review) => (
          <Grid item xs={12} md={6} lg={4} key={review.id}>
            <Card 
              sx={{ 
                height: '100%',
                display: 'flex',
                flexDirection: 'column',
                position: 'relative',
                '&:hover': {
                  boxShadow: 6,
                  transform: 'translateY(-2px)',
                  transition: 'all 0.3s ease-in-out'
                }
              }}
            >
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <Avatar 
                    src={review.user?.avatar}
                    sx={{ width: 40, height: 40, mr: 2 }}
                  >
                    {review.user?.name?.charAt(0)}
                  </Avatar>
                  <Box>
                    <Typography variant="subtitle1">
                      {review.user?.name}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {format(new Date(review.createdAt), 'dd MMMM yyyy', { locale: fr })}
                    </Typography>
                  </Box>
                </Box>

                <Box sx={{ mb: 2 }}>
                  <Rating value={review.rating} readOnly precision={0.5} />
                  <Chip
                    label={getStatusLabel(review.status)}
                    color={getStatusColor(review.status)}
                    size="small"
                    sx={{ ml: 1 }}
                  />
                </Box>

                <Typography variant="body1" sx={{ mb: 2 }}>
                  {review.comment}
                </Typography>

                {review.residence && (
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    Résidence : {review.residence.name}
                  </Typography>
                )}

                <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 1 }}>
                  {review.status === 'pending' && (
                    <>
                      <IconButton 
                        color="success"
                        size="small"
                        title="Approuver"
                      >
                        <CheckIcon />
                      </IconButton>
                      <IconButton 
                        color="error"
                        size="small"
                        title="Rejeter"
                      >
                        <CloseIcon />
                      </IconButton>
                    </>
                  )}
                  <IconButton 
                    color="primary"
                    size="small"
                    onClick={() => handleOpenDialog(review)}
                    title="Répondre"
                  >
                    <ReplyIcon />
                  </IconButton>
                  <IconButton 
                    color="warning"
                    size="small"
                    title="Signaler"
                  >
                    <FlagIcon />
                  </IconButton>
                </Box>

                {review.response && (
                  <Box sx={{ mt: 2, p: 2, bgcolor: 'grey.50', borderRadius: 1 }}>
                    <Typography variant="subtitle2" color="primary">
                      Réponse de l'équipe
                    </Typography>
                    <Typography variant="body2">
                      {review.response}
                    </Typography>
                  </Box>
                )}
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>
          Répondre à l'avis
        </DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <Box sx={{ mb: 3 }}>
            <Typography variant="subtitle2">Avis de {selectedReview?.user?.name}</Typography>
            <Rating value={selectedReview?.rating || 0} readOnly precision={0.5} />
            <Typography variant="body2" sx={{ mt: 1 }}>
              {selectedReview?.comment}
            </Typography>
          </Box>
          <TextField
            fullWidth
            multiline
            rows={4}
            label="Votre réponse"
            defaultValue={selectedReview?.response}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Annuler</Button>
          <Button variant="contained" color="primary">
            Répondre
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default ReviewsPage;
