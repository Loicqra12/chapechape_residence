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
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Email as EmailIcon,
  Facebook as FacebookIcon,
  Instagram as InstagramIcon,
  TrendingUp as TrendingUpIcon
} from '@mui/icons-material';
import { marketingService } from '../../services/marketingService';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';

const CampaignsPage = () => {
  const [campaigns, setCampaigns] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedCampaign, setSelectedCampaign] = useState(null);

  useEffect(() => {
    loadCampaigns();
  }, []);

  const loadCampaigns = async () => {
    setLoading(true);
    try {
      const response = await marketingService.getCampaigns();
      if (response.success) {
        setCampaigns(response.data);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des campagnes:', error);
    }
    setLoading(false);
  };

  const handleOpenDialog = (campaign = null) => {
    setSelectedCampaign(campaign);
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setSelectedCampaign(null);
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

  const getCampaignIcon = (type) => {
    switch (type) {
      case 'email':
        return <EmailIcon />;
      case 'facebook':
        return <FacebookIcon />;
      case 'instagram':
        return <InstagramIcon />;
      default:
        return <TrendingUpIcon />;
    }
  };

  const getConversionRate = (metrics) => {
    if (metrics.type === 'email') {
      return ((metrics.converted / metrics.sent) * 100).toFixed(1);
    }
    return ((metrics.conversions / metrics.impressions) * 100).toFixed(1);
  };

  if (loading) {
    return <LinearProgress />;
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Campagnes Marketing
        </Typography>
        <Button
          variant="contained"
          color="primary"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
        >
          Nouvelle Campagne
        </Button>
      </Box>

      <Grid container spacing={3}>
        {campaigns.map((campaign) => (
          <Grid item xs={12} md={6} key={campaign.id}>
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
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    {getCampaignIcon(campaign.type)}
                    <Typography variant="h6" component="h2">
                      {campaign.name}
                    </Typography>
                  </Box>
                  <Box>
                    <IconButton size="small" onClick={() => handleOpenDialog(campaign)}>
                      <EditIcon />
                    </IconButton>
                    <IconButton size="small" color="error">
                      <DeleteIcon />
                    </IconButton>
                  </Box>
                </Box>

                <Box sx={{ mb: 2 }}>
                  <Chip
                    label={getStatusLabel(campaign.status)}
                    color={getStatusColor(campaign.status)}
                    size="small"
                    sx={{ mr: 1 }}
                  />
                  {campaign.type === 'social' && campaign.platforms?.map(platform => (
                    <Chip
                      key={platform}
                      icon={platform === 'instagram' ? <InstagramIcon /> : <FacebookIcon />}
                      label={platform}
                      size="small"
                      sx={{ mr: 1 }}
                    />
                  ))}
                </Box>

                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Du {format(new Date(campaign.startDate), 'dd MMMM yyyy', { locale: fr })}
                  <br />
                  Au {format(new Date(campaign.endDate), 'dd MMMM yyyy', { locale: fr })}
                </Typography>

                {campaign.type === 'email' ? (
                  <Grid container spacing={2}>
                    <Grid item xs={6}>
                      <Typography variant="subtitle2">Envoyés</Typography>
                      <Typography variant="h6">{campaign.metrics.sent}</Typography>
                    </Grid>
                    <Grid item xs={6}>
                      <Typography variant="subtitle2">Ouverts</Typography>
                      <Typography variant="h6">{campaign.metrics.opened}</Typography>
                    </Grid>
                    <Grid item xs={6}>
                      <Typography variant="subtitle2">Cliqués</Typography>
                      <Typography variant="h6">{campaign.metrics.clicked}</Typography>
                    </Grid>
                    <Grid item xs={6}>
                      <Typography variant="subtitle2">Conversions</Typography>
                      <Typography variant="h6">{campaign.metrics.converted}</Typography>
                    </Grid>
                  </Grid>
                ) : (
                  <Grid container spacing={2}>
                    <Grid item xs={6}>
                      <Typography variant="subtitle2">Impressions</Typography>
                      <Typography variant="h6">{campaign.metrics.impressions}</Typography>
                    </Grid>
                    <Grid item xs={6}>
                      <Typography variant="subtitle2">Engagement</Typography>
                      <Typography variant="h6">{campaign.metrics.engagement}</Typography>
                    </Grid>
                    <Grid item xs={6}>
                      <Typography variant="subtitle2">Clics</Typography>
                      <Typography variant="h6">{campaign.metrics.clicks}</Typography>
                    </Grid>
                    <Grid item xs={6}>
                      <Typography variant="subtitle2">Conversions</Typography>
                      <Typography variant="h6">{campaign.metrics.conversions}</Typography>
                    </Grid>
                  </Grid>
                )}

                <Box sx={{ mt: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="body2" color="text.secondary">
                    Taux de conversion
                  </Typography>
                  <Typography variant="h6" color="primary">
                    {getConversionRate(campaign.metrics)}%
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>
          {selectedCampaign ? 'Modifier la campagne' : 'Nouvelle campagne'}
        </DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Nom de la campagne"
                defaultValue={selectedCampaign?.name}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Type de campagne</InputLabel>
                <Select
                  defaultValue={selectedCampaign?.type || 'email'}
                  label="Type de campagne"
                >
                  <MenuItem value="email">Email</MenuItem>
                  <MenuItem value="social">Réseaux sociaux</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                type="date"
                label="Date de début"
                defaultValue={selectedCampaign?.startDate}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                type="date"
                label="Date de fin"
                defaultValue={selectedCampaign?.endDate}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Statut</InputLabel>
                <Select
                  defaultValue={selectedCampaign?.status || 'scheduled'}
                  label="Statut"
                >
                  <MenuItem value="scheduled">Planifiée</MenuItem>
                  <MenuItem value="active">Active</MenuItem>
                  <MenuItem value="ended">Terminée</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Annuler</Button>
          <Button variant="contained" color="primary">
            {selectedCampaign ? 'Modifier' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default CampaignsPage;
