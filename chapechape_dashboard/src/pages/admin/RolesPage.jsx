import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Button,
  IconButton,
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
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  ListItemSecondaryAction,
  Paper,
  Tooltip,
  Alert,
  Checkbox,
  FormGroup,
  FormControlLabel,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Security as SecurityIcon,
  AdminPanelSettings as AdminIcon,
  SupervisorAccount as SupervisorIcon,
  VpnKey as KeyIcon,
  Check as CheckIcon,
} from '@mui/icons-material';
import { adminService } from '../../services/adminService';

const RolesPage = () => {
  const [roles, setRoles] = useState([]);
  const [permissions, setPermissions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedRole, setSelectedRole] = useState(null);
  const [error, setError] = useState(null);
  const [selectedPermissions, setSelectedPermissions] = useState([]);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [rolesResponse, permissionsResponse] = await Promise.all([
        adminService.getRoles(),
        adminService.getPermissions()
      ]);

      if (rolesResponse.success && permissionsResponse.success) {
        setRoles(rolesResponse.data);
        setPermissions(permissionsResponse.data);
      } else {
        setError('Erreur lors du chargement des données');
      }
    } catch (error) {
      setError('Une erreur est survenue lors de la communication avec le serveur');
    }
    setLoading(false);
  };

  const handleOpenDialog = (role = null) => {
    setSelectedRole(role);
    setSelectedPermissions(role?.permissions?.map(p => p.id) || []);
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setSelectedRole(null);
    setSelectedPermissions([]);
    setOpenDialog(false);
  };

  const handlePermissionToggle = (permissionId) => {
    setSelectedPermissions(prev => {
      if (prev.includes(permissionId)) {
        return prev.filter(id => id !== permissionId);
      } else {
        return [...prev, permissionId];
      }
    });
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    const formData = new FormData(event.target);
    const roleData = {
      name: formData.get('name'),
      description: formData.get('description'),
      permissions: selectedPermissions,
      isActive: formData.get('isActive') === 'true'
    };

    try {
      let response;
      if (selectedRole) {
        response = await adminService.updateRole(selectedRole.id, roleData);
      } else {
        response = await adminService.createRole(roleData);
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
    if (window.confirm('Êtes-vous sûr de vouloir supprimer ce rôle ?')) {
      try {
        const response = await adminService.deleteRole(id);
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
    switch (role?.name?.toLowerCase()) {
      case 'superadmin':
        return <SecurityIcon color="error" />;
      case 'admin':
        return <AdminIcon color="primary" />;
      case 'moderator':
        return <SupervisorIcon color="info" />;
      default:
        return <KeyIcon />;
    }
  };

  const groupPermissionsByCategory = (permissions) => {
    return permissions.reduce((acc, permission) => {
      const category = permission.category || 'Autre';
      if (!acc[category]) {
        acc[category] = [];
      }
      acc[category].push(permission);
      return acc;
    }, {});
  };

  if (loading) {
    return <LinearProgress />;
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Rôles et Permissions
        </Typography>
        <Button
          variant="contained"
          color="primary"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
        >
          Nouveau Rôle
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      <Grid container spacing={3}>
        {roles.map((role) => (
          <Grid item xs={12} md={6} lg={4} key={role.id}>
            <Card 
              sx={{ 
                height: '100%',
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
                    {getRoleIcon(role)}
                    <Typography variant="h6">
                      {role.name}
                    </Typography>
                  </Box>
                  <Box>
                    <Tooltip title="Modifier">
                      <IconButton size="small" onClick={() => handleOpenDialog(role)}>
                        <EditIcon />
                      </IconButton>
                    </Tooltip>
                    {!['superadmin', 'admin'].includes(role.name.toLowerCase()) && (
                      <Tooltip title="Supprimer">
                        <IconButton size="small" color="error" onClick={() => handleDelete(role.id)}>
                          <DeleteIcon />
                        </IconButton>
                      </Tooltip>
                    )}
                  </Box>
                </Box>

                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  {role.description}
                </Typography>

                <Typography variant="subtitle2" sx={{ mb: 1 }}>
                  Permissions ({role.permissions?.length || 0})
                </Typography>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                  {role.permissions?.map((permission) => (
                    <Chip
                      key={permission.id}
                      label={permission.name}
                      size="small"
                      variant="outlined"
                    />
                  ))}
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Dialog 
        open={openDialog} 
        onClose={handleCloseDialog}
        maxWidth="md"
        fullWidth
      >
        <form onSubmit={handleSubmit}>
          <DialogTitle>
            {selectedRole ? 'Modifier le rôle' : 'Nouveau rôle'}
          </DialogTitle>
          <DialogContent sx={{ pt: 2 }}>
            <Grid container spacing={3}>
              <Grid item xs={12} md={6}>
                <Grid container spacing={2}>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Nom du rôle"
                      name="name"
                      required
                      defaultValue={selectedRole?.name}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Description"
                      name="description"
                      multiline
                      rows={4}
                      defaultValue={selectedRole?.description}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <FormControl fullWidth required>
                      <InputLabel>Statut</InputLabel>
                      <Select
                        name="isActive"
                        defaultValue={selectedRole?.isActive ?? true}
                        label="Statut"
                      >
                        <MenuItem value="true">Actif</MenuItem>
                        <MenuItem value="false">Inactif</MenuItem>
                      </Select>
                    </FormControl>
                  </Grid>
                </Grid>
              </Grid>

              <Grid item xs={12} md={6}>
                <Typography variant="subtitle1" sx={{ mb: 2 }}>
                  Permissions
                </Typography>
                <Paper sx={{ maxHeight: 400, overflow: 'auto', p: 2 }}>
                  {Object.entries(groupPermissionsByCategory(permissions)).map(([category, perms]) => (
                    <Box key={category} sx={{ mb: 2 }}>
                      <Typography variant="subtitle2" color="primary" sx={{ mb: 1 }}>
                        {category}
                      </Typography>
                      <FormGroup>
                        {perms.map((permission) => (
                          <FormControlLabel
                            key={permission.id}
                            control={
                              <Checkbox
                                checked={selectedPermissions.includes(permission.id)}
                                onChange={() => handlePermissionToggle(permission.id)}
                                size="small"
                              />
                            }
                            label={
                              <Typography variant="body2">
                                {permission.name}
                              </Typography>
                            }
                          />
                        ))}
                      </FormGroup>
                    </Box>
                  ))}
                </Paper>
              </Grid>
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={handleCloseDialog}>Annuler</Button>
            <Button 
              type="submit"
              variant="contained" 
              color="primary"
              startIcon={<CheckIcon />}
            >
              {selectedRole ? 'Modifier' : 'Créer'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>
    </Box>
  );
};

export default RolesPage;
