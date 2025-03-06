import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Chip,
  IconButton,
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
} from '@mui/material';
import { Add as AddIcon, Edit as EditIcon, Delete as DeleteIcon } from '@mui/icons-material';
import { marketingService } from '../../services/marketingService';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';

const PromotionsPage = () => {
  const [promotions, setPromotions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedPromotion, setSelectedPromotion] = useState(null);

  useEffect(() => {
    loadPromotions();
  }, []);

  const loadPromotions = async () => {
    setLoading(true);
    try {
      const response = await marketingService.getPromotions();
      if (response.success) {
        setPromotions(response.data);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des promotions:', error);
    }
    setLoading(false);
  };

  const handleOpenDialog = (promotion = null) => {
    setSelectedPromotion(promotion);
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setSelectedPromotion(null);
    setOpenDialog(false);
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'active':
        return 'success';
      case 'scheduled':
        return 'info';
      case 'ended':
        return 'error';
      default:
        return 'default';
    }
  };

  const getStatusLabel = (status) => {
    switch (status) {
      case 'active':
        return 'Active';
      case 'scheduled':
        return 'Planifiée';
      case 'ended':
        return 'Terminée';
      default:
        return status;
    }
  };

  if (loading) {
    return <LinearProgress />;
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Promotions
        </Typography>
        <Button
          variant="contained"
          color="primary"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
        >
          Nouvelle Promotion
        </Button>
      </Box>

      <Grid container spacing={3}>
        {promotions.map((promotion) => (
          <Grid item xs={12} md={6} lg={4} key={promotion.id}>
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
              <CardContent sx={{ flexGrow: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                  <Typography variant="h6" component="h2" gutterBottom>
                    {promotion.title}
                  </Typography>
                  <Box>
                    <IconButton size="small" onClick={() => handleOpenDialog(promotion)}>
                      <EditIcon />
                    </IconButton>
                    <IconButton size="small" color="error">
                      <DeleteIcon />
                    </IconButton>
                  </Box>
                </Box>

                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  {promotion.description}
                </Typography>

                <Box sx={{ mb: 2 }}>
                  <Chip
                    label={getStatusLabel(promotion.status)}
                    color={getStatusColor(promotion.status)}
                    size="small"
                    sx={{ mr: 1 }}
                  />
                  <Chip
                    label={`${promotion.discountValue}${promotion.discountType === 'percentage' ? '%' : '€'}`}
                    color="primary"
                    size="small"
                  />
                </Box>

                <Typography variant="body2" color="text.secondary">
                  Du {format(new Date(promotion.startDate), 'dd MMMM yyyy', { locale: fr })}
                  <br />
                  Au {format(new Date(promotion.endDate), 'dd MMMM yyyy', { locale: fr })}
                </Typography>

                {promotion.conditions.length > 0 && (
                  <Box sx={{ mt: 2 }}>
                    {promotion.conditions.map((condition) => (
                      <Chip
                        key={condition}
                        label={condition}
                        size="small"
                        variant="outlined"
                        sx={{ mr: 1, mb: 1 }}
                      />
                    ))}
                  </Box>
                )}
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>
          {selectedPromotion ? 'Modifier la promotion' : 'Nouvelle promotion'}
        </DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Titre"
                defaultValue={selectedPromotion?.title}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                multiline
                rows={3}
                label="Description"
                defaultValue={selectedPromotion?.description}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                type="date"
                label="Date de début"
                defaultValue={selectedPromotion?.startDate}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                type="date"
                label="Date de fin"
                defaultValue={selectedPromotion?.endDate}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Type de réduction</InputLabel>
                <Select
                  defaultValue={selectedPromotion?.discountType || 'percentage'}
                  label="Type de réduction"
                >
                  <MenuItem value="percentage">Pourcentage</MenuItem>
                  <MenuItem value="fixed">Montant fixe</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                type="number"
                label="Valeur de la réduction"
                defaultValue={selectedPromotion?.discountValue}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Annuler</Button>
          <Button variant="contained" color="primary">
            {selectedPromotion ? 'Modifier' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default PromotionsPage;
