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
  ToggleButton,
  ToggleButtonGroup,
  Badge,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Block as BlockIcon,
  CheckCircle as CheckCircleIcon,
  Verified as VerifiedIcon,
  Email as EmailIcon,
  CalendarMonth as CalendarIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import ImageUpload from '../../components/common/ImageUpload';
import { adminService } from '../../services/adminService';

const ClientsPage = () => {
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedClient, setSelectedClient] = useState(null);
  const [verificationFilter, setVerificationFilter] = useState('all');
  const [openBookingsDialog, setOpenBookingsDialog] = useState(false);
  const [selectedClientBookings, setSelectedClientBookings] = useState([]);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [editingClient, setEditingClient] = useState(null);
  const [uploadedImage, setUploadedImage] = useState(null);

  useEffect(() => {
    loadClients();
  }, []);

  const loadClients = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await adminService.getAllClients();
      if (response.success) {
        // Transformer les données backend pour correspondre à l'interface
        const transformedClients = response.data.map(client => ({
          id: client._id || client.id,
          name: `${client.firstName || ''} ${client.lastName || ''}`.trim() || client.name || 'Utilisateur',
          email: client.email,
          phone: client.phoneNumber || client.phone,
          status: client.status || 'active',
          verified: client.isVerified || client.verified || false,
          createdAt: client.createdAt,
          lastLogin: client.lastLogin,
          bookingsCount: client.bookingsCount || 0,
          avatar: client.profileImage || client.avatar,
          bookings: client.bookings || [] // Sera chargé séparément si nécessaire
        }));
        setClients(transformedClients);
      } else {
        throw new Error(response.error || 'Erreur lors du chargement des clients');
      }
    } catch (error) {
      console.error('Erreur lors du chargement des clients:', error);
      setError(error.message || 'Erreur lors du chargement des clients');
      // En cas d'erreur, utiliser des données de fallback
      setClients([]);
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

  const handleOpenDialog = (client = null) => {
    setSelectedClient(client);
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setSelectedClient(null);
    setOpenDialog(false);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    const formData = new FormData(event.target);
    const clientData = {
      firstName: formData.get('firstName'),
      lastName: formData.get('lastName'),
      email: formData.get('email'),
      phoneNumber: formData.get('phone'),
      status: formData.get('status') || 'active'
    };

    try {
      let response;
      if (selectedClient && selectedClient.id) {
        // Mise à jour d'un client existant
        response = await adminService.updateClient(selectedClient.id, clientData);
      } else {
        // Création d'un nouveau client (si implémenté côté backend)
        console.log('Création de nouveaux clients non implémentée');
        return;
      }

      if (response.success) {
        await loadClients(); // Recharger la liste
        handleCloseDialog();
      } else {
        setError(response.error || 'Erreur lors de la sauvegarde du client');
      }
    } catch (error) {
      console.error('Erreur lors de la sauvegarde:', error);
      setError('Erreur lors de la sauvegarde du client');
    }
  };

  const handleDeleteClient = async (clientId) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer ce client ?')) {
      try {
        const response = await adminService.deleteClient(clientId);
        if (response.success) {
          await loadClients(); // Recharger la liste
        } else {
          setError(response.error || 'Erreur lors de la suppression du client');
        }
      } catch (error) {
        console.error('Erreur lors de la suppression:', error);
        setError('Erreur lors de la suppression du client');
      }
    }
  };

  const handleToggleClientStatus = async (clientId, currentStatus) => {
    const newStatus = currentStatus === 'active' ? 'inactive' : 'active';
    try {
      const response = await adminService.updateClient(clientId, { status: newStatus });
      if (response.success) {
        await loadClients(); // Recharger la liste
      } else {
        setError(response.error || 'Erreur lors de la mise à jour du statut');
      }
    } catch (error) {
      console.error('Erreur lors de la mise à jour du statut:', error);
      setError('Erreur lors de la mise à jour du statut');
    }
  };

  const handleVerificationFilterChange = (event, newFilter) => {
    if (newFilter !== null) {
      setVerificationFilter(newFilter);
    }
  };

  const handleOpenBookings = (client) => {
    setSelectedClient(client);
    setSelectedClientBookings(client.bookings);
    setOpenBookingsDialog(true);
  };

  const handleCloseBookings = () => {
    setSelectedClient(null);
    setSelectedClientBookings([]);
    setOpenBookingsDialog(false);
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'active':
        return 'success';
      case 'inactive':
        return 'warning';
      case 'blocked':
        return 'error';
      default:
        return 'default';
    }
  };

  const getStatusLabel = (status) => {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'inactive':
        return 'Inactif';
      case 'blocked':
        return 'Bloqué';
      default:
        return status;
    }
  };

  const getBookingStatusColor = (status) => {
    switch (status) {
      case 'confirmed':
        return 'success';
      case 'pending':
        return 'warning';
      case 'cancelled':
        return 'error';
      default:
        return 'default';
    }
  };

  const getBookingStatusLabel = (status) => {
    switch (status) {
      case 'confirmed':
        return 'Confirmée';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  };

  const handleEditClient = (client) => {
    setEditingClient(client);
    setUploadedImage(client?.avatar);
    setEditDialogOpen(true);
  };

  const handleCloseEditDialog = () => {
    setEditingClient(null);
    setUploadedImage(null);
    setEditDialogOpen(false);
  };

  const handleImageChange = async (file) => {
    // TODO: Implémenter l'upload vers le serveur
    const imageUrl = URL.createObjectURL(file);
    setUploadedImage(imageUrl);
  };

  const handleImageDelete = () => {
    setUploadedImage(null);
  };

  const handleSaveClient = async (event) => {
    event.preventDefault();
    const formData = new FormData(event.target);
    
    const clientData = {
      name: formData.get('name'),
      email: formData.get('email'),
      phone: formData.get('phone'),
      avatar: uploadedImage,
    };

    try {
      // TODO: Appel API pour sauvegarder le client
      console.log('Saving client:', clientData);
      handleCloseEditDialog();
    } catch (error) {
      setError('Erreur lors de la sauvegarde du client');
    }
  };

  const filteredClients = clients.filter(client => {
    switch (verificationFilter) {
      case 'verified':
        return client.verified;
      case 'unverified':
        return !client.verified;
      default:
        return true;
    }
  });

  if (loading) {
    return <LinearProgress />;
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Clients
        </Typography>
        <Button
          variant="contained"
          color="primary"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
        >
          Nouveau Client
        </Button>
      </Box>

      <Box sx={{ mb: 3 }}>
        <ToggleButtonGroup
          value={verificationFilter}
          exclusive
          onChange={handleVerificationFilterChange}
          aria-label="Filtre de vérification"
        >
          <ToggleButton value="all">
            Tous
          </ToggleButton>
          <ToggleButton value="verified">
            <VerifiedIcon sx={{ mr: 1 }} />
            Vérifiés
          </ToggleButton>
          <ToggleButton value="unverified">
            <BlockIcon sx={{ mr: 1 }} />
            Non vérifiés
          </ToggleButton>
        </ToggleButtonGroup>
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
              <TableCell>Client</TableCell>
              <TableCell>Contact</TableCell>
              <TableCell>Statut</TableCell>
              <TableCell>Réservations</TableCell>
              <TableCell>Dernière connexion</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredClients
              .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
              .map((client) => (
                <TableRow key={client.id} hover>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                      <Avatar 
                        src={client.avatar}
                        sx={{ mr: 2 }}
                      >
                        {client.name.charAt(0)}
                      </Avatar>
                      <Box>
                        <Typography variant="subtitle2">
                          {client.name}
                          {client.verified && (
                            <VerifiedIcon 
                              color="primary" 
                              sx={{ width: 16, height: 16, ml: 1 }}
                            />
                          )}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          Inscrit le {format(new Date(client.createdAt), 'dd/MM/yyyy', { locale: fr })}
                        </Typography>
                      </Box>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">{client.email}</Typography>
                    <Typography variant="caption" color="text.secondary">
                      {client.phone}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={getStatusLabel(client.status)}
                      color={getStatusColor(client.status)}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    <Button
                      variant="text"
                      startIcon={<CalendarIcon />}
                      onClick={() => handleOpenBookings(client)}
                    >
                      <Badge badgeContent={client.bookingsCount} color="primary">
                        Voir
                      </Badge>
                    </Button>
                  </TableCell>
                  <TableCell>
                    {format(new Date(client.lastLogin), 'dd/MM/yyyy HH:mm', { locale: fr })}
                  </TableCell>
                  <TableCell align="right">
                    <Tooltip title="Modifier">
                      <IconButton onClick={() => handleEditClient(client)} size="small">
                        <EditIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Envoyer un email">
                      <IconButton size="small">
                        <EmailIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Bloquer">
                      <IconButton size="small">
                        <BlockIcon />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
        <TablePagination
          component="div"
          count={filteredClients.length}
          page={page}
          onPageChange={handleChangePage}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          labelRowsPerPage="Lignes par page"
          labelDisplayedRows={({ from, to, count }) => `${from}-${to} sur ${count}`}
        />
      </TableContainer>

      {/* Dialog des réservations */}
      <Dialog
        open={openBookingsDialog}
        onClose={handleCloseBookings}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          Réservations de {selectedClient?.name}
        </DialogTitle>
        <DialogContent>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Résidence</TableCell>
                  <TableCell>Dates</TableCell>
                  <TableCell>Statut</TableCell>
                  <TableCell>Prix</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {selectedClientBookings.map((booking) => (
                  <TableRow key={booking.id}>
                    <TableCell>{booking.residenceName}</TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        Du {format(new Date(booking.checkIn), 'dd/MM/yyyy', { locale: fr })}
                      </Typography>
                      <Typography variant="body2">
                        Au {format(new Date(booking.checkOut), 'dd/MM/yyyy', { locale: fr })}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={getBookingStatusLabel(booking.status)}
                        color={getBookingStatusColor(booking.status)}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      {booking.totalPrice} €
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseBookings}>
            Fermer
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog d'édition du client */}
      <Dialog 
        open={editDialogOpen} 
        onClose={handleCloseEditDialog}
        maxWidth="sm"
        fullWidth
      >
        <form onSubmit={handleSaveClient}>
          <DialogTitle>
            {editingClient ? 'Modifier le client' : 'Nouveau client'}
          </DialogTitle>
          <DialogContent>
            <Grid container spacing={3} sx={{ mt: 1 }}>
              <Grid item xs={12} display="flex" justifyContent="center">
                <ImageUpload
                  currentImage={uploadedImage}
                  onImageChange={handleImageChange}
                  onImageDelete={handleImageDelete}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Nom complet"
                  name="name"
                  required
                  defaultValue={editingClient?.name}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Email"
                  name="email"
                  type="email"
                  required
                  defaultValue={editingClient?.email}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Téléphone"
                  name="phone"
                  defaultValue={editingClient?.phone}
                />
              </Grid>
              {!editingClient && (
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Mot de passe"
                    name="password"
                    type="password"
                    required
                  />
                </Grid>
              )}
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={handleCloseEditDialog}>
              Annuler
            </Button>
            <Button 
              type="submit" 
              variant="contained" 
              color="primary"
            >
              {editingClient ? 'Enregistrer' : 'Créer'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>
    </Box>
  );
};

export default ClientsPage;
