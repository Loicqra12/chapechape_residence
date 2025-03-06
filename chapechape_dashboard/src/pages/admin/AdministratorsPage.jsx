import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Button,
  IconButton,
  Avatar,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  LinearProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Tooltip,
  Alert,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Security as SecurityIcon,
  AdminPanelSettings as AdminIcon,
  SupervisorAccount as SupervisorIcon,
  Person as PersonIcon,
} from '@mui/icons-material';
import { adminService } from '../../services/adminService';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';

const AdministratorsPage = () => {
  const [administrators, setAdministrators] = useState([]);
  const [roles, setRoles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedAdmin, setSelectedAdmin] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [adminsResponse, rolesResponse] = await Promise.all([
        adminService.getAdministrators(),
        adminService.getRoles()
      ]);

      if (adminsResponse.success && rolesResponse.success) {
        setAdministrators(adminsResponse.data);
        setRoles(rolesResponse.data);
      } else {
        setError('Erreur lors du chargement des données');
      }
    } catch (error) {
      setError('Une erreur est survenue lors de la communication avec le serveur');
    }
    setLoading(false);
  };

  const handleOpenDialog = (admin = null) => {
    setSelectedAdmin(admin);
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setSelectedAdmin(null);
    setOpenDialog(false);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    const formData = new FormData(event.target);
    const adminData = {
      name: formData.get('name'),
      email: formData.get('email'),
      role: formData.get('role'),
      isActive: formData.get('isActive') === 'true'
    };

    try {
      let response;
      if (selectedAdmin) {
        response = await adminService.updateAdministrator(selectedAdmin.id, adminData);
      } else {
        response = await adminService.createAdministrator(adminData);
      }

      if (response.success) {
        handleCloseDialog();
        loadData();
      } else {
        setError(response.error);
      }
    } catch (error) {
      setError('Une erreur est survenue lors de l\'enregistrement');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer cet administrateur ?')) {
      try {
        const response = await adminService.deleteAdministrator(id);
        if (response.success) {
          loadData();
        } else {
          setError(response.error);
        }
      } catch (error) {
        setError('Une erreur est survenue lors de la suppression');
      }
    }
  };

  const getRoleIcon = (role) => {
    switch (role?.toLowerCase()) {
      case 'superadmin':
        return <SecurityIcon />;
      case 'admin':
        return <AdminIcon />;
      case 'moderator':
        return <SupervisorIcon />;
      default:
        return <PersonIcon />;
    }
  };

  const getRoleColor = (role) => {
    switch (role?.toLowerCase()) {
      case 'superadmin':
        return 'error';
      case 'admin':
        return 'primary';
      case 'moderator':
        return 'info';
      default:
        return 'default';
    }
  };

  if (loading) {
    return <LinearProgress />;
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Administrateurs
        </Typography>
        <Button
          variant="contained"
          color="primary"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
        >
          Nouvel Administrateur
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      <TableContainer component={Paper} sx={{ mb: 3 }}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Administrateur</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Rôle</TableCell>
              <TableCell>Statut</TableCell>
              <TableCell>Dernière connexion</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {administrators.map((admin) => (
              <TableRow key={admin.id} hover>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <Avatar 
                      src={admin.avatar}
                      sx={{ mr: 2 }}
                    >
                      {admin.name.charAt(0)}
                    </Avatar>
                    <Typography>{admin.name}</Typography>
                  </Box>
                </TableCell>
                <TableCell>{admin.email}</TableCell>
                <TableCell>
                  <Chip
                    icon={getRoleIcon(admin.role)}
                    label={admin.role}
                    color={getRoleColor(admin.role)}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  <Chip
                    label={admin.isActive ? 'Actif' : 'Inactif'}
                    color={admin.isActive ? 'success' : 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  {admin.lastLogin ? format(new Date(admin.lastLogin), 'dd/MM/yyyy HH:mm', { locale: fr }) : 'Jamais'}
                </TableCell>
                <TableCell align="right">
                  <Tooltip title="Modifier">
                    <IconButton 
                      size="small"
                      onClick={() => handleOpenDialog(admin)}
                    >
                      <EditIcon />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Supprimer">
                    <IconButton 
                      size="small"
                      color="error"
                      onClick={() => handleDelete(admin.id)}
                    >
                      <DeleteIcon />
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog 
        open={openDialog} 
        onClose={handleCloseDialog}
        maxWidth="sm"
        fullWidth
      >
        <form onSubmit={handleSubmit}>
          <DialogTitle>
            {selectedAdmin ? 'Modifier l\'administrateur' : 'Nouvel administrateur'}
          </DialogTitle>
          <DialogContent sx={{ pt: 2 }}>
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Nom"
                  name="name"
                  required
                  defaultValue={selectedAdmin?.name}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Email"
                  name="email"
                  type="email"
                  required
                  defaultValue={selectedAdmin?.email}
                />
              </Grid>
              <Grid item xs={12}>
                <FormControl fullWidth required>
                  <InputLabel>Rôle</InputLabel>
                  <Select
                    name="role"
                    defaultValue={selectedAdmin?.role || ''}
                    label="Rôle"
                  >
                    {roles.map((role) => (
                      <MenuItem key={role.id} value={role.name}>
                        {role.name}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12}>
                <FormControl fullWidth required>
                  <InputLabel>Statut</InputLabel>
                  <Select
                    name="isActive"
                    defaultValue={selectedAdmin?.isActive ?? true}
                    label="Statut"
                  >
                    <MenuItem value="true">Actif</MenuItem>
                    <MenuItem value="false">Inactif</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              {!selectedAdmin && (
                <>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Mot de passe"
                      name="password"
                      type="password"
                      required
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Confirmer le mot de passe"
                      name="confirmPassword"
                      type="password"
                      required
                    />
                  </Grid>
                </>
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
              {selectedAdmin ? 'Modifier' : 'Créer'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>
    </Box>
  );
};

export default AdministratorsPage;
