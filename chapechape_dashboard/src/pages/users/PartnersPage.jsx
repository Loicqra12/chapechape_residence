import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Button,
  IconButton,
  Avatar,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Grid,
  LinearProgress,
  Alert,
  Tooltip,
  Rating,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Block as BlockIcon,
  CheckCircle as CheckCircleIcon,
  Verified as VerifiedIcon,
  Email as EmailIcon,
  Home as HomeIcon,
  Star as StarIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { adminService } from '../../services/adminService';

const PartnersPage = () => {
  const [partners, setPartners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedPartner, setSelectedPartner] = useState(null);

  useEffect(() => {
    loadPartners();
  }, []);

  const loadPartners = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await adminService.getAllPartners();
      if (response.success) {
        // Transformer les données backend pour correspondre à l'interface
        const transformedPartners = response.data.map(partner => ({
          id: partner._id || partner.id,
          name: partner.companyName || partner.businessName || partner.name || `${partner.firstName || ''} ${partner.lastName || ''}`.trim() || 'Partenaire',
          contactName: `${partner.firstName || ''} ${partner.lastName || ''}`.trim() || partner.contactName || 'Contact',
          email: partner.email,
          phone: partner.phoneNumber || partner.phone,
          status: partner.status || 'active',
          verified: partner.verificationStatus === 'verified' || partner.verified || false,
          createdAt: partner.createdAt,
          lastActive: partner.lastLogin || partner.lastActive,
          propertiesCount: partner.residencesCount || partner.propertiesCount || 0,
          rating: partner.rating || 0,
          type: partner.partnerType || partner.type || 'individual',
          address: partner.address || partner.businessAddress,
          avatar: partner.profileImage || partner.avatar,
          // Champs additionnels pour les partenaires
          businessType: partner.businessType,
          documents: partner.documents || [],
          verificationStatus: partner.verificationStatus || 'pending'
        }));
        setPartners(transformedPartners);
      } else {
        throw new Error(response.error || 'Erreur lors du chargement des partenaires');
      }
    } catch (error) {
      console.error('Erreur lors du chargement des partenaires:', error);
      setError(error.message || 'Erreur lors du chargement des partenaires');
      // En cas d'erreur, utiliser des données de fallback
      setPartners([]);
    }
    setLoading(false);
  };

  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const handleOpenDialog = (partner = null) => {
    setSelectedPartner(partner);
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setSelectedPartner(null);
    setOpenDialog(false);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    // TODO: Implémenter la logique de sauvegarde
    handleCloseDialog();
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'active':
        return 'success';
      case 'pending':
        return 'warning';
      case 'inactive':
        return 'error';
      default:
        return 'default';
    }
  };

  const getStatusLabel = (status) => {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'pending':
        return 'En attente';
      case 'inactive':
        return 'Inactif';
      default:
        return status;
    }
  };

  const getPartnerTypeLabel = (type) => {
    switch (type) {
      case 'agency':
        return 'Agence';
      case 'individual':
        return 'Particulier';
      case 'company':
        return 'Entreprise';
      default:
        return type;
    }
  };

  if (loading) {
    return <LinearProgress />;
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Partenaires
        </Typography>
        <Button
          variant="contained"
          color="primary"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
        >
          Nouveau Partenaire
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Partenaire</TableCell>
              <TableCell>Contact</TableCell>
              <TableCell>Type</TableCell>
              <TableCell>Statut</TableCell>
              <TableCell>Résidences</TableCell>
              <TableCell>Note</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {partners
              .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
              .map((partner) => (
                <TableRow key={partner.id} hover>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                      <Avatar 
                        src={partner.avatar}
                        sx={{ mr: 2 }}
                      >
                        {partner.name.charAt(0)}
                      </Avatar>
                      <Box>
                        <Typography variant="subtitle2">
                          {partner.name}
                          {partner.verified && (
                            <VerifiedIcon 
                              color="primary" 
                              sx={{ width: 16, height: 16, ml: 1 }}
                            />
                          )}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {partner.address}
                        </Typography>
                      </Box>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">{partner.contactName}</Typography>
                    <Typography variant="caption" color="text.secondary">
                      {partner.email} • {partner.phone}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={getPartnerTypeLabel(partner.type)}
                      size="small"
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={getStatusLabel(partner.status)}
                      color={getStatusColor(partner.status)}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                      <HomeIcon sx={{ width: 16, height: 16, mr: 1 }} />
                      <Typography variant="body2">
                        {partner.propertiesCount}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Rating 
                      value={partner.rating} 
                      readOnly 
                      precision={0.5}
                      size="small"
                    />
                  </TableCell>
                  <TableCell align="right">
                    <Tooltip title="Envoyer un email">
                      <IconButton size="small" color="primary">
                        <EmailIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Modifier">
                      <IconButton 
                        size="small"
                        onClick={() => handleOpenDialog(partner)}
                      >
                        <EditIcon />
                      </IconButton>
                    </Tooltip>
                    {partner.status !== 'inactive' ? (
                      <Tooltip title="Désactiver">
                        <IconButton size="small" color="error">
                          <BlockIcon />
                        </IconButton>
                      </Tooltip>
                    ) : (
                      <Tooltip title="Activer">
                        <IconButton size="small" color="success">
                          <CheckCircleIcon />
                        </IconButton>
                      </Tooltip>
                    )}
                  </TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
        <TablePagination
          rowsPerPageOptions={[5, 10, 25]}
          component="div"
          count={partners.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          labelRowsPerPage="Lignes par page"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} sur ${count}`}
        />
      </TableContainer>

      <Dialog 
        open={openDialog} 
        onClose={handleCloseDialog}
        maxWidth="md"
        fullWidth
      >
        <form onSubmit={handleSubmit}>
          <DialogTitle>
            {selectedPartner ? 'Modifier le partenaire' : 'Nouveau partenaire'}
          </DialogTitle>
          <DialogContent sx={{ pt: 2 }}>
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Nom de l'entreprise"
                  name="name"
                  required
                  defaultValue={selectedPartner?.name}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Nom du contact"
                  name="contactName"
                  required
                  defaultValue={selectedPartner?.contactName}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Email"
                  name="email"
                  type="email"
                  required
                  defaultValue={selectedPartner?.email}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Téléphone"
                  name="phone"
                  required
                  defaultValue={selectedPartner?.phone}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Adresse"
                  name="address"
                  multiline
                  rows={2}
                  defaultValue={selectedPartner?.address}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth required>
                  <InputLabel>Type de partenaire</InputLabel>
                  <Select
                    name="type"
                    defaultValue={selectedPartner?.type || 'agency'}
                    label="Type de partenaire"
                  >
                    <MenuItem value="agency">Agence</MenuItem>
                    <MenuItem value="individual">Particulier</MenuItem>
                    <MenuItem value="company">Entreprise</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth required>
                  <InputLabel>Statut</InputLabel>
                  <Select
                    name="status"
                    defaultValue={selectedPartner?.status || 'pending'}
                    label="Statut"
                  >
                    <MenuItem value="active">Actif</MenuItem>
                    <MenuItem value="pending">En attente</MenuItem>
                    <MenuItem value="inactive">Inactif</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              {!selectedPartner && (
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Mot de passe initial"
                    name="password"
                    type="password"
                    required
                    helperText="Un email sera envoyé au partenaire pour définir son mot de passe"
                  />
                </Grid>
              )}
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={handleCloseDialog}>Annuler</Button>
            <Button 
              type="submit"
              variant="contained" 
              color="primary"
            >
              {selectedPartner ? 'Modifier' : 'Créer'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>
    </Box>
  );
};

export default PartnersPage;
