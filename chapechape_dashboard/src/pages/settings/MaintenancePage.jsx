import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  CardHeader,
  Button,
  LinearProgress,
  Alert,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  ListItemSecondaryAction,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Switch,
  FormControlLabel,
  Chip,
} from '@mui/material';
import {
  BuildCircle as BuildIcon,
  Storage as StorageIcon,
  DeleteSweep as CleanupIcon,
  Backup as BackupIcon,
  Restore as RestoreIcon,
  CloudUpload as UploadIcon,
  Check as CheckIcon,
  Warning as WarningIcon,
  Error as ErrorIcon,
  Schedule as ScheduleIcon,
  Delete as DeleteIcon,
  Download as DownloadIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { maintenanceService } from '../../services/maintenanceService';
import toast from 'react-hot-toast';

const MaintenancePage = () => {
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [backups, setBackups] = useState([]);
  const [systemStatus, setSystemStatus] = useState(null);
  const [openBackupDialog, setOpenBackupDialog] = useState(false);
  const [backupName, setBackupName] = useState('');

  useEffect(() => {
    loadSystemStatus();
    loadBackups();
    loadMaintenanceMode();
  }, []);

  const loadSystemStatus = async () => {
    try {
      const response = await maintenanceService.getSystemStatus();
      if (response.success) {
        setSystemStatus(response.data);
      }
    } catch (error) {
      console.error('Error loading system status:', error);
    }
  };

  const loadBackups = async () => {
    try {
      const response = await maintenanceService.getBackups();
      if (response.success) {
        setBackups(response.data);
      }
    } catch (error) {
      console.error('Error loading backups:', error);
    }
  };

  const loadMaintenanceMode = async () => {
    try {
      const response = await maintenanceService.getMaintenanceMode();
      if (response.success) {
        setMaintenanceMode(response.data.maintenanceMode);
      }
    } catch (error) {
      console.error('Error loading maintenance mode:', error);
    }
  };

  const handleMaintenanceToggle = async () => {
    try {
      setLoading(true);
      const response = await maintenanceService.toggleMaintenanceMode(!maintenanceMode);

      if (response.success) {
        setMaintenanceMode(!maintenanceMode);
        setSuccess(response.message);
        toast.success(response.message);
      } else {
        setError(response.error);
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Error toggling maintenance mode:', error);
      setError('Erreur lors du changement du mode maintenance');
      toast.error('Erreur lors du changement du mode maintenance');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateBackup = async () => {
    if (!backupName) return;
    try {
      setLoading(true);
      const response = await maintenanceService.createBackup(backupName);

      if (response.success) {
        setOpenBackupDialog(false);
        setBackupName('');
        setSuccess(response.message);
        toast.success(response.message);
        loadBackups(); // Reload backups list
      } else {
        setError(response.error);
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Error creating backup:', error);
      setError('Erreur lors de la création de la sauvegarde');
      toast.error('Erreur lors de la création de la sauvegarde');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteBackup = async (backupId) => {
    try {
      setLoading(true);
      const response = await maintenanceService.deleteBackup(backupId);

      if (response.success) {
        setSuccess(response.message);
        toast.success(response.message);
        loadBackups(); // Reload backups list
      } else {
        setError(response.error);
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Error deleting backup:', error);
      setError('Erreur lors de la suppression de la sauvegarde');
      toast.error('Erreur lors de la suppression');
    } finally {
      setLoading(false);
    }
  };

  const handleCleanup = async (type) => {
    try {
      setLoading(true);
      const response = await maintenanceService.cleanup(type);

      if (response.success) {
        setSuccess(response.data.message);
        toast.success(response.data.message);
        loadSystemStatus(); // Reload system status to reflect changes
      } else {
        setError(response.error);
        toast.error(response.error);
      }
    } catch (error) {
      console.error('Error during cleanup:', error);
      setError(`Erreur lors du nettoyage ${type}`);
      toast.error(`Erreur lors du nettoyage ${type}`);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'success':
        return 'success';
      case 'pending':
        return 'warning';
      case 'error':
        return 'error';
      default:
        return 'default';
    }
  };

  const formatSize = (size) => {
    return `${size}GB`;
  };

  const formatDate = (date) => {
    return format(new Date(date), 'dd/MM/yyyy HH:mm', { locale: fr });
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Maintenance Système
        </Typography>
        <FormControlLabel
          control={
            <Switch
              checked={maintenanceMode}
              onChange={handleMaintenanceToggle}
              disabled={loading}
            />
          }
          label={maintenanceMode ? 'Mode maintenance actif' : 'Mode maintenance inactif'}
        />
      </Box>

      {loading && <LinearProgress sx={{ mb: 2 }} />}

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess(null)}>
          {success}
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* État du Système */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader
              title="État du Système"
              avatar={<BuildIcon />}
            />
            <CardContent>
              {systemStatus ? (
                <List>
                  <ListItem>
                    <ListItemIcon>
                      <StorageIcon />
                    </ListItemIcon>
                    <ListItemText
                      primary="Espace Disque"
                      secondary={`${systemStatus.disk?.used || 0}GB utilisés sur ${systemStatus.disk?.total || 0}GB`}
                    />
                    <LinearProgress
                      variant="determinate"
                      value={systemStatus.disk ? (systemStatus.disk.used / systemStatus.disk.total) * 100 : 0}
                      sx={{ width: 100, ml: 2 }}
                    />
                  </ListItem>
                  <ListItem>
                    <ListItemIcon>
                      <StorageIcon />
                    </ListItemIcon>
                    <ListItemText
                      primary="Taille Base de Données"
                      secondary={`${systemStatus.database?.size || 0}GB`}
                    />
                  </ListItem>
                  <ListItem>
                    <ListItemIcon>
                      <StorageIcon />
                    </ListItemIcon>
                    <ListItemText
                      primary="Taille Cache"
                      secondary={`${systemStatus.cache?.size || 0}GB`}
                    />
                  </ListItem>
                  <ListItem>
                    <ListItemIcon>
                      <UploadIcon />
                    </ListItemIcon>
                    <ListItemText
                      primary="Taille Fichiers Uploadés"
                      secondary={`${systemStatus.uploads?.size || 0}GB`}
                    />
                  </ListItem>
                  <ListItem>
                    <ListItemIcon>
                      <ScheduleIcon />
                    </ListItemIcon>
                    <ListItemText
                      primary="Uptime Système"
                      secondary={systemStatus.uptime?.formatted || 'N/A'}
                    />
                  </ListItem>
                </List>
              ) : (
                <Typography>Chargement...</Typography>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Actions de Maintenance */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardHeader
              title="Actions de Maintenance"
              avatar={<CleanupIcon />}
            />
            <CardContent>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <Button
                    fullWidth
                    variant="outlined"
                    startIcon={<CleanupIcon />}
                    onClick={() => handleCleanup('cache')}
                    disabled={loading}
                  >
                    Nettoyer le Cache
                  </Button>
                </Grid>
                <Grid item xs={12}>
                  <Button
                    fullWidth
                    variant="outlined"
                    startIcon={<CleanupIcon />}
                    onClick={() => handleCleanup('temp')}
                    disabled={loading}
                  >
                    Nettoyer les Fichiers Temporaires
                  </Button>
                </Grid>
                <Grid item xs={12}>
                  <Button
                    fullWidth
                    variant="outlined"
                    startIcon={<CleanupIcon />}
                    onClick={() => handleCleanup('logs')}
                    disabled={loading}
                  >
                    Archiver les Logs
                  </Button>
                </Grid>
                <Grid item xs={12}>
                  <Button
                    fullWidth
                    variant="outlined"
                    color="warning"
                    startIcon={<CleanupIcon />}
                    onClick={() => handleCleanup('sessions')}
                    disabled={loading}
                  >
                    Nettoyer les Sessions Expirées
                  </Button>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Sauvegardes */}
        <Grid item xs={12}>
          <Card>
            <CardHeader
              title="Sauvegardes"
              avatar={<BackupIcon />}
              action={
                <Button
                  variant="contained"
                  startIcon={<BackupIcon />}
                  onClick={() => setOpenBackupDialog(true)}
                  disabled={loading}
                >
                  Nouvelle Sauvegarde
                </Button>
              }
            />
            <CardContent>
              <List>
                {backups.map((backup) => (
                  <ListItem key={backup.id}>
                    <ListItemIcon>
                      {backup.status === 'success' ? (
                        <CheckIcon color="success" />
                      ) : backup.status === 'pending' ? (
                        <WarningIcon color="warning" />
                      ) : (
                        <ErrorIcon color="error" />
                      )}
                    </ListItemIcon>
                    <ListItemText
                      primary={backup.name}
                      secondary={`${backup.size} • ${formatDate(backup.date)}`}
                    />
                    <Chip
                      label={backup.type === 'auto' ? 'Auto' : 'Manuel'}
                      size="small"
                      sx={{ mr: 1 }}
                    />
                    <Chip
                      label={backup.status}
                      color={getStatusColor(backup.status)}
                      size="small"
                      sx={{ mr: 1 }}
                    />
                    <ListItemSecondaryAction>
                      <IconButton
                        edge="end"
                        onClick={() => {/* TODO: Télécharger */ }}
                        disabled={backup.status !== 'success'}
                        sx={{ mr: 1 }}
                      >
                        <DownloadIcon />
                      </IconButton>
                      <IconButton
                        edge="end"
                        onClick={() => handleDeleteBackup(backup.id)}
                        disabled={loading}
                      >
                        <DeleteIcon />
                      </IconButton>
                    </ListItemSecondaryAction>
                  </ListItem>
                ))}
              </List>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Dialog Nouvelle Sauvegarde */}
      <Dialog
        open={openBackupDialog}
        onClose={() => setOpenBackupDialog(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          Nouvelle Sauvegarde
        </DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="Nom de la sauvegarde"
            value={backupName}
            onChange={(e) => setBackupName(e.target.value)}
            sx={{ mt: 2 }}
            placeholder="backup_manuel_20250306"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenBackupDialog(false)}>
            Annuler
          </Button>
          <Button
            variant="contained"
            onClick={handleCreateBackup}
            disabled={!backupName}
          >
            Créer
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default MaintenancePage;
